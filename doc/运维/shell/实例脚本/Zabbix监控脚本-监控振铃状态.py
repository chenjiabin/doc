#-*- coding:gbk -*-
#脚本用于检测振铃状态，并发送状态信息到zabbix服务器，需要配合zabbix模板，增加故障判断处理功能
# 版本3 增加每天定时自动重启振铃的功能 修复重启失败bug 缩减一些功能
import urllib2,json
import os,sys
import time,datetime
import serial
import getopt

#定义检测的振铃的ip地址
ip = "127.0.0.1"
#定义需要检测振铃的url地址
url = "http://%s:1234/Server/status" % ip
#定义振铃的控制串口号
triggerComPort = "COM56"
#定义振铃可用数量报警的阀值
normalThreshold = 10
#定义zabbix服务器地址
zabbixserver = '172.16.0.1'
#定义zabbix服务监听的端口，用于zabbix_sender发送数据
zabbixport = '10051'
#zabbix_sender命令的路径
zabbix_sender_bin = r'C:\zabbix_agent\bin\win32/zabbix_sender.exe'
#用于发送到zabbix的数据文件路径 --input-file选项之后
datacachefile = r'C:\zabbix_agent\trigger_status_%s_1234.txt' % ip
#定义zabbix web gui中配置的主机名称
HOST='Trigger02'

#定义检测振铃控制器数据口的字符串
alive_information = "order:noActive"
#定义振铃控制器数据口接收的命令1
order1 = "order:close1"


#定义日志函数，用于存放一些日志，简单调用python自带的logging模块，参数主要有两个日志信息和日志文件名称
def logger(info,logfile):
    import logging  
    logging.basicConfig(level=logging.DEBUG,
                        format='%(asctime)s    %(message)s',
                        datefmt='%a, %d %b %Y %H:%M:%S',
                        filename=logfile,
                        filemode='a')
    logging.debug(info)

#定义发邮件的函数，用于当振铃的可用数量低于阀值的时候自动发送邮件，参数是可拥振铃的数量
def information(num):
    import smtplib
    import email.utils
    from email.message import Message
    
    #邮件的发送地址，需要自定义
    from_addr = "xxxxx@163.com"
    #邮件的接收地址，需要自定义
    to_addr = "xxxxx@sabc.net"
    #主题
    subject = "TRIGGER ERROR!!!"
    #smtp server需要自定义
    smtpserver = "smtp.163.com"
    #用户名，一般和邮件发送地址相同
    username = from_addr
    #登陆密码
    password = "1234567789"
    #获取现在的事件 RFC 2822标准
    current_time = email.utils.formatdate(time.time(),True)
    #邮件发送的内容，里面写入振铃服务器可用数量的，内容可以自定义
    content = """This is a mail from trigger
    You should handle trigger server manually
    The SIM available number is : %s
    The trigger is 192.168.1.12
    """ % num

    #创建一个基础Message对象
    Smessage = Message()
    #指定主题
    Smessage["Subject"] = subject
    #制定发件人
    Smessage["From"] = from_addr
    #指定收件人
    Smessage["To"]= to_addr
    #指定抄送
    #Smessage["Cc"] = cc_addr
    #读入内容
    Smessage.set_payload(content+current_time)
    #返回字符串类型的 格式化信息
    msg = Smessage.as_string()

    try:
        #链接smtp服务器
        sm = smtplib.SMTP(smtpserver)
    #发生异常SMTPConnectError
    except SMTPConnectError as e:
        #打印异常类型 异常信息
        print SMTPConnectError,e
        #第一异常信息
        message = "SMTPConnectError,%s" % e
        #记录异常信息，调用logger函数
        logger(message,r'C:\Users\admin\Desktop\debug.log')
        exit()
    #如果没有任何异常
    else:
        try:
            #尝试登陆
            sm.login(username,password)
        #发生登陆异常 SMTPHeloError,SMTPAuthenticationError,SMTPException
        except (SMTPHeloError,SMTPAuthenticationError,SMTPException) as e:
            #定义异常信息 
            message = "SMTPHeloError,SMTPAuthenticationError,SMTPException,%s" % e
            #记录异常信息
            logger(message,r'C:\Users\admin\Desktop\debug.log')
            exit()
        #如果登录正常
        else:
            #执行发送邮件命令
            sm.sendmail(from_addr,to_addr,msg)
    #休息5秒钟
    time.sleep(5)
    #定义邮件发送成功的信息
    message = "mail send successfully!!!"
    #记录邮件发送成功信息
    logger(message,r'C:\Users\admin\Desktop\debug.log')
    #退出邮件服务器
    sm.quit()

#定义重启程序函数，用于发现故障第一不处理
def restart_program():
    #输出重启程序信息
    print  "重启程序中。。。"
    #定义kill程序的命令
    kill_java = r"taskkill /F /IM java.exe"
    #执行kill程序命令
    os.system(kill_java)
    #定义程序的路径
    filename = r"C:\Users\admin\Desktop\start.bat.lnk"
    #定义程序启动的命令
    cmd = r'cmd /k "start %s' % filename
    #执行程序启动
    os.popen(cmd)
    return


#定义一个类，用于发给zabbix的数据标准对象
class Metric(object):
    #初始化 包含主机 键 值 
    def __init__(self, host, key, value):
	    self.host = host
	    self.key = key
	    self.value = value
    #返回一个刻碟太对象	    
    def __iter__(self):
            return iter([self.host,self.key,self.value])

#定义状态函数 用于统计状态 发送数据到zabbix server	参数为函数名 给装饰器调用	
def status(func_name):
    #定义状态统计函数
    def status_count():
        #初始化各种状态计数变量值为0
        error=normal=total=failed_count=success_count=wait_count=doing_count = 0
        
        try:
            #尝试打开监控url
            data_init = urllib2.urlopen(url)
            #读取url数据
            data = data_init.read()
        #打开url发生异常
        except:
            try:
                #定义异常信息和异常代码
                message = "CODE: %s, Open the url failed!" % data_init.code
            #发生UnboundLocalError异常，非http异常
            except UnboundLocalError:
                #单独定义异常信息
                message = "UnboundLocalError: local variable 'data_init' referenced before assignment"
                sys.exit(3)

        #用json处理数据，转换为字典类型
        status_dict = json.loads(data)
        #遍历字典中的所有串口
        for port in status_dict["info"]["com"].keys():
                #如果发现状态为error 变量error自加1
                if status_dict["info"]["com"][port]["error"]:error += 1
                #否则normal自加1
                else:
                    normal += 1
                #每遍历一次total自加1
                total += 1
        #得到的值减去windows上自带的com1和振铃控制器串口
        total -= 2
        error -= 2
        #统计任务状态 for循环遍历
        for id in status_dict['info']['task'].keys():
                #如果状态为failed，那么变量failed_count自加1
                if status_dict['info']['task'][id]['callStatus'] == 'failed':failed_count += 1
                #如果状态为success，那么变量success_count自加1
                if status_dict['info']['task'][id]['callStatus'] == 'success':success_count += 1
                #如果状态为wait，那么变量wait_count自加1
                if status_dict['info']['task'][id]['callStatus'] == 'wait':wait_count += 1
                #如果状态为doing，那么变量doing_count自加1
                if status_dict['info']['task'][id]['callStatus'] == 'doing':doing_count += 1
        #返回各种状态的值 
        return error,normal,total,failed_count,success_count,wait_count,doing_count
    #定义生成zabbix的数据文件 --input-file选项之后
    def write2file():
        #定义字典的键值 放在一个列表 与上面一一对应
        namelist = ['Error','Available','Total','Failed','Success','Waiting','Doing']
        #生成状态字典
        datadict = dict(zip(namelist,status_count()))
        #打开数据文件
        f = open(datacachefile,'w')
        #遍历状态字典，生成每一行的数据字符串
        for key,value in datadict.items():
            #生成要写入文件每一行的字符串
            datastr = '\t'.join(Metric(HOST,('trigger.status[%s]' % key),str(value)))+'\n'
            #写如文件
            f.writelines(datastr)
        #刷新
        f.flush()
        #关闭文件
        f.close()
        #返回数据字典
        return datadict
    #定义发送到zabbix server的函数
    def send2zabbix():
        #发送到zabbix server的命令
        cmd = "%s --zabbix-server %s --port %s --input-file %s "  % (zabbix_sender_bin,zabbixserver,zabbixport,datacachefile)
        #执行命令
        os.system(cmd)
    #定义执行函数 调用上面的定义函数
    def execute():
        #执行函数 返回状态字典
        datadict = write2file()
        #发送到zabbix server
        send2zabbix()
        #返回
        return func_name(datadict)
    #返回execute闭包函数
    return execute
#定义函数装饰器
@status
#附加函数 返回状态字典
def r2d(datadict):
    return datadict

#定义重启系统的函数，用于发生故障第二步处理，用于如果程序自动重启之后 故障依旧
def soft_restart_system():
    #定义带有时间戳的日志文件
    logfile = r'C:\Users\admin\Desktop\logs_%s.txt' % time.strftime('%Y-%m-%d_%H-%M-%S', time.localtime())
    logger("警告： 准备软重启系统",logfile)
    print "开始软重启系统。。。"
    for i in range(5,-1,-1):
        print "倒计时。。   %s " % str(i)
    #定义系统重启命令
    restart_cmd = r"shutdown /r /t 00"
    #执行系统重启命令
    os.system(restart_cmd)
    return

#定义重启振铃，用于发生故障第三步处理    
def restart_trigger():
    #如果振铃控制串口是打开的
    if ser.isOpen():
        #休息5秒
        time.sleep(5)
        #向串口发送振铃控制命令1
        ser.write(order1)
        #输出振铃正在重启。。
        print "振铃正在重启中。。。"
    #如果串口没有打开
    else:
        #定义错误信息
        message = "振铃控制器数据口打开失败！"
        #输出错误信息
        print message
        #并记录到日志
        logger(message,r'C:\Users\admin\Desktop\debug.log')
        exit()

    
    
#定义振铃控制器是否正常检查函数，用于和振铃控制器通信
def alive_check():
    #如果串口是打开的
    if ser.isOpen():
        #发送监测信息
        ser.write(alive_information)
        #输出检测命令已发送
        print "控制器数据口检测: 通信正常"
    #否则
    else:
        #定义错误信息
        message = "振铃控制器数据口打开失败"
        #打印错误信息
        print message
        #记录错误信息
        logger(message,r'C:\Users\admin\Desktop\debug.log')
        exit()

#程序刚刚开机启动，等待50秒，等待java程序正常启动完成
time.sleep(50)

try:
    #尝试打开振铃控制器串口
    ser = serial.Serial(triggerComPort,115200)
    #打开成功 打印成功信息
    print "振铃控制器数据口打开成功"
    #如果串口状态是关闭的
    if ser.closed:
        #再次执行打开
        ser = serial.Serial(triggerComPort,115200)
#串口打开发生异常
except:
    #定义异常信息
    message = "振铃控制器数据口打开失败"
    #打印异常信息
    print message
    #记录异常信息
    logger(message,r'C:\Users\admin\Desktop\debug.log')
    #发送邮件通知，人工处理
    information("0")
    exit()

#开始程序正常无限循环进程
while True:
    #初始化故障处理标记为0
    RestartTriggerTag=0
    #获取状态字典
    datadict = r2d()
    #定义状态打印出值 用于console观察实时状态
    record_count = "可用的SIM卡数量: " + str(datadict['Available']) + " 失败的数量: " + str(datadict['Failed']) \
                   + " 成功的数量: " + str(datadict['Success']) + " 排队的数量: " + str(datadict['Waiting']) \
                   + " 正在处理的数量: " + str(datadict['Doing'])
    #打印信息
    print record_count
    #循环判断可用数量小于设定的阀值
    while datadict['Available'] <= normalThreshold:
        #如果还没有重启过振铃
        if RestartTriggerTag < 1:
            #重启振铃
            restart_trigger()
            #振铃重启标记加1
            RestartTriggerTag += 1
            #记录日志
            logger("严重警告: 重启振铃中。。。",r'C:\Users\admin\Desktop\debug.log')
            #休息30秒 等待振铃启动完成
            time.sleep(30)
            #重新获取状态数据
            datadict = r2d()
            #打印状态
            print "振铃重启标记",RestartTriggerTag,datadict['Available']
        #如果重启过振铃，还没重启过程序，可用数量依然低于阀值
        #去除重启程序服务
        else:
            #记录日志 我要重启了
            logger("警告： 软重启系统",r'C:\Users\admin\Desktop\debug.log')
            information(datadict['Available'])
            #重启操作系统
            soft_restart_system()
    #可用数量好了 高于设定阀值了
    else:
        #如果三者标记有一个为1 就是执行过
        if RestartTriggerTag == 1:
            #定义恢复成功信息
            message = "警报：振铃已经成功自我恢复。"
            #打印信息
            print message
            #记录日志
            logger(message,r'C:\Users\admin\Desktop\debug.log')
            #移除重启标记文件 为了执方便下一轮故障处理从0开始
            os.remove(r"C:\Users\admin\Desktop\local_com_checks.ini")
    #输出开始振铃控制器可用检测
    #print "Begain checking alive..."
    #执行检测函数 这个功能由于取消了 所以没做任何判断
    alive_check()
    #定时重启功能
    current_time_in_day =  datetime.datetime.now()
    if current_time_in_day.hour == 1 and current_time_in_day.minute == 10 and current_time_in_day.second < 45:
        restart_trigger()
        soft_restart_system()
    print "当前时间: %s \n" % current_time_in_day
    #休息十秒 每10秒循环一次
    time.sleep(10)

