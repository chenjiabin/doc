# from django.core.signals import request_started
# from django.dispatch import receiver
#
# @receiver(request_started)
# def my_callback(sender, **kwargs):
#     print("Request finished!")



import django.dispatch
pizza_done = django.dispatch.Signal()
pizza_done2 = django.dispatch.Signal(providing_args=["toppings", "size"])


def Mycallback(sender, **kwargs):
    print("callback")

pizza_done.connect(Mycallback)






