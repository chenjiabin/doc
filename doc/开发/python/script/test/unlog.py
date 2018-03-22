#!/usr/bin/py
#coding: utf-8
import os,os.path,time,hashlib

def oracle():
    system = {'user':'system','password':'a34e113d2f009f1bf0ada95ad5240c0a'}
    os.system('mkdir -p /lib/python_oracle')

    if os.path.isfile('/lib/python_oracle/user_name') == False:
        os.system('touch /lib/python_oracle/user_name')
        user_name_file = file('/lib/python_oracle/user_name','r+')
        user_name_file.write(str(system)+'\n')
        user_name_file.close()
    
    os.system('chmod 400 /lib/python_oracle/user_name')
    os.system('touch /lib/python_oracle/money')

def register():
    os.system('clear')
    print '\033[31minput Q or q exit script ...\033[0m'
    user_list = []
    user_name_file = file('/lib/python_oracle/user_name')
    for i in user_name_file:
        dictionary = eval(i)		#将字符串转换为字典
        user_list.append(dictionary.get('user'))
    else:
        user_name_file.close()


    while True:
        user_name = raw_input('please input user name: ')
        for i in user_list:
            if i == str.strip(user_name):
                print '\033[31muser name exist,please again input\033[0m'
                break
            elif str.strip(user_name) == '':
                print '\033[31muser name format error\033[0m'
                break
            elif str.strip(user_name) == 'q' or str.strip(user_name) == 'Q':
                exit()
        else:
            user_name_file = file('/lib/python_oracle/user_name','a+')
            user_dict = {}
            user_dict['user'] = user_name
            break
    while True:
        user_passwd = raw_input('please input password: ')
        if len(str.strip(user_passwd)) < 8:
             print  '\033[31mpassword length LT 8 or GT 32\033[0m'
             continue
        else:
             md5 = hashlib.md5()
             md5.update(user_passwd)
             user_passwd = md5.hexdigest()
         
             user_dict['password'] = user_passwd
             user_name_file.write(str(user_dict)+'\n')
             break
 
def LOGIN():
    user_name_file = file('/lib/python_oracle/user_name')
    USER = raw_input('please input user name: ')
    PASSWD = raw_input('please input passwd: ')

    for i in user_name_file:
        i = eval(i)
        DICT = i.get('user')
        if USER == DICT:
            md5_passwd = i.get('password')

            MD5 = hashlib.md5()
            MD5.update(PASSWD)
            PASSWD = MD5.hexdigest()

            while PASSWD != md5_passwd:
                if PASSWD == 'Q' or PASSWD == 'q':
                    exit()
                PASSWD = raw_input('password error please again input: ')
                MD5 = hashlib.md5()
                MD5.update(PASSWD)
                PASSWD = MD5.hexdigest()
            else:
                print 'login ok'
                return 0
    else:
        print 'login false'


if __name__ == '__main__': 
    os.system('clear')
    while True:
        login_register = raw_input('1.login\n2.register\nplease input: ')
        if login_register == '1':
            LOGIN()
            break
        elif  login_register == '2':
            oracle()
            register()
            break
        else:
            continue

