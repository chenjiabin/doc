#!/usr/bin/py
# coding: utf-8
#author E-main:2803660215@qq.com

import os,os.path,time,hashlib

def color(strin,COLOR='red'):	#定义终端显示颜色,接受显示的字符串和颜色(默认为红色)
    if COLOR == 'red':		#红
        tty = 31
    elif COLOR == 'green':	#绿
        tty = 32
    elif COLOR == 'yellow':	#黄
        tty = 33
    elif COLOR == 'blue':	#蓝
        tty = 34
    elif COLOR == 'purple':	#紫
        tty = 35
    elif COLOR == 'green+':	#深绿
        tty = 36

    ttycolor = '\033[%sm%s\033[0m' %(tty,strin)	
    print ttycolor	

def md5(md5_data):			#定义加密方法,接受一个字符串对他进行加密
    MD5 = hashlib.md5()			#创建md5类
    MD5.update(md5_data)		#加密字符串
    DATA = MD5.hexdigest()		#将加密后的结果保存到DATA中
    return DATA				#将DATA返回给函数

def check_file():		#检测认证文件
    user_file = os.path.isfile('/lib/ATM_python/user_name')	#检查认证文件是否存在
    if user_file == False:				#不存在
        user_dir = os.path.isdir('/lib/ATM_python')	#检查目录是否存在
        if user_dir == True:				#存在
            os.system('touch /lib/ATM_python/user_name')	#创建认证文件
        else:					 	   #目录不存在			
            os.system('mkdir -p /lib/ATM_python')	   #创建目录
            time.sleep(0.5)	         		   #延迟0.5秒
            os.system('touch /lib/ATM_python/user_name')   #创建认证文件
        start = file('/lib/ATM_python/user_name','r+')	   #打开认证文件
        syspasswd = md5('123456')			   #加密123456这个字符串
        start.write("{'password':\'%s\','user':'system'}\n" %syspasswd) #写入一个系统用户
        start.close() 					   #关闭文件			
        os.system('chmod 400 /lib/ATM_python/user_name')   #更改认证文件权限


def user_input():		#定义用户名检测
    color('user name must GT or EQ 3 LT 10')   #打印,用户名长度大于等于3小于10
    user_name_dict = {}			#定义空字典

    while True:		
        user_input = raw_input('please input username: ')	#用户输入用户名
        if len(str.strip(user_input)) >= 3 and len(str.strip(user_input)) < 10:
            #检测用户名是否合格,如果合格则跳出循环
            break

    user_name_dict['user'] = user_input		#将用户名加到字典中
    return user_name_dict		#将字典返回给函数

def passwd_input_func(user_passwd_dict):	#定义密码检测,接受上一个函数返回的字典
    color('password must GT or EQ 6 LT 129 input number')	#打印,密码只能是数字

    while True:
        passwd_input = raw_input('please input password: ')	#输入密码
        try:					#异常捕获
            long = len(passwd_input)		#计算密码长度
            int(passwd_input)			#检验用户输入的是否是数字
        except:					#如果产生异常
            color('input type error please again input') #打印,输入的类型错误
            continue       				#提前进入下一论循环
        if long >= 6 and long < 129:		#判断密码长度是否合格
            break				#如果合格则推出循环			

    user_passwd_dict['password'] = md5(passwd_input)  #对密码进行加密,保存到字典中
    return user_passwd_dict			#将字典返回给函数


if __name__ == '__main__':
    def register():		#定义注册用户函数
        check_file()		#调用检测文件函数
        time.sleep(1)		#延迟一秒
        user_file_start = file('/lib/ATM_python/user_name','r+')  #打开认证文件

        user_passwd_dict = user_input()	#将用户检测函数返回的字典保存在user_passwd_dict中
        dictionarys = passwd_input_func(user_passwd_dict)
        #将密码检测函数返回的字典保存在dictionarys中
        username_dict = dictionarys.get('user')  #取出字典中的用户名
   
        for i in user_file_start:		#读取用户认证文件
            check_user_name = eval(i).get('user')  #将文件中的行转换为字典,并取出用户名
            while True:
                if check_user_name == username_dict:  #判断用户名是否已经在认证文件中存在 
                    os.system('clear')
                    color('user name exist please again input','yellow')
                    username_dict = user_input().get('user') 
                    #调用用户名检测函数,并从新获取用户输入的用户名
                    user_file_start.seek(0)	#从文件开始处重新开始循环
                    break	#跳出while循环
                else:break	#如果用户名不存在

        user_file_start.close()		#关闭文件
        dictionarys['user'] = username_dict	#将新生成的用户名覆盖原来的用户名
    
        user_file_start = file('/lib/ATM_python/user_name','a+')  #打开文件
        user_file_start.write(str(dictionarys)+'\n')	#将字典一字符串的格式写入到文件
        user_file_start.close()			#关闭文件
        color('\n\nregister ok','green')	#打印注册成功

    def login():		#定义用户登录函数
        check_file()		#调用认证文件检测函数
        user_auth = file('/lib/ATM_python/user_name','r+')	#打开认证文件

        while True:
            user_name = raw_input('please input user name: ')	#输入用户名
            user_passwd = md5(raw_input('please input password: '))#输入密码,加密	
            for i in user_auth:			#循环文件
                username = eval(i).get('user')	#将文件中的行转换为字典,取出用户名
                userpasswd = eval(i).get('password')	#取出密码
                if username == str.strip(user_name):	#检测文件中是否有用户名
                    if userpasswd == str.strip(user_passwd):  #检测用户名和密码是否匹配
                        color('\n\nlogin ok','green') #打印,登录成功
                        user_auth.close()	#关闭文件
                        return 0	#退出函数
            else:	#如果用户名不存在或密码不匹配	
                color('username or password error ,please again input')
                user_auth.seek(0)	#让文件指针回到开始
    try:				#异常捕获	
        while True:	
           os.system('clear')		#清屏
           color('''			
       ----------------------------------
       +          1  register           +
       +          2  login              +
       +          Q  exit ...           +
       +          q  exit ...           +
       ----------------------------------
       ''','blue')     #打印,选择栏
           option = raw_input('option: ')   #用户输入选择
           if option == '1':		    #如果为1
               register()		    #调用注册函数
               break			    #结束循环
           elif option == '2':		    #如果为2
               login()			    #调用登录函数
               break
           elif option == 'q' or option == 'Q':		#如果为q或Q
               exit()					#推出脚本
           else:			    #如果都不是			
               continue			    #让用户重新选择
    except:				    #产生异常
        color('\n\n\nexit script ...')	    #退出脚本


