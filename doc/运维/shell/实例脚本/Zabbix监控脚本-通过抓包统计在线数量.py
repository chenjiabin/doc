#!/usr/bin/python  
# -*- coding:utf-8 -*-
# 版本 3 
# 增加了 排除tcp 连接断开状态数据包
# 重新规划了tcpdump命令
# 为了数据统计精确 去除了数据包协议统计功能
# 版本4 增加了在线数量30s超时功能
# 版本5 增加流量统计功能

import select
import re
import time,datetime
import subprocess, fcntl, os

#A02项目服务ip列表
A_Active_IP = ["172.20.3.107"]
A_Active2_IP = []
#A03项目服务ip列表
A03_service_IP = ["172.20.3.100","172.20.3.101","172.20.3.102","172.20.3.103","172.20.3.104",
    "172.20.3.105","172.20.3.106","172.20.3.107","172.20.3.116","172.20.3.117","172.20.3.118",
    "172.20.3.119","172.20.3.120","172.20.3.121","172.20.3.122","172.20.3.123"]
A03_Active2_IP = ["172.20.3.69","172.20.3.72","172.20.3.73","172.20.3.74","172.20.3.75","172.20.3.76","172.20.3.77",
    "172.20.3.78","172.20.3.79","172.20.3.81","172.20.3.82","172.20.3.83","172.20.3.84",
    "172.20.3.85","172.20.3.86"]

#定义项目列表 最后做标签使用
Projects_Name= ["A02.Active3","A03.Active3","A02.Active2","A03.Active2","UNKNOWN"]

#初始化字典函数
def init_info_array():
    #定义字典
    count = {}
    #初始化字典
    for pn in Projects_Name:
        count[pn] = {}
    return count
    
#统计10s内上传数据包数量 字典{项目名.访问源:{IP:[数据包个数,数据包总大小]}}} 统计没台上传的数据包总大小 每10s清空一次 单位bytes
om_packet_num = init_info_array()
#统计每个项目 每个服务的访问数量 字典{项目名.访问源:{{"服务IP,服务端口":{IP:数据包}}}}
service_visit_count = init_info_array()

#定义一个所有字典，用于记录所有数据包上传时间 有数据库的话可以选择此方案
#om_list = ["10.15.%s.%s" % (x,y) for x in xrange(0,256) for y in xrange(0,256)]
#om_update_time = {}
#采用动态列表 创建一个字典{项目名称.访问源:{IP:更新时间}}存放标识IP和数据报文上报时间 每10秒统计一次数据报文上报时间在60秒之内的数量  每60秒检索一次上报时间在60秒之外的 从字典移除
om_update_time = init_info_array()

#在线超时时间 秒
om_active_timeout = 60
#Active3 IP地址前缀
Active3_IP_prefix = "10.15"

#定义zabbix相关信息
zabbixserver = '172.16.0.1'
zabbixport = '10051'
zabbix_sender_bin = '/usr/local/zabbix/bin/zabbix_sender'
datacachefile = "/tmp/om_statistics.tmp"

#定义被监控服务器名称 用于zabbixsender发送的主机名 zabbix web gui 中定义的名称
name = "OMMonitor"

#定义抓包操作
#定义tcpdump命令和参数    
cmd1 = ['tcpdump','-i', 'eth0', '-nn','-tttt','-B', '4096','-s', '0','src','net','10.16.0.0/16']  

#生成子进程执行tcpdump 把标准输出重定向到管道
exec1 = subprocess.Popen(cmd1, stdout=subprocess.PIPE)

#定义grep结果输出管道的flags 执行F_GETFL
flags = fcntl.fcntl(exec1.stdout.fileno(), fcntl.F_GETFL)
#追加flags 非阻塞模式
fcntl.fcntl(exec1.stdout.fileno(), fcntl.F_SETFL, (flags | os.O_NONBLOCK))


def poll_tcpdump(proc):
    #打印实时信息变量为None
    every_packet_record = None  
    
    while True:  
        # 等待0.1秒接收数据
        readReady, _, _ = select.select([proc.stdout.fileno()], [], [], 0.1)  
        if not len(readReady):  
            break  
        try:  
            for line in iter(proc.stdout.readline, ""):  
                if every_packet_record is None:  
                    every_packet_record = ''
                    
                    
#定义匹配规则一，并算好相应的捕获组
                #2016-06-03 15:24:40.102650 IP 10.15.4.103.51183 > 172.20.3.104.7979: Flags [.], ack 4277003814, win 5840, options [nop,nop,TS val 103222 ecr 346730427], length 0
                pattern1 = re.compile(r'(\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2})\.(\d{6})\sIP\s+(\d+\.\d+\.\d+\.\d+)\.(\d+)\s>\s(\d+\.\d+\.\d+\.\d+)\.(\d+).*length\s(\d+)')
                match_line1 = re.search(pattern1,line)
#规则匹配，用以区分读取到的数据是哪一行（类）
                #如果匹配到了规则一
                if match_line1:
                    #匹配相应的变量
                    up_time = match_line1.group(1) + "." + match_line1.group(2)
                    src_ip = match_line1.group(3)
                    src_port = match_line1.group(4)
                    dst_ip = match_line1.group(5)
                    dst_port = match_line1.group(6)
                    data_length = match_line1.group(7)
                    #追加标准输出
                    every_packet_record = "时间: " + match_line1.group(1)+"."+ match_line1.group(2) + " 源IP地址: " + src_ip + " 源端口： " + src_port\
                    + " 目标IP地址: " + dst_ip + "目标端口" + dst_port + " 数据包长度: " + data_length
                    #检测数据包中数据长度是否为0 排出tcp三次握手 四次挥手数据包
                    if data_length == '0':
                        print "\033[0;34;1m 匹配到长度为0的数据包！ %s \033[0m" % every_packet_record
                        continue
                    else:
                        print every_packet_record
                     
                    #如果目标IP在哪个service_IP列表中，也就是说访问的是哪个服务服务
                    if dst_ip in A_Active_IP:Project = "A02.Active3"
                    elif dst_ip in A03_service_IP:Project = "A03.Active3"
                    elif dst_ip in A_Active2_IP:Project = "A02.Active2"
                    elif dst_ip in A03_Active2_IP:Project = "A03.Active2"
                    #如果发现数据包是回复的报文 break
                    elif Active3_IP_prefix in dst_ip:break
                    else:Project = "UNKNOWN"
#获取最小间隔时间，统计在线数量 从角度做统计
                    #更新数据上报时间
                    om_update_time[Project][src_ip] = up_time
                    #判断是否是第一次进来的IP 如果原地址不在字典中
                    if src_ip not in om_packet_num[Project]:
                        #初始化值为1
                        om_packet_num [Project][src_ip] = [1,int(data_length)]
                        #提示发现上线
                    if src_ip not in om_update_time[Project]:
                        print '\033[0;33;2m 提示: --> 有上线线 IP: %s \033[0m \n' % om_ip
                   	#非第一次出现的IP
                    else:
                        #数据包数量加1 数据包大小累加
                        om_packet_num [Project][src_ip][0] += 1
                        om_packet_num [Project][src_ip][1] += int(data_length)
#获取最各类服务的访问量 从服务角度做统计（目标地址，目标端口）
                    #定义以服务ip和端口命名的键
                    service_ip_port = "%s,%s" % (dst_ip,dst_port)
                    #判断是否是第一次访问的服务 如果目的地址不在目标字典中
                    if service_ip_port not in service_visit_count[Project]:
                        service_visit_count[Project][service_ip_port] = {src_ip:1}
                    #如果访问的服务在字典中，但访问的ip不在字典中
                    elif src_ip not in service_visit_count[Project][service_ip_port]:
                        service_visit_count[Project][service_ip_port][src_ip] = 1
                    #或服务和IP都在列表中 那么
                    else:
                        service_visit_count[Project][service_ip_port][src_ip] += 1
                        

        except IOError:
            print '\033[0;31;1m 未抓取到数据包。。。请等待!\033[0m'  
        break  
    #返回报文最短时间间隔 在线数量 报文类型数量
    return om_packet_num ,service_visit_count
  

import pprint
while True:
    #枚10s给zabbix发送一次统计数据
    if int(time.time() * 1000 ) % 10000 < 100:
        om_packet_num ,service_visit_count = poll_tcpdump(exec1)

        print '>>>> 上报数据.............'
        print om_packet_num
        print service_visit_count

        #把要发送的数据写入到缓存文件 
        #打开缓存文件 
        f = open(datacachefile,'w')
        #清空要写入的字符串
        datastr = ""
        #遍历Projects_Name=里的项目名称 
        current_time = datetime.datetime.now()
        for project_name in Projects_Name:
            #统计在线数量 先定义一个离线列表
            offline_om = []
            #遍历每一辆IP地址
            for om_ip in om_update_time[project_name]:
                #计算时间差 现在的时间和最新数据上报的时间
                up_timedelta = current_time - datetime.datetime.strptime(om_update_time[project_name][om_ip],"%Y-%m-%d %H:%M:%S.%f")
                #如果时间大于超时时间
                if up_timedelta > datetime.timedelta(0,om_active_timeout,0):
                    print '\033[0;33;1m 提示: --> 有离线 IP: %s 离线时间: %s \033[0m  \n' % (om_ip,up_timedelta)
                    #追加到离线列表
                    offline_om.append(om_ip)
            #遍历离线列表
            for ofline_om_ip in offline_om:
                #从列表字典中移除离线
                del  om_update_time[project_name][ofline_om_ip]
            #加入在线数量
            datastr += '\t'.join([name,"om_active_count[%s]" % project_name,str(len(om_update_time[project_name]))])+'\n'
            #统计每个项目的数据包个数 {项目名.访问源:{IP:[数据包个数，数据包总大小]}}}
            project_packet_num = sum([int(per_project_packet_num[0]) for per_project_packet_num in om_packet_num [project_name].values()])
            datastr += '\t'.join([name,"Packets_count[%s]" % project_name,str(project_packet_num)])+'\n'
            #统计每个项目的数据包大小 {项目名.访问源:{IP:[数据包个数，数据包总大小]}}} 结果除时间10s
            project_packet_size = sum([int(per_project_packet_size[1]) for per_project_packet_size in om_packet_num [project_name].values()])
            datastr += '\t'.join([name,"Packets_size[%s]" % project_name,str(project_packet_size/10)])+'\n'
            #加入每个服务访问的数量 访问数据包数量
            for service_ip_port in service_visit_count[project_name]:
                #统计每个服务访问数量 这里取字典service_visit_count[项目名][服务名]的长度
                datastr += '\t'.join([name,"service_visit_count_om_num[%s,%s]" % (project_name,service_ip_port),str(len(service_visit_count[project_name][service_ip_port]))])+'\n'
                #统计每个服务访问数据包数量 这里取字典service_visit_count[项目名][服务名]中的每个值得加和
                service_packet_num = sum([int(per_service_packet_num) for per_service_packet_num in service_visit_count[project_name][service_ip_port].values()])
                datastr += '\t'.join([name,"service_visit_count_packets_num[%s,%s]" % (project_name,service_ip_port),str(service_packet_num)])+'\n'
        #写入文件
        f.writelines(datastr)
        #刷新文件
        f.flush()
        #关闭文件
        f.close()
        #发送数据到 zabbix server
        cmd = "%s --zabbix-server %s --port %s --input-file %s" % (zabbix_sender_bin,zabbixserver,zabbixport,datacachefile)
        os.system(cmd)
        print om_update_time 
        print '>>>> 上报完成.............\n\n'
        #清空统计信息 每10s
        om_packet_num  = init_info_array()
        service_visit_count = init_info_array()
    #其他时间 正常打印 标准输出
    else:
        poll_tcpdump(exec1)
