#-*- coding: utf-8 -*-
import os,json
from aws_sqs import Sqs
from login import Resource,Session

def get_message():
    sqs = Sqs(queue_name="split")
    message = sqs.Handle()
    return message


def upload(file,upload_path):
    local_file = os.path.join("/tmp/",file)
    s3_storage_path = os.path.join(upload_path,file)
    s3 = Session("s3")
    s3.Bucket('boto-test').upload_file(local_file, s3_storage_path)

    cmd = 'rm -rf %s' %local_file
    os.system(cmd)



def download_unit():
    message = get_message()
    download_list =  json.loads(message[0])
    receipt_handle = message[1]
    queue_url = message[2]

    for unit_name in download_list:
        element = unit_name.split('/')
        unit = element.pop()
        download_name = os.path.join("/tmp/",unit)
        storage_name = unit.split("-")[0]

        s3 = Resource("s3")
        s3.meta.client.download_file('dxwind-split', unit_name, download_name)

        cmd = "cat %s >> /tmp/%s" %(download_name,storage_name)
        cmd2 = "rm -rf %s" %download_name
        os.system(cmd)
        os.system(cmd2)

        path = "/".join(element)
        s3.Object('dxwind-split',unit_name).delete()

    upload(storage_name,path)
    sqs = Resource("sqs")
    sqs.Message(queue_url,receipt_handle).delete()



def lambda_handler(event, context):
    download_unit()
