# -*- coding: utf-8 -*-
from __future__ import unicode_literals
from django.shortcuts import render
from django.shortcuts import HttpResponse
from django.http import HttpResponseRedirect
from models import *
from django.views.decorators.csrf import csrf_exempt
import json

def indxe(request):
    return render(request,'index.html')


def hosts(request):
    return HttpResponse('ok')


def groups(request):
    if request.method == 'GET':
        data = group.objects.all()
        return render(request,'group.html',{'data':data})
    else:
        name = request.POST.get('group')
        item = request.POST.get('item')
        drop = request.POST.get('delete')
        if name:
            group.objects.create(name=name,item=item)
            return HttpResponseRedirect('group')

        if drop:
            group.objects.filter(name=drop).delete()
            return HttpResponseRedirect('group')

        return HttpResponseRedirect('group')

@csrf_exempt
def ajax(request):
    redata = {'start':True,'error':'','info':''}

    if request.method == 'GET':
        return render(request,'ajax.html')
    else:
        user = request.POST.get('user')
        password = request.POST.get('password')
        if user and password:
            redata['info'] = '提交成功'
            return HttpResponse(json.dumps(redata))
        else:
            redata['start'] = False
            redata['error'] = '用户名或密码不能为空'
            return HttpResponse(json.dumps(redata))


def cache(request):
    import time
    times = time.time()
    return render(request,'cache.html',{'date':times})


from app01.tforms import fm

def form(request):
    if request.method == 'GET':
        result = fm()
        return render(request, 'tforms.html', {'info': result})

    elif request.method == 'POST':
        result = fm(request.POST)
        if result.is_valid():
            return HttpResponse('成功')
        else:
            return render(request,'tforms.html',{'error':result})

# def Signals(request):
#     from app01.tsignals import my_callback
#     return HttpResponse('ok')

def Customsignals(request):
    from app01.tsignals import pizza_done
    #pizza_done.send(sender='seven', toppings=123, size=456)
    pizza_done.send(sender='seven')
    return HttpResponse('test')


def Fbv(request):
    pass


from django.views import View

class CBV(View):
    def dispatch(self, request, *args, **kwargs):
        print '在接受到用户请求之后第一个执行的方法'
        response = super(CBV, self).dispatch(request, *args, **kwargs)
        #必须继承至父类
        print '在返回用户数据之前执行'
        return response         #必须返回父类的继承

    def get(self,request):
        print 'gggggggggggggggg'
        return HttpResponse('CBV')


















