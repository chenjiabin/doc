#!/usr/bin/env python
#coding:utf-8

from selenium import webdriver
from selenium.webdriver.common.desired_capabilities import DesiredCapabilities
from threading import Thread
import time

class test(Thread):
    def __init__(self,url,where):
        super(test,self).__init__()
        self.url = url
        self.where = where

    def run(self):
        driver = webdriver.Remote(
            command_executor=self.url,
            desired_capabilities=DesiredCapabilities.FIREFOX
        )

        driver.get(self.where)
        time.sleep(10)
        driver.close()


def pool():
    proxy = {
        'http://127.0.0.1:4444/wd/hub':'http://www.baidu.com',
        'http://127.0.0.1:5555/wd/hub':'http://www.jd.com'
    }
    return proxy


for url, where in pool().items():
    spider = test(url,where)
    spider.start()













