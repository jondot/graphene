#!/usr/bin/python

import httplib, urllib, sys
import subprocess

#with open('../app/js/graphene.js') as graphene_file:
#    graphene_content = graphene_file.read()

p = subprocess.Popen(['/usr/bin/coffee', '-cp', '../app/js/graphene.coffee'],stdout=subprocess.PIPE)
graphene_data = p.communicate()

params = urllib.urlencode([
    ('code_url', 'http://code.jquery.com/jquery-1.8.0.min.js'), # jquery
    ('code_url', 'http://underscorejs.org/underscore-min.js'), # underscore
    ('code_url', 'http://backbonejs.org/backbone-min.js'), # backbone
    ('code_url', 'http://d3js.org/d3.v3.min.js'), # d3
    ('js_code', graphene_data),
    ('compilation_level', 'SIMPLE_OPTIMIZATIONS'),
    ('output_format','text'),
    ('output_info','compiled_code'),
    ])

headers = {
    "Content-Type": "application/x-www-form-urlencoded",
}

conn = httplib.HTTPConnection('closure-compiler.appspot.com')
conn.request('POST','/compile',params,headers)
response = conn.get_response()
data = response.read()
print data
conn.close()
