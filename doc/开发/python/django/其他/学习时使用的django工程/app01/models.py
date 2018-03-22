# -*- coding: utf-8 -*-
from django.db import models


class group(models.Model):
    name = models.CharField(max_length=100,unique=True)
    item = models.CharField(max_length=100)


class host(models.Model):
    host = models.GenericIPAddressField()
    group = models.ForeignKey(group)


# class HostList(models.Model):
#     hostname = models.CharField(max_length=50)
#     ip = models.GenericIPAddressField()
#     memory = models.IntegerField()
#
#
# class Application(models.Model):
#     name = models.CharField(max_length=50)
#     path = models.CharField(max_length=200)
#
#
# class HostToGroup(models.Model):
#     hid = models.ForeignKey(HostList)
#     aid = models.ForeignKey(Application)

class Hosts(models.Model):
    hostname = models.CharField(max_length=50)
    ip = models.CharField(max_length=200)
    memory = models.IntegerField()


class Apps(models.Model):
    name = models.CharField(max_length=50)
    path = models.CharField(max_length=200)
    table = models.ManyToManyField(Hosts)















