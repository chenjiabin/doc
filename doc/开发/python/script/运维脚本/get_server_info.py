#!/usr/bin/env python
#-*- coding: utf-8 -*-
from subprocess import PIPE,Popen
import psutil
import sys
import netifaces


def shell(cmd):
    command = Popen(cmd, shell=True,stdout=PIPE)
    get_value = command.stdout.read().strip('\n').strip()
    return get_value

def company(num):
    #memory company M
    m = num / 1024
    m = m / 1024
    return m

def generate_dict(list_):
    dict_ = {}
    for name in list_:
        dict_[name] = sys._getframe().f_back.f_locals[name]
    return dict_


class GetServerInfo(object):
    def server(self):
        kernel = shell("uname -r")
        hostname = shell("hostname")
        uuid = shell("dmidecode -s system-uuid")
        snid = shell("dmidecode -s system-serial-number")
        description = shell("lsb_release -a | grep Description | awk -F: '{print $2}'")
        manufacturer = shell("dmidecode -s system-manufacturer")
        product = shell("dmidecode -s system-product-name")

        list_ = ["kernel","hostname","uuid","snid","description","manufacturer","product"]
        return generate_dict(list_)

    def cpu(self):
        phy = shell("cat /proc/cpuinfo| grep 'physical id'| sort| uniq| wc -l")
        cpu = shell("dmidecode -s processor-version")
        core = psutil.cpu_count(logical=False)
        thread = psutil.cpu_count()

        list_ = ["phy","cpu","core","thread"]
        return generate_dict(list_)

    def memory(self):
        mem_set = psutil.virtual_memory()
        total = company(mem_set[0])
        use = company(mem_set[3])
        free = company(mem_set[4])
        buffers = company(mem_set[7])               #缓冲
        cached = company(mem_set[8])                #缓存
        available = company(mem_set[5])             #可以内存

        list_ = ['total','use','free','buffers','cached','available']
        return generate_dict(list_)

    def disk(self):
        all_nic = psutil.disk_partitions()
        disk = []
        for device in all_nic:
            partition = device.device
            mount = device.mountpoint
            fstype = device.fstype
            disk_info = psutil.disk_usage(mount)
            total = company(disk_info.total)
            use = company(disk_info.used)
            free = company(disk_info.free)

            list_ = ['partition','mount','fstype','total','use','free']
            disk.append(generate_dict(list_))
        return disk

    def network(self):
        data = []
        driver_name_list = netifaces.interfaces()
        for driver_name in driver_name_list:
            network_card_info = netifaces.ifaddresses(driver_name)
            try:
                mac = network_card_info[netifaces.AF_LINK].pop()['addr']     #get mac
                ip_and_mask = network_card_info[netifaces.AF_INET].pop()
                ip = ip_and_mask['addr']
                mask = ip_and_mask['netmask']
                gateway = netifaces.gateways()['default'][netifaces.AF_INET][0]
                list_ = ['driver_name','ip','mask','mac','gateway']
                data.append(generate_dict(list_))
            except Exception:
                continue
        return data

    def raid(self):
        pass



server = GetServerInfo()
print server.disk()
print server.server()
print server.network()
print server.cpu()
print server.memory()



