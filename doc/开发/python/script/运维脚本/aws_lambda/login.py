#-*- coding:utf-8 -*-
import boto3

aws_key = 'xxxxxxxxxxxxxxx'
aws_secret = 'xxxxxxxxxxxxxxx'
bj = 'cn-north-1'
nx = 'cn-northwest-1a'


def Client(service,opsition=bj):
    obj = boto3.client(
        service,
        aws_access_key_id = aws_key,
        aws_secret_access_key = aws_secret,
        region_name = opsition,
    )
    return obj


def Resource(service,opsition=bj):
    obj = boto3.resource(
        service,
        aws_access_key_id = aws_key,
        aws_secret_access_key = aws_secret,
        region_name=opsition,
    )
    return obj


def Session(service,opsition=bj):
    session = boto3.Session(
        aws_access_key_id = aws_key,
        aws_secret_access_key = aws_secret,
        region_name=opsition
    )
    obj = session.resource(service)
    return obj
