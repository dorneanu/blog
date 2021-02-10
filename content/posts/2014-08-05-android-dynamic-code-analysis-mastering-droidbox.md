+++
title = "Android Dynamic Code Analysis - Mastering DroidBox"
date = "2014-08-05"
tags = ["android", "hacking", "networking", "security", "ipython", "code", "sca", "droidbox", "re", "mobile", "fakebanker", "appsec"]
author = "Victor Dorneanu"
category = "blog"
+++

In this article I'll have a a closer look at [DroidBox](https://code.google.com/p/droidbox/) which provides a mobile sandbox to look at Android applications. In the previous [post](/2014/07/07/disect-android-apks-like-a-pro-static-code-analysis/) I've dealt with *static code analysis*. This time will start running our malicious application and look at the "noise" it generates. That would be:

* file system access
* network activity
* interaction with the operating system
* interaction with other applications
* etc.

*DroidBox* is very easy to use and consists of an own system image and kernel meant to log one applications activities. Using `adb logcat` *DroidBox* will look for certain debug messages and collect anything related to the monitored app. However I must say that loged data isn't always complete. Sometimes you'll get only a *striped* version of the data which caused the activity. In that case it's almost impossible e.g. to have a deep look at the network traffic (especially HTTP). You won't be able to construct a full request-response-sequence due to missing data. Nevertheless you can use DroidBox to get an overview of malicious activities triggered by the app. For a more technical analysis of the data you'll need additional tools (more to come in future posts).

### Requirements for DroidBox

First you'll have to install some requirements DroidBox needs. First make sure you have the system relevant packages installed:

~~~ shell
root@kali:~# apt-get install python-virtualenv libatlas-dev liblapack-dev libblas-dev
~~~

You'll need those in order to use `scipy`, `matplotlib` and `numpy` along with Droidbox. Now create a virtual environment and install *python* dependencies:

~~~ shell
root@kali:~/work/apk# mkdir env
root@kali:~/work/apk# virtualenv env
...
root@kali:~/work/apk# source env/bin/activate
(env)root@kali:~/work/apk# pip install numpy scipy matplotlib
~~~

### Install Droidbox

Download the package:

~~~ shell
(env)root@kali:~/work/apk# wget https://droidbox.googlecode.com/files/DroidBox411RC.tar.gz
~~~

### Setup PATH


```
import os
import sys

# Setup new PATH
old_path = os.environ['PATH']
new_path = old_path + ":" + "/root/work/apk/SDK/android-sdk-linux/tools:/root/work/apk/SDK/android-sdk-linux/platform-tools:/root/work/apk/SDK/android-sdk-linux/build-tools/19.1.0"
os.environ['PATH'] = new_path

# Change working directory
os.chdir("/root/work/apk/DroidBox_4.1.1/")
```

### Setup IPython settings


```
%pylab inline
import binascii
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import networkx as nx
import datetime as dt
import time
import ipy_table
from IPython.display import display_pretty, display_html, display_jpeg, display_png, display_json, display_latex, display_svg
from IPython.display import HTML
from IPython.core.magic import register_cell_magic, Magics, magics_class, cell_magic
import jinja2

# Ipython settings
pd.set_option('display.height', 1000)
pd.set_option('display.max_rows', 500)
pd.set_option('display.max_columns', 500)
pd.set_option('display.max_colwidth', 100)
pd.set_option('display.width', 1000)
pd.set_option('display.column_space', 1000)
```

    Populating the interactive namespace from numpy and matplotlib
    height has been deprecated.
    


### External extensions


```
# Install
%install_ext https://raw.githubusercontent.com/dorneanu/ipython/master/extensions/diagmagic.py
    
# Then load extensions
%load_ext diagmagic
```

    Installed diagmagic.py. To use it, type:
      %load_ext diagmagic


### Utilities


```
from IPython import display
from IPython.core.magic import register_cell_magic, Magics, magics_class, cell_magic
import jinja2

# <!-- collapse=True -->
def df2table(df):
    """ Outputs a DataFrame as a table using ipy_table """
    entries = [list(i) for i in df.itertuples()]
    
    # Extract table header
    header = list(df.columns)
    
    # Add index to header
    header.insert(0, df.index.name)
    
    # Insert header at 1st place
    entries.insert(0, header)

    return ipy_table.make_table(entries)

# Create jinja cell magic (http://nbviewer.ipython.org/urls/gist.github.com/bj0/5343292/raw/23a0845ee874827e3635edb0bf5701710a537bfc/jinja2.ipynb)
@magics_class
class JinjaMagics(Magics):
    '''Magics class containing the jinja2 magic and state'''
    
    def __init__(self, shell):
        super(JinjaMagics, self).__init__(shell)
        
        # create a jinja2 environment to use for rendering
        # this can be modified for desired effects (ie: using different variable syntax)
        self.env = jinja2.Environment(loader=jinja2.FileSystemLoader('.'))
        
        # possible output types
        self.display_functions = dict(html=display.HTML, 
                                      latex=display.Latex,
                                      json=display.JSON,
                                      pretty=display.Pretty,
                                      display=display.display)

    
    @cell_magic
    def jinja(self, line, cell):
        '''
        jinja2 cell magic function.  Contents of cell are rendered by jinja2, and 
        the line can be used to specify output type.

        ie: "%%jinja html" will return the rendered cell wrapped in an HTML object.
        '''
        f = self.display_functions.get(line.lower().strip(), display.display)
        
        tmp = self.env.from_string(cell)
        rend = tmp.render(dict((k,v) for (k,v) in self.shell.user_ns.items() 
                                        if not k.startswith('_') and k not in self.shell.user_ns_hidden))
        
        return f(rend)
        
    
ip = get_ipython()
ip.register_magics(JinjaMagics)
```

## Create Android Virtual Device (ADV)

Now you'll have to install an Android device virtually in order to analyze the APK. Supposing you have installed the SDK in the previous step now you should have some *targets* available on your machine. If not (that was my case) then make sure you have a X session running and run `android` from the console. In my case I've fired up `vnc` and connected to the Kali machine. 

This is what I've got:


```bash
%%bash
android list targets | head -n 10
```

    Available Android targets:
    ----------
    id: 1 or "android-16"
         Name: Android 4.1.2
         Type: Platform
         API level: 16
         Revision: 4
         Skins: WXGA800-7in, WQVGA400, WVGA800 (default), WXGA800, HVGA, WSVGA, WVGA854, WQVGA432, WXGA720, QVGA
     Tag/ABIs : default/armeabi-v7a
    ----------


Now we **create** the AVD using following command:

```
# android create avd --abi default/armeabi-v7a -n android-4.1.2-droidbox -t 1 -c 1000M
Android 4.1.2 is a basic Android platform.
Do you wish to create a custom hardware profile [no]
Created AVD 'android-4.1.2-droidbox' based on Android 4.1.2, ARM (armeabi-v7a) processor,
with the following hardware config:
hw.lcd.density=240
hw.ramSize=512
hw.sdCard=yes
vm.heapSize=48

```


```bash
%%bash
android list avd
```

    Available Android Virtual Devices:
        Name: android-4.1.2-droidbox
        Path: /root/.android/avd/android-4.1.2-droidbox.avd
      Target: Android 4.1.2 (API level 16)
     Tag/ABI: default/armeabi-v7a
        Skin: WVGA800
      Sdcard: 1000M


### Start the emulator

In `DroidBox`s package directory you'll find `startemu.sh`. Open it and add your favourite parameters.



```bash
%%bash
cat startemu.sh
```

    #!/usr/bin/env bash
    
    emulator -avd $1 -system images/system.img -ramdisk images/ramdisk.img -wipe-data -prop dalvik.vm.execution-mode=int:portable &


Afterwards make sure you have a X session and **run** the emulator with your previously created AVD:

~~~ shell
(env)root@kali:~/work/apk/DroidBox# ./startemu.sh android-4.1.2-droidbox
...
~~~

Now you should see your emulator booting ...

### Run DroidBox


```
!./droidbox.sh /root/work/apk/DroidBox_4.1.1/APK/FakeBanker.apk
```

    [H[2J ____                        __  ____
    /\  _`\               __    /\ \/\  _`\
    \ \ \/\ \  _ __  ___ /\_\   \_\ \ \ \L\ \   ___   __  _
     \ \ \ \ \/\`'__\ __`\/\ \  /'_` \ \  _ <' / __`\/\ \/'\
      \ \ \_\ \ \ \/\ \L\ \ \ \/\ \L\ \ \ \L\ \ \L\ \/>  </
       \ \____/\ \_\ \____/\ \_\ \___,_\ \____/ \____//\_/\_\
        \/___/  \/_/\/___/  \/_/\/__,_ /\/___/ \/___/ \//\/_/
    Waiting for the device...
    Installing the application /root/work/apk/DroidBox_4.1.1/APK/FakeBanker.apk...
    Running the component com.gmail.xpack/com.gmail.xpack.MainActivity...
    Starting the activity com.gmail.xpack.MainActivity...
    Application started
    Analyzing the application during infinite time seconds...
    ^C


>DroidBox will then listen for activities until you kill it by ^C. 

Meanwhile I was interacting with the APP and saw that DroidBox was collecting the logs during the interacttions.
DroidBox will output its results as a JSON file. **I've uploaded the results to [pastebin.com](http://pastebin.com/7YSb3EMW)**. Now let's have some fun and take a look at the results.

Before starting analyzing the output keep in mind that:

> [...] all data received/sent, read/written are shown in hexadecimal since the handled data can contain binary data. 
> 
> (Source: https://github.com/floe/mobile-sandbox/blob/master/DroidBox_4.1.1/scripts/droidbox.py)


## Results analysis

First let's download the data and let python parse it


```
# <!-- collapse=True -->
import json
import urllib
url = "http://pastebin.com/raw.php?i=7YSb3EMW"

# Load data
jsonurl = urllib.urlopen(url)
result = json.loads(jsonurl.read())

# Show dictionary keys
result.keys()
```




    [u'apkName',
     u'enfperm',
     u'opennet',
     u'cryptousage',
     u'sendsms',
     u'servicestart',
     u'sendnet',
     u'closenet',
     u'accessedfiles',
     u'fdaccess',
     u'dataleaks',
     u'recvnet',
     u'dexclass',
     u'hashes',
     u'recvsaction',
     u'phonecalls']



So we have diffenrent categories of activities we can look at. After analyzing the JSON content I've come to following most important activities.

## File system activities

Let's have a look at the file system access actions triggered by the application. Due to DroidBox limitations I couldn't have a look at the **complete** raw data.


```
# <!-- collapse=True -->
# Convert timestamps to human readable time delta
timestamps = [str(datetime.timedelta(seconds=(round(float(i.encode("utf-8")))))) for i in result['fdaccess'].keys()]

# Create list of accessed files entries
accessed_files = [i[1] for i in result['fdaccess'].items()]

# Create dataframe
df_accessedfiles = pd.DataFrame(accessed_files, index=timestamps)
df_accessedfiles.sort(inplace=True)
df_accessedfiles.index.name='Timestamp'

# Unhexlify data
unhexed_data = [binascii.unhexlify(d) for d in df_accessedfiles['data']]
df_accessedfiles['rawdata'] = unhexed_data

df2table(df_accessedfiles[['operation', 'path', 'rawdata']].reset_index())
#ipy_table.apply_theme('basic')
df_accessedfiles[['operation', 'path', 'rawdata']].reset_index()
```




<div style="max-height:1000px;max-width:1500px;overflow:auto;">
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>Timestamp</th>
      <th>operation</th>
      <th>path</th>
      <th>rawdata</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0 </th>
      <td> 0:00:03</td>
      <td>  read</td>
      <td> /data/data/com.gmail.xpack/shared_prefs/MainPref.xml</td>
      <td> &lt;?xml version='1.0' encoding='utf-8' standalone='yes' ?&gt;\n&lt;map&gt;\n&lt;string name="DOWNLOADDOMAIN"&gt;c...</td>
    </tr>
    <tr>
      <th>1 </th>
      <td> 0:00:04</td>
      <td>  read</td>
      <td>                                   /proc/1184/cmdline</td>
      <td> com.gmail.xpack                                                             p/FakeBanker.apk ain...</td>
    </tr>
    <tr>
      <th>2 </th>
      <td> 0:00:04</td>
      <td>  read</td>
      <td>                                   /proc/1197/cmdline</td>
      <td> logcat DroidBox:W dalvikvm:W ActivityManager:I                              p/FakeBanker.apk ain...</td>
    </tr>
    <tr>
      <th>3 </th>
      <td> 0:00:08</td>
      <td>  read</td>
      <td> /data/data/com.gmail.xpack/shared_prefs/MainPref.xml</td>
      <td> &lt;?xml version='1.0' encoding='utf-8' standalone='yes' ?&gt;\n&lt;map&gt;\n&lt;string name="DOWNLOADDOMAIN"&gt;c...</td>
    </tr>
    <tr>
      <th>4 </th>
      <td> 0:00:09</td>
      <td> write</td>
      <td> /data/data/com.gmail.xpack/shared_prefs/MainPref.xml</td>
      <td> &lt;?xml version='1.0' encoding='utf-8' standalone='yes' ?&gt;\n&lt;map&gt;\n&lt;string name="DOWNLOADDOMAIN"&gt;c...</td>
    </tr>
    <tr>
      <th>5 </th>
      <td> 0:00:10</td>
      <td> write</td>
      <td> /data/data/com.gmail.xpack/shared_prefs/MainPref.xml</td>
      <td> &lt;?xml version='1.0' encoding='utf-8' standalone='yes' ?&gt;\n&lt;map&gt;\n&lt;string name="DOWNLOADDOMAIN"&gt;c...</td>
    </tr>
    <tr>
      <th>6 </th>
      <td> 0:00:10</td>
      <td>  read</td>
      <td>                                   /proc/1205/cmdline</td>
      <td> com.gmail.xpack:remote                                                      p/FakeBanker.apk ain...</td>
    </tr>
    <tr>
      <th>7 </th>
      <td> 0:00:36</td>
      <td> write</td>
      <td> /data/data/com.gmail.xpack/shared_prefs/MainPref.xml</td>
      <td> &lt;?xml version='1.0' encoding='utf-8' standalone='yes' ?&gt;\n&lt;map&gt;\n&lt;int name="PASSADDED" value="10...</td>
    </tr>
    <tr>
      <th>8 </th>
      <td> 0:00:36</td>
      <td>  read</td>
      <td> /data/data/com.gmail.xpack/shared_prefs/MainPref.xml</td>
      <td> &lt;?xml version='1.0' encoding='utf-8' standalone='yes' ?&gt;\n&lt;map&gt;\n&lt;string name="DOWNLOADDOMAIN"&gt;c...</td>
    </tr>
    <tr>
      <th>9 </th>
      <td> 0:01:05</td>
      <td>  read</td>
      <td> /data/data/com.gmail.xpack/shared_prefs/MainPref.xml</td>
      <td> &lt;?xml version='1.0' encoding='utf-8' standalone='yes' ?&gt;\n&lt;map&gt;\n&lt;int name="PASSADDED" value="10...</td>
    </tr>
    <tr>
      <th>10</th>
      <td> 0:15:06</td>
      <td> write</td>
      <td> /data/data/com.gmail.xpack/shared_prefs/MainPref.xml</td>
      <td> &lt;?xml version='1.0' encoding='utf-8' standalone='yes' ?&gt;\n&lt;map&gt;\n&lt;int name="PASSADDED" value="10...</td>
    </tr>
    <tr>
      <th>11</th>
      <td> 0:15:06</td>
      <td> write</td>
      <td> /data/data/com.gmail.xpack/shared_prefs/MainPref.xml</td>
      <td> &lt;?xml version='1.0' encoding='utf-8' standalone='yes' ?&gt;\n&lt;map&gt;\n&lt;int name="PASSADDED" value="10...</td>
    </tr>
    <tr>
      <th>12</th>
      <td> 0:15:24</td>
      <td>  read</td>
      <td>                                         /dev/urandom</td>
      <td>                                                                                E0 �2qV���4!=�Nd��V</td>
    </tr>
    <tr>
      <th>13</th>
      <td> 0:15:27</td>
      <td>  read</td>
      <td>                                   /proc/1239/cmdline</td>
      <td> com.android.exchange                                                        p/FakeBanker.apk ain...</td>
    </tr>
    <tr>
      <th>14</th>
      <td> 0:15:35</td>
      <td>  read</td>
      <td> /data/data/com.gmail.xpack/shared_prefs/MainPref.xml</td>
      <td> &lt;?xml version='1.0' encoding='utf-8' standalone='yes' ?&gt;\n&lt;map&gt;\n&lt;int name="PASSADDED" value="10...</td>
    </tr>
    <tr>
      <th>15</th>
      <td> 0:15:37</td>
      <td> write</td>
      <td> /data/data/com.gmail.xpack/shared_prefs/MainPref.xml</td>
      <td> &lt;?xml version='1.0' encoding='utf-8' standalone='yes' ?&gt;\n&lt;map&gt;\n&lt;int name="PASSADDED" value="10...</td>
    </tr>
    <tr>
      <th>16</th>
      <td> 0:15:37</td>
      <td> write</td>
      <td> /data/data/com.gmail.xpack/shared_prefs/MainPref.xml</td>
      <td> &lt;?xml version='1.0' encoding='utf-8' standalone='yes' ?&gt;\n&lt;map&gt;\n&lt;int name="PASSADDED" value="10...</td>
    </tr>
    <tr>
      <th>17</th>
      <td> 0:15:58</td>
      <td>  read</td>
      <td> /data/data/com.gmail.xpack/shared_prefs/MainPref.xml</td>
      <td> &lt;?xml version='1.0' encoding='utf-8' standalone='yes' ?&gt;\n&lt;map&gt;\n&lt;int name="PASSADDED" value="10...</td>
    </tr>
    <tr>
      <th>18</th>
      <td> 0:16:00</td>
      <td> write</td>
      <td> /data/data/com.gmail.xpack/shared_prefs/MainPref.xml</td>
      <td> &lt;?xml version='1.0' encoding='utf-8' standalone='yes' ?&gt;\n&lt;map&gt;\n&lt;int name="PASSADDED" value="10...</td>
    </tr>
    <tr>
      <th>19</th>
      <td> 0:16:01</td>
      <td> write</td>
      <td> /data/data/com.gmail.xpack/shared_prefs/MainPref.xml</td>
      <td> &lt;?xml version='1.0' encoding='utf-8' standalone='yes' ?&gt;\n&lt;map&gt;\n&lt;int name="PASSADDED" value="10...</td>
    </tr>
    <tr>
      <th>20</th>
      <td> 0:16:10</td>
      <td>  read</td>
      <td>                                      /proc/wakelocks</td>
      <td> name\tcount\texpire_count\twake_count\tactive_since\ttotal_time\tsleep_time\tmax_time\tlast_chan...</td>
    </tr>
  </tbody>
</table>
</div>



## Network activities

### Opened connections (opennet)


```
# <!-- collapse=True -->
# Convert timestamps to human readable time delta
timestamps = [str(datetime.timedelta(seconds=(round(float(i.encode("utf-8")))))) for i in result['opennet'].keys()]

# Create list of accessed files entries
open_net = [i[1] for i in result['opennet'].items()]

# Create dataframe
df_opennet = pd.DataFrame(open_net, index=timestamps)
df_opennet.sort(inplace=True)
df_opennet.index.name='Timestamp'


#df2table(df_opennet)
#ipy_table.apply_theme('basic')
df_opennet.reset_index()
```




<div style="max-height:1000px;max-width:1500px;overflow:auto;">
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>Timestamp</th>
      <th>desthost</th>
      <th>destport</th>
      <th>fd</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td> 0:00:08</td>
      <td> 80.74.128.17</td>
      <td> 80</td>
      <td> 17</td>
    </tr>
    <tr>
      <th>1</th>
      <td> 0:15:06</td>
      <td> 80.74.128.17</td>
      <td> 80</td>
      <td> 23</td>
    </tr>
    <tr>
      <th>2</th>
      <td> 0:15:36</td>
      <td> 80.74.128.17</td>
      <td> 80</td>
      <td> 28</td>
    </tr>
    <tr>
      <th>3</th>
      <td> 0:16:00</td>
      <td> 80.74.128.17</td>
      <td> 80</td>
      <td> 33</td>
    </tr>
  </tbody>
</table>
</div>



### Sent data (sendnet)

Here you can have a look at the sent data. Again: The POST/GET requests are not fully complete. 


```
# <!-- collapse=True -->
# Convert timestamps to human readable time delta
timestamps = [str(datetime.timedelta(seconds=(round(float(i.encode("utf-8")))))) for i in result['sendnet'].keys()]
# Create list of accessed files entries
send_net = [i[1] for i in result['sendnet'].items()]

# Create dataframe
df_sendnet = pd.DataFrame(send_net, index=timestamps)
df_sendnet.sort(inplace=True)
df_sendnet.index.name='Timestamp'

# Unhexlify data
unhexed_data = [binascii.unhexlify(d) for d in df_sendnet['data']]
df_sendnet['rawdata'] = unhexed_data

#df2table(df_sendnet[['desthost', 'destport', 'fd', 'operation', 'type', 'rawdata']])
#ipy_table.apply_theme('basic')
df_sendnet[['desthost', 'destport', 'fd', 'operation', 'type', 'rawdata']].reset_index()
```




<div style="max-height:1000px;max-width:1500px;overflow:auto;">
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>Timestamp</th>
      <th>desthost</th>
      <th>destport</th>
      <th>fd</th>
      <th>operation</th>
      <th>type</th>
      <th>rawdata</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td> 0:00:08</td>
      <td> 80.74.128.17</td>
      <td> 80</td>
      <td> 17</td>
      <td> send</td>
      <td> net write</td>
      <td> POST /images/1.php HTTP/1.1\r\nUser-agent: Mozilla/4.76 (Java; U;Linux armv7l 2.6.29-gc497e41; r...</td>
    </tr>
    <tr>
      <th>1</th>
      <td> 0:15:06</td>
      <td> 80.74.128.17</td>
      <td> 80</td>
      <td> 23</td>
      <td> send</td>
      <td> net write</td>
      <td> POST /images/1.php HTTP/1.1\r\nUser-agent: Mozilla/4.76 (Java; U;Linux armv7l 2.6.29-gc497e41; r...</td>
    </tr>
    <tr>
      <th>2</th>
      <td> 0:15:36</td>
      <td> 80.74.128.17</td>
      <td> 80</td>
      <td> 28</td>
      <td> send</td>
      <td> net write</td>
      <td> POST /images/1.php HTTP/1.1\r\nUser-agent: Mozilla/4.76 (Java; U;Linux armv7l 2.6.29-gc497e41; r...</td>
    </tr>
    <tr>
      <th>3</th>
      <td> 0:16:00</td>
      <td> 80.74.128.17</td>
      <td> 80</td>
      <td> 33</td>
      <td> send</td>
      <td> net write</td>
      <td> POST /images/1.php HTTP/1.1\r\nUser-agent: Mozilla/4.76 (Java; U;Linux armv7l 2.6.29-gc497e41; r...</td>
    </tr>
  </tbody>
</table>
</div>



### Received data (recvnet)


```
# <!-- collapse=True -->
# Convert timestamps to human readable time delta
timestamps = [str(datetime.timedelta(seconds=(round(float(i.encode("utf-8")))))) for i in result['recvnet'].keys()]

# Create list of accessed files entries
recv_net = [i[1] for i in result['recvnet'].items()]

# Create dataframe
df_recvnet = pd.DataFrame(recv_net, index=timestamps)
df_recvnet.sort(inplace=True)
df_recvnet.index.name='Timestamp'

# Unhexlify data
unhexed_data = [binascii.unhexlify(d) for d in df_recvnet['data']]
df_recvnet['rawdata'] = unhexed_data

#df2table(df_recvnet[['host', 'port', 'type', 'rawdata']])
#ipy_table.apply_theme('basic')
df_recvnet[['host', 'port', 'type', 'rawdata']].reset_index()
```




<div style="max-height:1000px;max-width:1500px;overflow:auto;">
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>Timestamp</th>
      <th>host</th>
      <th>port</th>
      <th>type</th>
      <th>rawdata</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td> 0:00:08</td>
      <td> 80.74.128.17</td>
      <td> 80</td>
      <td> net read</td>
      <td> HTTP/1.1 406 Not Acceptable\r\nDate: Mon, 28 Jul 2014 13:29:38 GMT\r\nServer: Apache\r\nContent-...</td>
    </tr>
    <tr>
      <th>1</th>
      <td> 0:00:08</td>
      <td> 80.74.128.17</td>
      <td> 80</td>
      <td> net read</td>
      <td> x=10\r\nConnection: Keep-Alive\r\nContent-Type: text/html; charset=iso-8859-1\r\n\r\n&lt;!DOCTYPE H...</td>
    </tr>
    <tr>
      <th>2</th>
      <td> 0:15:06</td>
      <td> 80.74.128.17</td>
      <td> 80</td>
      <td> net read</td>
      <td> x=10\r\nConnection: Keep-Alive\r\nContent-Type: text/html; charset=iso-8859-1\r\n\r\n&lt;!DOCTYPE H...</td>
    </tr>
    <tr>
      <th>3</th>
      <td> 0:15:06</td>
      <td> 80.74.128.17</td>
      <td> 80</td>
      <td> net read</td>
      <td> HTTP/1.1 406 Not Acceptable\r\nDate: Mon, 28 Jul 2014 13:44:36 GMT\r\nServer: Apache\r\nContent-...</td>
    </tr>
    <tr>
      <th>4</th>
      <td> 0:15:36</td>
      <td> 80.74.128.17</td>
      <td> 80</td>
      <td> net read</td>
      <td> HTTP/1.1 406 Not Acceptable\r\nDate: Mon, 28 Jul 2014 13:45:06 GMT\r\nServer: Apache\r\nContent-...</td>
    </tr>
    <tr>
      <th>5</th>
      <td> 0:15:36</td>
      <td> 80.74.128.17</td>
      <td> 80</td>
      <td> net read</td>
      <td> x=10\r\nConnection: Keep-Alive\r\nContent-Type: text/html; charset=iso-8859-1\r\n\r\n&lt;!DOCTYPE H...</td>
    </tr>
    <tr>
      <th>6</th>
      <td> 0:16:00</td>
      <td> 80.74.128.17</td>
      <td> 80</td>
      <td> net read</td>
      <td> HTTP/1.1 406 Not Acceptable\r\nDate: Mon, 28 Jul 2014 13:45:30 GMT\r\nServer: Apache\r\nContent-...</td>
    </tr>
    <tr>
      <th>7</th>
      <td> 0:16:00</td>
      <td> 80.74.128.17</td>
      <td> 80</td>
      <td> net read</td>
      <td> x=10\r\nConnection: Keep-Alive\r\nContent-Type: text/html; charset=iso-8859-1\r\n\r\n&lt;!DOCTYPE H...</td>
    </tr>
  </tbody>
</table>
</div>



## Requests sequence

Since I was not able to get the full contents of the POST/GET requests (and their equivalent responses), I had to rely on the information found [here](http://www.apk-analyzer.net/analysis/646/3752/0/html). Below is a short sequence diagramm describing the general process of the communication. Keep in mind that the sequence only tries to give you a short overview of the data exchange between the process and the webserver. 


```
%%seqdiag
# <!-- collapse=True -->
seqdiag {
  application  -> citroen-club.ch [label = "POST /images/1.php HTTP/1.1"];
  application <-- citroen-club.ch [label = "HTTP/1.1 406 Not Acceptable", leftnote= ""];
  application --> best-invest-int.com [label = "POST /gallery/3.php HTTP/1.1", note = "POST data=U2ltU3RhdGUgPSBOT1QgUkVBRFkgCg%3D%3D%0A&rid=25"];
  application <-- best-invest-int.com [label = "HTTP/1.1 403 Forbidden"];
  application --> best-invest-int.com [label = "POST /gallery/4.php HTTP/1.1", note = "POST data=U2ltU3RhdGUgPSBOT1QgUkVBRFkgCg%3D%3D%0A&LogCode=CONF&LogText=Get+config+data+from+server"];
  application <-- best-invest-int.com [label = "HTTP/1.1 403 Forbidden"];
  application --> best-invest-int.com [label = "POST /gallery/4.php HTTP/1.1", note = "POST data=U2ltU3RhdGUgPSBOT1QgUkVBRFkgCg%3D%3D%0A&LogCode=DATA&LogText=Send+data+to+server&"];
  application <-- best-invest-int.com [label = "..."];
}

```


    
![png](/posts/img/2014/android-dynamic-code-analysis-mastering-droidbox/output_44_0.png)
    


And now a complete request/response pair:

**Request**:

~~~ 
POST /gallery/4.php HTTP/1.1
User-agent: Mozilla/4.76 (Java; U;Linux i686 3.0.36-android-x86-eeepc+; ru; The Android Project 0)
Content-Type: application/x-www-form-urlencoded; charset=UTF-8
Pragma: no-cache
Host: best-invest-int.com
Connection: Keep-Alive
Accept-Encoding: gzip
Content-Length: 86
Data Raw: 64 61 74 61 3d 55 32 6c 74 55 33 52 68 64 47 55 67 50 53 42 4f 54 31 51 67 55 6b 56 42 52 46 6b 67 43 67 25 33 44 25 33 44 25 30 41 26 4c 6f 67 43 6f 64 65 3d 43 4f 4e 46 26 4c 6f 67 54 65 78 74 3d 43 68 65 63 6b 2b 70 75 6c 6c 2b 6f 66 66 2b 75 72 6c 73 26 
Data Ascii: data=U2ltU3RhdGUgPSBOT1QgUkVBRFkgCg%3D%3D%0A&LogCode=CONF&LogText=Check+pull+off+urls&
~~~

**Response**:

~~~
HTTP/1.1 403 Forbidden
Date: Thu, 21 Nov 2013 12:37:26 GMT
Server: Apache/2.2.3 (CentOS)
Content-Length: 299
Connection: close
Content-Type: text/html; charset=iso-8859-1

<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN"><html><head><title>403 Forbidden</title></head><body><h1>Forbidden</h1><p>You don't have permission to access /gallery/4.phpon this server.</p><hr><address>Apache/2.2.3 (CentOS) Server at best-invest-int.com Port 80</address></body></html>
~~~

## Crypto activities


```
# <!-- collapse=True -->
# Convert timestamps to human readable time delta
timestamps = [str(datetime.timedelta(seconds=(round(float(i.encode("utf-8")))))) for i in result['cryptousage'].keys()]

# Create list of accessed files entries
crypto_usage = [i[1] for i in result['cryptousage'].items()]

# Create dataframe
df_cryptousage = pd.DataFrame(crypto_usage, index=timestamps)
df_cryptousage.sort(inplace=True)
df_cryptousage.index.name='Timestamp'

# Unhexlify data
#unhexed_data = [binascii.unhexlify(d) for d in df_recvnet['data']]
#df_recvnet['rawdata'] = unhexed_data

#df_recvnet[['host', 'port', 'type', 'rawdata']]
df_cryptousage.reset_index()
```




<div style="max-height:1000px;max-width:1500px;overflow:auto;">
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>Timestamp</th>
      <th>algorithm</th>
      <th>key</th>
      <th>operation</th>
      <th>type</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td> 0:00:09</td>
      <td> Blowfish</td>
      <td> 52, 101, 54, 54, 55, 54, 54, 101, 54, 98, 54, 97, 54, 99, 54, 101, 55, 54, 54, 98, 54, 97, 52, 9...</td>
      <td> keyalgo</td>
      <td> crypto</td>
    </tr>
    <tr>
      <th>1</th>
      <td> 0:15:06</td>
      <td> Blowfish</td>
      <td> 52, 101, 54, 54, 55, 54, 54, 101, 54, 98, 54, 97, 54, 99, 54, 101, 55, 54, 54, 98, 54, 97, 52, 9...</td>
      <td> keyalgo</td>
      <td> crypto</td>
    </tr>
    <tr>
      <th>2</th>
      <td> 0:15:36</td>
      <td> Blowfish</td>
      <td> 52, 101, 54, 54, 55, 54, 54, 101, 54, 98, 54, 97, 54, 99, 54, 101, 55, 54, 54, 98, 54, 97, 52, 9...</td>
      <td> keyalgo</td>
      <td> crypto</td>
    </tr>
    <tr>
      <th>3</th>
      <td> 0:16:00</td>
      <td> Blowfish</td>
      <td> 52, 101, 54, 54, 55, 54, 54, 101, 54, 98, 54, 97, 54, 99, 54, 101, 55, 54, 54, 98, 54, 97, 52, 9...</td>
      <td> keyalgo</td>
      <td> crypto</td>
    </tr>
  </tbody>
</table>
</div>



## Activities chart

Now let's have a look in which *order* the several activities took place. Below you'll find a table containing the timestamp, operation and category of each specific activity (e.g. file system access, network read/write etc.)


```
# <!-- collapse=True -->
# Create df
df_activities = pd.DataFrame(columns=[['Timestamp', 'Operation', 'Category']])

# file system access
accessed_files = df_accessedfiles.reset_index()[[0,3]]
accessed_files['Category'] = "file system"
accessed_files.columns = ['Timestamp', 'Operation', 'Category']

# network activities
network_open = df_opennet.reset_index()[[0]]
network_open['Operation'] = 'net open'
network_open['Category'] = 'network'
network_open.columns = ['Timestamp', 'Operation', 'Category']

network_sent = df_sendnet.reset_index()[[0,6]]
network_sent['Category'] = "network"
network_sent.columns = ['Timestamp', 'Operation', 'Category']

network_recv = df_recvnet.reset_index()[[0,4]]
network_recv['Category'] = "network"
network_recv.columns = ['Timestamp', 'Operation', 'Category']

# crpyto usage
crypto_usage = df_cryptousage.reset_index()[[0,1]]
crypto_usage['Category'] = "crypto"
crypto_usage.columns = ['Timestamp', 'Operation', 'Category']

# Merge data frames
df_activities = pd.concat([accessed_files, network_open, network_sent, network_recv, crypto_usage], ignore_index=True)
df_activities.sort('Timestamp', inplace=True)

# Convert to JSON
d = df_activities.to_json(orient='records')
json_data = json.dumps(json.loads(d), ensure_ascii=False).encode("utf-8")

df_activities
```




<div style="max-height:1000px;max-width:1500px;overflow:auto;">
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>Timestamp</th>
      <th>Operation</th>
      <th>Category</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0 </th>
      <td> 0:00:03</td>
      <td>      read</td>
      <td> file system</td>
    </tr>
    <tr>
      <th>1 </th>
      <td> 0:00:04</td>
      <td>      read</td>
      <td> file system</td>
    </tr>
    <tr>
      <th>2 </th>
      <td> 0:00:04</td>
      <td>      read</td>
      <td> file system</td>
    </tr>
    <tr>
      <th>3 </th>
      <td> 0:00:08</td>
      <td>      read</td>
      <td> file system</td>
    </tr>
    <tr>
      <th>21</th>
      <td> 0:00:08</td>
      <td>  net open</td>
      <td>     network</td>
    </tr>
    <tr>
      <th>25</th>
      <td> 0:00:08</td>
      <td> net write</td>
      <td>     network</td>
    </tr>
    <tr>
      <th>29</th>
      <td> 0:00:08</td>
      <td>  net read</td>
      <td>     network</td>
    </tr>
    <tr>
      <th>30</th>
      <td> 0:00:08</td>
      <td>  net read</td>
      <td>     network</td>
    </tr>
    <tr>
      <th>4 </th>
      <td> 0:00:09</td>
      <td>     write</td>
      <td> file system</td>
    </tr>
    <tr>
      <th>37</th>
      <td> 0:00:09</td>
      <td>  Blowfish</td>
      <td>      crypto</td>
    </tr>
    <tr>
      <th>5 </th>
      <td> 0:00:10</td>
      <td>     write</td>
      <td> file system</td>
    </tr>
    <tr>
      <th>6 </th>
      <td> 0:00:10</td>
      <td>      read</td>
      <td> file system</td>
    </tr>
    <tr>
      <th>7 </th>
      <td> 0:00:36</td>
      <td>     write</td>
      <td> file system</td>
    </tr>
    <tr>
      <th>8 </th>
      <td> 0:00:36</td>
      <td>      read</td>
      <td> file system</td>
    </tr>
    <tr>
      <th>9 </th>
      <td> 0:01:05</td>
      <td>      read</td>
      <td> file system</td>
    </tr>
    <tr>
      <th>10</th>
      <td> 0:15:06</td>
      <td>     write</td>
      <td> file system</td>
    </tr>
    <tr>
      <th>11</th>
      <td> 0:15:06</td>
      <td>     write</td>
      <td> file system</td>
    </tr>
    <tr>
      <th>22</th>
      <td> 0:15:06</td>
      <td>  net open</td>
      <td>     network</td>
    </tr>
    <tr>
      <th>26</th>
      <td> 0:15:06</td>
      <td> net write</td>
      <td>     network</td>
    </tr>
    <tr>
      <th>31</th>
      <td> 0:15:06</td>
      <td>  net read</td>
      <td>     network</td>
    </tr>
    <tr>
      <th>32</th>
      <td> 0:15:06</td>
      <td>  net read</td>
      <td>     network</td>
    </tr>
    <tr>
      <th>38</th>
      <td> 0:15:06</td>
      <td>  Blowfish</td>
      <td>      crypto</td>
    </tr>
    <tr>
      <th>12</th>
      <td> 0:15:24</td>
      <td>      read</td>
      <td> file system</td>
    </tr>
    <tr>
      <th>13</th>
      <td> 0:15:27</td>
      <td>      read</td>
      <td> file system</td>
    </tr>
    <tr>
      <th>14</th>
      <td> 0:15:35</td>
      <td>      read</td>
      <td> file system</td>
    </tr>
    <tr>
      <th>23</th>
      <td> 0:15:36</td>
      <td>  net open</td>
      <td>     network</td>
    </tr>
    <tr>
      <th>27</th>
      <td> 0:15:36</td>
      <td> net write</td>
      <td>     network</td>
    </tr>
    <tr>
      <th>33</th>
      <td> 0:15:36</td>
      <td>  net read</td>
      <td>     network</td>
    </tr>
    <tr>
      <th>34</th>
      <td> 0:15:36</td>
      <td>  net read</td>
      <td>     network</td>
    </tr>
    <tr>
      <th>39</th>
      <td> 0:15:36</td>
      <td>  Blowfish</td>
      <td>      crypto</td>
    </tr>
    <tr>
      <th>15</th>
      <td> 0:15:37</td>
      <td>     write</td>
      <td> file system</td>
    </tr>
    <tr>
      <th>16</th>
      <td> 0:15:37</td>
      <td>     write</td>
      <td> file system</td>
    </tr>
    <tr>
      <th>17</th>
      <td> 0:15:58</td>
      <td>      read</td>
      <td> file system</td>
    </tr>
    <tr>
      <th>18</th>
      <td> 0:16:00</td>
      <td>     write</td>
      <td> file system</td>
    </tr>
    <tr>
      <th>24</th>
      <td> 0:16:00</td>
      <td>  net open</td>
      <td>     network</td>
    </tr>
    <tr>
      <th>28</th>
      <td> 0:16:00</td>
      <td> net write</td>
      <td>     network</td>
    </tr>
    <tr>
      <th>35</th>
      <td> 0:16:00</td>
      <td>  net read</td>
      <td>     network</td>
    </tr>
    <tr>
      <th>36</th>
      <td> 0:16:00</td>
      <td>  net read</td>
      <td>     network</td>
    </tr>
    <tr>
      <th>40</th>
      <td> 0:16:00</td>
      <td>  Blowfish</td>
      <td>      crypto</td>
    </tr>
    <tr>
      <th>19</th>
      <td> 0:16:01</td>
      <td>     write</td>
      <td> file system</td>
    </tr>
    <tr>
      <th>20</th>
      <td> 0:16:10</td>
      <td>      read</td>
      <td> file system</td>
    </tr>
  </tbody>
</table>
</div>



A fancier overview ... 


```
%%jinja html
<!-- collapse=True -->
<html>
<head>
  <script src="http://d3js.org/d3.v3.min.js"></script>
  <script src="http://dimplejs.org/dist/dimple.v2.1.0.min.js"></script>
<title>{{ title }}</title>
</head>
<body>
<div id="bar_chart"></div>
  <script type="text/javascript">
    var json_data  = {{ json_data }};
    var svg = dimple.newSvg("#bar_chart", 800, 800);
    var myChart = new dimple.chart(svg, json_data);
    myChart.setBounds(150, 50, 700, 680)
    myChart.addCategoryAxis("x", ["Category", "Operation"]);
    myChart.addCategoryAxis("y", "Timestamp");
    myChart.addSeries("Operation", dimple.plot.bar);
    myChart.addLegend(170, 10, 630, 20, "right");
    myChart.draw();
  </script>
</body>
</html>
```




<!-- collapse=True -->
<html>
<head>
  <script src="http://d3js.org/d3.v3.min.js"></script>
  <script src="http://dimplejs.org/dist/dimple.v2.1.0.min.js"></script>
<title></title>
</head>
<body>
<div id="bar_chart"></div>
  <script type="text/javascript">
    var json_data  = [{"Category": "file system", "Timestamp": "0:00:03", "Operation": "read"}, {"Category": "file system", "Timestamp": "0:00:04", "Operation": "read"}, {"Category": "file system", "Timestamp": "0:00:04", "Operation": "read"}, {"Category": "file system", "Timestamp": "0:00:08", "Operation": "read"}, {"Category": "network", "Timestamp": "0:00:08", "Operation": "net open"}, {"Category": "network", "Timestamp": "0:00:08", "Operation": "net write"}, {"Category": "network", "Timestamp": "0:00:08", "Operation": "net read"}, {"Category": "network", "Timestamp": "0:00:08", "Operation": "net read"}, {"Category": "file system", "Timestamp": "0:00:09", "Operation": "write"}, {"Category": "crypto", "Timestamp": "0:00:09", "Operation": "Blowfish"}, {"Category": "file system", "Timestamp": "0:00:10", "Operation": "write"}, {"Category": "file system", "Timestamp": "0:00:10", "Operation": "read"}, {"Category": "file system", "Timestamp": "0:00:36", "Operation": "write"}, {"Category": "file system", "Timestamp": "0:00:36", "Operation": "read"}, {"Category": "file system", "Timestamp": "0:01:05", "Operation": "read"}, {"Category": "file system", "Timestamp": "0:15:06", "Operation": "write"}, {"Category": "file system", "Timestamp": "0:15:06", "Operation": "write"}, {"Category": "network", "Timestamp": "0:15:06", "Operation": "net open"}, {"Category": "network", "Timestamp": "0:15:06", "Operation": "net write"}, {"Category": "network", "Timestamp": "0:15:06", "Operation": "net read"}, {"Category": "network", "Timestamp": "0:15:06", "Operation": "net read"}, {"Category": "crypto", "Timestamp": "0:15:06", "Operation": "Blowfish"}, {"Category": "file system", "Timestamp": "0:15:24", "Operation": "read"}, {"Category": "file system", "Timestamp": "0:15:27", "Operation": "read"}, {"Category": "file system", "Timestamp": "0:15:35", "Operation": "read"}, {"Category": "network", "Timestamp": "0:15:36", "Operation": "net open"}, {"Category": "network", "Timestamp": "0:15:36", "Operation": "net write"}, {"Category": "network", "Timestamp": "0:15:36", "Operation": "net read"}, {"Category": "network", "Timestamp": "0:15:36", "Operation": "net read"}, {"Category": "crypto", "Timestamp": "0:15:36", "Operation": "Blowfish"}, {"Category": "file system", "Timestamp": "0:15:37", "Operation": "write"}, {"Category": "file system", "Timestamp": "0:15:37", "Operation": "write"}, {"Category": "file system", "Timestamp": "0:15:58", "Operation": "read"}, {"Category": "file system", "Timestamp": "0:16:00", "Operation": "write"}, {"Category": "network", "Timestamp": "0:16:00", "Operation": "net open"}, {"Category": "network", "Timestamp": "0:16:00", "Operation": "net write"}, {"Category": "network", "Timestamp": "0:16:00", "Operation": "net read"}, {"Category": "network", "Timestamp": "0:16:00", "Operation": "net read"}, {"Category": "crypto", "Timestamp": "0:16:00", "Operation": "Blowfish"}, {"Category": "file system", "Timestamp": "0:16:01", "Operation": "write"}, {"Category": "file system", "Timestamp": "0:16:10", "Operation": "read"}];
    var svg = dimple.newSvg("#bar_chart", 800, 800);
    var myChart = new dimple.chart(svg, json_data);
    myChart.setBounds(150, 50, 700, 680)
    myChart.addCategoryAxis("x", ["Category", "Operation"]);
    myChart.addCategoryAxis("y", "Timestamp");
    myChart.addSeries("Operation", dimple.plot.bar);
    myChart.addLegend(170, 10, 630, 20, "right");
    myChart.draw();
  </script>
</body>
</html>



A few **observations**:

* file system access (both read and write) are taking place all the time
* the crypto routines are apparently involved when sending data over internet or receiving data

## Conclusion

I think `DroidBox` is a very good tool to deal with Android APKs and analyze their behaviour during run-time. It comes with a working mobile sandbox meant to inspect and monitor an applications activities. However during my analysis I had to rely on previous analysis since the results didn't contain the full details. Not only the network traffic but also the contents read from files weren't complete. In order to fully unterstand one malware I need complete details about its behaviour.  For example I had following response from the server which is completely useless:

~~~
HTTP/1.1 406 Not Acceptable\r\nDate: Mon, 28 Jul 2014 13:29:38 GMT\r\nServer: Apache\r\nContent-...
~~~

Besides that I was indeed able to see that the application is reading from some file. But the delivered content was once again striped:

~~~
<?xml version='1.0' encoding='utf-8' standalone='yes' ?>\n<map>\n<string name="DOWNLOADDOMAIN">c...
~~~

I hope the developers will see this as a vital necessity and update as soon as possible. Furthermore I'll look forward to other mobile sandboxes which have data instrumentation capabilities. Next time I'll have a deeper look at Androids [DDMS](http://developer.android.com/tools/debugging/ddms.html).
