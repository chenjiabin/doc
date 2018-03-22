#-*- coding: utf-8 -*-
from login import Resource
from aws_sqs import Sqs
import json


class JoinQueue(object):
    def __init__(self):
        self.__name_list = self.__get_file_name()
        self.__unit_name = self.__get_complete_file()

    __s3 = Resource("s3")

    def __get_file_name(self):
        bucket = self.__s3.Bucket("dxwind-split")
        response = bucket.objects.all()
        rule = []
        name_list = []
        for obj in list(response):
            data = str(obj)
            name = data.split("key")[1].replace(")","=").strip("=").replace("u",'').strip("\'")
            name_list.append(name)
            if "-999" in name:
                unit_path = name.split("/")
                file_name = unit_path.pop().split("-")[0]
                unit_path.append(file_name)
                path = "/".join(unit_path)
                rule.append(path)
        return rule,name_list


    def __get_complete_file(self):
        rule = self.__name_list[0]
        name_list = self.__name_list[1]
        for real_name in rule:
            file_name = []
            for name in name_list:
                if real_name in name:
                    file_name.append(name)
            file_name.sort(key=lambda x:int(x.split("-")[1]))
            Sqs(data_list=json.dumps(file_name),queue_name="split").Put()


def lambda_handler(event, context):
    JoinQueue()


