#!/usr/bin/env python

import sys
import smtplib
import requests
import json
from optparse import OptionParser
from email.mime.text import MIMEText
from datetime import datetime

try:
    from sensu import Handler
except ImportError:
    print('You must have the sensu Python module i.e.: pip install sensu')
    sys.exit(1)

class SccdHandler(Handler):

    def handle(self):
        mail_subj = self.settings.get('sccd', {}).get('mail_subject', 'Sensu Alert')
        mail_to = self.settings.get('sccd', {}).get('sccd_email', 'root@localhost')
        mail_from_addr = self.settings.get('sccd', {}).get('mail_user', 'sensu@localhost')
        mail_host = self.settings.get('sccd', {}).get('mail_host', 'localhost')
        mail_port = self.settings.get('sccd', {}).get('mail_port', 25)
        mail_user = self.settings.get('sccd', {}).get('mail_user', None)
        mail_password = self.settings.get('sccd', {}).get('mail_password', None)
        print 'SENSU_EVENT=========================='
        print self.event
        self.check_kedb()
        if self.event.get('occurences') < 2 and self.event.get('action') == 'create':
            self.send_mail(mail_subj, mail_to, mail_from_addr, mail_host, mail_port, mail_user, mail_password)
        else:
            if self.event.get('action') != 'create':
                self.send_mail(mail_subj, mail_to, mail_from_addr, mail_host, mail_port, mail_user, mail_password)            

    def check_kedb(self):
        host = self.settings.get('sccd', {}).get('kedb_host', 'localhost')
        port = self.settings.get('sccd', {}).get('kedb_port', 25)
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

    def send_mail(self, subj=None, to_addr=None, from_addr=None, host='localhost',
        port=25, user=None, password=None):
        # attempt to parse sensu message
        try:
            data = self.event
            client_host = data.get('client', {}).get('name')
            check_name = data.get('check', {}).get('name')
            check_action = data.get('action')
            timestamp = data.get('check', {}).get('issued')
            check_date = datetime.fromtimestamp(int(timestamp)).strftime('%Y-%m-%d %H:%M:%S')
            if data.get('known_error'):
                template_id = 'CL-%s-%s' % (data.get('level'), data.get('severity'))
                applies_to = 'incident'
            else:
                template_id = 'CL-L2-INT'
                applies_to = 'incident'
            parts = (
                '<MAXIMOEMAILCONTENT>',
                '  <LSNRACTION>%s</LSNRACTION>' % check_action.upper(),
                '  <LSNRAPPLIESTO>%s</LSNRAPPLIESTO>' % applies_to.upper(),
                '  <TICKETID><![CDATA[&AUTOKEY&]]></TICKETID>',
                '  <CLASS>%s</CLASS>' % applies_to.upper(),
                '  <DESCRIPTION>%s @ %s</DESCRIPTION>' % (check_name, client_host),
                '  <DESCRIPTION_LONGDESCRIPTION>%s: %s</DESCRIPTION_LONGDESCRIPTION>' % (check_date, data.get('check', {}).get('output')),
                '  <TEMPLATEID>%s</TEMPLATEID>' % template_id.upper(),
                '  <SITEID>%s</SITEID>' % self.settings.get('sccd', {}).get('sccd_site', 'default_site'),
                '</MAXIMOEMAILCONTENT>',
            )
            text = '\n'.join(parts)
            subj = '{0} [{1}: {2} ({3})]'.format(subj, client_host, check_name, check_action)
        except Exception, e:
            text = str(e)

        print 'TEXT============================='
        print text

        msg = MIMEText(text)
        msg['Subject'] = subj
        msg['To'] = to_addr
        msg['From'] = from_addr

        if self.settings.get('sccd', {}).get('mail_encryption', None) == 'ssl':
            s = smtplib.SMTP_SSL(host, int(port))
        else:
            s = smtplib.SMTP(host, int(port))
        s.set_debuglevel(True)

        if user:
            s.login(user, password)

        s.sendmail(from_addr, [to_addr], msg.as_string())
        print s
        s.quit()

if __name__=='__main__':
    m = SccdHandler()
    sys.exit(0)
