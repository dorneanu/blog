+++
title = "Web Application Survey Tutorial"
date = "2014-08-06"
tags = ["ipython", "appsec", "web", "python"]
author = "Victor Dorneanu"
category = "blog"
+++

Suppose you get a list of some URLs and you are asked to "investigate" them. The list is full of some random URLs related to your company and nobody knows about. You don't have a clue who is responsible for them nor which applications (if any) are running behind them. Sounds like a cool task, ugh?

Well in today's post I'll show you how I've managed it to minimize the process of analyzing each URL manually and saved me a lot of time automatizing things.

## Setup environment


```
%pylab inline
# <!-- collapse=True -->
import binascii
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import networkx as nx
import datetime as dt
import time
import ipy_table
import dnslib
import pythonwhois
import urlparse
import tldextract
import json
import os
import sys
import urllib2


from yurl import URL
from urlparse import urlparse
from IPython.display import display_pretty, display_html, display_jpeg, display_png, display_json, display_latex, display_svg

# Ipython settings
pd.set_option('display.height', 1000)
pd.set_option('display.max_rows', 500)
pd.set_option('display.max_columns', 500)
pd.set_option('display.max_colwidth', 100)
pd.set_option('display.width', 3000)
pd.set_option('display.column_space', 1000)

# Change working directory
os.chdir("/root/work/appsurvey")
```

    Populating the interactive namespace from numpy and matplotlib
    height has been deprecated.
    


First I'll read the list of targets from some CSV file.


```
# Fetch list of random URLs (found using Google)
response = urllib2.urlopen('http://files.ianonavy.com/urls.txt')
targets_row = response.read()

# Create DataFrame
targets = pd.DataFrame([t for t in targets_row.splitlines()], columns=["Target"])
print("First 20 entries in the targets list")
targets[:20]
```

    First 20 entries in the targets list





<div style="max-height:1000px;max-width:1500px;overflow:auto;">
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>Target</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0 </th>
      <td>                 http://www.altpress.org/</td>
    </tr>
    <tr>
      <th>1 </th>
      <td>              http://www.nzfortress.co.nz</td>
    </tr>
    <tr>
      <th>2 </th>
      <td>            http://www.evillasforsale.com</td>
    </tr>
    <tr>
      <th>3 </th>
      <td>             http://www.playingenemy.com/</td>
    </tr>
    <tr>
      <th>4 </th>
      <td>         http://www.richardsonscharts.com</td>
    </tr>
    <tr>
      <th>5 </th>
      <td>                    http://www.xenith.net</td>
    </tr>
    <tr>
      <th>6 </th>
      <td>                http://www.tdbrecords.com</td>
    </tr>
    <tr>
      <th>7 </th>
      <td>     http://www.electrichumanproject.com/</td>
    </tr>
    <tr>
      <th>8 </th>
      <td>        http://tweekerchick.blogspot.com/</td>
    </tr>
    <tr>
      <th>9 </th>
      <td> http://www.besound.com/pushead/home.html</td>
    </tr>
    <tr>
      <th>10</th>
      <td>   http://www.porkchopscreenprinting.com/</td>
    </tr>
    <tr>
      <th>11</th>
      <td>              http://www.kinseyvisual.com</td>
    </tr>
    <tr>
      <th>12</th>
      <td>                http://www.rathergood.com</td>
    </tr>
    <tr>
      <th>13</th>
      <td>                   http://www.lepoint.fr/</td>
    </tr>
    <tr>
      <th>14</th>
      <td>                     http://www.revhq.com</td>
    </tr>
    <tr>
      <th>15</th>
      <td>           http://www.poprocksandcoke.com</td>
    </tr>
    <tr>
      <th>16</th>
      <td>              http://www.samuraiblue.com/</td>
    </tr>
    <tr>
      <th>17</th>
      <td>   http://www.openbsd.org/cgi-bin/man.cgi</td>
    </tr>
    <tr>
      <th>18</th>
      <td>                   http://www.sysblog.com</td>
    </tr>
    <tr>
      <th>19</th>
      <td>            http://www.voicesofsafety.com</td>
    </tr>
  </tbody>
</table>
</div>



Now I'll split the URLs in several parts:

* schema (HTTP, FTP, SSH etc.)
* host
* port
* path
* query (?q=somevalue etc.)


```
# <!-- collapse=True -->
# Join root domain + suffix
extract_root_domain =  lambda x: '.'.join(tldextract.extract(x)[1:3])

target_columns = ['scheme', 'userinfo', 'host', 'port', 'path', 'query', 'fragment', 'decoded']
target_component = [list(URL(t)) for t in targets['Target']]

df_targets = pd.DataFrame(target_component, columns=target_columns)
empty_hosts = df_targets[df_targets['host'] == '']

# Copy path information to host
for index,row in empty_hosts.iterrows():
    df_targets.ix[index:index]['host'] = df_targets.ix[index:index]['path']
    df_targets.ix[index:index]['path'] = ''
    
# Extract root tld
df_targets['root_domain'] = df_targets['host'].apply(extract_root_domain)

# Drop unnecessary columns
df_targets.drop(['query', 'fragment', 'decoded'], axis=1, inplace=True)

# Write df to file (for later use)
df_targets.to_csv("targets_df.csv", sep="\t")

print("First 20 Entries")
df_targets[:20]
```

    First 20 Entries





<div style="max-height:1000px;max-width:1500px;overflow:auto;">
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>scheme</th>
      <th>userinfo</th>
      <th>host</th>
      <th>port</th>
      <th>path</th>
      <th>root_domain</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0 </th>
      <td> http</td>
      <td> </td>
      <td>               www.altpress.org</td>
      <td> </td>
      <td>                  /</td>
      <td>               altpress.org</td>
    </tr>
    <tr>
      <th>1 </th>
      <td> http</td>
      <td> </td>
      <td>           www.nzfortress.co.nz</td>
      <td> </td>
      <td>                   </td>
      <td>           nzfortress.co.nz</td>
    </tr>
    <tr>
      <th>2 </th>
      <td> http</td>
      <td> </td>
      <td>         www.evillasforsale.com</td>
      <td> </td>
      <td>                   </td>
      <td>         evillasforsale.com</td>
    </tr>
    <tr>
      <th>3 </th>
      <td> http</td>
      <td> </td>
      <td>           www.playingenemy.com</td>
      <td> </td>
      <td>                  /</td>
      <td>           playingenemy.com</td>
    </tr>
    <tr>
      <th>4 </th>
      <td> http</td>
      <td> </td>
      <td>      www.richardsonscharts.com</td>
      <td> </td>
      <td>                   </td>
      <td>      richardsonscharts.com</td>
    </tr>
    <tr>
      <th>5 </th>
      <td> http</td>
      <td> </td>
      <td>                 www.xenith.net</td>
      <td> </td>
      <td>                   </td>
      <td>                 xenith.net</td>
    </tr>
    <tr>
      <th>6 </th>
      <td> http</td>
      <td> </td>
      <td>             www.tdbrecords.com</td>
      <td> </td>
      <td>                   </td>
      <td>             tdbrecords.com</td>
    </tr>
    <tr>
      <th>7 </th>
      <td> http</td>
      <td> </td>
      <td>   www.electrichumanproject.com</td>
      <td> </td>
      <td>                  /</td>
      <td>   electrichumanproject.com</td>
    </tr>
    <tr>
      <th>8 </th>
      <td> http</td>
      <td> </td>
      <td>      tweekerchick.blogspot.com</td>
      <td> </td>
      <td>                  /</td>
      <td>  tweekerchick.blogspot.com</td>
    </tr>
    <tr>
      <th>9 </th>
      <td> http</td>
      <td> </td>
      <td>                www.besound.com</td>
      <td> </td>
      <td> /pushead/home.html</td>
      <td>                besound.com</td>
    </tr>
    <tr>
      <th>10</th>
      <td> http</td>
      <td> </td>
      <td> www.porkchopscreenprinting.com</td>
      <td> </td>
      <td>                  /</td>
      <td> porkchopscreenprinting.com</td>
    </tr>
    <tr>
      <th>11</th>
      <td> http</td>
      <td> </td>
      <td>           www.kinseyvisual.com</td>
      <td> </td>
      <td>                   </td>
      <td>           kinseyvisual.com</td>
    </tr>
    <tr>
      <th>12</th>
      <td> http</td>
      <td> </td>
      <td>             www.rathergood.com</td>
      <td> </td>
      <td>                   </td>
      <td>             rathergood.com</td>
    </tr>
    <tr>
      <th>13</th>
      <td> http</td>
      <td> </td>
      <td>                 www.lepoint.fr</td>
      <td> </td>
      <td>                  /</td>
      <td>                 lepoint.fr</td>
    </tr>
    <tr>
      <th>14</th>
      <td> http</td>
      <td> </td>
      <td>                  www.revhq.com</td>
      <td> </td>
      <td>                   </td>
      <td>                  revhq.com</td>
    </tr>
    <tr>
      <th>15</th>
      <td> http</td>
      <td> </td>
      <td>        www.poprocksandcoke.com</td>
      <td> </td>
      <td>                   </td>
      <td>        poprocksandcoke.com</td>
    </tr>
    <tr>
      <th>16</th>
      <td> http</td>
      <td> </td>
      <td>            www.samuraiblue.com</td>
      <td> </td>
      <td>                  /</td>
      <td>            samuraiblue.com</td>
    </tr>
    <tr>
      <th>17</th>
      <td> http</td>
      <td> </td>
      <td>                www.openbsd.org</td>
      <td> </td>
      <td>   /cgi-bin/man.cgi</td>
      <td>                openbsd.org</td>
    </tr>
    <tr>
      <th>18</th>
      <td> http</td>
      <td> </td>
      <td>                www.sysblog.com</td>
      <td> </td>
      <td>                   </td>
      <td>                sysblog.com</td>
    </tr>
    <tr>
      <th>19</th>
      <td> http</td>
      <td> </td>
      <td>         www.voicesofsafety.com</td>
      <td> </td>
      <td>                   </td>
      <td>         voicesofsafety.com</td>
    </tr>
  </tbody>
</table>
</div>



## Whois

Now get WHOIS information based on data in `df_targets`:


```bash
%%bash
if [ ! -d "WHOIS" ]; then
    mkdir WHOIS
fi
```


```
# Get unique values
uniq_roots = df_targets['root_domain'].unique()
uniq_subdomains = df_targets['host'].unique()
```


```
# <!-- collapse=True -->

def date_handler(obj):
    return obj.isoformat() if hasattr(obj, 'isoformat') else obj

target_whois = {}

def fetch_whois(domains):
    """ Fetch WHOIS information for specified domains (list) """
    for d in domains:
        print("Get WHOIS for\t %s ..." % d)

        # Check if file already exists
        if os.path.isfile("WHOIS/%s.json" % d):
            print("File exists already. Aborting.")
            continue

        try:
            # Get whois information
            whois_data = pythonwhois.get_whois(d)

            # Convert to JSON$
            json_data = json.dumps(whois_data, default=date_handler)

            # Write contents to file
            with open('WHOIS/%s.json' % d, 'w') as outfile:
              json.dump(json_data, outfile)

            # Sleep for 20s    
            time.sleep(20)
        except:
            print("[ERROR] Couldn't retrieve WHOIS for\t %s" % d)
            
# I'll only fetch the root domains and only the first 20. Feel free to uncomment this
# and adapt it to your needs.
#fetch_whois(uniq_subdomains)
fetch_whois(uniq_roots[:20])
    
```

    Get WHOIS for	 altpress.org ...
    Get WHOIS for	 nzfortress.co.nz ...
    Get WHOIS for	 evillasforsale.com ...
    Get WHOIS for	 playingenemy.com ...
    Get WHOIS for	 richardsonscharts.com ...
    Get WHOIS for	 xenith.net ...
    Get WHOIS for	 tdbrecords.com ...
    Get WHOIS for	 electrichumanproject.com ...
    Get WHOIS for	 tweekerchick.blogspot.com ...
    Get WHOIS for	 besound.com ...
    Get WHOIS for	 porkchopscreenprinting.com ...
    Get WHOIS for	 kinseyvisual.com ...
    Get WHOIS for	 rathergood.com ...
    Get WHOIS for	 lepoint.fr ...
    Get WHOIS for	 revhq.com ...
    Get WHOIS for	 poprocksandcoke.com ...
    Get WHOIS for	 samuraiblue.com ...
    Get WHOIS for	 openbsd.org ...
    Get WHOIS for	 sysblog.com ...
    Get WHOIS for	 voicesofsafety.com ...


## Get all DNS records


```bash
%%bash
if [ ! -d "DNS" ]; then
    mkdir DNS
fi
```


```
# <!-- collapse=True -->
def fetch_dns(domains):
    """ Fetch all DNS records for specified domains (list) """
    for d in domains:
        print("Dig DNS records for\t %s ..." % d)

        # Check if file already exists
        if os.path.isfile("DNS/%s.txt" % d):
            print("File exists already. Aborting.")
            continue
            
        # Get DNS info
        dig_data = !dig +nocmd $d any +multiline +noall +answer
        dig_output = "\n".join(dig_data)
        
        # Write contents to file
        with open('DNS/%s.txt' % d, 'w') as outfile:
            outfile.write(dig_output)
            outfile.close()
        
        time.sleep(5)
        
# I'll only fetch the root domains and only the first 20. Feel free to uncomment this
# and adapt it to your needs.
#fetch_dns(uniq_subdomains)
fetch_dns(uniq_roots[:20])
```

    Dig DNS records for	 altpress.org ...
    Dig DNS records for	 nzfortress.co.nz ...
    Dig DNS records for	 evillasforsale.com ...
    Dig DNS records for	 playingenemy.com ...
    Dig DNS records for	 richardsonscharts.com ...
    Dig DNS records for	 xenith.net ...
    Dig DNS records for	 tdbrecords.com ...
    Dig DNS records for	 electrichumanproject.com ...
    Dig DNS records for	 tweekerchick.blogspot.com ...
    Dig DNS records for	 besound.com ...
    Dig DNS records for	 porkchopscreenprinting.com ...
    Dig DNS records for	 kinseyvisual.com ...
    Dig DNS records for	 rathergood.com ...
    Dig DNS records for	 lepoint.fr ...
    Dig DNS records for	 revhq.com ...
    Dig DNS records for	 poprocksandcoke.com ...
    Dig DNS records for	 samuraiblue.com ...
    Dig DNS records for	 openbsd.org ...
    Dig DNS records for	 sysblog.com ...
    Dig DNS records for	 voicesofsafety.com ...


## Read WHOIS information

After collecting the data I'll try to manipulate data in a pythonic way in order to export it later to some useful format like Excel. I'll therefor read the collected data from every single file, merge the data and create a `DataFrame`.


```
# <!-- collapse=True -->
from pprint import pprint

# Global DF frames
frames = []

def read_whois(domains):
    for d in domains:
        print("Reading WHOIS for\t %s" % d)
        
        try:
            with open('WHOIS/%s.json' % d, 'r') as inputfile:
                whois = json.loads(json.load(inputfile))

                # Delete raw record
                whois.pop('raw', None)

                data = []
                
                # Iterate contacts -> tech
                if whois['contacts']['tech']:
                    for i in whois['contacts']['tech']:
                        data.append([d, 'contacts', 'tech', i, whois['contacts']['tech'][i]])

                # Iterate contacts -> admin
                if whois['contacts']['admin']:
                    for i in whois['contacts']['admin']:
                        data.append([d, 'contacts', 'admin', i, whois['contacts']['admin'][i]])

                # Nameservers
                if "nameservers" in whois:
                    for i in whois['nameservers']:
                        data.append([d, 'nameservers', '', '', i])

                # Create DF only if data is not empty
                if data:
                    df = pd.DataFrame(data, columns=['domain', 'element', 'type', 'field', 'value'])
                    frames.append(df)

                # Close file
                inputfile.close()
        except:
            print("[ERROR] Couldn't read WHOIS for\t %s" % d)

#read_whois(uniq_subdomains)
read_whois(uniq_roots[:20])
```

    Reading WHOIS for	 altpress.org
    Reading WHOIS for	 nzfortress.co.nz
    Reading WHOIS for	 evillasforsale.com
    Reading WHOIS for	 playingenemy.com
    Reading WHOIS for	 richardsonscharts.com
    Reading WHOIS for	 xenith.net
    Reading WHOIS for	 tdbrecords.com
    Reading WHOIS for	 electrichumanproject.com
    Reading WHOIS for	 tweekerchick.blogspot.com
    Reading WHOIS for	 besound.com
    Reading WHOIS for	 porkchopscreenprinting.com
    Reading WHOIS for	 kinseyvisual.com
    Reading WHOIS for	 rathergood.com
    Reading WHOIS for	 lepoint.fr
    Reading WHOIS for	 revhq.com
    Reading WHOIS for	 poprocksandcoke.com
    Reading WHOIS for	 samuraiblue.com
    Reading WHOIS for	 openbsd.org
    Reading WHOIS for	 sysblog.com
    Reading WHOIS for	 voicesofsafety.com



```
df_whois = pd.concat(frames)
```


```
df_whois.set_index(['domain', 'element', 'type', 'field'])
```




<div style="max-height:1000px;max-width:1500px;overflow:auto;">
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th>value</th>
    </tr>
    <tr>
      <th>domain</th>
      <th>element</th>
      <th>type</th>
      <th>field</th>
      <th></th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th rowspan="22" valign="top">altpress.org</th>
      <th rowspan="20" valign="top">contacts</th>
      <th rowspan="10" valign="top">tech</th>
      <th>city</th>
      <td>                                                            Baltimore</td>
    </tr>
    <tr>
      <th>handle</th>
      <td>                                                        AB10045-GANDI</td>
    </tr>
    <tr>
      <th>name</th>
      <td>                                                           a.h.s. boy</td>
    </tr>
    <tr>
      <th>country</th>
      <td>                                                                   US</td>
    </tr>
    <tr>
      <th>phone</th>
      <td>                                                        +1.4102358565</td>
    </tr>
    <tr>
      <th>state</th>
      <td>                                                                   MD</td>
    </tr>
    <tr>
      <th>street</th>
      <td>                                                   2710 N. Calvert St</td>
    </tr>
    <tr>
      <th>postalcode</th>
      <td>                                                                21218</td>
    </tr>
    <tr>
      <th>organization</th>
      <td>                                                            dada typo</td>
    </tr>
    <tr>
      <th>email</th>
      <td>           29bcde81a3c0e645a9f2a60290ecf2df-1566139@contact.gandi.net</td>
    </tr>
    <tr>
      <th rowspan="10" valign="top">admin</th>
      <th>city</th>
      <td>                                                            Baltimore</td>
    </tr>
    <tr>
      <th>handle</th>
      <td>                                                        AB10045-GANDI</td>
    </tr>
    <tr>
      <th>name</th>
      <td>                                                           a.h.s. boy</td>
    </tr>
    <tr>
      <th>country</th>
      <td>                                                                   US</td>
    </tr>
    <tr>
      <th>phone</th>
      <td>                                                        +1.4102358565</td>
    </tr>
    <tr>
      <th>state</th>
      <td>                                                                   MD</td>
    </tr>
    <tr>
      <th>street</th>
      <td>                                                   2710 N. Calvert St</td>
    </tr>
    <tr>
      <th>postalcode</th>
      <td>                                                                21218</td>
    </tr>
    <tr>
      <th>organization</th>
      <td>                                                            dada typo</td>
    </tr>
    <tr>
      <th>email</th>
      <td>           29bcde81a3c0e645a9f2a60290ecf2df-1566139@contact.gandi.net</td>
    </tr>
    <tr>
      <th rowspan="2" valign="top">nameservers</th>
      <th rowspan="2" valign="top"></th>
      <th></th>
      <td>                                                  DNS.NOTHINGNESS.ORG</td>
    </tr>
    <tr>
      <th></th>
      <td>                                                     DNS.DADATYPO.NET</td>
    </tr>
    <tr>
      <th rowspan="20" valign="top">evillasforsale.com</th>
      <th rowspan="18" valign="top">contacts</th>
      <th rowspan="9" valign="top">tech</th>
      <th>city</th>
      <td>                                                           Manchester</td>
    </tr>
    <tr>
      <th>name</th>
      <td>                                                          Andy Deakin</td>
    </tr>
    <tr>
      <th>country</th>
      <td>                                                                   GB</td>
    </tr>
    <tr>
      <th>phone</th>
      <td>                                                       +44.1616605550</td>
    </tr>
    <tr>
      <th>state</th>
      <td>                                                   Greater Manchester</td>
    </tr>
    <tr>
      <th>street</th>
      <td>                                               66 Grosvenor St Denton</td>
    </tr>
    <tr>
      <th>postalcode</th>
      <td>                                                              M34 3GA</td>
    </tr>
    <tr>
      <th>organization</th>
      <td>                                PCmend.net Computer Solutions Limited</td>
    </tr>
    <tr>
      <th>email</th>
      <td>                                                   domains@pcmend.net</td>
    </tr>
    <tr>
      <th rowspan="9" valign="top">admin</th>
      <th>city</th>
      <td>                                                           Manchester</td>
    </tr>
    <tr>
      <th>name</th>
      <td>                                                          Andy Deakin</td>
    </tr>
    <tr>
      <th>country</th>
      <td>                                                                   GB</td>
    </tr>
    <tr>
      <th>phone</th>
      <td>                                                       +44.1616605550</td>
    </tr>
    <tr>
      <th>state</th>
      <td>                                                   Greater Manchester</td>
    </tr>
    <tr>
      <th>street</th>
      <td>                                               66 Grosvenor St Denton</td>
    </tr>
    <tr>
      <th>postalcode</th>
      <td>                                                              M34 3GA</td>
    </tr>
    <tr>
      <th>organization</th>
      <td>                                PCmend.net Computer Solutions Limited</td>
    </tr>
    <tr>
      <th>email</th>
      <td>                                                   domains@pcmend.net</td>
    </tr>
    <tr>
      <th rowspan="2" valign="top">nameservers</th>
      <th rowspan="2" valign="top"></th>
      <th></th>
      <td>                                                       NS1.PCMEND.NET</td>
    </tr>
    <tr>
      <th></th>
      <td>                                                       NS2.PCMEND.NET</td>
    </tr>
    <tr>
      <th rowspan="2" valign="top">playingenemy.com</th>
      <th rowspan="2" valign="top">nameservers</th>
      <th rowspan="2" valign="top"></th>
      <th></th>
      <td>                                                   ns04.a2z-server.jp</td>
    </tr>
    <tr>
      <th></th>
      <td>                                                  dns04.a2z-server.jp</td>
    </tr>
    <tr>
      <th rowspan="22" valign="top">richardsonscharts.com</th>
      <th rowspan="20" valign="top">contacts</th>
      <th rowspan="10" valign="top">tech</th>
      <th>city</th>
      <td>                                                          New Bedford</td>
    </tr>
    <tr>
      <th>fax</th>
      <td>                                                        +1.5089926604</td>
    </tr>
    <tr>
      <th>name</th>
      <td>                                                 Garrity, Christopher</td>
    </tr>
    <tr>
      <th>country</th>
      <td>                                                                   US</td>
    </tr>
    <tr>
      <th>phone</th>
      <td>                                                        +1.8888396604</td>
    </tr>
    <tr>
      <th>state</th>
      <td>                                                                   MA</td>
    </tr>
    <tr>
      <th>street</th>
      <td>                                           90 Hatch Street, 1st Floor</td>
    </tr>
    <tr>
      <th>postalcode</th>
      <td>                                                                02745</td>
    </tr>
    <tr>
      <th>organization</th>
      <td>                                                                 null</td>
    </tr>
    <tr>
      <th>email</th>
      <td>                                                 cgarrity@maptech.com</td>
    </tr>
    <tr>
      <th rowspan="10" valign="top">admin</th>
      <th>city</th>
      <td>                                                          New Bedford</td>
    </tr>
    <tr>
      <th>fax</th>
      <td>                                                        +1.5089926604</td>
    </tr>
    <tr>
      <th>name</th>
      <td>                                                           Estes, Lee</td>
    </tr>
    <tr>
      <th>country</th>
      <td>                                                                   US</td>
    </tr>
    <tr>
      <th>phone</th>
      <td>                                                        +1.8888396604</td>
    </tr>
    <tr>
      <th>state</th>
      <td>                                                                   MA</td>
    </tr>
    <tr>
      <th>street</th>
      <td>                                           90 Hatch Street, 1st Floor</td>
    </tr>
    <tr>
      <th>postalcode</th>
      <td>                                                                02745</td>
    </tr>
    <tr>
      <th>organization</th>
      <td>                                                                 null</td>
    </tr>
    <tr>
      <th>email</th>
      <td>                                                   richcharts@aol.com</td>
    </tr>
    <tr>
      <th rowspan="2" valign="top">nameservers</th>
      <th rowspan="2" valign="top"></th>
      <th></th>
      <td>                                                   NS2.TERENCENET.NET</td>
    </tr>
    <tr>
      <th></th>
      <td>                                                    NS.TERENCENET.NET</td>
    </tr>
    <tr>
      <th rowspan="22" valign="top">xenith.net</th>
      <th rowspan="20" valign="top">contacts</th>
      <th rowspan="10" valign="top">tech</th>
      <th>city</th>
      <td>                                                         PALM SPRINGS</td>
    </tr>
    <tr>
      <th>fax</th>
      <td>                                                        +1.7603255504</td>
    </tr>
    <tr>
      <th>name</th>
      <td>                                                            DNS Admin</td>
    </tr>
    <tr>
      <th>country</th>
      <td>                                                                   US</td>
    </tr>
    <tr>
      <th>phone</th>
      <td>                                                        +1.7603254755</td>
    </tr>
    <tr>
      <th>state</th>
      <td>                                                                   CA</td>
    </tr>
    <tr>
      <th>street</th>
      <td>                                        1001 S PALM CANYON DR STE 217</td>
    </tr>
    <tr>
      <th>postalcode</th>
      <td>                                                           92264-8349</td>
    </tr>
    <tr>
      <th>organization</th>
      <td>                                                            DNS Admin</td>
    </tr>
    <tr>
      <th>email</th>
      <td>                                                dns@ADVANCEDMINDS.COM</td>
    </tr>
    <tr>
      <th rowspan="10" valign="top">admin</th>
      <th>city</th>
      <td>                                                      San Luis Obispo</td>
    </tr>
    <tr>
      <th>fax</th>
      <td>                                                        +1.7345724470</td>
    </tr>
    <tr>
      <th>name</th>
      <td>                                                        Phelan, Kelly</td>
    </tr>
    <tr>
      <th>country</th>
      <td>                                                                   US</td>
    </tr>
    <tr>
      <th>phone</th>
      <td>                                                        +1.7349456066</td>
    </tr>
    <tr>
      <th>state</th>
      <td>                                                                   CA</td>
    </tr>
    <tr>
      <th>street</th>
      <td>                                                    777 Mill St Apt 6</td>
    </tr>
    <tr>
      <th>postalcode</th>
      <td>                                                                93401</td>
    </tr>
    <tr>
      <th>organization</th>
      <td>                                                                 null</td>
    </tr>
    <tr>
      <th>email</th>
      <td>                                                   centaurus7@AOL.COM</td>
    </tr>
    <tr>
      <th rowspan="2" valign="top">nameservers</th>
      <th rowspan="2" valign="top"></th>
      <th></th>
      <td>                                              NS2.WEST-DATACENTER.NET</td>
    </tr>
    <tr>
      <th></th>
      <td>                                              NS1.WEST-DATACENTER.NET</td>
    </tr>
    <tr>
      <th rowspan="21" valign="top">tdbrecords.com</th>
      <th rowspan="18" valign="top">contacts</th>
      <th rowspan="9" valign="top">tech</th>
      <th>city</th>
      <td>                                                               Boston</td>
    </tr>
    <tr>
      <th>name</th>
      <td>                                                     Jonah Livingston</td>
    </tr>
    <tr>
      <th>country</th>
      <td>                                                        United States</td>
    </tr>
    <tr>
      <th>phone</th>
      <td>                                                           6172308529</td>
    </tr>
    <tr>
      <th>state</th>
      <td>                                                        Massachusetts</td>
    </tr>
    <tr>
      <th>street</th>
      <td>                                                   902 Huntington ave</td>
    </tr>
    <tr>
      <th>postalcode</th>
      <td>                                                                02115</td>
    </tr>
    <tr>
      <th>organization</th>
      <td>                                                          TDB Records</td>
    </tr>
    <tr>
      <th>email</th>
      <td>                                             bloodbathrecords@aol.com</td>
    </tr>
    <tr>
      <th rowspan="9" valign="top">admin</th>
      <th>city</th>
      <td>                                                               Boston</td>
    </tr>
    <tr>
      <th>name</th>
      <td>                                                     Jonah Livingston</td>
    </tr>
    <tr>
      <th>country</th>
      <td>                                                        United States</td>
    </tr>
    <tr>
      <th>phone</th>
      <td>                                                           6172308529</td>
    </tr>
    <tr>
      <th>state</th>
      <td>                                                        Massachusetts</td>
    </tr>
    <tr>
      <th>street</th>
      <td>                                                   902 Huntington ave</td>
    </tr>
    <tr>
      <th>postalcode</th>
      <td>                                                                02115</td>
    </tr>
    <tr>
      <th>organization</th>
      <td>                                                          TDB Records</td>
    </tr>
    <tr>
      <th>email</th>
      <td>                                             bloodbathrecords@aol.com</td>
    </tr>
    <tr>
      <th rowspan="3" valign="top">nameservers</th>
      <th rowspan="3" valign="top"></th>
      <th></th>
      <td>                                                    NS1.DREAMHOST.COM</td>
    </tr>
    <tr>
      <th></th>
      <td>                                                    NS2.DREAMHOST.COM</td>
    </tr>
    <tr>
      <th></th>
      <td>                                                    NS3.DREAMHOST.COM</td>
    </tr>
    <tr>
      <th rowspan="20" valign="top">electrichumanproject.com</th>
      <th rowspan="18" valign="top">contacts</th>
      <th rowspan="9" valign="top">tech</th>
      <th>city</th>
      <td>                                                              Tsukuba</td>
    </tr>
    <tr>
      <th>name</th>
      <td>                                        840Domains Tsukuba 840Domains</td>
    </tr>
    <tr>
      <th>country</th>
      <td>                                                                Japan</td>
    </tr>
    <tr>
      <th>phone</th>
      <td>                                                       +81.5055349763</td>
    </tr>
    <tr>
      <th>state</th>
      <td>                                                              Ibaraki</td>
    </tr>
    <tr>
      <th>street</th>
      <td>                        Baien 2-1-15\nSupuringutekku Tsukuba bld. 401</td>
    </tr>
    <tr>
      <th>postalcode</th>
      <td>                                                             305-0045</td>
    </tr>
    <tr>
      <th>organization</th>
      <td>                                                              Tsukuba</td>
    </tr>
    <tr>
      <th>email</th>
      <td>                                          domain_resister@yahoo.co.jp</td>
    </tr>
    <tr>
      <th rowspan="9" valign="top">admin</th>
      <th>city</th>
      <td>                                                              Tsukuba</td>
    </tr>
    <tr>
      <th>name</th>
      <td>                                        840Domains Tsukuba 840Domains</td>
    </tr>
    <tr>
      <th>country</th>
      <td>                                                                Japan</td>
    </tr>
    <tr>
      <th>phone</th>
      <td>                                                       +81.5055349763</td>
    </tr>
    <tr>
      <th>state</th>
      <td>                                                              Ibaraki</td>
    </tr>
    <tr>
      <th>street</th>
      <td>                        Baien 2-1-15\nSupuringutekku Tsukuba bld. 401</td>
    </tr>
    <tr>
      <th>postalcode</th>
      <td>                                                             305-0045</td>
    </tr>
    <tr>
      <th>organization</th>
      <td>                                                              Tsukuba</td>
    </tr>
    <tr>
      <th>email</th>
      <td>                                          domain_resister@yahoo.co.jp</td>
    </tr>
    <tr>
      <th rowspan="2" valign="top">nameservers</th>
      <th rowspan="2" valign="top"></th>
      <th></th>
      <td>                                             SNS41.WEBSITEWELCOME.COM</td>
    </tr>
    <tr>
      <th></th>
      <td>                                             SNS42.WEBSITEWELCOME.COM</td>
    </tr>
    <tr>
      <th rowspan="21" valign="top">besound.com</th>
      <th rowspan="19" valign="top">contacts</th>
      <th rowspan="9" valign="top">tech</th>
      <th>city</th>
      <td>                                                            San Diego</td>
    </tr>
    <tr>
      <th>fax</th>
      <td>                                                         858-450-0567</td>
    </tr>
    <tr>
      <th>country</th>
      <td>                                                        United States</td>
    </tr>
    <tr>
      <th>phone</th>
      <td>                                                         858-458-0490</td>
    </tr>
    <tr>
      <th>state</th>
      <td>                                                           California</td>
    </tr>
    <tr>
      <th>street</th>
      <td>                                                   5266 Eastgate Mall</td>
    </tr>
    <tr>
      <th>postalcode</th>
      <td>                                                                92121</td>
    </tr>
    <tr>
      <th>organization</th>
      <td>                                                                A+Net</td>
    </tr>
    <tr>
      <th>email</th>
      <td>                                                         dns@abac.com</td>
    </tr>
    <tr>
      <th rowspan="10" valign="top">admin</th>
      <th>city</th>
      <td>                                                          LINDENHURST</td>
    </tr>
    <tr>
      <th>fax</th>
      <td>                                                         999 999 9999</td>
    </tr>
    <tr>
      <th>name</th>
      <td>                                                        Richard Lopez</td>
    </tr>
    <tr>
      <th>country</th>
      <td>                                                        United States</td>
    </tr>
    <tr>
      <th>phone</th>
      <td>                                                       (516) 226-8430</td>
    </tr>
    <tr>
      <th>state</th>
      <td>                                                             New York</td>
    </tr>
    <tr>
      <th>street</th>
      <td>                                                          180 34TH ST</td>
    </tr>
    <tr>
      <th>postalcode</th>
      <td>                                                           11757-3243</td>
    </tr>
    <tr>
      <th>organization</th>
      <td>                                                   BeSound Multimedia</td>
    </tr>
    <tr>
      <th>email</th>
      <td>                                                besound@optonline.net</td>
    </tr>
    <tr>
      <th rowspan="2" valign="top">nameservers</th>
      <th rowspan="2" valign="top"></th>
      <th></th>
      <td>                                              BDNS.CV.SITEPROTECT.COM</td>
    </tr>
    <tr>
      <th></th>
      <td>                                              ADNS.CV.SITEPROTECT.COM</td>
    </tr>
    <tr>
      <th rowspan="18" valign="top">porkchopscreenprinting.com</th>
      <th rowspan="16" valign="top">contacts</th>
      <th rowspan="8" valign="top">tech</th>
      <th>city</th>
      <td>                                                             New York</td>
    </tr>
    <tr>
      <th>name</th>
      <td>                                                     Domain Registrar</td>
    </tr>
    <tr>
      <th>country</th>
      <td>                                                                   US</td>
    </tr>
    <tr>
      <th>phone</th>
      <td>                                                        +1.9027492701</td>
    </tr>
    <tr>
      <th>state</th>
      <td>                                                                   NY</td>
    </tr>
    <tr>
      <th>street</th>
      <td>                                            575 8th Avenue 11th Floor</td>
    </tr>
    <tr>
      <th>postalcode</th>
      <td>                                                                10018</td>
    </tr>
    <tr>
      <th>organization</th>
      <td>                                                         Register.Com</td>
    </tr>
    <tr>
      <th rowspan="8" valign="top">admin</th>
      <th>city</th>
      <td>                                                              Seattle</td>
    </tr>
    <tr>
      <th>name</th>
      <td>                                                        Damon Baldwin</td>
    </tr>
    <tr>
      <th>country</th>
      <td>                                                                   US</td>
    </tr>
    <tr>
      <th>phone</th>
      <td>                                                        +1.2067064764</td>
    </tr>
    <tr>
      <th>state</th>
      <td>                                                                   WA</td>
    </tr>
    <tr>
      <th>street</th>
      <td>                                                      9218 9th ave NW</td>
    </tr>
    <tr>
      <th>postalcode</th>
      <td>                                                                98117</td>
    </tr>
    <tr>
      <th>organization</th>
      <td>                                            Pork Chop Screen Printing</td>
    </tr>
    <tr>
      <th rowspan="2" valign="top">nameservers</th>
      <th rowspan="2" valign="top"></th>
      <th></th>
      <td>                                            ns1.hosting-advantage.com</td>
    </tr>
    <tr>
      <th></th>
      <td>                                            ns2.hosting-advantage.com</td>
    </tr>
    <tr>
      <th rowspan="22" valign="top">kinseyvisual.com</th>
      <th rowspan="20" valign="top">contacts</th>
      <th rowspan="10" valign="top">tech</th>
      <th>city</th>
      <td>                                                          Culver City</td>
    </tr>
    <tr>
      <th>fax</th>
      <td>                                                        +1.8186498230</td>
    </tr>
    <tr>
      <th>name</th>
      <td>                                                ADMINISTRATOR, DOMAIN</td>
    </tr>
    <tr>
      <th>country</th>
      <td>                                                                   US</td>
    </tr>
    <tr>
      <th>phone</th>
      <td>                                                        +1.8775784000</td>
    </tr>
    <tr>
      <th>state</th>
      <td>                                                                   CA</td>
    </tr>
    <tr>
      <th>street</th>
      <td>                                               8520 National Blvd. #A</td>
    </tr>
    <tr>
      <th>postalcode</th>
      <td>                                                                90232</td>
    </tr>
    <tr>
      <th>organization</th>
      <td>                                                         Media Temple</td>
    </tr>
    <tr>
      <th>email</th>
      <td>                                             dnsadmin@MEDIATEMPLE.NET</td>
    </tr>
    <tr>
      <th rowspan="10" valign="top">admin</th>
      <th>city</th>
      <td>                                                            SAN DIEGO</td>
    </tr>
    <tr>
      <th>fax</th>
      <td>                                                        +1.6195449594</td>
    </tr>
    <tr>
      <th>name</th>
      <td>                                                         Kinsey, Dave</td>
    </tr>
    <tr>
      <th>country</th>
      <td>                                                                   US</td>
    </tr>
    <tr>
      <th>phone</th>
      <td>                                                        +1.6195449595</td>
    </tr>
    <tr>
      <th>state</th>
      <td>                                                                   CA</td>
    </tr>
    <tr>
      <th>street</th>
      <td>                                                         705 12TH AVE</td>
    </tr>
    <tr>
      <th>postalcode</th>
      <td>                                                           92101-6507</td>
    </tr>
    <tr>
      <th>organization</th>
      <td>                                                         BlkMkrt Inc.</td>
    </tr>
    <tr>
      <th>email</th>
      <td>                                                     dave@BLKMRKT.COM</td>
    </tr>
    <tr>
      <th rowspan="2" valign="top">nameservers</th>
      <th rowspan="2" valign="top"></th>
      <th></th>
      <td>                                                  NS1.MEDIATEMPLE.NET</td>
    </tr>
    <tr>
      <th></th>
      <td>                                                  NS2.MEDIATEMPLE.NET</td>
    </tr>
    <tr>
      <th rowspan="23" valign="top">rathergood.com</th>
      <th rowspan="20" valign="top">contacts</th>
      <th rowspan="10" valign="top">tech</th>
      <th>city</th>
      <td>                                                               London</td>
    </tr>
    <tr>
      <th>fax</th>
      <td>                                                        +1.9999999999</td>
    </tr>
    <tr>
      <th>name</th>
      <td>                                                         Veitch, Joel</td>
    </tr>
    <tr>
      <th>country</th>
      <td>                                                                   UK</td>
    </tr>
    <tr>
      <th>phone</th>
      <td>                                                       +1.08072547734</td>
    </tr>
    <tr>
      <th>state</th>
      <td>                                                                 null</td>
    </tr>
    <tr>
      <th>street</th>
      <td>                                                    10 Croston Street</td>
    </tr>
    <tr>
      <th>postalcode</th>
      <td>                                                                 null</td>
    </tr>
    <tr>
      <th>organization</th>
      <td>                                                                 null</td>
    </tr>
    <tr>
      <th>email</th>
      <td>                                                  joel@rathergood.com</td>
    </tr>
    <tr>
      <th rowspan="10" valign="top">admin</th>
      <th>city</th>
      <td>                                                               London</td>
    </tr>
    <tr>
      <th>fax</th>
      <td>                                                        +1.9999999999</td>
    </tr>
    <tr>
      <th>name</th>
      <td>                                                         Veitch, Joel</td>
    </tr>
    <tr>
      <th>country</th>
      <td>                                                                   UK</td>
    </tr>
    <tr>
      <th>phone</th>
      <td>                                                       +1.08072547734</td>
    </tr>
    <tr>
      <th>state</th>
      <td>                                                                 null</td>
    </tr>
    <tr>
      <th>street</th>
      <td>                                                    10 Croston Street</td>
    </tr>
    <tr>
      <th>postalcode</th>
      <td>                                                                 null</td>
    </tr>
    <tr>
      <th>organization</th>
      <td>                                                                 null</td>
    </tr>
    <tr>
      <th>email</th>
      <td>                                                  joel@rathergood.com</td>
    </tr>
    <tr>
      <th rowspan="3" valign="top">nameservers</th>
      <th rowspan="3" valign="top"></th>
      <th></th>
      <td>                                                    NS1.DREAMHOST.COM</td>
    </tr>
    <tr>
      <th></th>
      <td>                                                    NS3.DREAMHOST.COM</td>
    </tr>
    <tr>
      <th></th>
      <td>                                                    NS2.DREAMHOST.COM</td>
    </tr>
    <tr>
      <th rowspan="22" valign="top">lepoint.fr</th>
      <th rowspan="19" valign="top">contacts</th>
      <th rowspan="9" valign="top">tech</th>
      <th>city</th>
      <td>                                                                Paris</td>
    </tr>
    <tr>
      <th>handle</th>
      <td>                                                          GR283-FRNIC</td>
    </tr>
    <tr>
      <th>name</th>
      <td>                                                           GANDI ROLE</td>
    </tr>
    <tr>
      <th>country</th>
      <td>                                                                   FR</td>
    </tr>
    <tr>
      <th>street</th>
      <td>                                        Gandi\n15, place de la Nation</td>
    </tr>
    <tr>
      <th>postalcode</th>
      <td>                                                                75011</td>
    </tr>
    <tr>
      <th>type</th>
      <td>                                                                 ROLE</td>
    </tr>
    <tr>
      <th>email</th>
      <td>                                                        noc@gandi.net</td>
    </tr>
    <tr>
      <th>changedate</th>
      <td>                                                  2006-03-03T00:00:00</td>
    </tr>
    <tr>
      <th rowspan="10" valign="top">admin</th>
      <th>city</th>
      <td>                                                                Paris</td>
    </tr>
    <tr>
      <th>handle</th>
      <td>                                                        SDED175-FRNIC</td>
    </tr>
    <tr>
      <th>name</th>
      <td>                    SOCIETE D'EXPLOITATION DE L'HEBDOMADAIRE LE POINT</td>
    </tr>
    <tr>
      <th>country</th>
      <td>                                                                   FR</td>
    </tr>
    <tr>
      <th>phone</th>
      <td>                                                    +33 1 44 10 10 10</td>
    </tr>
    <tr>
      <th>street</th>
      <td>                                                  74, avenue du maine</td>
    </tr>
    <tr>
      <th>postalcode</th>
      <td>                                                                75014</td>
    </tr>
    <tr>
      <th>type</th>
      <td>                                                         ORGANIZATION</td>
    </tr>
    <tr>
      <th>email</th>
      <td>            b396c2138803c796a2cc37d347a1797c-857941@contact.gandi.net</td>
    </tr>
    <tr>
      <th>changedate</th>
      <td>                                                  2013-07-10T00:00:00</td>
    </tr>
    <tr>
      <th rowspan="3" valign="top">nameservers</th>
      <th rowspan="3" valign="top"></th>
      <th></th>
      <td>                                                      b.dns.gandi.net</td>
    </tr>
    <tr>
      <th></th>
      <td>                                                      a.dns.gandi.net</td>
    </tr>
    <tr>
      <th></th>
      <td>                                                      c.dns.gandi.net</td>
    </tr>
    <tr>
      <th rowspan="24" valign="top">revhq.com</th>
      <th rowspan="20" valign="top">contacts</th>
      <th rowspan="10" valign="top">tech</th>
      <th>city</th>
      <td>                                                     HUNTINGTON BEACH</td>
    </tr>
    <tr>
      <th>fax</th>
      <td>                                                        +1.5555555555</td>
    </tr>
    <tr>
      <th>name</th>
      <td>                                                        JORDAN COOPER</td>
    </tr>
    <tr>
      <th>country</th>
      <td>                                                                   US</td>
    </tr>
    <tr>
      <th>phone</th>
      <td>                                                        +1.7148427584</td>
    </tr>
    <tr>
      <th>state</th>
      <td>                                                                   CA</td>
    </tr>
    <tr>
      <th>street</th>
      <td>                                                        P.O. BOX 5232</td>
    </tr>
    <tr>
      <th>postalcode</th>
      <td>                                                                92615</td>
    </tr>
    <tr>
      <th>organization</th>
      <td>                                                     REV DISTRIBUTION</td>
    </tr>
    <tr>
      <th>email</th>
      <td>                                                    JCOOPER@REVHQ.COM</td>
    </tr>
    <tr>
      <th rowspan="10" valign="top">admin</th>
      <th>city</th>
      <td>                                                     HUNTINGTON BEACH</td>
    </tr>
    <tr>
      <th>fax</th>
      <td>                                                        +1.5555555555</td>
    </tr>
    <tr>
      <th>name</th>
      <td>                                                        JORDAN COOPER</td>
    </tr>
    <tr>
      <th>country</th>
      <td>                                                                   US</td>
    </tr>
    <tr>
      <th>phone</th>
      <td>                                                        +1.7148427584</td>
    </tr>
    <tr>
      <th>state</th>
      <td>                                                                   CA</td>
    </tr>
    <tr>
      <th>street</th>
      <td>                                                        P.O. BOX 5232</td>
    </tr>
    <tr>
      <th>postalcode</th>
      <td>                                                                92615</td>
    </tr>
    <tr>
      <th>organization</th>
      <td>                                                     REV DISTRIBUTION</td>
    </tr>
    <tr>
      <th>email</th>
      <td>                                                    JCOOPER@REVHQ.COM</td>
    </tr>
    <tr>
      <th rowspan="4" valign="top">nameservers</th>
      <th rowspan="4" valign="top"></th>
      <th></th>
      <td>                                                      NS1.CLOUDNS.NET</td>
    </tr>
    <tr>
      <th></th>
      <td>                                                      NS2.CLOUDNS.NET</td>
    </tr>
    <tr>
      <th></th>
      <td>                                                      NS3.CLOUDNS.NET</td>
    </tr>
    <tr>
      <th></th>
      <td>                                                      NS4.CLOUDNS.NET</td>
    </tr>
    <tr>
      <th rowspan="18" valign="top">poprocksandcoke.com</th>
      <th rowspan="16" valign="top">contacts</th>
      <th rowspan="8" valign="top">tech</th>
      <th>city</th>
      <td>                                                            Ljubljana</td>
    </tr>
    <tr>
      <th>name</th>
      <td>                                                         Matija Zajec</td>
    </tr>
    <tr>
      <th>country</th>
      <td>                                                             Slovenia</td>
    </tr>
    <tr>
      <th>phone</th>
      <td>                                                        +386.30363699</td>
    </tr>
    <tr>
      <th>state</th>
      <td>                                                    Osrednjeslovenska</td>
    </tr>
    <tr>
      <th>street</th>
      <td>                                                  Krizevniska ulica 7</td>
    </tr>
    <tr>
      <th>postalcode</th>
      <td>                                                                 1000</td>
    </tr>
    <tr>
      <th>email</th>
      <td>                                                     kukmak@gmail.com</td>
    </tr>
    <tr>
      <th rowspan="8" valign="top">admin</th>
      <th>city</th>
      <td>                                                            Ljubljana</td>
    </tr>
    <tr>
      <th>name</th>
      <td>                                                         Matija Zajec</td>
    </tr>
    <tr>
      <th>country</th>
      <td>                                                             Slovenia</td>
    </tr>
    <tr>
      <th>phone</th>
      <td>                                                        +386.30363699</td>
    </tr>
    <tr>
      <th>state</th>
      <td>                                                    Osrednjeslovenska</td>
    </tr>
    <tr>
      <th>street</th>
      <td>                                                  Krizevniska ulica 7</td>
    </tr>
    <tr>
      <th>postalcode</th>
      <td>                                                                 1000</td>
    </tr>
    <tr>
      <th>email</th>
      <td>                                                     kukmak@gmail.com</td>
    </tr>
    <tr>
      <th rowspan="2" valign="top">nameservers</th>
      <th rowspan="2" valign="top"></th>
      <th></th>
      <td>                                                        NS3.WEBDNS.PW</td>
    </tr>
    <tr>
      <th></th>
      <td>                                                        NS4.WEBDNS.PW</td>
    </tr>
    <tr>
      <th rowspan="22" valign="top">samuraiblue.com</th>
      <th rowspan="20" valign="top">contacts</th>
      <th rowspan="10" valign="top">tech</th>
      <th>city</th>
      <td>                                                           Louisville</td>
    </tr>
    <tr>
      <th>fax</th>
      <td>                                                        +1.5025692774</td>
    </tr>
    <tr>
      <th>name</th>
      <td>                                                      MaximumASP, LLC</td>
    </tr>
    <tr>
      <th>country</th>
      <td>                                                                   US</td>
    </tr>
    <tr>
      <th>phone</th>
      <td>                                                        +1.5025692771</td>
    </tr>
    <tr>
      <th>state</th>
      <td>                                                                   KY</td>
    </tr>
    <tr>
      <th>street</th>
      <td>                                                    540 Baxter Avenue</td>
    </tr>
    <tr>
      <th>postalcode</th>
      <td>                                                                40204</td>
    </tr>
    <tr>
      <th>organization</th>
      <td>                                                      MaximumASP, LLC</td>
    </tr>
    <tr>
      <th>email</th>
      <td>                                                   noc@maximumasp.com</td>
    </tr>
    <tr>
      <th rowspan="10" valign="top">admin</th>
      <th>city</th>
      <td>                                                                Tampa</td>
    </tr>
    <tr>
      <th>fax</th>
      <td>                                                        +1.9999999999</td>
    </tr>
    <tr>
      <th>name</th>
      <td>                                                         Meronek, Rob</td>
    </tr>
    <tr>
      <th>country</th>
      <td>                                                                   US</td>
    </tr>
    <tr>
      <th>phone</th>
      <td>                                                         +1.838575819</td>
    </tr>
    <tr>
      <th>state</th>
      <td>                                                                   FL</td>
    </tr>
    <tr>
      <th>street</th>
      <td>                                         777 North Ashley Drive #1212</td>
    </tr>
    <tr>
      <th>postalcode</th>
      <td>                                                                33602</td>
    </tr>
    <tr>
      <th>organization</th>
      <td>                                                           The Boardr</td>
    </tr>
    <tr>
      <th>email</th>
      <td>                                                      rob@meronek.com</td>
    </tr>
    <tr>
      <th rowspan="2" valign="top">nameservers</th>
      <th rowspan="2" valign="top"></th>
      <th></th>
      <td>                                                    DNS1.MIDPHASE.COM</td>
    </tr>
    <tr>
      <th></th>
      <td>                                                    DNS2.MIDPHASE.COM</td>
    </tr>
    <tr>
      <th rowspan="27" valign="top">openbsd.org</th>
      <th rowspan="20" valign="top">contacts</th>
      <th rowspan="10" valign="top">tech</th>
      <th>city</th>
      <td>                                                      Calgary Alberta</td>
    </tr>
    <tr>
      <th>handle</th>
      <td>                                                           CR32086106</td>
    </tr>
    <tr>
      <th>name</th>
      <td>                                                       Theos Software</td>
    </tr>
    <tr>
      <th>country</th>
      <td>                                                                   CA</td>
    </tr>
    <tr>
      <th>phone</th>
      <td>                                                          +1.40323798</td>
    </tr>
    <tr>
      <th>state</th>
      <td>                                                              Alberta</td>
    </tr>
    <tr>
      <th>street</th>
      <td>                                                      812 23rd ave SE</td>
    </tr>
    <tr>
      <th>postalcode</th>
      <td>                                                              T2G 1N8</td>
    </tr>
    <tr>
      <th>organization</th>
      <td>                                                       Theos Software</td>
    </tr>
    <tr>
      <th>email</th>
      <td>                                                    deraadt@theos.com</td>
    </tr>
    <tr>
      <th rowspan="10" valign="top">admin</th>
      <th>city</th>
      <td>                                                              Calgary</td>
    </tr>
    <tr>
      <th>handle</th>
      <td>                                                           CR32086107</td>
    </tr>
    <tr>
      <th>name</th>
      <td>                                                        Theo de Raadt</td>
    </tr>
    <tr>
      <th>country</th>
      <td>                                                                   CA</td>
    </tr>
    <tr>
      <th>phone</th>
      <td>                                                        +1.4032379834</td>
    </tr>
    <tr>
      <th>state</th>
      <td>                                                              Alberta</td>
    </tr>
    <tr>
      <th>street</th>
      <td>                                                      812 23rd Ave SE</td>
    </tr>
    <tr>
      <th>postalcode</th>
      <td>                                                               T2G1N8</td>
    </tr>
    <tr>
      <th>organization</th>
      <td>                                                       Theos Software</td>
    </tr>
    <tr>
      <th>email</th>
      <td>                                                    deraadt@theos.com</td>
    </tr>
    <tr>
      <th rowspan="7" valign="top">nameservers</th>
      <th rowspan="7" valign="top"></th>
      <th></th>
      <td>                                                      NS1.TELSTRA.NET</td>
    </tr>
    <tr>
      <th></th>
      <td>                                                     NS.SIGMASOFT.COM</td>
    </tr>
    <tr>
      <th></th>
      <td>                                                   NS1.SUPERBLOCK.NET</td>
    </tr>
    <tr>
      <th></th>
      <td>                                                   NS2.SUPERBLOCK.NET</td>
    </tr>
    <tr>
      <th></th>
      <td>                                                       ZEUS.THEOS.COM</td>
    </tr>
    <tr>
      <th></th>
      <td>                                                         C.NS.BSWS.DE</td>
    </tr>
    <tr>
      <th></th>
      <td>                                                         A.NS.BSWS.DE</td>
    </tr>
    <tr>
      <th rowspan="22" valign="top">sysblog.com</th>
      <th rowspan="20" valign="top">contacts</th>
      <th rowspan="10" valign="top">tech</th>
      <th>city</th>
      <td>                                                              Waltham</td>
    </tr>
    <tr>
      <th>fax</th>
      <td>                                                        +1.7818392801</td>
    </tr>
    <tr>
      <th>name</th>
      <td> Toll Free: 866-822-9073 Worldwide: 339-222-5132 This Domain For Sale</td>
    </tr>
    <tr>
      <th>country</th>
      <td>                                                                   US</td>
    </tr>
    <tr>
      <th>phone</th>
      <td>                                                        +1.8668229073</td>
    </tr>
    <tr>
      <th>state</th>
      <td>                                                                   MA</td>
    </tr>
    <tr>
      <th>street</th>
      <td>                                                 738 Main Street #389</td>
    </tr>
    <tr>
      <th>postalcode</th>
      <td>                                                                02451</td>
    </tr>
    <tr>
      <th>organization</th>
      <td>                                                       BuyDomains.com</td>
    </tr>
    <tr>
      <th>email</th>
      <td>                                             brokerage@buydomains.com</td>
    </tr>
    <tr>
      <th rowspan="10" valign="top">admin</th>
      <th>city</th>
      <td>                                                              Waltham</td>
    </tr>
    <tr>
      <th>fax</th>
      <td>                                                        +1.7818392801</td>
    </tr>
    <tr>
      <th>name</th>
      <td> Toll Free: 866-822-9073 Worldwide: 339-222-5132 This Domain For Sale</td>
    </tr>
    <tr>
      <th>country</th>
      <td>                                                                   US</td>
    </tr>
    <tr>
      <th>phone</th>
      <td>                                                        +1.8668229073</td>
    </tr>
    <tr>
      <th>state</th>
      <td>                                                                   MA</td>
    </tr>
    <tr>
      <th>street</th>
      <td>                                                 738 Main Street #389</td>
    </tr>
    <tr>
      <th>postalcode</th>
      <td>                                                                02451</td>
    </tr>
    <tr>
      <th>organization</th>
      <td>                                                       BuyDomains.com</td>
    </tr>
    <tr>
      <th>email</th>
      <td>                                             brokerage@buydomains.com</td>
    </tr>
    <tr>
      <th rowspan="2" valign="top">nameservers</th>
      <th rowspan="2" valign="top"></th>
      <th></th>
      <td>                                                    NS.BUYDOMAINS.COM</td>
    </tr>
    <tr>
      <th></th>
      <td>                                             THIS-DOMAIN-FOR-SALE.COM</td>
    </tr>
    <tr>
      <th rowspan="22" valign="top">voicesofsafety.com</th>
      <th rowspan="20" valign="top">contacts</th>
      <th rowspan="10" valign="top">tech</th>
      <th>city</th>
      <td>                                                           Burlington</td>
    </tr>
    <tr>
      <th>fax</th>
      <td>                                                         +1.782722915</td>
    </tr>
    <tr>
      <th>name</th>
      <td>                                                    BizLand.com, Inc.</td>
    </tr>
    <tr>
      <th>country</th>
      <td>                                                                   US</td>
    </tr>
    <tr>
      <th>phone</th>
      <td>                                                         +1.782725585</td>
    </tr>
    <tr>
      <th>state</th>
      <td>                                                                   MA</td>
    </tr>
    <tr>
      <th>street</th>
      <td>                                               121 Middlesex Turnpike</td>
    </tr>
    <tr>
      <th>postalcode</th>
      <td>                                                                01803</td>
    </tr>
    <tr>
      <th>organization</th>
      <td>                                                    BizLand.com, Inc.</td>
    </tr>
    <tr>
      <th>email</th>
      <td>                                               DomReg@BIZLAND-INC.COM</td>
    </tr>
    <tr>
      <th rowspan="10" valign="top">admin</th>
      <th>city</th>
      <td>                                                      NORTHE COLDWELL</td>
    </tr>
    <tr>
      <th>fax</th>
      <td>                                                        +1.9732280276</td>
    </tr>
    <tr>
      <th>name</th>
      <td>                                                  VOICESOFSAFTY INT'L</td>
    </tr>
    <tr>
      <th>country</th>
      <td>                                                                   US</td>
    </tr>
    <tr>
      <th>phone</th>
      <td>                                                        +1.9732282258</td>
    </tr>
    <tr>
      <th>state</th>
      <td>                                                                   NJ</td>
    </tr>
    <tr>
      <th>street</th>
      <td>                                                         264 park ave</td>
    </tr>
    <tr>
      <th>postalcode</th>
      <td>                                                                07006</td>
    </tr>
    <tr>
      <th>organization</th>
      <td>                                                  VOICESOFSAFTY INT'L</td>
    </tr>
    <tr>
      <th>email</th>
      <td>                                         webmaster@voicesofsafety.com</td>
    </tr>
    <tr>
      <th rowspan="2" valign="top">nameservers</th>
      <th rowspan="2" valign="top"></th>
      <th></th>
      <td>                                              CLICKME2.CLICK2SITE.COM</td>
    </tr>
    <tr>
      <th></th>
      <td>                                               CLICKME.CLICK2SITE.COM</td>
    </tr>
  </tbody>
</table>
</div>



## Read DNS information 

Do the same with the DNS files... 


```
# <!-- collapse=True -->
from pprint import pprint
import re
import traceback

# Global DF frames
frames = []

def read_dns(domains):
    for d in domains:
        print("Reading WHOIS for\t %s" % d)
        data = []
        try:
            with open('DNS/%s.txt' % d, 'r') as inputfile:
                dns = inputfile.read()
                
                for l in dns.splitlines():
                    records = l.split()
                    
                    # Check only for NS, MX, A, CNAME, TXT
                    a = re.compile("^(NS|MX|A|CNAME|TXT)$")
                    if len(records) >= 4:
                        if a.match(records[3]):
                            data.append([d, records[3], records[4]])
                
                # Create DF only if data is not empty
                if data:
                    df = pd.DataFrame(data, columns=['domain', 'dns_record', 'value'])
                    frames.append(df)      
                    
                # Close file
                inputfile.close()
                
        except Exception, err:
            print("[ERROR] Couldn't read WHOIS for\t %s" % d)
            traceback.print_exc()

#read_dns(uniq_subdomains)            
read_dns(uniq_roots[:20])
```

    Reading WHOIS for	 altpress.org
    Reading WHOIS for	 nzfortress.co.nz
    Reading WHOIS for	 evillasforsale.com
    Reading WHOIS for	 playingenemy.com
    Reading WHOIS for	 richardsonscharts.com
    Reading WHOIS for	 xenith.net
    Reading WHOIS for	 tdbrecords.com
    Reading WHOIS for	 electrichumanproject.com
    Reading WHOIS for	 tweekerchick.blogspot.com
    Reading WHOIS for	 besound.com
    Reading WHOIS for	 porkchopscreenprinting.com
    Reading WHOIS for	 kinseyvisual.com
    Reading WHOIS for	 rathergood.com
    Reading WHOIS for	 lepoint.fr
    Reading WHOIS for	 revhq.com
    Reading WHOIS for	 poprocksandcoke.com
    Reading WHOIS for	 samuraiblue.com
    Reading WHOIS for	 openbsd.org
    Reading WHOIS for	 sysblog.com
    Reading WHOIS for	 voicesofsafety.com



```
df_dns = pd.concat(frames)
```


```
df_dns.set_index(['domain', 'dns_record'])
```




<div style="max-height:1000px;max-width:1500px;overflow:auto;">
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th></th>
      <th>value</th>
    </tr>
    <tr>
      <th>domain</th>
      <th>dns_record</th>
      <th></th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th rowspan="2" valign="top">altpress.org</th>
      <th>NS</th>
      <td>                 dns.dadatypo.net.</td>
    </tr>
    <tr>
      <th>NS</th>
      <td>              dns.nothingness.org.</td>
    </tr>
    <tr>
      <th rowspan="4" valign="top">nzfortress.co.nz</th>
      <th>NS</th>
      <td>          ns-1637.awsdns-12.co.uk.</td>
    </tr>
    <tr>
      <th>NS</th>
      <td>             ns-913.awsdns-50.net.</td>
    </tr>
    <tr>
      <th>NS</th>
      <td>             ns-203.awsdns-25.com.</td>
    </tr>
    <tr>
      <th>NS</th>
      <td>            ns-1284.awsdns-32.org.</td>
    </tr>
    <tr>
      <th rowspan="2" valign="top">evillasforsale.com</th>
      <th>NS</th>
      <td>                   ns2.pcmend.net.</td>
    </tr>
    <tr>
      <th>NS</th>
      <td>                   ns1.pcmend.net.</td>
    </tr>
    <tr>
      <th rowspan="2" valign="top">playingenemy.com</th>
      <th>NS</th>
      <td>              dns04.a2z-server.jp.</td>
    </tr>
    <tr>
      <th>NS</th>
      <td>               ns04.a2z-server.jp.</td>
    </tr>
    <tr>
      <th rowspan="8" valign="top">richardsonscharts.com</th>
      <th>NS</th>
      <td>               ns2.interbasix.net.</td>
    </tr>
    <tr>
      <th>A</th>
      <td>                     207.97.239.35</td>
    </tr>
    <tr>
      <th>MX</th>
      <td>                                10</td>
    </tr>
    <tr>
      <th>TXT</th>
      <td>                           "v=spf1</td>
    </tr>
    <tr>
      <th>NS</th>
      <td>                ns.interbasix.net.</td>
    </tr>
    <tr>
      <th>MX</th>
      <td>                                30</td>
    </tr>
    <tr>
      <th>MX</th>
      <td>                                40</td>
    </tr>
    <tr>
      <th>MX</th>
      <td>                                20</td>
    </tr>
    <tr>
      <th rowspan="4" valign="top">xenith.net</th>
      <th>NS</th>
      <td>          ns1.west-datacenter.net.</td>
    </tr>
    <tr>
      <th>NS</th>
      <td>          ns2.west-datacenter.net.</td>
    </tr>
    <tr>
      <th>A</th>
      <td>                    206.130.121.98</td>
    </tr>
    <tr>
      <th>MX</th>
      <td>                                10</td>
    </tr>
    <tr>
      <th rowspan="6" valign="top">tdbrecords.com</th>
      <th>NS</th>
      <td>                ns2.dreamhost.com.</td>
    </tr>
    <tr>
      <th>NS</th>
      <td>                ns1.dreamhost.com.</td>
    </tr>
    <tr>
      <th>MX</th>
      <td>                                 0</td>
    </tr>
    <tr>
      <th>NS</th>
      <td>                ns3.dreamhost.com.</td>
    </tr>
    <tr>
      <th>MX</th>
      <td>                                 0</td>
    </tr>
    <tr>
      <th>A</th>
      <td>                     75.119.220.89</td>
    </tr>
    <tr>
      <th rowspan="3" valign="top">electrichumanproject.com</th>
      <th>NS</th>
      <td>         sns41.websitewelcome.com.</td>
    </tr>
    <tr>
      <th>NS</th>
      <td>         sns42.websitewelcome.com.</td>
    </tr>
    <tr>
      <th>A</th>
      <td>                       67.18.68.14</td>
    </tr>
    <tr>
      <th rowspan="4" valign="top">tweekerchick.blogspot.com</th>
      <th>CNAME</th>
      <td> blogspot.l.googleusercontent.com.</td>
    </tr>
    <tr>
      <th>A</th>
      <td>                     173.194.44.10</td>
    </tr>
    <tr>
      <th>A</th>
      <td>                     173.194.44.12</td>
    </tr>
    <tr>
      <th>A</th>
      <td>                     173.194.44.11</td>
    </tr>
    <tr>
      <th rowspan="2" valign="top">besound.com</th>
      <th>NS</th>
      <td>          bdns.cv.siteprotect.com.</td>
    </tr>
    <tr>
      <th>NS</th>
      <td>          adns.cv.siteprotect.com.</td>
    </tr>
    <tr>
      <th rowspan="4" valign="top">porkchopscreenprinting.com</th>
      <th>NS</th>
      <td>        ns1.hosting-advantage.com.</td>
    </tr>
    <tr>
      <th>NS</th>
      <td>        ns2.hosting-advantage.com.</td>
    </tr>
    <tr>
      <th>A</th>
      <td>                      64.92.121.42</td>
    </tr>
    <tr>
      <th>MX</th>
      <td>                                 5</td>
    </tr>
    <tr>
      <th rowspan="4" valign="top">kinseyvisual.com</th>
      <th>A</th>
      <td>                   205.186.183.161</td>
    </tr>
    <tr>
      <th>NS</th>
      <td>              ns1.mediatemple.net.</td>
    </tr>
    <tr>
      <th>MX</th>
      <td>                                10</td>
    </tr>
    <tr>
      <th>NS</th>
      <td>              ns2.mediatemple.net.</td>
    </tr>
    <tr>
      <th rowspan="6" valign="top">rathergood.com</th>
      <th>MX</th>
      <td>                                 0</td>
    </tr>
    <tr>
      <th>NS</th>
      <td>                ns2.dreamhost.com.</td>
    </tr>
    <tr>
      <th>NS</th>
      <td>                ns1.dreamhost.com.</td>
    </tr>
    <tr>
      <th>MX</th>
      <td>                                 0</td>
    </tr>
    <tr>
      <th>NS</th>
      <td>                ns3.dreamhost.com.</td>
    </tr>
    <tr>
      <th>A</th>
      <td>                      64.90.57.150</td>
    </tr>
    <tr>
      <th rowspan="3" valign="top">lepoint.fr</th>
      <th>NS</th>
      <td>                  c.dns.gandi.net.</td>
    </tr>
    <tr>
      <th>NS</th>
      <td>                  b.dns.gandi.net.</td>
    </tr>
    <tr>
      <th>NS</th>
      <td>                  a.dns.gandi.net.</td>
    </tr>
    <tr>
      <th rowspan="4" valign="top">revhq.com</th>
      <th>NS</th>
      <td>                  ns1.cloudns.net.</td>
    </tr>
    <tr>
      <th>NS</th>
      <td>                  ns4.cloudns.net.</td>
    </tr>
    <tr>
      <th>NS</th>
      <td>                  ns3.cloudns.net.</td>
    </tr>
    <tr>
      <th>NS</th>
      <td>                  ns2.cloudns.net.</td>
    </tr>
    <tr>
      <th rowspan="4" valign="top">poprocksandcoke.com</th>
      <th>A</th>
      <td>                   184.164.147.132</td>
    </tr>
    <tr>
      <th>MX</th>
      <td>                                 0</td>
    </tr>
    <tr>
      <th>NS</th>
      <td>                    ns3.webdns.pw.</td>
    </tr>
    <tr>
      <th>NS</th>
      <td>                    ns4.webdns.pw.</td>
    </tr>
    <tr>
      <th rowspan="5" valign="top">samuraiblue.com</th>
      <th>NS</th>
      <td>               dns1.anhosting.com.</td>
    </tr>
    <tr>
      <th>NS</th>
      <td>               dns2.anhosting.com.</td>
    </tr>
    <tr>
      <th>MX</th>
      <td>                                 0</td>
    </tr>
    <tr>
      <th>TXT</th>
      <td>                           "v=spf1</td>
    </tr>
    <tr>
      <th>A</th>
      <td>                   174.127.110.249</td>
    </tr>
    <tr>
      <th rowspan="10" valign="top">openbsd.org</th>
      <th>NS</th>
      <td>                     c.ns.bsws.de.</td>
    </tr>
    <tr>
      <th>NS</th>
      <td>               ns2.superblock.net.</td>
    </tr>
    <tr>
      <th>A</th>
      <td>                     129.128.5.194</td>
    </tr>
    <tr>
      <th>NS</th>
      <td>                     a.ns.bsws.de.</td>
    </tr>
    <tr>
      <th>NS</th>
      <td>               ns1.superblock.net.</td>
    </tr>
    <tr>
      <th>NS</th>
      <td>                 ns.sigmasoft.com.</td>
    </tr>
    <tr>
      <th>NS</th>
      <td>                  ns1.telstra.net.</td>
    </tr>
    <tr>
      <th>NS</th>
      <td>                   zeus.theos.com.</td>
    </tr>
    <tr>
      <th>MX</th>
      <td>                                10</td>
    </tr>
    <tr>
      <th>MX</th>
      <td>                                 6</td>
    </tr>
    <tr>
      <th rowspan="3" valign="top">sysblog.com</th>
      <th>MX</th>
      <td>                                 0</td>
    </tr>
    <tr>
      <th>A</th>
      <td>                     66.151.181.49</td>
    </tr>
    <tr>
      <th>TXT</th>
      <td>                           "v=spf1</td>
    </tr>
    <tr>
      <th rowspan="2" valign="top">voicesofsafety.com</th>
      <th>NS</th>
      <td>           clickme.click2site.com.</td>
    </tr>
    <tr>
      <th>NS</th>
      <td>          clickme2.click2site.com.</td>
    </tr>
  </tbody>
</table>
</div>



## Connect to targets

For every single target I'll connect to it per HTTP(s) using `urllib2` and store the HTTP headers. 


```
# <!-- collapse=True -->
import urllib2
import httplib


c_targets = [t for t in targets['Target'][:20]]
frames = []

# Collect here all URLs failed to connect to
error_urls = []

def send_request(target, data):
    """ Sends a single request to the target """            
    
    # Set own headers
    headers = {'User-Agent' : 'Mozilla 5.10'}

    # Create request
    request = urllib2.Request(target, None, headers)
    
    # Default response
    response = None
        
    try:
        # Send request
        response = urllib2.urlopen(request, timeout=5)
        
        # Add headers
        for h in response.info():
            data.append([target, response.code, h, response.info()[h]])
        
    except urllib2.HTTPError, e:
        print('[ERROR] HTTPError = ' + str(e.code))
        data.append([target, e.code, '', ''])
            
    except urllib2.URLError, e:
        print('[ERROR] URLError = ' + str(e.reason))
        data.append([target, e.reason, '', ''])
            
    except ValueError, e:
        # Most probably the target didn't have any schema
        # So send the request again with HTTP
        error_urls.append(target)
        print('[ERROR] ValueError = ' + e.message)
            
    except httplib.HTTPException, e:
        print('[ERROR] HTTPException')
            
    except Exception:
        import traceback
        print('[ERROR] Exception: ' + traceback.format_exc())
        
    finally:
        return response
        

    
    
def open_connection(targets):
    """ Iterate through targets and send requests """
    data = []
    for t in targets:
        print("Connecting to\t %s" % t)
        
        response = send_request(t, data)
        
    # Create DF only if data is not empty
    if data:
        df = pd.DataFrame(data, columns=['url', 'response', 'header', 'value'])
        frames.append(df)    
        

# Open connection to targets and collect information
open_connection(c_targets)

# If there are any urls not having been tested, then
# prepend http:// to <target> and run again
new_targets =  ["http://"+u for u in error_urls]
open_connection(new_targets)
```

    Connecting to	 http://www.altpress.org/
    Connecting to	 http://www.nzfortress.co.nz
    Connecting to	 http://www.evillasforsale.com
    Connecting to	 http://www.playingenemy.com/
    [ERROR] URLError = timed out
    Connecting to	 http://www.richardsonscharts.com
    Connecting to	 http://www.xenith.net
    [ERROR] Exception: Traceback (most recent call last):
      File "<ipython-input-19-d057092f77b5>", line 26, in send_request
        response = urllib2.urlopen(request, timeout=5)
      File "/usr/lib/python2.7/urllib2.py", line 127, in urlopen
        return _opener.open(url, data, timeout)
      File "/usr/lib/python2.7/urllib2.py", line 401, in open
        response = self._open(req, data)
      File "/usr/lib/python2.7/urllib2.py", line 419, in _open
        '_open', req)
      File "/usr/lib/python2.7/urllib2.py", line 379, in _call_chain
        result = func(*args)
      File "/usr/lib/python2.7/urllib2.py", line 1211, in http_open
        return self.do_open(httplib.HTTPConnection, req)
      File "/usr/lib/python2.7/urllib2.py", line 1184, in do_open
        r = h.getresponse(buffering=True)
      File "/usr/lib/python2.7/httplib.py", line 1034, in getresponse
        response.begin()
      File "/usr/lib/python2.7/httplib.py", line 407, in begin
        version, status, reason = self._read_status()
      File "/usr/lib/python2.7/httplib.py", line 365, in _read_status
        line = self.fp.readline()
      File "/usr/lib/python2.7/socket.py", line 447, in readline
        data = self._sock.recv(self._rbufsize)
    timeout: timed out
    
    Connecting to	 http://www.tdbrecords.com
    Connecting to	 http://www.electrichumanproject.com/
    Connecting to	 http://tweekerchick.blogspot.com/
    Connecting to	 http://www.besound.com/pushead/home.html
    Connecting to	 http://www.porkchopscreenprinting.com/
    Connecting to	 http://www.kinseyvisual.com
    Connecting to	 http://www.rathergood.com
    Connecting to	 http://www.lepoint.fr/
    Connecting to	 http://www.revhq.com
    Connecting to	 http://www.poprocksandcoke.com
    Connecting to	 http://www.samuraiblue.com/
    Connecting to	 http://www.openbsd.org/cgi-bin/man.cgi
    Connecting to	 http://www.sysblog.com
    Connecting to	 http://www.voicesofsafety.com



```
df_connection = pd.concat(frames)
```


```
df_connection.set_index(['url', 'response', 'header'])
```




<div style="max-height:1000px;max-width:1500px;overflow:auto;">
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th></th>
      <th></th>
      <th>value</th>
    </tr>
    <tr>
      <th>url</th>
      <th>response</th>
      <th>header</th>
      <th></th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th rowspan="13" valign="top">http://www.altpress.org/</th>
      <th rowspan="13" valign="top">200</th>
      <th>content-length</th>
      <td>                                                                                               24576</td>
    </tr>
    <tr>
      <th>x-powered-by</th>
      <td>                                                                               PHP/5.2.4-2ubuntu5.27</td>
    </tr>
    <tr>
      <th>set-cookie</th>
      <td>                                                  PHPSESSID=1498f60d82d31ec081debde379e605eb; path=/</td>
    </tr>
    <tr>
      <th>expires</th>
      <td>                                                                       Thu, 19 Nov 1981 08:52:00 GMT</td>
    </tr>
    <tr>
      <th>vary</th>
      <td>                                                                                     Accept-Encoding</td>
    </tr>
    <tr>
      <th>server</th>
      <td>         Apache/2.2.8 (Ubuntu) PHP/5.2.4-2ubuntu5.27 with Suhosin-Patch mod_ssl/2.2.8 OpenSSL/0.9.8g</td>
    </tr>
    <tr>
      <th>last-modified</th>
      <td>                                                                       Wed, 06 Aug 2014 11:42:08 GMT</td>
    </tr>
    <tr>
      <th>connection</th>
      <td>                                                                                               close</td>
    </tr>
    <tr>
      <th>etag</th>
      <td>                                                                  "8ea9fc88e045b56cd96e6fc8b487cbd9"</td>
    </tr>
    <tr>
      <th>pragma</th>
      <td>                                                                                            no-cache</td>
    </tr>
    <tr>
      <th>cache-control</th>
      <td>                                                                              public,must-revalidate</td>
    </tr>
    <tr>
      <th>date</th>
      <td>                                                                       Wed, 06 Aug 2014 11:44:55 GMT</td>
    </tr>
    <tr>
      <th>content-type</th>
      <td>                                                                            text/html; charset=utf-8</td>
    </tr>
    <tr>
      <th rowspan="11" valign="top">http://www.nzfortress.co.nz</th>
      <th rowspan="11" valign="top">200</th>
      <th>x-powered-by</th>
      <td>                                                                               PHP/5.3.10-1ubuntu3.6</td>
    </tr>
    <tr>
      <th>transfer-encoding</th>
      <td>                                                                                             chunked</td>
    </tr>
    <tr>
      <th>set-cookie</th>
      <td> bblastvisit=1407325495; expires=Thu, 06-Aug-2015 11:44:55 GMT; path=/, bblastactivity=0; expires...</td>
    </tr>
    <tr>
      <th>vary</th>
      <td>                                                                          Accept-Encoding,User-Agent</td>
    </tr>
    <tr>
      <th>server</th>
      <td>                                                                              Apache/2.2.22 (Ubuntu)</td>
    </tr>
    <tr>
      <th>connection</th>
      <td>                                                                                               close</td>
    </tr>
    <tr>
      <th>x-ua-compatible</th>
      <td>                                                                                                IE=7</td>
    </tr>
    <tr>
      <th>pragma</th>
      <td>                                                                                             private</td>
    </tr>
    <tr>
      <th>cache-control</th>
      <td>                                                                                             private</td>
    </tr>
    <tr>
      <th>date</th>
      <td>                                                                       Wed, 06 Aug 2014 11:44:55 GMT</td>
    </tr>
    <tr>
      <th>content-type</th>
      <td>                                                                       text/html; charset=ISO-8859-1</td>
    </tr>
    <tr>
      <th rowspan="9" valign="top">http://www.evillasforsale.com</th>
      <th rowspan="9" valign="top">200</th>
      <th>content-length</th>
      <td>                                                                                               14610</td>
    </tr>
    <tr>
      <th>accept-ranges</th>
      <td>                                                                                               bytes</td>
    </tr>
    <tr>
      <th>vary</th>
      <td>                                                                          Accept-Encoding,User-Agent</td>
    </tr>
    <tr>
      <th>server</th>
      <td>                                                                                            Apache/2</td>
    </tr>
    <tr>
      <th>last-modified</th>
      <td>                                                                       Thu, 21 Jan 2010 13:33:43 GMT</td>
    </tr>
    <tr>
      <th>connection</th>
      <td>                                                                                               close</td>
    </tr>
    <tr>
      <th>etag</th>
      <td>                                                                        "2040cf7-3912-47dacc06c1bc0"</td>
    </tr>
    <tr>
      <th>date</th>
      <td>                                                                       Wed, 06 Aug 2014 11:46:01 GMT</td>
    </tr>
    <tr>
      <th>content-type</th>
      <td>                                                                                           text/html</td>
    </tr>
    <tr>
      <th>http://www.playingenemy.com/</th>
      <th>timed out</th>
      <th></th>
      <td>                                                                                                    </td>
    </tr>
    <tr>
      <th rowspan="10" valign="top">http://www.richardsonscharts.com</th>
      <th rowspan="10" valign="top">200</th>
      <th>x-powered-by</th>
      <td>                                                                                            PleskLin</td>
    </tr>
    <tr>
      <th>transfer-encoding</th>
      <td>                                                                                             chunked</td>
    </tr>
    <tr>
      <th>set-cookie</th>
      <td>                                                        PHPSESSID=8cg77frbg8biv0ru8m7udb6877; path=/</td>
    </tr>
    <tr>
      <th>expires</th>
      <td>                                                                       Thu, 19 Nov 1981 08:52:00 GMT</td>
    </tr>
    <tr>
      <th>server</th>
      <td>                                                                                              Apache</td>
    </tr>
    <tr>
      <th>connection</th>
      <td>                                                                                               close</td>
    </tr>
    <tr>
      <th>pragma</th>
      <td>                                                                                            no-cache</td>
    </tr>
    <tr>
      <th>cache-control</th>
      <td>                                      no-store, no-cache, must-revalidate, post-check=0, pre-check=0</td>
    </tr>
    <tr>
      <th>date</th>
      <td>                                                                       Wed, 06 Aug 2014 11:45:00 GMT</td>
    </tr>
    <tr>
      <th>content-type</th>
      <td>                                                                                           text/html</td>
    </tr>
    <tr>
      <th rowspan="9" valign="top">http://www.tdbrecords.com</th>
      <th rowspan="9" valign="top">200</th>
      <th>content-length</th>
      <td>                                                                                                2600</td>
    </tr>
    <tr>
      <th>accept-ranges</th>
      <td>                                                                                               bytes</td>
    </tr>
    <tr>
      <th>vary</th>
      <td>                                                                                     Accept-Encoding</td>
    </tr>
    <tr>
      <th>server</th>
      <td>                                                                                              Apache</td>
    </tr>
    <tr>
      <th>last-modified</th>
      <td>                                                                       Mon, 03 Oct 2011 00:02:54 GMT</td>
    </tr>
    <tr>
      <th>connection</th>
      <td>                                                                                               close</td>
    </tr>
    <tr>
      <th>etag</th>
      <td>                                                                                 "a28-4ae59b253c780"</td>
    </tr>
    <tr>
      <th>date</th>
      <td>                                                                       Wed, 06 Aug 2014 11:46:45 GMT</td>
    </tr>
    <tr>
      <th>content-type</th>
      <td>                                                                                           text/html</td>
    </tr>
    <tr>
      <th rowspan="8" valign="top">http://www.electrichumanproject.com/</th>
      <th rowspan="8" valign="top">200</th>
      <th>content-length</th>
      <td>                                                                                               14683</td>
    </tr>
    <tr>
      <th>accept-ranges</th>
      <td>                                                                                               bytes</td>
    </tr>
    <tr>
      <th>vary</th>
      <td>                                                                                     Accept-Encoding</td>
    </tr>
    <tr>
      <th>server</th>
      <td>                                                                                              Apache</td>
    </tr>
    <tr>
      <th>last-modified</th>
      <td>                                                                       Tue, 05 Aug 2014 18:19:00 GMT</td>
    </tr>
    <tr>
      <th>connection</th>
      <td>                                                                                               close</td>
    </tr>
    <tr>
      <th>date</th>
      <td>                                                                       Wed, 06 Aug 2014 11:45:06 GMT</td>
    </tr>
    <tr>
      <th>content-type</th>
      <td>                                                                                           text/html</td>
    </tr>
    <tr>
      <th rowspan="11" valign="top">http://tweekerchick.blogspot.com/</th>
      <th rowspan="11" valign="top">200</th>
      <th>alternate-protocol</th>
      <td>                                                                                             80:quic</td>
    </tr>
    <tr>
      <th>x-xss-protection</th>
      <td>                                                                                       1; mode=block</td>
    </tr>
    <tr>
      <th>x-content-type-options</th>
      <td>                                                                                             nosniff</td>
    </tr>
    <tr>
      <th>expires</th>
      <td>                                                                       Wed, 06 Aug 2014 11:45:06 GMT</td>
    </tr>
    <tr>
      <th>server</th>
      <td>                                                                                                 GSE</td>
    </tr>
    <tr>
      <th>last-modified</th>
      <td>                                                                       Wed, 06 Aug 2014 05:34:08 GMT</td>
    </tr>
    <tr>
      <th>connection</th>
      <td>                                                                                               close</td>
    </tr>
    <tr>
      <th>etag</th>
      <td>                                                              "d6b75768-8b38-4991-b414-a06cc4608563"</td>
    </tr>
    <tr>
      <th>cache-control</th>
      <td>                                                                                  private, max-age=0</td>
    </tr>
    <tr>
      <th>date</th>
      <td>                                                                       Wed, 06 Aug 2014 11:45:06 GMT</td>
    </tr>
    <tr>
      <th>content-type</th>
      <td>                                                                            text/html; charset=UTF-8</td>
    </tr>
    <tr>
      <th rowspan="8" valign="top">http://www.besound.com/pushead/home.html</th>
      <th rowspan="8" valign="top">200</th>
      <th>content-length</th>
      <td>                                                                                                3870</td>
    </tr>
    <tr>
      <th>accept-ranges</th>
      <td>                                                                                               bytes</td>
    </tr>
    <tr>
      <th>server</th>
      <td>                                                                                              Apache</td>
    </tr>
    <tr>
      <th>last-modified</th>
      <td>                                                                       Fri, 09 Jun 2006 04:34:30 GMT</td>
    </tr>
    <tr>
      <th>connection</th>
      <td>                                                                                               close</td>
    </tr>
    <tr>
      <th>etag</th>
      <td>                                                                                 "f1e-415c31dd2c180"</td>
    </tr>
    <tr>
      <th>date</th>
      <td>                                                                       Wed, 06 Aug 2014 11:45:07 GMT</td>
    </tr>
    <tr>
      <th>content-type</th>
      <td>                                                                                           text/html</td>
    </tr>
    <tr>
      <th rowspan="11" valign="top">http://www.porkchopscreenprinting.com/</th>
      <th rowspan="11" valign="top">200</th>
      <th>content-length</th>
      <td>                                                                                               11811</td>
    </tr>
    <tr>
      <th>set-cookie</th>
      <td>                                                                                     HttpOnly;Secure</td>
    </tr>
    <tr>
      <th>accept-ranges</th>
      <td>                                                                                               bytes</td>
    </tr>
    <tr>
      <th>expires</th>
      <td>                                                                       Wed, 06 Aug 2014 11:45:27 GMT</td>
    </tr>
    <tr>
      <th>server</th>
      <td>                                                                                              Apache</td>
    </tr>
    <tr>
      <th>last-modified</th>
      <td>                                                                       Tue, 28 Aug 2012 17:44:17 GMT</td>
    </tr>
    <tr>
      <th>connection</th>
      <td>                                                                                               close</td>
    </tr>
    <tr>
      <th>etag</th>
      <td>                                                                              "b893e5-2e23-503d0371"</td>
    </tr>
    <tr>
      <th>cache-control</th>
      <td>                                                                                          max-age=20</td>
    </tr>
    <tr>
      <th>date</th>
      <td>                                                                       Wed, 06 Aug 2014 11:45:07 GMT</td>
    </tr>
    <tr>
      <th>content-type</th>
      <td>                                                                                           text/html</td>
    </tr>
    <tr>
      <th rowspan="11" valign="top">http://www.kinseyvisual.com</th>
      <th rowspan="11" valign="top">200</th>
      <th>x-powered-by</th>
      <td>                                                                                          PHP/5.3.27</td>
    </tr>
    <tr>
      <th>transfer-encoding</th>
      <td>                                                                                             chunked</td>
    </tr>
    <tr>
      <th>set-cookie</th>
      <td>                                                  PHPSESSID=b5f9f0af80bf4e08f41eeb02be6e6ad1; path=/</td>
    </tr>
    <tr>
      <th>expires</th>
      <td>                                                                       Thu, 19 Nov 1981 08:52:00 GMT</td>
    </tr>
    <tr>
      <th>vary</th>
      <td>                                                                          User-Agent,Accept-Encoding</td>
    </tr>
    <tr>
      <th>server</th>
      <td>                                                                                       Apache/2.2.22</td>
    </tr>
    <tr>
      <th>connection</th>
      <td>                                                                                               close</td>
    </tr>
    <tr>
      <th>pragma</th>
      <td>                                                                                            no-cache</td>
    </tr>
    <tr>
      <th>cache-control</th>
      <td>                                      no-store, no-cache, must-revalidate, post-check=0, pre-check=0</td>
    </tr>
    <tr>
      <th>date</th>
      <td>                                                                       Wed, 06 Aug 2014 11:45:08 GMT</td>
    </tr>
    <tr>
      <th>content-type</th>
      <td>                                                                                           text/html</td>
    </tr>
    <tr>
      <th rowspan="11" valign="top">http://www.rathergood.com</th>
      <th rowspan="11" valign="top">200</th>
      <th>transfer-encoding</th>
      <td>                                                                                             chunked</td>
    </tr>
    <tr>
      <th>set-cookie</th>
      <td>                                 c6ef959f4780c6a62e86c7a2d2e5ccea=4ilfnp83k67evmmn281i9qcnu3; path=/</td>
    </tr>
    <tr>
      <th>vary</th>
      <td>                                                                                     Accept-Encoding</td>
    </tr>
    <tr>
      <th>server</th>
      <td>                                                                                              Apache</td>
    </tr>
    <tr>
      <th>connection</th>
      <td>                                                                                               close</td>
    </tr>
    <tr>
      <th>pragma</th>
      <td>                                                                                            no-cache</td>
    </tr>
    <tr>
      <th>cache-control</th>
      <td>                                                                       no-cache, max-age=0, no-cache</td>
    </tr>
    <tr>
      <th>date</th>
      <td>                                                                       Wed, 06 Aug 2014 11:45:08 GMT</td>
    </tr>
    <tr>
      <th>p3p</th>
      <td>                                                  CP="NOI ADM DEV PSAi COM NAV OUR OTRo STP IND DEM"</td>
    </tr>
    <tr>
      <th>content-type</th>
      <td>                                                                            text/html; charset=utf-8</td>
    </tr>
    <tr>
      <th>x-mod-pagespeed</th>
      <td>                                                                                       1.6.29.7-3566</td>
    </tr>
    <tr>
      <th rowspan="10" valign="top">http://www.lepoint.fr/</th>
      <th rowspan="10" valign="top">200</th>
      <th>x-xss-protection</th>
      <td>                                                                                       1; mode=block</td>
    </tr>
    <tr>
      <th>x-content-type-options</th>
      <td>                                                                                             nosniff</td>
    </tr>
    <tr>
      <th>x-powered-by</th>
      <td>                                                                                           PHP/5.5.9</td>
    </tr>
    <tr>
      <th>transfer-encoding</th>
      <td>                                                                                             chunked</td>
    </tr>
    <tr>
      <th>vary</th>
      <td>                                                                          User-Agent,Accept-Encoding</td>
    </tr>
    <tr>
      <th>server</th>
      <td>                                                                      Apache/2.2.25 (Unix) PHP/5.5.9</td>
    </tr>
    <tr>
      <th>connection</th>
      <td>                                                                                               close</td>
    </tr>
    <tr>
      <th>date</th>
      <td>                                                                       Wed, 06 Aug 2014 11:45:09 GMT</td>
    </tr>
    <tr>
      <th>x-frame-options</th>
      <td>                                                                                          SAMEORIGIN</td>
    </tr>
    <tr>
      <th>content-type</th>
      <td>                                                                                           text/html</td>
    </tr>
    <tr>
      <th rowspan="11" valign="top">http://www.revhq.com</th>
      <th rowspan="11" valign="top">200</th>
      <th>x-powered-by</th>
      <td>                                                                  Atari TT posix / Python / php 5.3x</td>
    </tr>
    <tr>
      <th>transfer-encoding</th>
      <td>                                                                                             chunked</td>
    </tr>
    <tr>
      <th>set-cookie</th>
      <td>                                                        PHPSESSID=e1jmcg9c2pgbi9rhgcdkhq5ge4; path=/</td>
    </tr>
    <tr>
      <th>expires</th>
      <td>                                                                       Thu, 19 Nov 1981 08:52:00 GMT</td>
    </tr>
    <tr>
      <th>vary</th>
      <td>                                                                                     Accept-Encoding</td>
    </tr>
    <tr>
      <th>server</th>
      <td>                                                                                       Apache/2.2.22</td>
    </tr>
    <tr>
      <th>connection</th>
      <td>                                                                                               close</td>
    </tr>
    <tr>
      <th>pragma</th>
      <td>                                                                                            no-cache</td>
    </tr>
    <tr>
      <th>cache-control</th>
      <td>                                      no-store, no-cache, must-revalidate, post-check=0, pre-check=0</td>
    </tr>
    <tr>
      <th>date</th>
      <td>                                                                       Wed, 06 Aug 2014 11:45:19 GMT</td>
    </tr>
    <tr>
      <th>content-type</th>
      <td>                                                                                           text/html</td>
    </tr>
    <tr>
      <th rowspan="7" valign="top">http://www.poprocksandcoke.com</th>
      <th rowspan="7" valign="top">200</th>
      <th>x-powered-by</th>
      <td>                                                                                          PHP/5.3.24</td>
    </tr>
    <tr>
      <th>transfer-encoding</th>
      <td>                                                                                             chunked</td>
    </tr>
    <tr>
      <th>server</th>
      <td>                                                                                              Apache</td>
    </tr>
    <tr>
      <th>connection</th>
      <td>                                                                                               close</td>
    </tr>
    <tr>
      <th>date</th>
      <td>                                                                       Wed, 06 Aug 2014 11:45:10 GMT</td>
    </tr>
    <tr>
      <th>content-type</th>
      <td>                                                                            text/html; charset=UTF-8</td>
    </tr>
    <tr>
      <th>x-pingback</th>
      <td>                                                           http://www.poprocksandcoke.com/xmlrpc.php</td>
    </tr>
    <tr>
      <th rowspan="7" valign="top">http://www.samuraiblue.com/</th>
      <th rowspan="7" valign="top">200</th>
      <th>content-length</th>
      <td>                                                                                               54005</td>
    </tr>
    <tr>
      <th>x-powered-by</th>
      <td>                                                                                          PHP/5.4.31</td>
    </tr>
    <tr>
      <th>server</th>
      <td>                                                                                              Apache</td>
    </tr>
    <tr>
      <th>connection</th>
      <td>                                                                                               close</td>
    </tr>
    <tr>
      <th>date</th>
      <td>                                                                       Wed, 06 Aug 2014 11:45:12 GMT</td>
    </tr>
    <tr>
      <th>content-type</th>
      <td>                                                                            text/html; charset=UTF-8</td>
    </tr>
    <tr>
      <th>x-pingback</th>
      <td>                                                                   http://samuraiblue.com/xmlrpc.php</td>
    </tr>
    <tr>
      <th rowspan="7" valign="top">http://www.openbsd.org/cgi-bin/man.cgi</th>
      <th rowspan="7" valign="top">200</th>
      <th>transfer-encoding</th>
      <td>                                                                                             chunked</td>
    </tr>
    <tr>
      <th>server</th>
      <td>                                                                                              Apache</td>
    </tr>
    <tr>
      <th>connection</th>
      <td>                                                                                               close</td>
    </tr>
    <tr>
      <th>pragma</th>
      <td>                                                                                            no-cache</td>
    </tr>
    <tr>
      <th>cache-control</th>
      <td>                                                                                            no-cache</td>
    </tr>
    <tr>
      <th>date</th>
      <td>                                                                       Wed, 06 Aug 2014 11:45:13 GMT</td>
    </tr>
    <tr>
      <th>content-type</th>
      <td>                                                                            text/html; charset=utf-8</td>
    </tr>
    <tr>
      <th rowspan="15" valign="top">http://www.sysblog.com</th>
      <th rowspan="15" valign="top">200</th>
      <th>content-length</th>
      <td>                                                                                               48663</td>
    </tr>
    <tr>
      <th>x-varnish</th>
      <td>                                                                                 718735313 718731229</td>
    </tr>
    <tr>
      <th>x-cache</th>
      <td>                                                                                                 HIT</td>
    </tr>
    <tr>
      <th>x-powered-by</th>
      <td>                                                                                          PHP/5.3.16</td>
    </tr>
    <tr>
      <th>set-cookie</th>
      <td>                                                        PHPSESSID=5vk936712pnke6t5ki26n9frf4; path=/</td>
    </tr>
    <tr>
      <th>accept-ranges</th>
      <td>                                                                                               bytes</td>
    </tr>
    <tr>
      <th>expires</th>
      <td>                                                                       Thu, 19 Nov 1981 08:52:00 GMT</td>
    </tr>
    <tr>
      <th>server</th>
      <td>                                                                                              Apache</td>
    </tr>
    <tr>
      <th>connection</th>
      <td>                                                                                               close</td>
    </tr>
    <tr>
      <th>via</th>
      <td>                                                                                         1.1 varnish</td>
    </tr>
    <tr>
      <th>pragma</th>
      <td>                                                                                            no-cache</td>
    </tr>
    <tr>
      <th>cache-control</th>
      <td>                                      no-store, no-cache, must-revalidate, post-check=0, pre-check=0</td>
    </tr>
    <tr>
      <th>date</th>
      <td>                                                                       Wed, 06 Aug 2014 11:45:14 GMT</td>
    </tr>
    <tr>
      <th>content-type</th>
      <td>                                                                            text/html; charset=UTF-8</td>
    </tr>
    <tr>
      <th>age</th>
      <td>                                                                                                  40</td>
    </tr>
    <tr>
      <th rowspan="7" valign="top">http://www.voicesofsafety.com</th>
      <th rowspan="7" valign="top">200</th>
      <th>content-length</th>
      <td>                                                                                               20854</td>
    </tr>
    <tr>
      <th>accept-ranges</th>
      <td>                                                                                        bytes, bytes</td>
    </tr>
    <tr>
      <th>server</th>
      <td>                                                                                            Apache/2</td>
    </tr>
    <tr>
      <th>connection</th>
      <td>                                                                                               close</td>
    </tr>
    <tr>
      <th>date</th>
      <td>                                                                       Wed, 06 Aug 2014 11:45:15 GMT</td>
    </tr>
    <tr>
      <th>content-type</th>
      <td>                                                                                           text/html</td>
    </tr>
    <tr>
      <th>age</th>
      <td>                                                                                                   0</td>
    </tr>
  </tbody>
</table>
</div>



## Save to Excel

Now feel free to do whatever you want with your DataFrames: Export them to CSV, EXCEL, TXT etc.


```
from pandas import ExcelWriter
writer = ExcelWriter('Excel/output.xls')
df_whois.to_excel(writer, "Sheet - WHOIS")
df_dns.to_excel(writer, "Sheet - DNS")
#df_connection.to_excel(writer, "Sheet - Connections")
```

Since I wasn't able to export the `df_connection` to Excel (`Exception: Unexpected data type <class 'socket.timeout'>`) I had to export it to CSV:


```
df_connection.to_csv("Excel/connection.csv", sep="\t", header=True)
```
