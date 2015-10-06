#!/usr/bin/env python
"""
nagios plugin to monitor supervisor processes
---------------------------------------------

usage

::

    check_supervisor_proc.py -p PROCESS_NAME

    check_supervisor_proc.py -p PROCESS_NAME -s unix:///tmp/supervisord_openstack.sock

"""
from optparse import OptionParser
import os

#nagios return codes
UNKNOWN = -1
OK = 0
WARNING = 1
CRITICAL = 2

SUPERV_STAT_CHECK='sudo supervisorctl'

#supervisor states, map state to desired warning level
supervisor_states = {
    'STOPPED': OK,
    'RUNNING': OK,
    'STOPPING': WARNING,
    'STARTING': WARNING,
    'EXITED': CRITICAL,
    'BACKOFF': CRITICAL,
    'FATAL': CRITICAL,
    'UNKNOWN': CRITICAL
    }

def get_status(proc_name, socket):
    try:
        if socket != None:
          status_output = os.popen('%s -s %s status %s' % (SUPERV_STAT_CHECK, socket, proc_name)).read()
        else:
          status_output = os.popen('%s status %s' % (SUPERV_STAT_CHECK, proc_name)).read()
        proc_status = status_output.split()[1]
        return (status_output, supervisor_states[proc_status])
    except:
        print "CRITICAL: Could not get status of %s" % proc_name
        raise SystemExit, CRITICAL

parser = OptionParser()
parser.add_option('-p', '--processes-name', dest='proc_name',
    help="Name of process as it appears in supervisorctl status")
parser.add_option('-v', '--verbose', dest='verbose', action='store_true',
    default=False)
parser.add_option('-q', '--quiet', dest='quiet', action='store_false')
parser.add_option('-s', '--socket', dest='socket', default=None)

options, args = parser.parse_args()

output = get_status(options.proc_name, options.socket)
print output[0]
raise SystemExit, output[1]
