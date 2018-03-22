# -*- coding: utf-8 -*-
from django import forms

class fm(forms.Form):
    email = forms.EmailField()
    a = forms.DateField()
    import re
    reg = re.compile(r'^(13[0-9]|15[0-9]|17[678]|18[0-9]|14[57])[0-9]{8}$')
    phone = forms.RegexField(reg)









