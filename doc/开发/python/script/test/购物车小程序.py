#!/usr/bin/py
#coding: utf-8
#介绍：购物车小程序
import os

money = 0		#定义money初始值
iphone = 8000		#定义商品价格
vivo = 3000
oppo = 5000
Mi5 = 2500
apple = 10000000000
HP = 70000000000

def AUTHOR():			#介绍作着联系方式
    os.system('clear')		
    print '\033[34mAuthor E-main:2803660215@qq.com\033[0m'

def MONEY():
    while True:			
        global money		#定义全局变量
        money = raw_input('please input you of money: ')  #用户输入money
        try:
            if int(money):		#判断输入的是否为数字
                money  = int(money)
                break			#如果为数字则结束循环
        except:	
            continue			#如果不是数字的话则进入下一轮循环
        

def GOODS():				#格式话打印输出
        print '''you of money:%s		
Goods List:
	  1.  iphone:%s
	  2.    vivo:%s
	  3.    oppo:%s
	  4.     Mi4:%s
	  5.   apple:%s
	  6.      HP:%s
''' %(money,iphone,vivo,oppo,Mi5,apple,HP)

def SUM():			#判断money是否能够购买商品
    os.system('clear')
    if money >= 0:
        GOODS()
        print '\033[32mOK\033[0m'
    else:
        print '\033[31myou of money lack\033[0m'
        exit()

def EXISTSGOODS():
    global money		#定义全局变量
    while True:		#判断用户购买的商品是什么
        shop = raw_input('please input you of need: ')
        if shop == '1':
            money = money - iphone
            SUM()
        elif shop == '2':
            money = money - vivo
            SUM()
        elif shop == '3':
            money = money - oppo
            SUM()
        elif shop == '4':
            money = money - Mi5
            SUM()
        elif shop == '5':
            money = money - apple
            SUM()
        elif shop == '6':
            money = money - HP 
            SUM()
        elif shop == 'q' or shop == 'Q':
            exit()
        else:
            print '\033[31mError Please Again Input,q or Q exit ...\033[0m'

AUTHOR()
MONEY()
GOODS()
EXISTSGOODS()

