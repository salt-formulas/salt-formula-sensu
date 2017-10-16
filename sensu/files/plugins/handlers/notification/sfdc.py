#!/usr/bin/env python

import logging
import os
import sys
import yaml
import json
import sys
import smtplib
import requests
import json
import socket
from optparse import OptionParser
from email.mime.text import MIMEText
from datetime import datetime
import dateutil.parser
from argparse import ArgumentParser
from salesforce import OAuth2, Client


try:
    from sensu import Handler
except ImportError:
    print('You must have the sensu Python module i.e.: pip install sensu')
    sys.exit(1)

DELTA_SECONDS=3000000000

LOG = logging.getLogger()
#LOG.setLevel(INFO)

class SfdcHandler(Handler):

    def filter_repeated(self):
        # Disable the default implementation of this so that we can manage filters
        # completely via the model/Sensu config.
        return False

    def _format_body(self, data):
        s = ""
        keys = list(data.keys())
        keys.sort()
        for k in keys:
            if k == 'Description':
                continue
            else:
                s += "{}: {}\n".format(k, data[k])
        if 'Description' in keys:
            s += "\nDescription:\n" + self._format_body(data['Description'])
        return s

    def handle(self):
        client_id = self.settings.get('sfdc', {}).get('sfdc_client_id')
        client_secret = self.settings.get('sfdc', {}).get('sfdc_client_secret')
        username = self.settings.get('sfdc', {}).get('sfdc_username')
        password = self.settings.get('sfdc', {}).get('sfdc_password')
        auth_url = self.settings.get('sfdc', {}).get('sfdc_auth_url')
        http_proxy = self.settings.get('sfdc', {}).get('sfdc_http_proxy')
        https_proxy = self.settings.get('sfdc', {}).get('sfdc_https_proxy')
        organization_id = self.settings.get('sfdc', {}).get('sfdc_organization_id')
        environment = self.settings.get('sfdc', {}).get('environment')
        token_cache_file = self.settings.get('sfdc', {}).get('token_cache_file', None)

        print self.event
        print "client_id: ", client_id
        #print "client_secrete: ", client_secret
        print "auth_url: ", auth_url
        print "http_proxy: ", http_proxy
        print "https_proxy: ", https_proxy
        print "organization: ", organization_id
        print "username: ", username
        sfdc_oauth2 = OAuth2(client_id, client_secret, username, password,
                             auth_url, http_proxy, https_proxy, organization_id)

        data = self.event
        client_host = data.get('client', {}).get('name')
        check_name = data.get('check', {}).get('name')
        check_action = data.get('action')
        timestamp = data.get('check', {}).get('issued')
        check_date = datetime.fromtimestamp(int(timestamp)).strftime('%Y-%m-%d %H:%M:%S')
        check_output = data.get('check', {}).get('output')
        status = data.get('check', {}).get('status')

        severity_map = {
            0: '060 Informational',
            1: '080 Warning',
            2: '090 Critical',
            3: '070 Unknown'
        }
        notification_map = {
            'create': 'PROBLEM',
            'resolve': 'RECOVERY'
        }

        try:
            severity = severity_map[int(status)]
        except (KeyError, ValueError):
            severity = "none"
            
        try:
            notification = notification_map[check_action]
        except KeyError:
            notification = "CUSTOM"

        Alert_ID = '{}--{}--{}'.format(environment,client_host, check_name)
        
        print 'Alert_Id: {} '.format(Alert_ID)
        LOG.debug('Alert_Id: {} '.format(Alert_ID))

        sfdc_client = Client(sfdc_oauth2)
        # read cached token if it exists
        if token_cache_file:
            try:
                with open(token_cache_file, 'r') as fp:
                    cached_tokens = yaml.load(fp)
            except IOError as e:
                cached_tokens = None
                LOG.debug('Error reading token_cache_file')
                LOG.debug(e)
            if isinstance(cached_tokens, dict) and 'access' in cached_tokens \
                    and 'instance_url' in cached_tokens:

                sfdc_client.access_token = cached_tokens['access']
                sfdc_client.instance_url = cached_tokens['instance_url']

                #TODO: There's probably better way to handle this test.
                test_response = sfdc_client.get_case('case_id_that_doesnt_exist')
                if test_response.status_code == 401:
                    # If auth fails, reset tokens to None to force re-auth.
                    sfdc_client.access_token = None
                    sfdc_client.instance_url = None
                    LOG.debug('Cached access token expired.  Going to re-auth.')
                else:
                    LOG.debug('Using cached access token.')

        print "severity", severity
        print "check_action", check_action
        print "check_output", check_output
        print "long_date_time", check_date
        print "environment", environment
        print "NOTIFICATION", notification
        payload = {
            'notification_type': notification,
            'check_output':      check_output,
            'long_date_time':    check_date,
        }

        subject = "{}/{}".format(client_host, check_name)
        data = {
            'IsMosAlert__c':     'true',
            #'Description':       json.dumps(payload, sort_keys=True, indent=4),
            'Description':       self._format_body(payload),
            'Alert_ID__c':       Alert_ID,
            'Subject':           subject,
            'Environment2__c':   environment,
            'Alert_Priority__c': severity,
            'Alert_Host__c':     client_host,
            'Alert_Service__c':  check_name,
        }

        feed_data_body = {
            'Description':    payload,
            'Alert_Id':       Alert_ID,
            'Cloud_ID':       environment,
            'Alert_Priority': severity,
            'Status':         "New",
        }

        try:
            new_case = sfdc_client.create_case(data)
        except Exception as E:
            print "new case exception", E
            sys.exit(1)


        #  If Case exist
        if (new_case.status_code == 400) and \
                (new_case.json()[0]['errorCode'] == 'DUPLICATE_VALUE'):

            LOG.debug('Code: {}, Error message: {} '.format(new_case.status_code,
                                                            new_case.text))
            # Find Case ID
            ExistingCaseId = new_case.json()[0]['message'].split(" ")[-1]
            LOG.debug('ExistingCaseId: {} '.format(ExistingCaseId))
            # Get Case
            current_case = sfdc_client.get_case(ExistingCaseId).json()
            LOG.debug("Existing Case: \n {}".format(json.dumps(current_case,
                                                    sort_keys=True, indent=4)))

            LastModifiedDate = current_case['LastModifiedDate']
            ExistingCaseStatus = current_case['Status']
            feed_data_body['Status'] = ExistingCaseStatus

            Now = datetime.now().replace(tzinfo=None)
            delta = Now - dateutil.parser.parse(LastModifiedDate).replace(tzinfo=None)

            LOG.debug("Check if Case should be marked as OUTDATED. Case "
                      "modification date is: {} , Now: {} , Delta(sec): {}, "
                      "OutdateDelta(sec): {}".format(LastModifiedDate, Now,
                                                     delta.seconds, DELTA_SECONDS))

            if (delta.seconds > DELTA_SECONDS):
                # Old Case is outdated
                tmp_date = datetime.strftime(datetime.now(), "%Y.%m.%d-%H:%M:%S")
                new_data = {
                   'Alert_Id__c': '{}_closed_at_{}'.format(current_case['Alert_ID__c'],
                                                           tmp_date),
                   'Alert_Priority__c': '000 OUTDATED',
                }
                u = sfdc_client.update_case(id=ExistingCaseId, data=new_data)
                LOG.debug('Update status code: {} \n\nUpdate content: {}'
                          '\n\n Update headers: {}\n\n'.format(u.status_code,
                                                               u.content,
                                                               u.headers))

                # Try to create new case again
                try:
                    new_case = sfdc_client.create_case(data)
                except Exception as E:
                    LOG.debug(E)
                    sys.exit(1)
                else:
                    # Case was outdated an new was created
                    CaseId = new_case.json()['id']
                    LOG.debug("Case was just created, old one marked as Outdated")
                    # Add comment, because Case head should contains LAST data
                    # overwritten on any update
                    CaseId = new_case.json()['id']

                    feeditem_data = {
                      'ParentId':   CaseId,
                      'Visibility': 'AllUsers',
                      #'Body': json.dumps(feed_data_body, sort_keys=True, indent=4),
                      'Body': self._format_body(feed_data_body),
                    }
                    LOG.debug("FeedItem Data: {}".format(json.dumps(feeditem_data,
                                                                    sort_keys=True,
                                                                    indent=4)))
                    add_feed_item = sfdc_client.create_feeditem(feeditem_data)
                    LOG.debug('Add FeedItem status code: {}\nAdd FeedItem '
                              'reply: {}'.format(add_feed_item.status_code,
                                                 add_feed_item.text))

            else:
                # Update Case
                # If ok, mark case as solved.
                if notification == "RECOVERY":
                    data['Status'] = 'Auto-solved'
                    feed_data_body['Status'] = 'Auto-solved'

                u = sfdc_client.update_case(id=ExistingCaseId, data=data)
                LOG.debug('Upate status code: {} '.format(u.status_code))

                feeditem_data = {
                    'ParentId':   ExistingCaseId,
                    'Visibility': 'AllUsers',
                    #'Body': json.dumps(feed_data_body, sort_keys=True, indent=4),
                    'Body': self._format_body(feed_data_body),
                }

                LOG.debug("FeedItem Data: {}".format(json.dumps(feeditem_data,
                                                                sort_keys=True,
                                                                indent=4)))
                add_feed_item = sfdc_client.create_feeditem(feeditem_data)
                LOG.debug('Add FeedItem status code: {}\nAdd FeedItem '
                          'reply: {} '.format(add_feed_item.status_code,
                                              add_feed_item.text))

        # Else If Case did not exist before and was just created
        elif (new_case.status_code == 201):
            LOG.debug("Case was just created")

            # Add comment, because Case head should contain LAST data
            # overwritten on any update
            CaseId = new_case.json()['id']

            # If OK, ensure "Auto-solved" is in the first feed.
            if notification == "RECOVERY":
                feed_data_body['Status'] = 'Auto-solved'
            feeditem_data = {
              'ParentId':   CaseId,
              'Visibility': 'AllUsers',
              #'Body': json.dumps(feed_data_body, sort_keys=True, indent=4),
              'Body': self._format_body(feed_data_body),
     
            }
            LOG.debug("FeedItem Data: {}".format(json.dumps(feeditem_data,
                                                            sort_keys=True,
                                                            indent=4)))
            add_feed_item = sfdc_client.create_feeditem(feeditem_data)
            LOG.debug('Add FeedItem status code: {}\nAdd FeedItem '
                      'reply: {} '.format(add_feed_item.status_code,
                                          add_feed_item.text))

            # If OK, mark case as solved.
            if notification == "RECOVERY":
                data['Status'] = 'Auto-solved'

            u = sfdc_client.update_case(id=CaseId, data=data)
            LOG.debug('Update status code: {} '.format(u.status_code))

        else:
            LOG.debug("Unexpected error: Case was not created (code !=201) "
                      "and Case does not exist (code != 400)")


        # Write out token/instance_url
        if token_cache_file:
            try:
                with open(token_cache_file, 'w') as fp:
                    fp.write("access: {}\n".format(sfdc_client.access_token))
                    fp.write("instance_url: {}\n".format(sfdc_client.instance_url))
            except IOError as e:
                LOG.debug('Error writing out token cache.')
                LOG.debug(e)

        sys.exit(1)

    def check_kedb(self):
        host = self.settings.get('sfdc', {}).get('kedb_host', 'localhost')
        port = self.settings.get('sfdc', {}).get('kedb_port', 25)
        url = 'http://%s:%s/handle/' % (host, port)
        print 'URL============================='
        print url
        payload = {
            'event': self.event,
        }
        print 'PAYLOAD============================='
        print payload
        response = requests.post(url, data=json.dumps(payload))
        print 'RESPONSE============================='
        print response
        print 'RESPONSE-DATA=========================='
        self.event = response.json()
        print self.event
#        return data

if __name__=='__main__':
    m = SfdcHandler()
    sys.exit(0)
