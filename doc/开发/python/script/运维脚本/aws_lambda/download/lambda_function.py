from aws_sqs import Sqs
import download
from login import Resource

def lambda_handler(event, context):
    sqs = Sqs()
    data = sqs.Handle()
    if data != None:
        body = data[0]
        key = data[1]
        queue_url = data[2]

        r_sqs = Resource("sqs")
        download.Download(body)                     #run download
        r_sqs.Message(queue_url,key).delete()       #download success delete queue message
    else:
        exit(110)



