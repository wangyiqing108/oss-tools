#!/bin/sh

#install package
yum install -y falcon-fe falcon-portal falcon-dashboard falcon-hbs falcon-query falcon-graph falcon-transfer falcon-judge falcon-alarm falcon-sender falcon-aggregator falcon-links falcon-nodata falcon-task falcon-anteye

#env
LOCALIP=`ifconfig |grep inet |grep -v '127.0' |awk '{print $2}'`
IPTHIRD=`ip -o -f inet add show |grep br0|head -1|awk '{print $4}'|awk -F '/' '{print $1}' |awk -F '.' '{print $3}'`

REGION=`hostname |awk -F '.' '{print $2}'`
EXTURL=falcon-${REGION}.console.lecloud.com

ALARMSMSURL=http://devops.${REGION}.lcs.i-lecloud.com:9007/send_sms
ALARMMAILURL=http://devops.${REGION}.lcs.i-lecloud.com:9007/send_email
ALARMCALLBACK=http://devops.${REGION}.lcs.i-lecloud.com:9007/alarm_callback

MYSQLSERVER=mysqlserver
MYSQLPORT=4407
MYSQLPASS=6Sfsf3rgw2

REDISSERVER=redisserver
REDISPORT=6378

FALCONSERVER=falconserver
FALCONVIP=10.248.${IPTHIRD}.243

JUDGE00=10.248.${IPTHIRD}.224
JUDGE01=10.248.${IPTHIRD}.225

GRAPH00=10.248.${IPTHIRD}.224
GRAPH01=10.248.${IPTHIRD}.225

RGRAPH00=
RGRAPH01=

ALARM00=10.248.${IPTHIRD}.224
ALARM01=10.248.${IPTHIRD}.225

#graph
cat > /etc/open-falcon/falcon-graph.json  << EOF

{
	"debug": false,
	"http": {
		"enabled": true,
		"listen": "0.0.0.0:6071"
	},
	"rpc": {
		"enabled": true,
		"listen": "$LOCALIP:6070"
	},
	"rrd": {
		"storage": "/letv/open-falcon/graph/6070"
	},
	"db": {
		"dsn": "graph:$MYSQLPASS@tcp($MYSQLSERVER:$MYSQLPORT)/graph?loc=Local&parseTime=true",
		"maxIdle": 4
	},
	"callTimeout": 5000,
	"migrate": {
		"enabled": false,
		"concurrency": 2,
		"replicas": 500,
		"cluster": {
			"graph-00" : "127.0.0.1:6070"
		}
	}
}

EOF

systemctl restart falcon-graph
systemctl enable falcon-graph
systemctl status falcon-graph

#hbs
cat > /etc/open-falcon/falcon-hbs.json  << EOF

{
    "debug": true,
    "database": "falcon_portal:$MYSQLPASS@tcp($MYSQLSERVER:$MYSQLPORT)/falcon_portal?loc=Local&parseTime=true",
    "hosts": "",
    "maxIdle": 100,
    "listen": "$LOCALIP:6030",
    "trustable": [""],
    "http": {
        "enabled": true,
        "listen": "0.0.0.0:6031"
    }
}

EOF

systemctl restart falcon-hbs
systemctl enable falcon-hbs
systemctl status falcon-hbs

#judge
cat > /etc/open-falcon/falcon-judge.json  << EOF
{
    "debug": true,
    "debugHost": "nil",
    "remain": 11, 
    "http": {
        "enabled": true,
        "listen": "0.0.0.0:6081"
    },
    "rpc": {
        "enabled": true,
        "listen": "$LOCALIP:6082"
    },
    "hbs": {
        "servers": ["$FALCONSERVER:6030"],
        "timeout": 300,
        "interval": 60
    },
    "alarm": {
        "enabled": true,
        "minInterval": 300,
        "queuePattern": "event:p%v",
        "redis": {
            "dsn": "$REDISSERVER:$REDISPORT",
            "maxIdle": 5,
            "connTimeout": 5000,
            "readTimeout": 5000,
            "writeTimeout": 5000
        }
    }
}

EOF

systemctl restart falcon-judge
systemctl enable falcon-judge
systemctl status falcon-judge

#transfer
cat > /etc/open-falcon/falcon-transfer.json << EOF

{
    "debug": true,
    "minStep": 30,
    "http": {
        "enabled": true,
        "listen": "$LOCALIP:6060"
    },
    "rpc": {
        "enabled": true,
        "listen": "$LOCALIP:8433"
    },
    "socket": {
        "enabled": true,
        "listen": "0.0.0.0:4444",
        "timeout": 3600
    },
    "judge": {
        "enabled": true,
        "batch": 200,
        "connTimeout": 1000,
        "callTimeout": 5000,
        "maxConns": 32,
        "maxIdle": 32,
        "replicas": 500,
        "cluster": {
            "judge-00" : "$JUDGE00:6082",
            "judge-01" : "$JUDGE01:6082"
        }
    },
    "graph": {
        "enabled": true,
        "batch": 200,
        "connTimeout": 1000,
        "callTimeout": 5000,
        "maxConns": 32,
        "maxIdle": 32,
        "replicas": 500,
        "cluster": {
            "graph-00" : "$GRAPH00:6070",
            "graph-01" : "$GRAPH01:6070"
        }
    },
    "tsdb": {
        "enabled": false,
        "batch": 200,
        "connTimeout": 1000,
        "callTimeout": 5000,
        "maxConns": 32,
        "maxIdle": 32,
        "retry": 3,
        "address": "127.0.0.1:8088"
    }
}

EOF

systemctl restart falcon-transfer
systemctl enable falcon-transfer
systemctl status falcon-transfer

#query
cat > /etc/open-falcon/falcon-query.json << EOF


{
    "debug": "false",
    "http": {
        "enabled":  true,
        "listen":   "$LOCALIP:9966"
    },
    "graph": {
        "connTimeout": 1000,
        "callTimeout": 5000,
        "maxConns": 32,
        "maxIdle": 32,
        "replicas": 500,
        "cluster": {
            "graph-00": "$GRAPH00:6070",
            "graph-01": "$GRAPH01:6070"
        }
    },
    "api": {
        "query": "http://$FALCONSERVER:9966",
        "dashboard": "http://$FALCONSERVER:8081",
        "max": 1000
    }
}

EOF

systemctl restart falcon-query
systemctl enable falcon-query
systemctl status falcon-query

#dashboard
cat > /etc/open-falcon/falcon-dashboard.json << EOF

#-*-coding:utf8-*-
import os

#-- dashboard db config --
DASHBOARD_DB_HOST = "$MYSQLSERVER"
DASHBOARD_DB_PORT = $MYSQLPORT
DASHBOARD_DB_USER = "dashboard"
DASHBOARD_DB_PASSWD = "$MYSQLPASS"
DASHBOARD_DB_NAME = "dashboard"

#-- graph db config --
GRAPH_DB_HOST = "$MYSQLSERVER"
GRAPH_DB_PORT = $MYSQLPORT
GRAPH_DB_USER = "graph"
GRAPH_DB_PASSWD = "$MYSQLPASS"
GRAPH_DB_NAME = "graph"

#-- app config --
DEBUG = True
SECRET_KEY = "secret-key"
SESSION_COOKIE_NAME = "open-falcon"
PERMANENT_SESSION_LIFETIME = 3600 * 24 * 30
SITE_COOKIE = "open-falcon-ck"

#-- query config --
QUERY_ADDR = "http://$FALCONSERVER:9966"

BASE_DIR = "/letv/open-falcon/dashboard/"
LOG_PATH = os.path.join(BASE_DIR,"log/")

try:
    from rrd.local_config import *
except:
    pass

EOF

cat > /usr/local/open-falcon/falcon-dashboard/gunicorn.conf << EOF

workers = 20
bind = '$LOCALIP:8081'
proc_name = 'falcon-dashboard-opensource'
pidfile = '/tmp/falcon-dashboard-opensource.pid'
limit_request_field_size = 0
limit_request_line = 0

EOF

systemctl restart falcon-dashboard
systemctl enable falcon-dashboard
systemctl status falcon-dashboard

#portal
cat > /etc/open-falcon/falcon-portal.json << EOF

# -*- coding:utf-8 -*-
__author__ = 'Ulric Qin'

# -- app config --
DEBUG = True

# -- db config --
DB_HOST = "$MYSQLSERVER"
DB_PORT = $MYSQLPORT
DB_USER = "falcon_portal"
DB_PASS = "$MYSQLPASS"
DB_NAME = "falcon_portal"

# -- cookie config --
SECRET_KEY = "4e.5tyg8-u9ioj"
SESSION_COOKIE_NAME = "falcon-portal"
PERMANENT_SESSION_LIFETIME = 3600 * 24 * 30

UIC_ADDRESS = {
    'internal': 'http://$FALCONVIP:1234',
    'external': 'http://$EXTURL:1234',
}

UIC_TOKEN = ''

MAINTAINERS = ['root']
CONTACT = 'ulric.qin@gmail.com'

COMMUNITY = True

try:
    from frame.local_config import *
except Exception, e:
    print "[warning] %s" % e

EOF

cat > /usr/local/open-falcon/falcon-portal/gunicorn.conf << EOF

workers = 20
bind = '$LOCALIP:5050'
proc_name = 'falcon-portal'
pidfile = 'var/app.pid'
limit_request_field_size = 0
limit_request_line = 0

EOF

systemctl restart falcon-portal
systemctl enable falcon-portal
systemctl status falcon-portal

#fe
cat > /etc/open-falcon/falcon-fe.json << EOF

{
    "log": "debug",
    "company": "MI",
    "http": {
        "enabled": true,
        "listen": "$LOCALIP:1234"
    },
    "cache": {
        "enabled": true,
        "redis": "$REDISSERVER:6378",
        "idle": 10,
        "max": 1000,
        "timeout": {
            "conn": 10000,
            "read": 5000,
            "write": 5000
        }
    },
    "salt": "",
    "canRegister": false,
    "ldap": {
        "enabled": false,
        "addr": "ldap.example.com:389",
        "baseDN": "dc=example,dc=com",
        "bindDN": "cn=mananger,dc=example,dc=com",
        "bindPasswd": "12345678",
        "userField": "uid",
        "attributes": ["sn","mail","telephoneNumber"]
    },
    "uic": {
        "addr": "uic:$MYSQLPASS@tcp($MYSQLSERVER:$MYSQLPORT)/uic?charset=utf8&loc=Asia%2FChongqing",
        "idle": 10,
        "max": 100
    },
    "shortcut": {
        "falconPortal": "http://$EXTURL:5050/",
        "falconDashboard": "http://$EXTURL:8081/",
        "falconAlarm": "http://$EXTURL:6067/"
    }
}

EOF

systemctl restart falcon-fe
systemctl enable falcon-fe
systemctl status falcon-fe

#alarm
cat > /etc/open-falcon/falcon-alarm.json << EOF

{
    "debug": true,
    "uicToken": "",
    "http": {
        "enabled": true,
        "listen": "$LOCALIP:6067"
    },
    "queue": {
        "sms": "/sms",
        "mail": "/mail"
    },
    "redis": {
        "addr": "$REDISSERVER:6378",
        "maxIdle": 5,
        "highQueues": [
            "event:p0",
            "event:p1",
            "event:p2",
            "event:p3",
            "event:p4",
            "event:p5"
        ],
        "lowQueues": [
            "event:p6"
        ],
        "userSmsQueue": "/queue/user/sms",
        "userMailQueue": "/queue/user/mail"
    },
    "api": {
        "portal": "http://$FALCONVIP:5050",
        "uic": "http://$FALCONVIP:1234",
        "links": "http://$FALCONVIP:5090"
    }
}

EOF

#nodata
cat > /etc/open-falcon/falcon-nodata.json << EOF
{
    "debug": true,
    "http": {
        "enabled": true,
        "listen": "$LOCALIP:6090"
    },
    "query":{
        "connectTimeout": 5000,
        "requestTimeout": 30000,
        "queryAddr": "$FALCONSERVER:9966"
    },
    "config": {
        "enabled": true,
        "dsn": "falcon_portal:$MYSQLPASS@tcp($MYSQLSERVER:$MYSQLPORT)/falcon_portal?loc=Local&parseTime=true&wait_timeout=604800",
        "maxIdle": 4
    },
    "collector":{
        "enabled": true,
        "batch": 200,
        "concurrent": 10
    },
    "sender":{
        "enabled": true,
        "connectTimeout": 5000,
        "requestTimeout": 30000,
        "transferAddr": "$FALCONSERVER:6060",
        "batch": 500,
        "block": {
            "enabled": false,
            "threshold": 32
        }
    }
}

EOF

if [ $ALARM00 = $LOCALIP ] ;then

#anteye-a
cat > /etc/open-falcon/falcon-anteye.json << EOF

{
    "debug": false,
    "http": {
        "enable": true,
        "listen": "0.0.0.0:8001"
    },
    "mail" : {
        "enable": true,
        "url" : "${ALARMMAILURL}",
        "receivers" : "huangbaohua@le.com,dongzhiyang@le.com"
    },
    "sms" : {
        "enable": true,
        "url" : "${ALARMSMSURL}",
        "receivers" : "13718915002,18618102830"
    },
    "callback" : {
        "enable": true,
        "url" : "${ALARMCALLBACK}"
    },
    "monitor" : {
        "cluster" : [
            "${REGION}_fe,falcon-a:1234/health",
            "${REGION}_fe,falcon-b:1234/health",
            "${REGION}_query,falcon-a:9966/health",
            "${REGION}_query,falcon-b:9966/health",
            "${REGION}_hbs,falcon-a:6031/health",
            "${REGION}_hbs,falcon-b:6031/health",
            "${REGION}_transfer,falcon-a:6060/health",
            "${REGION}_transfer,falcon-b:6060/health",
            "${REGION}_graph,falcon-a:6071/health",
            "${REGION}_graph,falcon-b:6071/health",
            "${REGION}_judge,falcon-a:6081/health",
            "${REGION}_judge,falcon-b:6081/health",
            "${REGION}_alarm,falcon-a:6067/health",
            "${REGION}_sender,falcon-a:6066/health",
            "${REGION}_sender,falcon-a:6066/health",
            "${REGION}_sender,falcon-b:5050/api/health",
            "${REGION}_sender,falcon-b:5050/api/health",
            "${REGION}_nodata,falcon-a:6090/health",
            "${REGION}_anteye,falcon-b:8001/health"
        ]

    }
} 

EOF

    
    systemctl restart falcon-anteye
    systemctl status falcon-anteye
    systemctl enable falcon-anteye
    
    systemctl restart falcon-nodata
    systemctl status falcon-nodata
    systemctl enable falcon-nodata
    
    systemctl status falcon-alarm
    systemctl enable falcon-alarm
    systemctl status falcon-alarm

else
#anteye-b
cat > /etc/open-falcon/falcon-anteye.json << EOF

{
    "debug": false,
    "http": {
        "enable": true,
        "listen": "0.0.0.0:8001"
    },
    "mail" : {
        "enable": true,
        "url" : "${ALARMMAILURL}",
        "receivers" : "huangbaohua@le.com,dongzhiyang@le.com"
    },
    "sms" : {
        "enable": true,
        "url" : "${ALARMSMSURL}",
        "receivers" : "13718915002,18618102830"
    },
    "callback" : {
        "enable": true,
        "url" : "${ALARMCALLBACK}"
    },
    "monitor" : {
        "cluster" : [
            "${REGION}_anteye,falcon-a:8001/health"
        ]

    }
} 

EOF

    systemctl restart falcon-anteye
    systemctl status falcon-anteye
    systemctl enable falcon-anteye
fi 

#sender
cat > /etc/open-falcon/falcon-sender.json << EOF

{
    "debug": true,
    "http": {
        "enabled": true,
        "listen": "0.0.0.0:6066"
    },
    "redis": {
        "addr": "$REDISSERVER:6378",
        "maxIdle": 5
    },
    "queue": {
        "sms": "/sms",
        "mail": "/mail"
    },
    "worker": {
        "sms": 10,
        "mail": 50
    },
    "api": {
        "sms": "${ALARMSMSURL}",
        "mail": "${ALARMMAILURL}"
    }
}

EOF

systemctl enable falcon-sender
systemctl restart falcon-sender
systemctl status falcon-sender


sleep 1

##tail log
for i in `ls /var/log/open-falcon`;do
    echo "****** $i ******"
    tail -5 /var/log/open-falcon/$i
done
