#!/usr/bin/env python
#-*- coding:utf-8 -*-
from __future__ import unicode_literals
from login import *


class Sqs(object):
    def __init__(self,data_list=None,queue_name='download'):
        self.name = queue_name                  #queue name
        self.queue_url = self.__Createqueue()
        self.data = data_list
    c_sqs = Client("sqs")

    def __Createqueue(self):                    #if queue not exist be create,exist be ignore
        sqs_obj = self.c_sqs.create_queue(
            QueueName=self.name,
            Attributes = {"VisibilityTimeout":"300"}
        )
        QueueUrl = sqs_obj.get('QueueUrl')
        return QueueUrl

    def Put(self):                #put data to queue
        QueueUrl = self.queue_url
        self.c_sqs.send_message(
            QueueUrl = QueueUrl,
            MessageBody = self.data
        )


    def __Get(self):                            #get queue message
        QueueUrl = self.queue_url
        messages = self.c_sqs.receive_message(QueueUrl = QueueUrl).get("Messages")
        return messages,QueueUrl

    def Handle(self):                           #Processing data
        data = self.__Get()
        messages = data[0]
        queue_url = data[1]

        if messages != None:
            dict_data = messages.pop()
            value = dict_data.get('Body')
            receipt_handle = dict_data.get('ReceiptHandle')

            return value,receipt_handle,queue_url
        else:
            return None


