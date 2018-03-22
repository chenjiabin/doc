#!/usr/bin/py
#coding: utf-8
#Author E-main:2803660215@qq.com

#pwfe file format:
#user:root passwd:123.com	root:UserName	123.com:Passwd

#auth file format
#root				root:UserName
'''
需求：编写登录接口
1、提示用户输入用户名和密码
2、认证成功后显示登录成功
3、输错三次后锁定帐号
'''  
def INTERFACELOGIN():
    sum = 0			#定义初始值
    while sum < 3:		
        sum += 1		#每次循环sum加1
        user = raw_input('Please Input User Name: ')	#用户输入用户名
        password = raw_input('Please Input password: ')	#用户输入密码
        pwfe = open('/root/passwd')	#打开身份验证文件
        auth = open('/root/auth')	#打开被锁定的帐号文件
        while user == '' and password == '': #判断输入是否为空
            print '\033[31mUser Or Passwd NO is blank\033[0m' 
            user = raw_input('Please Input User Name: ')
            password = raw_input('Please Input password: ')
        for j in auth:			#遍历文件
            j = j.strip()		#去除空格和换行符
            if j == user:		#判断帐号是否被锁定
               print '\033[31mUserName is Locked\033[0m'
               auth.close()		#关闭文件
               exit()			#退出程序

        for i in pwfe:			#遍历文件，如果用户存在
            i = i.strip()		
            i = i.split()		#已空格为分隔符，分隔字符串
            if i[0] == 'user:'+ user:	#判断用户是否存在
                if i[1] == 'passwd:'+ password:	   #判断用户密码是否正确
                    print '\033[32mLogin OK\033[0m'
                    pwfe.close()	#关闭文件
                    exit()		#退出程序
        else:				#如果用户不存在
            print '\033[31mLogin False\033[0m'
            pwfe.close()		#关闭文件

if __name__ == '__main__':		
    try:				
        INTERFACELOGIN()		#调用函数
    except KeyboardInterrupt:		#如果程序被CTRL+C终止时运行的代码
        print '\n\033[31mexit script\033[0m'
