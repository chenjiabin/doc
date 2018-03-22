#-*- coding:utf-8 -*-
from __future__ import unicode_literals
from login import Client

client = Client("lambda")

def call_download(thread=50):
    for digital in range(thread):
        client.invoke(
            FunctionName='arn:aws-cn:lambda:cn-north-1:333452484733:function:download',
            InvocationType='Event',
        )


def call_join(thread=50):
    for digital in range(thread):
        client.invoke(
            FunctionName='arn:aws-cn:lambda:cn-north-1:333452484733:function:split-join',
            InvocationType='Event',
        )