    '''订阅者可以订阅一个或多个频道，发布者向一个频道发送消息后，所有订阅这个频道的订阅者都将收到消息，
	而发布者也将收到一个数值，这个数值是收到消息的订阅者的数量。
	订阅者只能收到自它开始订阅后发布者所发布的消息，
	之前发布的消息呢，就不可能收到了。'''

#面向过程的方法
#!/usr/bin/python
#coding:utf-8

#服务器端
import redis  
r = redis.Redis(host='127.0.0.1',port='6379')#连接redis
p = r.pubsub()  	    		#开启订阅
p.subscribe('6379') #接收订阅的数据,订阅的频道 

for item in p.listen(): #读取接收的数据
    print item 
    if item['type'] == 'message':#判断数据是否是用户发布的数据   
        data = item['data']     #取出用户要发布的数据
        print data  #打印要发布的数据

        if item['data'] == 'Q' or item['data'] == 'q':    
            break;  			    #退出程序
p.unsubscribe('6379')#关闭频道  
print '取消订阅'

#客户端
#!/usr/bin/py
#coding:utf-8
import redis  
r = redis.Redis(host='127.0.0.1',port=6379)#连接redis
  
while True:  
    my_input = raw_input("请输入发布内容:")#输入发布的内容  
    r.publish('6379', my_input)#发送到的频道,发布的内容  

    if my_input == 'Q' or my_input == 'q':  	    #判断用户是否要退出程序
        print '停止发布'  
        break; 


#面向对象的方法
#服务器端
#!/usr/bin/python
#coding:utf-8
import redis

class server(object):
    def __init__(self,ip='127.0.0.1',port=6379,sub='A'):
        self.ip = ip
        self.port = port
        self.connect = redis.Redis(host=self.ip,port=self.port)  #连接redis
        self.sub = sub #监听频道
    def se(self):
        spub = self.connect.pubsub()#打开订阅
        spub.subscribe(self.sub)#开始监听
        spub.listen()#用户发布的数据
        return spub

x = server()
p = x.se()
for item in p.listen():				    #打印接收到的数据
    print item

#客户端
#!/usr/bin/python
#coding:utf-8
import redis

class client(object):
    def __init__(self,ip='127.0.0.1',port=6379,pub='A'):
        self.ip = ip
        self.port = port
        self.connect = redis.Redis(host=self.ip,port=self.port)
        self.pub = pub		        #连接的频道
    def cl(self,content):
        self.connect.publish(self.pub,content)#频道,发送的数据

x = client()
while True:
    my_input = raw_input('请输入发布内容：')	    #发布的数据
    x.cl(my_input)

		
		