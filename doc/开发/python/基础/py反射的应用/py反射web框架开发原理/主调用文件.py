#!/usr/bin/py
#coding: utf-8
#charset-liet
#包的位置/root/python
import sys					
sys.path.append('/root')		#添加包搜索路径
url = raw_input('please input url: ')	#要求用户输入url(格式：url1/url2)
url2 = url.split('/')			#将url1和url2单独取出来
k = __import__('python.'+url2[0])	#导入 "包名+url1" 指定的模块
k1 = getattr(k,url2[0])			#导入包里的模块
k2 = getattr(k1,url2[1])		#调用模块里的函数
k2()					#执行函数


'''
例子
In [1]: k = __import__('python.function')	导入python.function模块

In [2]: k1 = getattr(p,'function')		调用function模块

In [3]: k2 = getattr(l,'login')			调用function模块里的login函数

In [4]: k2()					调用函数
login						输出信息
'''
