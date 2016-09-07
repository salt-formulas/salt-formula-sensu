#    Copyright 2016 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
#
#


import requests
import json
import xml.dom.minidom
import logging

#requests.packages.urllib3.disable_warnings()

LOG = logging.getLogger()

class OAuth2(object):
    def __init__(self, client_id, client_secret, username, password, auth_url=None, organizationId=None):
        if not auth_url:
            auth_url = 'https://login.salesforce.com'

        self.auth_url = auth_url
        self.client_id = client_id
        self.client_secret = client_secret
        self.username = username
        self.password = password
        self.organizationId = organizationId

    def getUniqueElementValueFromXmlString(self, xmlString, elementName):
        """
        Extracts an element value from an XML string.

        For example, invoking
        getUniqueElementValueFromXmlString('<?xml version="1.0" encoding="UTF-8"?><foo>bar</foo>', 'foo')
        should return the value 'bar'.
        """
        xmlStringAsDom = xml.dom.minidom.parseString(xmlString)
        elementsByName = xmlStringAsDom.getElementsByTagName(elementName)
        elementValue = None
        if len(elementsByName) > 0:
            elementValue = elementsByName[0].toxml().replace('<' + elementName + '>', '').replace('</' + elementName + '>', '')
        return elementValue



    def authenticate_soap(self):

        soap_url = '{}/services/Soap/u/36.0'.format(self.auth_url)

        login_soap_request_body = """<?xml version="1.0" encoding="utf-8" ?>
        <soapenv:Envelope
                xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
                xmlns:urn="urn:partner.soap.sforce.com">
            <soapenv:Header>
                <urn:CallOptions>
                    <urn:client>RestForce</urn:client>
                    <urn:defaultNamespace>sf</urn:defaultNamespace>
                </urn:CallOptions>
                <urn:LoginScopeHeader>
                    <urn:organizationId>{organizationId}</urn:organizationId>
                </urn:LoginScopeHeader>
            </soapenv:Header>
            <soapenv:Body>
                <urn:login>
                    <urn:username>{username}</urn:username>
                    <urn:password>{password}</urn:password>
                </urn:login>
            </soapenv:Body>
        </soapenv:Envelope>""".format(
        username=self.username, password=self.password, organizationId=self.organizationId)

        login_soap_request_headers = {
            'content-type': 'text/xml',
            'charset': 'UTF-8',
            'SOAPAction': 'login'
        }

        response = requests.post(soap_url,
                             login_soap_request_body,
                             headers=login_soap_request_headers)
        LOG.debug(response)
        LOG.debug(response.status_code)
        LOG.debug(response.text)


        session_id = self.getUniqueElementValueFromXmlString(response.content, 'sessionId')
        server_url = self.getUniqueElementValueFromXmlString(response.content, 'serverUrl')

        response_json = {
            'access_token': session_id, 
            'instance_url': self.auth_url 
        }

        session_id = self.getUniqueElementValueFromXmlString(response.content, 'sessionId')
        response.raise_for_status()
        return response_json

    def authenticate_rest(self):
        data = {
            'grant_type': 'password',
            'client_id': self.client_id,
            'client_secret': self.client_secret,
            'username': self.username,
            'password': self.password,
        }

        url = '{}/services/oauth2/token'.format(self.auth_url)
        response = requests.post(url, data=data)
        response.raise_for_status()
        return response.json()


    def authenticate(self, **kwargs):
        if self.organizationId:
            LOG.debug('self.organizationId={}'.format(self.organizationId))
            LOG.debug('Auth method = SOAP')
            return  self.authenticate_soap( **kwargs )
        else:
            LOG.debug('Auth method = REST')
            return  self.authenticate_rest( **kwargs )




class Client(object):
    def __init__(self, oauth2):
        self.oauth2 = oauth2

        self.access_token = None
        self.instance_url = None

    def ticket(self, id):
        try:
            return self.get('/services/data/v36.0/sobjects/proxyTicket__c/{}'.format(id)).json()
        except requests.HTTPError:
            return False

    def create_mos_alert(self, data):
        return self.post('/services/data/v36.0/sobjects/MOS_Alerts__c', data=json.dumps(data), headers={"content-type": "application/json"})

    def create_mos_alert_comment(self, data):
        return self.post('/services/data/v36.0/sobjects/MOS_Alert_Comment__c', data=json.dumps(data), headers={"content-type": "application/json"})

    def get_mos_alert_comment(self, id):
        return self.get('/services/data/v36.0/sobjects/MOS_Alert_Comment__c/{}'.format(id))


    def del_mos_alert_comment(self, id):
        return self.delete('/services/data/v36.0/sobjects/MOS_Alert_Comment__c/{}'.format(id))


    def create_feeditem(self, data):
        return self.post('/services/data/v36.0/sobjects/FeedItem', data=json.dumps(data), headers={"content-type": "application/json"})


    def create_case(self, data):
        return self.post('/services/data/v36.0/sobjects/Case', data=json.dumps(data), headers={"content-type": "application/json"})


    def create_ticket(self, data):
        return self.post('/services/data/v36.0/sobjects/Case', data=json.dumps(data), headers={"content-type": "application/json"}).json()

    def get_case(self, id):
        return self.get('/services/data/v36.0/sobjects/Case/{}'.format(id))

    def get_mos_alert(self, id):
        return self.get('/services/data/v36.0/sobjects/MOS_Alerts__c/{}'.format(id))

    def del_mos_alert(self, id):
        return self.delete('/services/data/v36.0/sobjects/MOS_Alerts__c/{}'.format(id))


    def update_ticket(self, id, data):
        return self.patch('/services/data/v36.0/sobjects/proxyTicket__c/{}'.format(id), data=json.dumps(data), headers={"content-type": "application/json"})

    def update_mos_alert(self, id, data):
        return self.patch('/services/data/v36.0/sobjects/MOS_Alerts__c/{}'.format(id), data=json.dumps(data), headers={"content-type": "application/json"})

    def update_case(self, id, data):
        return self.patch('/services/data/v36.0/sobjects/Case/{}'.format(id), data=json.dumps(data), headers={"content-type": "application/json"})


    def update_comment(self, id, data):
        return self.patch('/services/data/v36.0/sobjects/proxyTicketComment__c/{}'.format(id), data=json.dumps(data), headers={"content-type": "application/json"})

    def create_ticket_comment(self, data):
        return self.post('/services/data/v36.0/sobjects/proxyTicketComment__c', data=json.dumps(data), headers={"content-type": "application/json"}).json()

    def environment(self, id):
        return self.get('/services/data/v36.0/sobjects/Environment__c/{}'.format(id)).json()

    def ticket_comments(self, ticket_id):
        return self.search("SELECT Comment__c, CreatedById, external_id__c, Id, CreatedDate, createdby.name "
                           "FROM proxyTicketComment__c "
                           "WHERE related_id__c='{}'".format(ticket_id))

    def ticket_comment(self, comment_id):
        return self.get('/services/data/v36.0/query',
                        params=dict(q="SELECT Comment__c, CreatedById, Id "
                                      "FROM proxyTicketComment__c "
                                      "WHERE external_id__c='{}'".format(comment_id))).json()
    def search(self, query):
        response = self.get('/services/data/v36.0/query', params=dict(q=query)).json()
        while True:
            for record in response['records']:
                yield record

            if response['done']:
                return

            response = self.get(response['nextRecordsUrl']).json()

    def get(self, url, **kwargs):
        return self._request('get', url, **kwargs)

    def patch(self, url, **kwargs):
        return self._request('patch', url, **kwargs)

    def post(self, url, **kwargs):
        return self._request('post', url, **kwargs)

    def delete(self, url, **kwargs):
        return self._request('delete', url, **kwargs)


    def delete1(self, url, **kwargs):
        return self._request('post', url, **kwargs)



    def _request(self, method, url, headers=None, **kwargs):
        if not headers:
            headers = {}

        if not self.access_token or not self.instance_url:
            result = self.oauth2.authenticate()
            self.access_token = result['access_token']
            self.instance_url = result['instance_url']

        headers['Authorization'] = 'Bearer {}'.format(self.access_token)

        url = self.instance_url + url
        print "URL", url
        print "KWARGS", kwargs
        response = requests.request(method, url, headers=headers, **kwargs)
        print "RESPONSE", response
# Debug only
        LOG.debug("Response code: {}".format(response.status_code))
        try:
          LOG.debug("Response content: {}".format(json.dumps(response.json(),sort_keys=True, indent=4, separators=(',', ': '))))
        except Exception:
          LOG.debug("Response content: {}".format(response.content))

        return response
