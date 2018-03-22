#-*- coding: utf-8 -*-
from __future__ import unicode_literals
from aws_sqs import Sqs
import datetime
import json
import get_size


def get_yyyymmdd():
    dtobj = datetime.datetime.utcnow()
    delta = datetime.timedelta(hours=8)
    dtobj2 = dtobj + delta
    dtobj = dtobj2
    yr = dtobj.year
    mo = dtobj.month
    dy = dtobj.day
    hr = dtobj.hour
    dt = '%04d%02d%02d%02d' % (yr,mo,dy,hr)
    yyyymmdd = dt[0:8]
    return(yyyymmdd)

def get_yyyymmdd_1dayago():
    dtobj = datetime.datetime.utcnow()
    delta = datetime.timedelta(hours=8-24)
    dtobj2 = dtobj + delta
    dtobj = dtobj2
    yr = dtobj.year
    mo = dtobj.month
    dy = dtobj.day
    hr = dtobj.hour
    dt = '%04d%02d%02d%02d' % (yr,mo,dy,hr)
    yyyymmdd = dt[0:8]
    return(yyyymmdd)

def int_to_str(l):
    new_list = []
    for i in l:
        if i < 10:
            data = "00" + str(i)
        if i > 10 and i < 100:
            data = "0" + str(i)
        if i > 100:
            data = str(i)
        new_list.append(data)
    return new_list

def join_path(name, ymd, hour):
    if ymd != 0:
        date = get_yyyymmdd_1dayago()
    else:
        date = get_yyyymmdd()
    path = "http://ftpprd.ncep.noaa.gov/data/nccf/com/gfs/prod/gfs.{}{}/{}".format(date,hour,name)
    return path

def nameing_rules(filetype, day, ymd, hour):
    day_list = range(0,day+1,3)
    day_list = int_to_str(day_list)
    url_list = []
    for unit in day_list:
        name = "gfs.t{}z.pgrb2.{}.f{}".format(hour,filetype,unit)
        url = join_path(name,ymd,hour)
        size = get_size.get_file_size(url)
        data = [url,0,size,0]
        url_list.append(data)
    return url_list

def run(filetype="0p50", hour="00", ymd=0, day=192):
    if filetype != "0p50" and filetype != "1p00" and filetype != "0p25":
        print 'Type[0p50|1p00|0p25]'
        exit(10)

    if hour != "00" and hour != "06" and hour != "12" and hour != "18":
        print 'hour[00|06|12|18]'
        exit(10)

    message_list = nameing_rules(filetype,day,ymd,hour)

    #put message to aws queue
    for message in message_list:
        sqs = Sqs(json.dumps(message))
        sqs.Put()

def lambda_handler(event, context):
    run(filetype="0p50", hour="00", ymd=1)
    run(filetype="0p50", hour="12", ymd=1)
    run(filetype="1p00", hour="00", ymd=1)
    run(filetype="1p00", hour="12", ymd=1)
