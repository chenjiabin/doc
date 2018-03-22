"""web01 URL Configuration

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/1.11/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  url(r'^$', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  url(r'^$', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.conf.urls import url, include
    2. Add a URL to urlpatterns:  url(r'^blog/', include('blog.urls'))
"""
from django.conf.urls import url
from django.conf.urls import include
from django.contrib import admin
from app01.views import *
import debug_toolbar


urlpatterns = [
    url(r'^admin/', admin.site.urls),
    url(r'^index/', indxe),
    url(r'^$', indxe),
    url(r'^host/', hosts),
    url(r'^group/', groups),
    url(r'^ajax/', ajax),
    url(r'^cache/', cache),
    url(r'^form/', form),
    #url(r'^signals/', Signals),
    url(r'^signals/', Customsignals),
    url(r'^fvb/', Fbv),
    url(r'^cbv/', CBV.as_view()),
    url(r'^__debug__/', include(debug_toolbar.urls)),
]
















