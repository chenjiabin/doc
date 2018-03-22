#!/usr/bin/py
#coding: utf-8
def decorator(func):					#定义装饰器,装饰器必须接受一个函数作为参数
    def deco_func(data):				#定义装饰的内容,接受被装饰函数的一个产生
        print 1,'display',data				
        ret = func(data)				#被装饰的函数，接受一个参数
        return ret					#返回,被装饰函数的返回值
    return deco_func					#返回被装饰的内容


@decorator						#调用装饰器
def show_func(data):					#定义被装饰的函数,并接受一个参数
    print 2,'state',data				
    return 'where'					#被装饰函数的返回值

ret2 = show_func('virtual')				#调用被装饰的函数,并传递一个参数
print ret2						#输出被装饰函数的返回值


