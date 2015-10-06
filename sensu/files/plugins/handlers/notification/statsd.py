#!/usr/bin/env python
import sys
import smtplib
from optparse import OptionParser
from email.mime.text import MIMEText
import json
from datetime import datetime
try:
    from sensu import Handler
except ImportError:
    print('You must have the sensu Python module i.e.: pip install sensu')
    sys.exit(1)

try:
    import statsd
except ImportError:
    print('You must have the Statsd Python module i.e.: \
        pip install python-statsd==1.6.0')
    sys.exit(1)


class StatsdHandler(Handler):

    def handle(self):
        statsd_connection = statsd.Connection(
            host=self.settings.get('statsd').get('host', '127.0.0.1'),
            port=self.settings.get('statsd').get('port', 8125),
            sample_rate=self.settings.get('statsd').get('sample_rate', 1),
        )
        meter = statsd.Gauge(
            self.settings.get('statsd').get('prefix', 'sensu'),
            statsd_connection)

        key = '{}.{}'.format(self.event['client']['name'].replace(
            '.', '_'), self.event['check']['name'].replace('.', '_'))

        meter.send(key, self.event['check']['status'])

if __name__ == '__main__':
    m = StatsdHandler()
    sys.exit(0)
