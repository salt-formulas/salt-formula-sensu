#!/usr/bin/env python
"""
nagios plugin to monitor fqdn validity
--------------------------------------

usage

::

    check_fqdn.py -n node01 -f node01.cluster.domain.com

"""
from optparse import OptionParser
import os
import subprocess

#nagios return codes
UNKNOWN = -1
OK = 0
WARNING = 1
CRITICAL = 2

HOSTNAME_CHECK='hostname'

#supervisor states, map state to desired warning level

def get_status(hostname, fqdn):

    ok = []
    crit = []
    warn = []

    lines = subprocess.Popen([HOSTNAME_CHECK], stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()[0]
    hostname_output = lines.splitlines()[0]

    if hostname == hostname_output:
      ok.append('Hostname is OK. ')
    else:
      crit.append('Hostname %s does not match desired %s. ' % (hostname_output, hostname))

    try:
        lines = subprocess.Popen([HOSTNAME_CHECK, '-f'], stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()[0]
        fqdn_output = lines.splitlines()[0]

        if fqdn == fqdn_output:
          ok.append('FQDN is OK. ')
        else:
          crit.append('FQDN %s does not match desired %s. ' % (fqdn_output, fqdn))
    except:
        crit.append('FQDN is not desired %s. ' % fqdn)

    status = OK
    prepend = "OK"

    if len(warn) > 0:
      status = WARNING
      prepend = "WARNING"

    if len(crit) > 0:
      status = CRITICAL
      prepend = "CRITICAL"

    return ("%s - %s%s%s" %(prepend, "".join(crit), "".join(warn), "".join(ok)), status)

parser = OptionParser()
parser.add_option('-n', '--hostname', dest='hostname',
    help="Server hostname")
parser.add_option('-f', '--fqdn', dest='fqdn')

options, args = parser.parse_args()

output = get_status(options.hostname, options.fqdn)
print output[0]
raise SystemExit, output[1]
