#!/usr/bin/env py
#coding:utf-8
import os
import os.path
import re
import sys
import paramiko
import threading
import time
from IPy import IP as ipy



def syntax_check():			#配置文件检查
    return_value = os.system('python /etc/addresspool.conf')
    if return_value != 0:
       exit()


def ACL_check(value):		#获取用户定义的ip和网段
    if value == 'ip':
        value = re.compile('^allow_ip.*')		#获取ip
    elif value == 'network':
        value = re.compile('^allow_network.*')	#获取网段
    else:
        print '\033[31mparameter error\033[0m'
        exit()    

    num = 0
    conf_file  = open('/etc/addresspool.conf')	
    for i in conf_file:						#读取配置文件内容
        ip_or_net = re.findall(value,i)
        if ip_or_net != []:
            num += 1
            ACL_add = ip_or_net[0]
            ACL_add = ACL_add.split('=')[1]
            ACL_add = ACL_add.split(',')		#获取ip地址池
    else:
        if num == 0:				#如果用户没有定义地址
            return 'None'

    conf_file.close()
    return ACL_add 			#返回地址池名称

    
def GET_ip(ip_pool):		#处理地址池名称,生成ip地址(IP对象)
    path = sys.path[2]
    copy_mod = 'cp /etc/addresspool.conf %s/addresspool.py' %path
    os.system(copy_mod)

    import addresspool as add
    ip_list = []
    for i in ip_pool:
        i = i.strip()
        ACL_ip =  getattr(add,i)
        for ip in ACL_ip:
            ip_list.append(ip)
    return ip_list			#返回ip地址池


def GET_net(net_pool):		#处理地址池名称(NET对象)
    import addresspool as network
    net_list = []
    for i in net_pool:
        i = i.strip()
        ACL_net =  getattr(network,i)
        for net in ACL_net:
            net_list.append(net)
    return net_list			#返回网段

    
def IPY(net_list):			#将网段解析成ip地址
    net_pool = []
    net_add = []
    for i in net_list: 
        ip_pool = []
        ip_list = ipy(i)
        for ip in ip_list:
            ip = str(ip)
            ip_pool.append(ip)
        else:
            ip_pool.pop(0)
            ip_pool.pop()
        net_pool.append(ip_pool)
    return net_pool			#返回ip地址池

'-----------------------------------config_file--------------------------------------------'


def telnet(ip,port,user,passwd,comd):		#shell命名处理
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(ip,port,user,passwd)
        stdin,stdout,stderr = ssh.exec_command(comd)
       
        stderr = stderr.read()
        if stderr.strip() != '':
            print '\033[34m%s %s\033[0m' %(ip,stderr)
    except:
        print '\033[31mconnect %s\033[0m' %ip



def get_or_put(file2, file4, ip, port, user, passwd):		#文件上传处理
    try:
        get_put = paramiko.Transport((ip,port))			#服务器ip和端口(使用SFTP时使用)
        get_put.connect(username=user, password=passwd)             #连接服务器，用户名和密码
        sftp = paramiko.SFTPClient.from_transport(get_put)        	#使用SFTP协议
        sftp.put(file2,file4)
    except:
        print '\033[31merror %s\033[0m' %ip


'------------------------------------handle------------------------'
def conf():				#生成配置文件内容
    content = '''
#default deny all
#allow appoint ip address or appoint network address

ACL_ip_name1 = [
    "192.168.0.2",
    "192.168.0.10",
    "192.168.0.40",
    "192.168.0.60",
]

#ACL_network_name1 = [
#    "192.168.1.0/24",
#]

allow_ip = ACL_ip_name1
#allow_network = ACL_network_name1
    '''

    if os.path.isfile('/etc/addresspool.conf') == False:	
        os.system('touch /etc/addresspool.conf')
        mod_content = "echo '%s' > /etc/addresspool.conf" %content.strip()
        os.system(mod_content)



'----------------------------------confing_file_content------------'

if __name__ == '__main__':
    conf()		#首次执行生成配置文件
    def Syntax():		#定义命令语法
        print '''
        syntax error:
            -h display help info
            -t test config file syntax
            -s execute shell "command option argv"
            -p upload file upload_file_path  upload_preservation_path  
        '''
    
    try:
        put = ''
        comd = ''
        argv = sys.argv
        opt = argv[1]
        if opt == '-s':
            comd = argv[2]
        elif opt == '-h':
            Syntax()
        elif opt == '-t':
            test = os.system('python /etc/addresspool.conf')
            if test == 0:
                print '"/etc/addresspool.conf"  Syntax ok\n\n'
        elif opt == '-p':
            put = 'put'
            file2 = argv[2]
            filename = file2.split('/').pop()

            file = argv[3]
            file4 = file +'/'+ filename 
        else:
            Syntax()
    except:
            Syntax()
    

    syntax_check()
    ip = ACL_check('ip')
    net = ACL_check('network')
    if ip != 'None':
        ip_list = GET_ip(ip)

    if net != 'None':				
        net_list = GET_net(net)
        net_pool = IPY(net_list)
        for netadd in net_pool:
            for ipadd in netadd:
                ip_list.append(ipadd)

    user = 'root'
    passwd = '123.com'
    port = 22

    if comd != '':			#多线程执行命令
        for ip in ip_list:
            try:
                sshd = threading.Thread(target=telnet,args=(ip ,port ,user ,passwd ,comd,))
                sshd.start()
                time.sleep(0.1)	#延迟打印
            except:
                pass
 
    if put != '':			#多线程上传文件
        for ip in ip_list:
            try:
                exce = threading.Thread(target=get_or_put, args=(file2,file4,ip,port,user,passwd,))
                exce.start()
                time.sleep(0.1)	#延迟打印
            except:
                pass

     
    path = sys.path[2]
    rm_mod = 'rm -f %s/addresspool.py' %path
    os.system(rm_mod)





