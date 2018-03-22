#!/usr/bin/python
#_*_ coding:UTF-8 _*_
## modified by lijianghao,2017,01,05
import os
import sys
import pwd
import smtplib
from email.header import Header
from email.mime.text import MIMEText


def sendmail(to, subj, body=None, fr=None, mailhost='smtp.exmail.qq.com'):
    if fr == None:
        fr = 'xxxx@xxxx.com'

    if body == None:
        body = subj
    msg = MIMEText(body,_subtype='plain',_charset='utf-8')
    msg['From'] = fr
    msg['Subject'] = Header(subj, 'utf-8')
    msg['To'] = 'xxx@xxx.com'
    passwd = 'xxxx'
    to = 'xxx@xxx.com'
    try:
        server = smtplib.SMTP()
        server.connect(mailhost)
        server.starttls()
        server.login(fr, passwd)
        server.sendmail(fr, to, msg.as_string())
        server.quit()
        stat = 0
        print "邮件发送成功"
    except:
        stat = -1
        print "Error:无法发送邮件"
    return(stat)


def get_input_argv():
    to_email = ['xxx@xxx.com',]
    from_email = 'xxx@xxx.com'
    subject = 'suject test'
    body = 'body test'
    if len(sys.argv) == 1:
        pass
    else:
        if '-t' in sys.argv:
            try:
                to_email = sys.argv[sys.argv.index('-t') + 1]
            except:
                pass
        else:
            pass
        if '-f' in sys.argv:
            try:
                from_email = sys.argv[sys.argv.index('-f') + 1]
            except:
                from_email = 'xxx@xxx.com'
        else:
            from_email = 'xxx@xxx.com'
        if '-u' in sys.argv:
            ind = sys.argv.index('-u') + 1
            subject = ''
            for i in range(ind, len(sys.argv), 1):
                if sys.argv[i] in ['-t', '-f', '-m']:
                    break
                subject = '%s %s ' % (subject, sys.argv[i])
        if '-m' in sys.argv:
            ind = sys.argv.index('-m') + 1
            body = ''
            for i in range(ind, len(sys.argv), 1):
                if sys.argv[i] in ['-t', '-f', '-u']:
                    break
                body = '%s %s ' % (body, sys.argv[i])
    return(to_email, from_email, subject, body)

if __name__ == '__main__':
    to_email, from_email, subject, body = get_input_argv()
    print to_email, from_email, subject, body
    print sendmail(to_email, subject, fr=from_email, body=body)
