# -*- coding:utf-8 -*-
import smtplib
import os
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText  #导入MIMEText类
from email.mime.image import MIMEImage

HOST = "smtp.163.com"
SUBJECT = u"数据报告"
TO = "xxxx@163.com"
FROM = "yyyy@163.com"

def addimg(src,imgid):  #添加图片函数，参数1：图片路径 参数2：图片id
    fp = open(src,'rb') #打开文件
    msgImage = MIMEImage(fp.read()) #创建MIMEImage对象，读取图片内容并作为参数
    fp.close()
    msgImage.add_header('Content-ID',imgid) #指定图片文件的Content-ID，<img>标签
    return msgImage
msg = MIMEMultipart('related') #创建MIMEMultipart对象，采用related定义内嵌资源的邮件体
msgtext = MIMEText(""" 
<table width="600" border="0" cellspacing="0" cellpadding="4">
    <tr bgcolor="#CECFAD" height="20" style="font-size:14px">
        <td colspan=2>* 性能数据 <a href="www.baidu.oom"> 更多 >></a></td>
    </tr>
    <tr bgcolor="#EFEBDE" height="100" style="font-size:13px">
        <td>
            <img src="cid:io">
        </td>
    </tr>
</table>
""","html","utf-8")
msg.attach(msgtext)
img_path = os.path.join(os.path.dirname(os.path.dirname(os.path.realpath(__file__))),"graph/Context_switches_per_second.png")
msg.attach(addimg(img_path,"io"))



msg['Subject'] = SUBJECT
msg['From'] = FROM
msg['To'] = TO
try:
    server = smtplib.SMTP()
    server.connect(HOST,"25")
    server.starttls()
    server.login("yyy@163.com","123456789")
    server.sendmail(FROM,TO,msg.as_string())
    server.quit()
    print "邮件发送成功！"
except Exception,e:
    print "失败: %s" % str(e)