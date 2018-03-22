#!/usr/bin/py
#-*- coding: utf-8 -*-

from multiprocessing import Process

def run(info_list,n):
    info_list.append(n)
    print info_list 

li = []
for i in range(1,10):
    p = Process(target=run,args=[li,i])
    p.start()