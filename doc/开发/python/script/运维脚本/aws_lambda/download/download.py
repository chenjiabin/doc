#!/usr/bin/env python
#-*- coding:utf-8 -*-
from __future__ import unicode_literals
import os,json
from login import *
from aws_sqs import Sqs

def start_download(data,name):
    url = data[0]
    size = data[1]
    total_size = data[2]
    count = data[3]

    if size != 0:
        start = size + 1
    else:
        start = size
    end = size + 2000000

    result = int(total_size) - end
    if result > 0:
        count = count+1
        localfile = name + '-' + str(count)
        new_message = [url,end,total_size,count]
        value = json.dumps(new_message)
        sqs = Sqs(str(value))
        sqs.Put()
    else:
        localfile = name + '-' + str(999)

    cmd = "curl -r %s-%s -o /tmp/%s %s" %(start,end,localfile,url)
    os.system(cmd)
    return localfile


def Upload(upload_position,name,upload_type,upload_date,name2):
    year = upload_date[0:4]
    year_month = upload_date[0:6]
    s3_path1 = os.path.join(year,year_month)
    s3_path2 = os.path.join(upload_type,s3_path1)
    s3_path3 = os.path.join(s3_path2,upload_date)
    path1 = os.path.join(s3_path3,name)

    path2 = path1.split("/")
    path2.pop()
    path2.append(name2)
    s3_storage_path = "/".join(path2)

    s3 = Session("s3")
    s3.Bucket('dxwind-split').upload_file(upload_position, s3_storage_path)

    cmd = 'rm -rf %s' %upload_position
    os.system(cmd)

def Download(data):
    data = json.loads(data)
    url = data[0]
    path_spilt = url.split('/')
    download_file = path_spilt.pop()
    download_datetime_and_gfs = path_spilt.pop()

    rule = download_file.split('.')
    download_datetime = download_datetime_and_gfs.split('.').pop()

    prefix =  rule[0]
    suffix = rule.pop()
    download_type = rule.pop()
    element = [prefix,download_datetime,suffix]
    name = '.'.join(element)

    name2 = start_download(data,name)             #download file
    download_position = os.path.join('/tmp/',name2)
    Upload(download_position,name,download_type,download_datetime,name2)    #put aws s3


