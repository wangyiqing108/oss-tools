#!/usr/bin/env python
# -*- coding: utf-8 -*-  
from IPy import IP
import sys
import urllib2
import json
from optparse import OptionParser  
reload(sys)  
sys.setdefaultencoding('utf8')   

class GetApi():
    def __init__(self, host='http://lingshu.letv.cn/cmdb/cmdbapi/', apiname='getmanageperpage', parameter='ip_query', ip='125.39.12.44', token='7973bf4e0bc6ca846385ed258af1c090'):
        self.url = "%s%s?%s=%s&link_token=%s" % (host, apiname, parameter, ip, token)

    def result(self):
        r = urllib2.urlopen(self.url, timeout=2)
        res = json.loads(r.read())
        return res


class GetVmInfo():
    def __init__(self, host='http://lingshu-test.letv.cn/cmdb/cmdbapi/', apiname='getvminfo', parameter='ip', ip='10.154.21.33', token='17a710902c1e356bc718136a3b854d63'):
        self.url = "%s%s?%s=%s&link_token=%s" % (host, apiname, parameter, ip, token)

    def result(self):
        r = urllib2.urlopen(self.url, timeout=2)
        res = json.loads(r.read())
        return res


class GetStoreHostInfo():
    def __init__(self, host='http://lingshu-test.letv.cn/cmdb/cmdbapi/', apiname='getstorehostinfo', parameter='ip', ip='10.154.81.33', token='f52254c630d8a2b2d50ed46e56c99945'):
        self.url = "%s%s?%s=%s&link_token=%s" % (host, apiname, parameter, ip, token)

    def result(self):
        r = urllib2.urlopen(self.url, timeout=2)
        res = json.loads(r.read())
        return res


USAGE = "gzcx-report.py [-c] ip" 
parser = OptionParser(USAGE)
parser.add_option("-e", "--exsit",
   dest="ip",
   default=False,
   help="check ip")

parser.add_option("-c", "--cabinet", 
   dest="ip", 
   default=False, 
   help="search cabinet") 

parser.add_option("-v", "--vm",
   dest="ip",
   default=False,
   help="search hypervisor vm ip list")

parser.add_option("--hyper",
   dest="ip",
   default=False,
   help="search vm in hypervisor ip")

parser.add_option("-a", "--all",
   dest="ip",
   default=False,
   help="search all info")
(options, args) = parser.parse_args()

r = GetApi(ip="%s" % options.ip)
r1 = GetVmInfo(ip="%s" % options.ip)
r2 = GetStoreHostInfo(ip="%s" % options.ip)

if len(sys.argv) == 1:
    parser.error('-h/--help')
if sys.argv[1] in ["-e", "--exsit"]:
    if r.result()['code'] == '000':
        print True
    else:
        print False
elif sys.argv[1] in ["-c", "--cabinet"]:
    if r.result()['code'] == '000':
        print r.result()['result'][0]['cabinet']['name']
    else:
        print False
elif sys.argv[1] in ["-a", "--all"]:
    if r.result()['code'] == '000':
        print r.result()['result'][0]
    else:
        print False
elif sys.argv[1] in ["-v", "--vm"]:
    if r1.result()['code'] == '000':
        for iplist in r1.result()['data']:
            try:
                print ",".join([ i['ip'] for i in iplist['machineip']])
            except:
                pass
    else:
        print False
elif sys.argv[1] in ["-hy", "--hyper"]:
    if r2.result()['code'] == '000':
        ip = r2.result()['data']['machineip']
        print ",".join([ i['ip'] for i in ip])
    else:
        print False
elif sys.argv[1] in ["-a", "--all"]:
    if r.result()['code'] == '000':
        print r.result()['result'][0]
    else:
        print False
else:
    parser.error('-h/--help')

