#!/bin/env python
# -*- coding:utf-8 -*-
'''
Used for monitoring  url API
Author:banbanqiu
'''
import sys,time
import urllib2

def dspt(url,data):
    RequestUrl = url
    try:
        u_data = data
        #u_data = json.dumps(u_data)
        urlrequest = urllib2.Request(url=RequestUrl)
        urlrequest.add_header('Content-Type', 'application/xxx.if1.v1.message+json')
        urlrequest.add_header('charset', 'UTF-8')
        data_init = urllib2.urlopen(urlrequest, data=u_data, timeout=30)
        data = data_init.read()
        #print len(data)
        return data
    except:
        return

Normal = 0
ABNormal = 1
CCNum = "715599"
URL = 'http://192.168.1.10:3300/if1/v2/data/json/id/FFFEEEFFFFFFFFB1/services/events/up?IdentifierType=0'
DATA = '''{
    'TriggerIP':'192.168.1.88',
    'checkingserial':'/dev/ttyACM1', 
    'lastcheckingserial':4, 
    'lastcheckingresult':2,
     'lastcheckphonenum':'13521418110',
     'TaskNum':12345678,
     'TaskTime':time.tiem(),
     'Task':"ring",
    'Target': 010101010,
    'Content':None, 
    'LastTMCheckTime':1233564.343,
    'TMCheckingSuccessNum':0, 
    'TMCheckingFailNum':0,
    'TMCheckingTotalNum':0,
    'CallLostRate':0
}'''
try:
    rdata = dspt(URL,DATA)
    if rdata:
        if len(rdata) != 0:
            if CCNum in rdata:
                print Normal
                sys.exit(Normal)
    print ABNormal
    sys.exit(ABNormal)
except Exception,e:
    print ABNormal,e
    sys.exit(ABNormal)