#!/usr/bin/env py
#coding:utf-8
import socket			

obj = socket.socket()		
obj.connect(('192.168.0.10',8888))			#连接服务器

while True:						#循环接收数据
    data = obj.recv(1024)				#接收的数据
    print '\033[31m%s\033[0m'%data 
    sending = raw_input('请输入发送内容: ')		#发送给服务器的数据
  
    while str.strip(sending) == '':			#判断数据是否为空
        sending = raw_input('请输入发送内容: ')		#为空则让用户在次输入
        
    obj.sendall(sending)				#发送数据给服务端
    
        


