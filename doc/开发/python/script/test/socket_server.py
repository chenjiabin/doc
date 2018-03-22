#!/usr/bin/env py
#coding: utf-8
import socket						#导入socket模块


def cre_obj(IP,PORT):					
    obj = socket.socket()				#创建socket对象
    ip_add = (IP,PORT)					#监听的ip和端口
    obj.bind(ip_add)					#绑定ip和端口
    obj.listen(5)					#最大连接数
    return obj						#返回socket对象


def soc_ser(server):
        obj,ip_add = server.accept()			#阻塞监听
        obj.sendall('hello')				#发送给客户端的数据
        print ip_add[0]					#打印客户端的ip
        while True:					#循环发送内容
            data = obj.recv(1024)			#接受客服端的数据，一次最多1024字节
            print '\033[31m%s\033[0m' %data		#打印客户端的内容

            sending = raw_input('请输入内容: ')		#服务器回复客户端的内容
            sending = str.strip(sending)		

            if sending != '':				#回复内容不为空
                obj.sendall(sending)			#发送数据
            else:					#回复内容为空
                sending = '服务器故障'			#默认数据
                obj.sendall(sending)			#发送默认数据

        obj.close()					#断开连接


if __name__ == '__main__':
    server = cre_obj('192.168.0.10',8080)		#监听的ip和端口
    while True:
        soc_ser(server)					#循环监听






