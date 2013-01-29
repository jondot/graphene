#!/usr/bin/python2.7

import httplib, urllib, sys
import subprocess

with open('../app/js/d3.gauge.js') as graphene_gauge_file:
    graphene_gauge = graphene_gauge_file.read()

p = subprocess.Popen(['/usr/bin/coffee', '-cp', '../app/js/graphene.coffee'],stdout=subprocess.PIPE)
graphene_data = p.communicate()[0]

params = urllib.urlencode([
    ('code_url', 'http://code.jquery.com/jquery-1.8.0.min.js'), # jquery
    ('code_url', 'http://underscorejs.org/underscore-min.js'), # underscore
    ('code_url', 'http://backbonejs.org/backbone-min.js'), # backbone
    ('code_url', 'http://d3js.org/d3.v3.min.js'), # d3
    ('js_code', graphene_gauge),
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
response = conn.getresponse()
data = response.read()

f = open('../build/index.js','w')
f.write(data)

print "Done."

conn.close()
