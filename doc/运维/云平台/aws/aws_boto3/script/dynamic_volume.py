#!/usr/bin/env python
#-*- coding:utf-8 -*-
from __future__ import unicode_literals
import boto3,os


class Ec2Volume(object):
    def __init__(self,volume_id,ec2_id='',dev_name='',connect=True,region="cn-northwest-1",
                    aws_key='xxxxxxxxxxxxxxx',aws_secret='xxxxxxxxxxxxxxx'
                 ):
        self.volume = volume_id
        self.ec2 = ec2_id
        self.dev = os.path.join('/dev/',dev_name)
        self.connect = connect

        self.region = region
        self.key = aws_key
        self.key2 = aws_secret


        self.login = self.Login()
        self.Run()

    def Login(self):
        aws_key = self.key
        aws_secret = self.key2

        ec2 = boto3.client(
                    'ec2',
                    aws_access_key_id = aws_key,
                    aws_secret_access_key = aws_secret,
                    region_name = self.region
                )
        return ec2

    def Attachvolume(self):
        ec2 = self.login
        ec2.attach_volume(
            Device = self.dev,
            InstanceId = self.ec2,
            VolumeId = self.volume,
        )


    def Detachvolume(self):
        ec2 = self.login
        ec2.detach_volume(
            VolumeId = self.volume,
        )


    def Run(self):
        if self.connect:
            self.Attachvolume()
        else:
            self.Detachvolume()


if __name__ == "__main__":
    import sys
    argv = sys.argv
    help2 = """help info:
        -vid       (must)                  #volume id
        -eid       (Attach must)           #ec2 id
        -dna       (Attach must)           #device  name
        -con       True | False  default=True    #Attach or Detach
        -h | --help
    """

    if "-h" in argv or "--help" in argv:
        print help2


    def Getvalue(value):
        position = argv.index(value) + 1
        resilt = argv[position]
        return resilt

    ##
    if "-con" in argv:
        con = Getvalue("-con")
        con = con.capitalize()
        if con == "True":
            con = True
        else:
            con = False
    else:
        con = True

    if "-vid" in argv:
        vid = Getvalue("-vid")
    else:
        print "\033[31mforat error\033[0m"
        print help2
        sys.exit(4)

    if "-eid" in argv:
        eid = Getvalue("-eid")
    else:
        print "\033[31mforat error\033[0m"
        print help2
        sys.exit(5)

    if "-dna" in argv:
        dna = Getvalue("-dna")
    else:
        print "\033[31mforat error\033[0m"
        print help2
        sys.exit(6)

    Ec2Volume(vid,eid,dna,con)
    """
    Example
    arg: -con false -vid vol-0814515c228f7c13b -dna sdh -eid i-0d5641f85faf744d4
    Ec2Volume('vol-0814515c228f7c13b','i-0d5641f85faf744d4','sdh',False)
    """
