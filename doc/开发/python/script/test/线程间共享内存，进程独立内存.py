#!/usr/bin/py
#-*- coding: utf-8 -*-
from multiprocessing import Process
from threading import Thread
import time

def run(info_list,n):
    info_list.append(n)
    print info_list 


print '多进程++++++++++++++++++++++++++++++++++++++++'
time.sleep(0.01)

li = []
for i in range(1,10):
    p = Process(target=run,args=[li,i])
    p.start()


time.sleep(0.01)
print '\n\n\n多线程++++++++++++++++++++++++++++++++++++++++'


li2 = []
for j in range(1,10):
    x = Thread(target=run,args=[li2,j])
    x.start()


