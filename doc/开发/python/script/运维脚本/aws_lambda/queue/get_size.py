import urllib2
def get_file_size(url):
    opener = urllib2.build_opener()
    request = urllib2.Request(url)
    request.get_method = lambda: 'HEAD'
    response = opener.open(request)
    response.read()
    return dict(response.headers).get('content-length', 0)
