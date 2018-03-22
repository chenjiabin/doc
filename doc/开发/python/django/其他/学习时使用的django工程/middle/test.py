# -*- coding: utf-8 -*-
from django.utils.deprecation import MiddlewareMixin
from django.shortcuts import HttpResponse



class test(MiddlewareMixin):
    def process_request(self,request):
        print "中间件1请求"
        #print request
        #return HttpResponse('拦截你的请求')

    def process_view(self, request, index, index_args, index_kwargs):
        print("中间件3view")

    def process_response(self,request,response):
        print "中间件1返回"
        #print response
        return response

    def process_exception(self, request, exception):
        print exception
        return HttpResponse('error')


