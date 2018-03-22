#!/usr/bin/py
# coding: utf-8
import os
file1 = open('/etc/passwd')	#打开文件
os.system('clear')
print '\033[34mInput q or Q exit ...\033[0m'

while True:
    inputcolor = '\033[31mUSERNAME: \033[0m'
    user = raw_input(inputcolor)	     #用户输入需要查询的用户名
    if user == 'q' or user == 'Q':	#输入q或Q退出脚本
        exit()
    elif user == '':		#输入为空的话提前进入下一纶循环
        continue
    elif user == 'clear':	#输入clear清除屏幕
        os.system('clear') 
    stats = 0

    for i in file1:			
        s = i.split(':')[0]	
        if user in s:			#支持用户名模糊查找	
            color = '\033[32m%s\033[0m'% s	#将查找到的用户名高亮显示
            k = i.split(':')		#将字符串以:分隔
            k.pop(0)			#将用户名删除
            strfind = '' 			
            p = 0
            for j in k:
                if p == 0:			#第一次循环
                    strfind += color + ':' + j	#将用户名和其他元素连接
                    p += 1			
                else:			#第一次之后的循环
                    strfind += ':' + j	#将列表的元素以:为分界拼接在一起
                    p += 1
            print strfind,			#打印出拼接之后的结果
            stats = stats + 1
    file1.seek(0)
    if user != 'clear':			#判断用户是否是清除屏幕
        print '\nfind \033[31m%s\033[0m individual user'% stats

