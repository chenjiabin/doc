#!/usr/bin/env python
# -*- coding:utf8 -*-
import json
import urllib2
import timehandler

url = 'http://172.16.1.254/api_jsonrpc.php'
username = "admin"
password = "zabbix"

class ZabbixAuth():
    """ class::ZabbixAuth authorization for zabbix access """
    def __init__(self, url, username, password):
        self.url = url
        self.username = username
        self.password = password
    def authenticate(self):
        values = {'jsonrpc': '2.0',
                  'method': 'user.login',
                  'params': {
                      'user': self.username,
                      'password': self.password
                  },
                  'id': '0'
                  }
    
        data = json.dumps(values)
        req = urllib2.Request(self.url, data, {'Content-Type': 'application/json-rpc'})
        response = urllib2.urlopen(req, data)
        output = json.loads(response.read())
        try:
            message = output['result']
        except:
            message = output['error']['data']
            print message
            quit()
        return output['result'] 
     
def _data_request(url, data):    
    req = urllib2.Request(url, data, {'Content-Type': 'application/json-rpc'})
    response = urllib2.urlopen(req, data)
    output = json.loads(response.read())
    return output['result'] 
    
class ZabbixDatas(ZabbixAuth):
    """ Get all zabbix datas ,includes a few methods of hosts, item and data .etc """
    def __init__(self, url, username, password):
        ZabbixAuth.__init__(self, url, username, password) 
    def __str__(self):
        print "You url is : %s " % self.url
    class GetHosts(ZabbixAuth):
        def __init__(self):
            ZabbixAuth.__init__(self, url, username, password)        
        def _getall(self):     
            data = json.dumps({
                               'jsonrpc': '2.0',
                               'method': 'host.get',
                               'params': {
                                          "output": ["hostid","status","host"], 
                                          "selectInterfaces": ["interfaceid", "ip" ],
                                          },                          
                               'id': '1',
                               'auth': self.authenticate()
                                })
            return _data_request(self.url, data)
        def _search(self, search_pattern):
            """Return results that match the given wildcard search.

                Accepts an array, where the keys are property names, and the values are strings 
                to search for. If no additional options are given, this will perform a LIKE “%…%” search.

                Allows searching by interface properties. Works only with text fields."""
            data = json.dumps({
                               'jsonrpc': '2.0',
                               'method': 'host.get',
                               'params': {
                                          "output": ["hostid","status","host"], 
                                          "selectInterfaces": ["interfaceid", "ip" ],
                                          "search":{
                                                    "host":["%s" % search_pattern]   
                                               }
                                          },
                               'id': '1',
                               'auth': self.authenticate()
                                })
            return _data_request(self.url, data)
        def _filter(self, filter_pattern):
            """Return only those results that exactly match the given filter.

                Accepts an array, where the keys are property names, 
                and the values are either a single value or an array of values to match against. 

                Allows filtering by interface properties."""
            data = json.dumps({
                               'jsonrpc': '2.0',
                               'method': 'host.get',
                               'params': {
                                          "output": ["hostid","status","host"], 
                                          "selectInterfaces": ["interfaceid", "ip" ],
                                          "filter":{
                                                    "host":["%s" % filter_pattern]   
                                               }
                                          },
                               'id': '1',
                               'auth': self.authenticate()
                                })
            return _data_request(self.url, data)
        def __str__(self):
            return str(self._getall())
    class GetItems(ZabbixAuth):
        def __init__(self, hostid):
            ZabbixAuth.__init__(self, url, username, password)
            self.hostid = hostid      
        def _getall(self):     
            data = json.dumps({
                               'jsonrpc': '2.0',
                               'method': 'item.get',
                               'params': {
                                          "output": ["itemid","name","key_","state","status","lastvalue","hostid"], 
                                          "hostids":self.hostid,
                                          "sortfield": "name",
                                          },                     
                               'id': '1',
                               'auth': self.authenticate()
                               })
            return _data_request(self.url, data)
        def _search(self, search_pattern):
            data = json.dumps({
                               'jsonrpc': '2.0',
                               'method': 'item.get',
                               'params': {
                                          "output": ["itemid","name","key_","state","status","lastvalue","hostid"], 
                                          "hostids":self.hostid,
                                          "search":{
                                                    "key_": "%s" % search_pattern,
                                                },
                                          "sortfield": "name",
                                          },                     
                               'id': '1',
                               'auth': self.authenticate()
                               })            
            return _data_request(self.url, data)
        def _filter(self, filter_pattern):
            """Return only those results that exactly match the given filter.

                Accepts an array, where the keys are property names, and the values are either a single value or an array of values to match against. 

                Supports additional filters: 
                host - technical name of the host that the item belongs to."""
            data = json.dumps({
                               'jsonrpc': '2.0',
                               'method': 'item.get',
                               'params': {
                                          "output": ["itemid","name","key_","state","status","lastvalue","hostid"], 
                                          "hostids":self.hostid,
                                          "filter":{
                                                    "key_": "[%s]" % filter_pattern,
                                                },
                                          "sortfield": "name",
                                          },                     
                               'id': '1',
                               'auth': self.authenticate()
                               })            
            return _data_request(self.url, data)
        def __str__(self):
            return str(self._getall())
    class GetItemDatas(ZabbixAuth):
        def __init__(self, hostid, itemid):
            ZabbixAuth.__init__(self, url, username, password)
            self.hostid = hostid
            self.itemid = itemid
        def _items_data_get(self, start_time,end_time):
            """_items_data_get
            it accept hostid and itemid (required) and unix timestamp starttiem and end time"""
            data = json.dumps({
                       'jsonrpc': '2.0',
                       'method': 'history.get',
                       'params': {
                                  "output": "extend", 
                                  "hostids":self.hostid,
                                  'itemids':self.itemid,
                                  #"sortfield": "clock",
                                  #"limit":10,
                                  'time_from': start_time,
                                  'time_till': end_time,
                                  },
                        'id': '1',
                        'auth': self.authenticate()
                        })    
            return _data_request(self.url, data)
        def _getall(self): 
            """    Get an item all history date
             actually there are two hidden arguments: start tiem equal "0" and end time now
             This method will return more data,so it will very slow(Don't suggest use unless for debugging) """    
            start_time = "0"
            end_time = timehandler.currenttimestamp()
            itemsdict = self._items_data_get(start_time, end_time)
            return itemsdict
        def _specific_time(self, days=0, hours=0, minutes=0, seconds=0):
            """ Get some times ago util now histoey date of hostid.itemid"""
            start_time = timehandler.timedeltahandler(days=days,hours=hours,minutes=minutes,seconds=seconds)
            end_time = timehandler.currenttimestamp()
            itemsdict = self._items_data_get(start_time, end_time)
            return itemsdict
        def __str__(self):
            return str(self._getall())
        
if __name__ == "__main__":
    import pprint
    new = ZabbixDatas(url, username, password) 
    new = new.GetItems("10084")
    pprint.pprint(new._search("net"))
