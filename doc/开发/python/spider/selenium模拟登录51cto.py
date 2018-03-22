#!/usr/bin/env python
#coding:utf-8

#模拟登录51cto
from selenium import webdriver

driver = webdriver.Firefox()
driver.get('http://home.51cto.com/index?reback=http://blog.51cto.com')
driver.find_element_by_id('loginform-username').clear()
driver.find_element_by_id('loginform-username').send_keys('用户名')

driver.find_element_by_id('loginform-password').clear()
driver.find_element_by_id('loginform-password').send_keys('密码')

driver.find_element_by_name('login-button').submit()






