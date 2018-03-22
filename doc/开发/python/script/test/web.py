#!/usr/bin/python
#-*- coding: utf-8 -*-
from wsgiref.simple_server import make_server           #内置模块

def index():                    #定义处理请求的函数
    return '<h1>index</h1>'

def login():
    return '<h1>login</h1>'

def logout():
    return '<h1>logout</h1>'

def found():
    return '<h1>404</h1>'

url = [                             #关系映射
    ['/index',index],
    ['/login',login],
    ['/logout',logout],
]


def RunServer(environ, start_response):             #应用程序
    start_response('200 ok', [('Content-Type', 'text/html')])   #状态码和请求类型
    userUrl = environ['PATH_INFO']                  #获取用户请求的url
    for i in url:
        if userUrl == '/':                          #如果用户没有请求页面则直接返回首页
            return index()

        if userUrl == i[0]:         #判断用户请求的url是否存在
            func = i[1]             #获取url对应的函数
            result = func()         #获取函数执行的结果
            return result           #将函数执行的结果返回给用户
    else:
        return found()              #如果没有匹配到用户请求的url则返回404页面


if __name__ == '__main__':          #服务器程序
    httpd = make_server('', 80, RunServer)      #调用应用程序，监听80端口
    print 'server HTTP ON port 80 ...'
    httpd.serve_forever()           #启动程序


