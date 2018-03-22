#!/usr/bin/env py
#coding: utf-8
import SocketServer

class MyServer(SocketServer.BaseRequestHandler):	#使用SocketServer必须的实例化的类

    def handle(self):			#解析请求,BaseRequestHandler子类的方法
       conn = self.request 		#创建请求
     
       conn.send('hello')		#发送给客户端的数据
       while True:			#循环发送数据
           data =conn.recv(1024)	#接收客户端发送的数据,最大1024字节
           print data			#打印客户端发送的数据
           conn.send('world')		#发送给客户端的数据

       conn.close()			#关闭连接

server = SocketServer.ThreadingTCPServer(('192.168.0.10',8888),MyServer)	#基本的网络同步TCP服务器
print server.serve_forever()			#无限处理请求


