#coding:utf-8


import gevent
from gevent import monkey
monkey.patch_socket()                   #自动完成io切换(必须有)


def test1(a):
    print 'test1',a
    gevent.sleep(0)
    print 'test111'


def test2(a,b):
    print 'test2',a
    gevent.sleep(0)
    print 'test222',b


gevent.joinall([
    gevent.spawn(test1,'test1aaaa'),                        #执行函数
    gevent.spawn(test2,'test2bbbb','test2cccc'),
])



