#!/usr/bin/py
import sys,difflib

try:
    file1 = sys.argv[1]
    file2 = sys.argv[2]
except:
    print '\033[31m  FormatError: file1 file2\033[0m'
    exit()

def readfile(filename):
    try:
        A = open(filename)
        test = A.readlines()
        A.close()
        return test
    except:
        print '\033[31m  OpenError: open %s error\033[0m' %filename
        exit()


test1 = readfile(file1)
test2 = readfile(file2)

diff = difflib.ndiff(test1,test2)
for i in diff:
    print i,



