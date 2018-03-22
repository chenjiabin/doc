#!/usr/bin/py
#coding: utf-8

def test(**dic):	#定义函数，接受参数
    for k,v in dic.items():	#循环字典的key和value
        print '\033[31mkey=%s  value=%s\033[0m'% (k,v)  #打印key和value

if __name__ == '__main__':
    try:
        sum1 = 0		#定义初始值
        while True:
            if sum1 == 0:	#第一次循环执行的代码
                di = {}		#定义空dictionary
                print '\033[31minput q or Q ending input\033[0m'
                sum1 += 1

            key1 = raw_input('please input key: ') #用户输入的key
            if key1 == 'q' or key1 == 'Q':	#判断是否为q或者Q
                print di		#打印dictionary
                break			#跳出循环
            elif key1 =='':		#判断是否为空
                print '\033[31mkey cannot is enter\033[0m'
                continue		#提前进入下一轮循环
            elif di.has_key(key1) == True:	#判断key是否已经存在
                while True:	
                    cg = raw_input('key exist change [Y/N]: ')
                    #如果存在则要用户输入是否更改key的值
                    if cg == 'Y' or cg == 'y' or cg == 'N' or cg == 'n':
                        break
                     #如果输入的不是Y,y,N,n则要求用户重新输入
                if cg == 'N' or cg == 'n':
                     #如果输入为N或n则提前进入下一论循环
                    continue
            value1 = raw_input('please input value: ') #用户输入value
            di[key1] = value1  #将key和value加到dictionart中
    except KeyboardInterrupt:  #如果用户按下ctrl+c则推出脚本
            print ''
            exit()
    test(**di)		#将dictionary当作参数传给function
        
    
