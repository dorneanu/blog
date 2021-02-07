+++
title = "24h Android sniffing using tcpdump - IPython Notebook Version"
date = "2014-01-23"
tags = ["android", "hacking", "networking", "security", "appsec", "python", "ipython", "iptables", "sqlite", "google"]
category = "blog"
+++

# Motivation

I've started this little project since I was mainly interested in the data my smartphone is sending all the time without my knowledge. I have a bunch of apps installed on my phone and I have absolutely no ideea which (kind of) data is beeing transfered to the Internet all day long. I thought I'd be a great ideea to monitor/sniff my data interface (3G, Edge etc. NOT Wifi) for 24h during my normal daily phone usage.

# Sniff environment

I've used my Samsung Note 1 (GT N7000) as sniffing device. At the moment I use a customized ROM (slimbean) with root access. In order to be to use sniffing tools on my phone I had to work in a chrooted environment like "Debian on Android". This way I was given access to phones data interfaces and I was ready to go. 

    u0_a99@android:/ $ deb
    e2fsck 1.41.11 (14-Mar-2010)
    /storage/sdcard1/debian-kit/debian.img: recovering journal
    /storage/sdcard1/debian-kit/debian.img: clean, 55210/170752 files, 426942/512000 blocks
    root@debian-on-android:/# ifconfig -a
    ...
    rmnet0    Link encap:Point-to-Point Protocol  
          POINTOPOINT NOARP MULTICAST  MTU:1500  Metric:1
          RX packets:37490 errors:0 dropped:0 overruns:0 frame:0
          TX packets:30841 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000 
          RX bytes:34233580 (32.6 MiB)  TX bytes:5906191 (5.6 MiB)



Initially I wanted to use tshark for the sniffing part but it didn't work quite well. So I came back to old school tcpdump.
Since my data interface was going done all the time I had to make sure that tcpdump was restarted as soon as the data interface was online again. I used the following script:

    root@debian-on-android:~# cat monitor.sh 
    #!/bin/bash

    DATE=`date +"%Y-%m-%d-%s"`

    while true; 
    do 
        tcpdump -i rmnet0 -np -w output-`date +"%Y-%m-%d-%s"`.pcap; sleep 10 
    done

I've fired up my script and after 24 hours I had these outputs:

    root@debian-on-android:~# ls -l output-2014-01-1*
    -rw-r--r--. 1 root root    24907 Jan 18 12:53 output-2014-01-18-1390049466.pcap
    -rw-r--r--. 1 root root     2881 Jan 18 12:55 output-2014-01-18-1390049736.pcap
    -rw-r--r--. 1 root root 14963016 Jan 18 14:02 output-2014-01-18-1390049777.pcap
    -rw-r--r--. 1 root root 54695690 Jan 19 14:03 output-2014-01-18-1390053867.pcap
    -rw-r--r--. 1 root root 12492822 Jan 19 16:27 output-2014-01-19-1390140216.pcap
    root@debian-on-android:~# 


# Merge pcap files
```
$ mergecap -F libpcap -a output-* -w merged.pcap
```
# Convert pcap to SQLite3 DB


```
PCAP_FILE = "/home/victor/work/Projects/24h-Android-Monitoring/pcap/merged.pcap"

# Tshark generated files
DNS_QUERIES  = "/home/victor/work/Projects/24h-Android-Monitoring/pcap/dns_queries.csv"
CONNECTIONS  = "/home/victor/work/Projects/24h-Android-Monitoring/pcap/connections.csv"
HTTP_TRAFFIC = "/home/victor/work/Projects/24h-Android-Monitoring/pcap/http_traffic.csv"
```


```

```

# Extract valuable information from pcap file


```
dns_queries = !tshark -r $PCAP_FILE  -R "dns.flags.response == 1"  -E occurrence=f -E header=y \
              -T fields  -e frame.number -e frame.time -e dns.qry.name -e dns.resp.addr > $DNS_QUERIES
    
connections = !tshark -r $PCAP_FILE -E header=y -E separator=\; -T fields -e frame.number \
              -e frame.time -e ip.src -e ip.dst -e tcp.dstport -e frame.protocols > $CONNECTIONS

http_traffic = !tshark -r $PCAP_FILE -Y "http.request" -E header=y -T fields \
              -e frame.number -e frame.time -e ip.dst -e http.request.method -e http.request.uri -e http.user_agent \
              -e http.response.code  -e http.response.phrase -e http.content_length -e data -e text > $HTTP_TRAFFIC
```


```

```


```
import sqlite3 as sql
con = sql.connect(":memory:")
cur = con.cursor()
```


```

```


```
import binascii
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import pandas.io.sql as pdsql 

# Pandas settings
pd.set_option('display.height', 500)
pd.set_option('display.max_rows', 500)
pd.set_option('display.max_columns', 500)
pd.set_option('display.width', 500)
pd.set_option('display.max_colwidth', 1000)

# Useful functions
def hex2str(s):
    if str(s) == 'nan':
        return None
    else:
        return bytes.fromhex(str(s)).decode('utf-8')
    
# Import DNS queries
dns_df = pd.read_table(DNS_QUERIES)
dns_df.columns = ['frame_number', 'frame_time', 'dns_query', 'dns_response']

# Import connections
con_df = pd.read_table(CONNECTIONS, sep=";")
con_df.columns = ['frame_number', 'frame_time', 'src', 'dst', 'dstport', 'frame_protocols']

# Import http traffic
http_df = pd.read_table(HTTP_TRAFFIC)
http_df.columns = ['frame_number', 'frame_time', 'ip_dst','request_method', 'request_uri', 'user_agent','response_code', 'response_phrase','content_length', 'data', 'text']

# Convert data (hex) to ascii
convert_data = lambda x: hex2str(x)
http_df['data'] = http_df['data'].apply(convert_data)


# Write to SQLite
pdsql.write_frame(dns_df, name="dns", con=con, if_exists="delete")
pdsql.write_frame(con_df, name="connection", con=con, if_exists="delete")
pdsql.write_frame(http_df, name="http", con=con, if_exists="delete")

dns_df.head(5)

#p2 = pdsql.read_frame("""SELECT COUNT(dns_response), dns_query FROM dns""", cnx)
#p2

# Count unique values
#unique_dns = dns_df.groupby('DNS Query')['DNS Response'].nunique().reset_index()
#unique_dns.columns = ['DNS', '# DNS Queries']
#unique_dns.sort(['# DNS Queries'], ascending=False).head(10)
```




<div style="max-height:1000px;max-width:1500px;overflow:auto;">
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>frame_number</th>
      <th>frame_time</th>
      <th>dns_query</th>
      <th>dns_response</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>  4</td>
      <td> Jan 18, 2014 13:52:43.079188000</td>
      <td> clients3.google.com</td>
      <td> 173.194.70.138</td>
    </tr>
    <tr>
      <th>1</th>
      <td>  5</td>
      <td> Jan 18, 2014 13:52:43.079389000</td>
      <td> orcart.facebook.com</td>
      <td>  69.171.248.65</td>
    </tr>
    <tr>
      <th>2</th>
      <td> 29</td>
      <td> Jan 18, 2014 13:52:43.775665000</td>
      <td>    mtalk.google.com</td>
      <td> 173.194.70.188</td>
    </tr>
    <tr>
      <th>3</th>
      <td> 71</td>
      <td> Jan 18, 2014 13:52:46.433026000</td>
      <td>      push.parse.com</td>
      <td>   23.22.41.206</td>
    </tr>
    <tr>
      <th>4</th>
      <td> 82</td>
      <td> Jan 18, 2014 13:52:47.243004000</td>
      <td>    e16.whatsapp.net</td>
      <td>   50.22.225.86</td>
    </tr>
  </tbody>
</table>
</div>




```

```


```

```

# Top DNS queries


```
p1 = pdsql.read_frame("""
    SELECT COUNT(dns_response) AS '# DNS Responses', dns_query AS 'DNS to lookup' 
    FROM dns GROUP BY dns_query 
    ORDER by 1 DESC
""", con)
#print(p1.head(100).to_string())
p1.head(100)
```




<div style="max-height:1000px;max-width:1500px;overflow:auto;">
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th># DNS Responses</th>
      <th>DNS to lookup</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0 </th>
      <td> 670</td>
      <td>           graph.facebook.com</td>
    </tr>
    <tr>
      <th>1 </th>
      <td> 535</td>
      <td>               www.google.com</td>
    </tr>
    <tr>
      <th>2 </th>
      <td> 435</td>
      <td>          orcart.facebook.com</td>
    </tr>
    <tr>
      <th>3 </th>
      <td> 360</td>
      <td>       android.googleapis.com</td>
    </tr>
    <tr>
      <th>4 </th>
      <td> 340</td>
      <td>           www.googleapis.com</td>
    </tr>
    <tr>
      <th>5 </th>
      <td> 295</td>
      <td>         fbprod.flipboard.com</td>
    </tr>
    <tr>
      <th>6 </th>
      <td> 245</td>
      <td>   android.clients.google.com</td>
    </tr>
    <tr>
      <th>7 </th>
      <td> 190</td>
      <td>             ad.flipboard.com</td>
    </tr>
    <tr>
      <th>8 </th>
      <td> 165</td>
      <td>               push.parse.com</td>
    </tr>
    <tr>
      <th>9 </th>
      <td> 155</td>
      <td>          play.googleapis.com</td>
    </tr>
    <tr>
      <th>10</th>
      <td> 150</td>
      <td>            cdn.flipboard.com</td>
    </tr>
    <tr>
      <th>11</th>
      <td> 130</td>
      <td>        apresolve.spotify.com</td>
    </tr>
    <tr>
      <th>12</th>
      <td> 120</td>
      <td>                www.google.de</td>
    </tr>
    <tr>
      <th>13</th>
      <td> 115</td>
      <td>           b-api.facebook.com</td>
    </tr>
    <tr>
      <th>14</th>
      <td>  80</td>
      <td>                pbs.twimg.com</td>
    </tr>
    <tr>
      <th>15</th>
      <td>  75</td>
      <td>          ticks2.bugsense.com</td>
    </tr>
    <tr>
      <th>16</th>
      <td>  70</td>
      <td>     settings.crashlytics.com</td>
    </tr>
    <tr>
      <th>17</th>
      <td>  60</td>
      <td>             www.theverge.com</td>
    </tr>
    <tr>
      <th>18</th>
      <td>  55</td>
      <td>                e.apsalar.com</td>
    </tr>
    <tr>
      <th>19</th>
      <td>  55</td>
      <td>                  twitter.com</td>
    </tr>
    <tr>
      <th>20</th>
      <td>  50</td>
      <td>                 i1.ytimg.com</td>
    </tr>
    <tr>
      <th>21</th>
      <td>  50</td>
      <td>      polpix.sueddeutsche.com</td>
    </tr>
    <tr>
      <th>22</th>
      <td>  45</td>
      <td>              bilder1.n-tv.de</td>
    </tr>
    <tr>
      <th>23</th>
      <td>  45</td>
      <td>            feeds.reuters.com</td>
    </tr>
    <tr>
      <th>24</th>
      <td>  45</td>
      <td>            www.tagesschau.de</td>
    </tr>
    <tr>
      <th>25</th>
      <td>  40</td>
      <td>           mobile.twitter.com</td>
    </tr>
    <tr>
      <th>26</th>
      <td>  40</td>
      <td>             mtalk.google.com</td>
    </tr>
    <tr>
      <th>27</th>
      <td>  40</td>
      <td>     s2.googleusercontent.com</td>
    </tr>
    <tr>
      <th>28</th>
      <td>  40</td>
      <td>     www.googleadservices.com</td>
    </tr>
    <tr>
      <th>29</th>
      <td>  35</td>
      <td>              bilder2.n-tv.de</td>
    </tr>
    <tr>
      <th>30</th>
      <td>  35</td>
      <td>              bilder3.n-tv.de</td>
    </tr>
    <tr>
      <th>31</th>
      <td>  35</td>
      <td>              bilder4.n-tv.de</td>
    </tr>
    <tr>
      <th>32</th>
      <td>  35</td>
      <td>        ecx.images-amazon.com</td>
    </tr>
    <tr>
      <th>33</th>
      <td>  30</td>
      <td>              cdn1.spiegel.de</td>
    </tr>
    <tr>
      <th>34</th>
      <td>  30</td>
      <td>              cdn2.spiegel.de</td>
    </tr>
    <tr>
      <th>35</th>
      <td>  30</td>
      <td>            e.crashlytics.com</td>
    </tr>
    <tr>
      <th>36</th>
      <td>  30</td>
      <td>        weather.yahooapis.com</td>
    </tr>
    <tr>
      <th>37</th>
      <td>  30</td>
      <td>               www.amazon.com</td>
    </tr>
    <tr>
      <th>38</th>
      <td>  25</td>
      <td>              api.twitter.com</td>
    </tr>
    <tr>
      <th>39</th>
      <td>  25</td>
      <td>          clients4.google.com</td>
    </tr>
    <tr>
      <th>40</th>
      <td>  25</td>
      <td>             e12.whatsapp.net</td>
    </tr>
    <tr>
      <th>41</th>
      <td>  25</td>
      <td>             e16.whatsapp.net</td>
    </tr>
    <tr>
      <th>42</th>
      <td>  25</td>
      <td>              e4.whatsapp.net</td>
    </tr>
    <tr>
      <th>43</th>
      <td>  25</td>
      <td>     mobile.smartadserver.com</td>
    </tr>
    <tr>
      <th>44</th>
      <td>  25</td>
      <td>        photos-d.ak.fbcdn.net</td>
    </tr>
    <tr>
      <th>45</th>
      <td>  25</td>
      <td>      scontent-a.xx.fbcdn.net</td>
    </tr>
    <tr>
      <th>46</th>
      <td>  25</td>
      <td>             www.facebook.com</td>
    </tr>
    <tr>
      <th>47</th>
      <td>  25</td>
      <td>       www.fahrinfo-berlin.de</td>
    </tr>
    <tr>
      <th>48</th>
      <td>  25</td>
      <td>     www.google-analytics.com</td>
    </tr>
    <tr>
      <th>49</th>
      <td>  20</td>
      <td>              apis.google.com</td>
    </tr>
    <tr>
      <th>50</th>
      <td>  20</td>
      <td>              cdn3.spiegel.de</td>
    </tr>
    <tr>
      <th>51</th>
      <td>  20</td>
      <td>              cdn4.spiegel.de</td>
    </tr>
    <tr>
      <th>52</th>
      <td>  20</td>
      <td>              de.sitestat.com</td>
    </tr>
    <tr>
      <th>53</th>
      <td>  20</td>
      <td>             e10.whatsapp.net</td>
    </tr>
    <tr>
      <th>54</th>
      <td>  20</td>
      <td>             e11.whatsapp.net</td>
    </tr>
    <tr>
      <th>55</th>
      <td>  20</td>
      <td>             e13.whatsapp.net</td>
    </tr>
    <tr>
      <th>56</th>
      <td>  20</td>
      <td>              e3.whatsapp.net</td>
    </tr>
    <tr>
      <th>57</th>
      <td>  20</td>
      <td>              e9.whatsapp.net</td>
    </tr>
    <tr>
      <th>58</th>
      <td>  20</td>
      <td> fbcdn-profile-a.akamaihd.net</td>
    </tr>
    <tr>
      <th>59</th>
      <td>  20</td>
      <td>  googleads.g.doubleclick.net</td>
    </tr>
    <tr>
      <th>60</th>
      <td>  20</td>
      <td>               gwp.nuggad.net</td>
    </tr>
    <tr>
      <th>61</th>
      <td>  20</td>
      <td>               imap.gmail.com</td>
    </tr>
    <tr>
      <th>62</th>
      <td>  20</td>
      <td>                  img.welt.de</td>
    </tr>
    <tr>
      <th>63</th>
      <td>  20</td>
      <td>               media0.faz.net</td>
    </tr>
    <tr>
      <th>64</th>
      <td>  20</td>
      <td>  oauth.googleusercontent.com</td>
    </tr>
    <tr>
      <th>65</th>
      <td>  20</td>
      <td>                  p5.focus.de</td>
    </tr>
    <tr>
      <th>66</th>
      <td>  20</td>
      <td>               script.ioam.de</td>
    </tr>
    <tr>
      <th>67</th>
      <td>  20</td>
      <td>              ssl.gstatic.com</td>
    </tr>
    <tr>
      <th>68</th>
      <td>  20</td>
      <td>                 www.golem.de</td>
    </tr>
    <tr>
      <th>69</th>
      <td>  15</td>
      <td>          accounts.google.com</td>
    </tr>
    <tr>
      <th>70</th>
      <td>  15</td>
      <td>             api.facebook.com</td>
    </tr>
    <tr>
      <th>71</th>
      <td>  15</td>
      <td>               api.tunigo.com</td>
    </tr>
    <tr>
      <th>72</th>
      <td>  15</td>
      <td>          cdn.api.twitter.com</td>
    </tr>
    <tr>
      <th>73</th>
      <td>  15</td>
      <td>         connect.facebook.net</td>
    </tr>
    <tr>
      <th>74</th>
      <td>  15</td>
      <td>                   de.ioam.de</td>
    </tr>
    <tr>
      <th>75</th>
      <td>  15</td>
      <td>                dl.google.com</td>
    </tr>
    <tr>
      <th>76</th>
      <td>  15</td>
      <td>              e1.whatsapp.net</td>
    </tr>
    <tr>
      <th>77</th>
      <td>  15</td>
      <td>             e14.whatsapp.net</td>
    </tr>
    <tr>
      <th>78</th>
      <td>  15</td>
      <td>              e2.whatsapp.net</td>
    </tr>
    <tr>
      <th>79</th>
      <td>  15</td>
      <td>              e6.whatsapp.net</td>
    </tr>
    <tr>
      <th>80</th>
      <td>  15</td>
      <td>              e7.whatsapp.net</td>
    </tr>
    <tr>
      <th>81</th>
      <td>  15</td>
      <td>              e8.whatsapp.net</td>
    </tr>
    <tr>
      <th>82</th>
      <td>  15</td>
      <td>            gdata.youtube.com</td>
    </tr>
    <tr>
      <th>83</th>
      <td>  15</td>
      <td>                getpocket.com</td>
    </tr>
    <tr>
      <th>84</th>
      <td>  15</td>
      <td>               images.zeit.de</td>
    </tr>
    <tr>
      <th>85</th>
      <td>  15</td>
      <td>                    m.faz.net</td>
    </tr>
    <tr>
      <th>86</th>
      <td>  15</td>
      <td>               media1.faz.net</td>
    </tr>
    <tr>
      <th>87</th>
      <td>  15</td>
      <td>                p.twitter.com</td>
    </tr>
    <tr>
      <th>88</th>
      <td>  15</td>
      <td>         platform.twitter.com</td>
    </tr>
    <tr>
      <th>89</th>
      <td>  15</td>
      <td>      scontent-b.xx.fbcdn.net</td>
    </tr>
    <tr>
      <th>90</th>
      <td>  15</td>
      <td>      stats.g.doubleclick.net</td>
    </tr>
    <tr>
      <th>91</th>
      <td>  15</td>
      <td>           sueddeut.ivwbox.de</td>
    </tr>
    <tr>
      <th>92</th>
      <td>  15</td>
      <td>             sz.met.vgwort.de</td>
    </tr>
    <tr>
      <th>93</th>
      <td>  15</td>
      <td>                tags.w55c.net</td>
    </tr>
    <tr>
      <th>94</th>
      <td>  15</td>
      <td>                  www.faz.net</td>
    </tr>
    <tr>
      <th>95</th>
      <td>  15</td>
      <td>                 www.heute.de</td>
    </tr>
    <tr>
      <th>96</th>
      <td>  15</td>
      <td>          www.sueddeutsche.de</td>
    </tr>
    <tr>
      <th>97</th>
      <td>  15</td>
      <td>                   www.taz.de</td>
    </tr>
    <tr>
      <th>98</th>
      <td>  10</td>
      <td>                 a0.twimg.com</td>
    </tr>
    <tr>
      <th>99</th>
      <td>  10</td>
      <td>        api.geo.kontagent.net</td>
    </tr>
  </tbody>
</table>
</div>




```
p_testing = pdsql.read_frame(""" 
    SELECT COUNT(c.dst),c.dst, c.dstport, c.frame_protocols FROM connection AS c 
    JOIN dns AS d ON c.dst=d.dns_response
    WHERE c.dst == "173.194.70.95" AND c.dst NOT LIKE "10.%"
    ORDER by 1 DESC
""", con)
#p_testing.head(100)

p_testing = pdsql.read_frame("""
    SELECT COUNT(*), (SELECT dns_query FROM dns WHERE dns_response=c.dst LIMIT 1) as DNS, c.dstport, c.frame_protocols FROM connection AS c
    WHERE c.dst NOT LIKE "10.%"
    GROUP by 2
    ORDER by 1 DESC
""", con)
p_testing.head(100)
```




<div style="max-height:1000px;max-width:1500px;overflow:auto;">
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>COUNT(*)</th>
      <th>DNS</th>
      <th>dstport</th>
      <th>frame_protocols</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0 </th>
      <td> 5570</td>
      <td>                     cdn.flipboard.com</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>1 </th>
      <td> 5248</td>
      <td>                   orcart.facebook.com</td>
      <td>  443</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>2 </th>
      <td> 4670</td>
      <td>                  fbprod.flipboard.com</td>
      <td>  443</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>3 </th>
      <td> 4446</td>
      <td>                    www.googleapis.com</td>
      <td>  443</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>4 </th>
      <td> 4418</td>
      <td>                    graph.facebook.com</td>
      <td>  443</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>5 </th>
      <td> 2744</td>
      <td>                        media1.faz.net</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>6 </th>
      <td> 2642</td>
      <td>                                  None</td>
      <td>  NaN</td>
      <td> sll:ip:icmp:ip:udp:dns</td>
    </tr>
    <tr>
      <th>7 </th>
      <td> 2477</td>
      <td>                        www.google.com</td>
      <td>  443</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>8 </th>
      <td> 2016</td>
      <td>               polpix.sueddeutsche.com</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>9 </th>
      <td> 1722</td>
      <td> r6---sn-i5onxoxu-q0nl.googlevideo.com</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>10</th>
      <td> 1277</td>
      <td>            android.clients.google.com</td>
      <td>  443</td>
      <td>         sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>11</th>
      <td> 1264</td>
      <td>                      ad.flipboard.com</td>
      <td>  443</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>12</th>
      <td> 1191</td>
      <td>                  platform.twitter.com</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>13</th>
      <td>  989</td>
      <td>              www.google-analytics.com</td>
      <td>  443</td>
      <td>         sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>14</th>
      <td>  986</td>
      <td>                www.thisiscolossal.com</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>15</th>
      <td>  902</td>
      <td>                     feeds.reuters.com</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>16</th>
      <td>  856</td>
      <td>                     www.tagesschau.de</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>17</th>
      <td>  762</td>
      <td>                          i1.ytimg.com</td>
      <td>  443</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>18</th>
      <td>  727</td>
      <td>                images03.futurezone.at</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>19</th>
      <td>  725</td>
      <td>                       cdn2.spiegel.de</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>20</th>
      <td>  701</td>
      <td>             cdn.blog.malwarebytes.org</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>21</th>
      <td>  676</td>
      <td>                   ticks2.bugsense.com</td>
      <td>  443</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>22</th>
      <td>  557</td>
      <td>                            www.taz.de</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>23</th>
      <td>  513</td>
      <td>                       cdn4.spiegel.de</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>24</th>
      <td>  481</td>
      <td>                      mtalk.google.com</td>
      <td> 5228</td>
      <td>        sll:ip:tcp:data</td>
    </tr>
    <tr>
      <th>25</th>
      <td>  478</td>
      <td>                      www.theverge.com</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>26</th>
      <td>  461</td>
      <td>                           i.imgur.com</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>27</th>
      <td>  443</td>
      <td>                www.fahrinfo-berlin.de</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>28</th>
      <td>  439</td>
      <td>                    b-api.facebook.com</td>
      <td>  443</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>29</th>
      <td>  438</td>
      <td>                      intelcrawler.com</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>30</th>
      <td>  438</td>
      <td>                         lh3.ggpht.com</td>
      <td>  443</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>31</th>
      <td>  410</td>
      <td>                       api.twitter.com</td>
      <td>  443</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>32</th>
      <td>  398</td>
      <td>                        imap.gmail.com</td>
      <td>  993</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>33</th>
      <td>  378</td>
      <td>                         www.google.de</td>
      <td>  443</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>34</th>
      <td>  346</td>
      <td>                  google-analytics.com</td>
      <td>  443</td>
      <td>         sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>35</th>
      <td>  303</td>
      <td>                       bilder2.n-tv.de</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>36</th>
      <td>  264</td>
      <td>                           p5.focus.de</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>37</th>
      <td>  261</td>
      <td>                         e.apsalar.com</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>38</th>
      <td>  255</td>
      <td>                       bilder4.n-tv.de</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>39</th>
      <td>  248</td>
      <td>                         pbs.twimg.com</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>40</th>
      <td>  246</td>
      <td>                     gdata.youtube.com</td>
      <td>  443</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>41</th>
      <td>  244</td>
      <td>               scontent-b.xx.fbcdn.net</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>42</th>
      <td>  242</td>
      <td>                        www.amazon.com</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>43</th>
      <td>  231</td>
      <td>                            m.heute.de</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>44</th>
      <td>  230</td>
      <td>                       cdn3.spiegel.de</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>45</th>
      <td>  221</td>
      <td>                        push.parse.com</td>
      <td> 8253</td>
      <td>        sll:ip:tcp:data</td>
    </tr>
    <tr>
      <th>46</th>
      <td>  211</td>
      <td>                      e12.whatsapp.net</td>
      <td> 5222</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>47</th>
      <td>  206</td>
      <td>                    mobile.twitter.com</td>
      <td>  443</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>48</th>
      <td>  203</td>
      <td>               stats.g.doubleclick.net</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>49</th>
      <td>  194</td>
      <td>                  cm.g.doubleclick.net</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>50</th>
      <td>  186</td>
      <td>                         abs.twimg.com</td>
      <td>  443</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>51</th>
      <td>  185</td>
      <td>                           twitter.com</td>
      <td>  443</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>52</th>
      <td>  163</td>
      <td>                  st02.androidpit.info</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>53</th>
      <td>  158</td>
      <td>                        images.zeit.de</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>54</th>
      <td>  154</td>
      <td>                       e2.whatsapp.net</td>
      <td> 5222</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>55</th>
      <td>  153</td>
      <td>                 ecx.images-amazon.com</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>56</th>
      <td>  149</td>
      <td>              settings.crashlytics.com</td>
      <td>  443</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>57</th>
      <td>  145</td>
      <td>                           img.welt.de</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>58</th>
      <td>  143</td>
      <td>                 photos-d.ak.fbcdn.net</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>59</th>
      <td>  139</td>
      <td>                        gwp.nuggad.net</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>60</th>
      <td>  135</td>
      <td>                          ma.twimg.com</td>
      <td>  443</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>61</th>
      <td>  132</td>
      <td>                       apis.google.com</td>
      <td>  443</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>62</th>
      <td>  129</td>
      <td>                             m.faz.net</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>63</th>
      <td>  128</td>
      <td>                   clients3.google.com</td>
      <td>  443</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>64</th>
      <td>  126</td>
      <td>                         www.fubiz.net</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>65</th>
      <td>  125</td>
      <td>                 apresolve.spotify.com</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>66</th>
      <td>  124</td>
      <td>              mobile.smartadserver.com</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>67</th>
      <td>  124</td>
      <td>                 photos-b.ak.fbcdn.net</td>
      <td>  443</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>68</th>
      <td>  123</td>
      <td>                          www.golem.de</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>69</th>
      <td>  121</td>
      <td>                       ssl.gstatic.com</td>
      <td>  443</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>70</th>
      <td>  110</td>
      <td>           oauth.googleusercontent.com</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>71</th>
      <td>  108</td>
      <td>        fbcdn-sphotos-e-a.akamaihd.net</td>
      <td>  443</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>72</th>
      <td>   96</td>
      <td>               z-ecx.images-amazon.com</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>73</th>
      <td>   92</td>
      <td>                     fls-na.amazon.com</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>74</th>
      <td>   88</td>
      <td>                      e13.whatsapp.net</td>
      <td> 5222</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>75</th>
      <td>   88</td>
      <td>                         p.twitter.com</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>76</th>
      <td>   85</td>
      <td>                          www.heute.de</td>
      <td>  443</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>77</th>
      <td>   83</td>
      <td>                static.ak.facebook.com</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>78</th>
      <td>   81</td>
      <td>                     e.crashlytics.com</td>
      <td>  443</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>79</th>
      <td>   80</td>
      <td>          fbcdn-profile-a.akamaihd.net</td>
      <td>  443</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>80</th>
      <td>   76</td>
      <td>                  connect.facebook.net</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>81</th>
      <td>   74</td>
      <td>                    pop3.variomedia.de</td>
      <td>  995</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>82</th>
      <td>   73</td>
      <td>                        script.ioam.de</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>83</th>
      <td>   71</td>
      <td>                        api.tunigo.com</td>
      <td>  443</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>84</th>
      <td>   71</td>
      <td>          dsms0mj1bbhn4.cloudfront.net</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>85</th>
      <td>   70</td>
      <td>                     static.plista.com</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>86</th>
      <td>   69</td>
      <td>                     www.androidpit.de</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>87</th>
      <td>   64</td>
      <td>                         tags.w55c.net</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>88</th>
      <td>   63</td>
      <td>                          a0.twimg.com</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>89</th>
      <td>   63</td>
      <td>                   mms882.whatsapp.net</td>
      <td>  443</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>90</th>
      <td>   59</td>
      <td>                       e9.whatsapp.net</td>
      <td>  443</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>91</th>
      <td>   58</td>
      <td>                       e3.whatsapp.net</td>
      <td> 5222</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>92</th>
      <td>   57</td>
      <td>                   s95.research.de.com</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>93</th>
      <td>   57</td>
      <td>                sphotos-c.ak.fbcdn.net</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>94</th>
      <td>   57</td>
      <td>                   www.sueddeutsche.de</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>95</th>
      <td>   53</td>
      <td>               g-ecx.images-amazon.com</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>96</th>
      <td>   53</td>
      <td>                           www.byte.fm</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>97</th>
      <td>   52</td>
      <td>                            de.ioam.de</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>98</th>
      <td>   52</td>
      <td>                 s.amazon-adsystem.com</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
    <tr>
      <th>99</th>
      <td>   51</td>
      <td>                         blogs.faz.net</td>
      <td>   80</td>
      <td>             sll:ip:tcp</td>
    </tr>
  </tbody>
</table>
</div>




```

```

# Top connections


```
p2 = pdsql.read_frame(""" 
    SELECT COUNT(c.dst), d.dns_query, c.dstport, c.frame_protocols FROM connection AS c 
    JOIN dns AS d ON c.dst=d.dns_response
    WHERE c.frame_protocols LIKE "sll:ip:tcp:%"
    GROUP by c.dst
    ORDER by 1 DESC
""", con)
p2.head(100)
```




<div style="max-height:1000px;max-width:1500px;overflow:auto;">
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>COUNT(c.dst)</th>
      <th>dns_query</th>
      <th>dstport</th>
      <th>frame_protocols</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0 </th>
      <td> 5064575</td>
      <td>           www.googleapis.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>1 </th>
      <td>  652600</td>
      <td>             www.facebook.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>2 </th>
      <td>  504000</td>
      <td>             www.facebook.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>3 </th>
      <td>  492200</td>
      <td>             www.facebook.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>4 </th>
      <td>  254625</td>
      <td>          orcart.facebook.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>5 </th>
      <td>  146300</td>
      <td>          orcart.facebook.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>6 </th>
      <td>  137475</td>
      <td>          orcart.facebook.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>7 </th>
      <td>   96375</td>
      <td>          ticks2.bugsense.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>8 </th>
      <td>   89600</td>
      <td>               www.google.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>9 </th>
      <td>   73200</td>
      <td>               www.google.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>10</th>
      <td>   73100</td>
      <td>          orcart.facebook.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>11</th>
      <td>   62200</td>
      <td>             mtalk.google.com</td>
      <td> 5228</td>
      <td> sll:ip:tcp:data</td>
    </tr>
    <tr>
      <th>12</th>
      <td>   51425</td>
      <td>               www.google.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>13</th>
      <td>   44100</td>
      <td>               www.google.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>14</th>
      <td>   42975</td>
      <td>          clients4.google.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>15</th>
      <td>   42975</td>
      <td>          orcart.facebook.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>16</th>
      <td>   41125</td>
      <td>         fbprod.flipboard.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>17</th>
      <td>   36575</td>
      <td>         fbprod.flipboard.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>18</th>
      <td>   36000</td>
      <td>               www.google.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>19</th>
      <td>   34875</td>
      <td>         platform.twitter.com</td>
      <td>   80</td>
      <td> sll:ip:tcp:http</td>
    </tr>
    <tr>
      <th>20</th>
      <td>   30750</td>
      <td>         fbprod.flipboard.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>21</th>
      <td>   30600</td>
      <td>         fbprod.flipboard.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>22</th>
      <td>   29100</td>
      <td>         fbprod.flipboard.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>23</th>
      <td>   27900</td>
      <td>                 i1.ytimg.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>24</th>
      <td>   25000</td>
      <td>                  www.faz.net</td>
      <td>   80</td>
      <td> sll:ip:tcp:http</td>
    </tr>
    <tr>
      <th>25</th>
      <td>   22350</td>
      <td>         fbprod.flipboard.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>26</th>
      <td>   20500</td>
      <td>     www.google-analytics.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>27</th>
      <td>   19800</td>
      <td>               www.google.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>28</th>
      <td>   19600</td>
      <td>         fbprod.flipboard.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>29</th>
      <td>   19250</td>
      <td>               www.google.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>30</th>
      <td>   18450</td>
      <td>     www.google-analytics.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>31</th>
      <td>   16400</td>
      <td>     www.google-analytics.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>32</th>
      <td>   16050</td>
      <td>          orcart.facebook.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>33</th>
      <td>   15000</td>
      <td>         fbprod.flipboard.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>34</th>
      <td>   14550</td>
      <td>               www.google.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>35</th>
      <td>   14375</td>
      <td>               www.google.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>36</th>
      <td>   13750</td>
      <td>                www.google.de</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>37</th>
      <td>   13600</td>
      <td> themes.googleusercontent.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>38</th>
      <td>   13300</td>
      <td>         fbprod.flipboard.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>39</th>
      <td>   11000</td>
      <td>            www.tagesschau.de</td>
      <td>   80</td>
      <td> sll:ip:tcp:http</td>
    </tr>
    <tr>
      <th>40</th>
      <td>   10850</td>
      <td>           b-api.facebook.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>41</th>
      <td>   10800</td>
      <td>         fbprod.flipboard.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>42</th>
      <td>   10600</td>
      <td>           b-api.facebook.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>43</th>
      <td>   10325</td>
      <td>          orcart.facebook.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>44</th>
      <td>   10150</td>
      <td>                 i1.ytimg.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>45</th>
      <td>    9900</td>
      <td>            feeds.reuters.com</td>
      <td>   80</td>
      <td> sll:ip:tcp:http</td>
    </tr>
    <tr>
      <th>46</th>
      <td>    8900</td>
      <td>         fbprod.flipboard.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>47</th>
      <td>    8700</td>
      <td>         fbprod.flipboard.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>48</th>
      <td>    8625</td>
      <td>              bilder4.n-tv.de</td>
      <td>   80</td>
      <td> sll:ip:tcp:http</td>
    </tr>
    <tr>
      <th>49</th>
      <td>    8625</td>
      <td>              bilder4.n-tv.de</td>
      <td>   80</td>
      <td> sll:ip:tcp:http</td>
    </tr>
    <tr>
      <th>50</th>
      <td>    7700</td>
      <td>           b-api.facebook.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>51</th>
      <td>    7350</td>
      <td>           mobile.twitter.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>52</th>
      <td>    7300</td>
      <td>         fbprod.flipboard.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>53</th>
      <td>    6625</td>
      <td>       www.fahrinfo-berlin.de</td>
      <td>   80</td>
      <td> sll:ip:tcp:http</td>
    </tr>
    <tr>
      <th>54</th>
      <td>    6050</td>
      <td>              api.twitter.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>55</th>
      <td>    5550</td>
      <td>         fbprod.flipboard.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>56</th>
      <td>    4000</td>
      <td>               imap.gmail.com</td>
      <td>  993</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>57</th>
      <td>    4000</td>
      <td>     www.googleadservices.com</td>
      <td>   80</td>
      <td> sll:ip:tcp:http</td>
    </tr>
    <tr>
      <th>58</th>
      <td>    3750</td>
      <td>                www.google.de</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>59</th>
      <td>    3375</td>
      <td>         fbprod.flipboard.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>60</th>
      <td>    3300</td>
      <td>               www.google.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>61</th>
      <td>    3300</td>
      <td>     www.google-analytics.com</td>
      <td>   80</td>
      <td> sll:ip:tcp:http</td>
    </tr>
    <tr>
      <th>62</th>
      <td>    3300</td>
      <td>             www.theverge.com</td>
      <td>   80</td>
      <td> sll:ip:tcp:http</td>
    </tr>
    <tr>
      <th>63</th>
      <td>    3150</td>
      <td>          image5.pubmatic.com</td>
      <td>   80</td>
      <td> sll:ip:tcp:http</td>
    </tr>
    <tr>
      <th>64</th>
      <td>    2750</td>
      <td>         fbprod.flipboard.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>65</th>
      <td>    2550</td>
      <td>            gdata.youtube.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>66</th>
      <td>    2500</td>
      <td>         fbprod.flipboard.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>67</th>
      <td>    2500</td>
      <td>                 i1.ytimg.com</td>
      <td>   80</td>
      <td> sll:ip:tcp:http</td>
    </tr>
    <tr>
      <th>68</th>
      <td>    2250</td>
      <td>     www.googleadservices.com</td>
      <td>   80</td>
      <td> sll:ip:tcp:http</td>
    </tr>
    <tr>
      <th>69</th>
      <td>    2200</td>
      <td>                   www.taz.de</td>
      <td>   80</td>
      <td> sll:ip:tcp:http</td>
    </tr>
    <tr>
      <th>70</th>
      <td>    2025</td>
      <td>              www.youtube.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>71</th>
      <td>    1950</td>
      <td>              cdn4.spiegel.de</td>
      <td>   80</td>
      <td> sll:ip:tcp:http</td>
    </tr>
    <tr>
      <th>72</th>
      <td>    1950</td>
      <td>        apresolve.spotify.com</td>
      <td>   80</td>
      <td> sll:ip:tcp:http</td>
    </tr>
    <tr>
      <th>73</th>
      <td>    1900</td>
      <td>                  twitter.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>74</th>
      <td>    1750</td>
      <td>             e12.whatsapp.net</td>
      <td> 5222</td>
      <td> sll:ip:tcp:xmpp</td>
    </tr>
    <tr>
      <th>75</th>
      <td>    1550</td>
      <td>           pop3.variomedia.de</td>
      <td>  995</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>76</th>
      <td>    1500</td>
      <td>   android.clients.google.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>77</th>
      <td>    1425</td>
      <td>             e12.whatsapp.net</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>78</th>
      <td>    1400</td>
      <td>                p.twitter.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>79</th>
      <td>    1350</td>
      <td>                www.google.de</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>80</th>
      <td>    1350</td>
      <td>                yt4.ggpht.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>81</th>
      <td>    1300</td>
      <td>      polpix.sueddeutsche.com</td>
      <td>   80</td>
      <td> sll:ip:tcp:http</td>
    </tr>
    <tr>
      <th>82</th>
      <td>    1275</td>
      <td>               imap.gmail.com</td>
      <td>  993</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>83</th>
      <td>    1200</td>
      <td>                www.google.de</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>84</th>
      <td>    1200</td>
      <td>      polpix.sueddeutsche.com</td>
      <td>   80</td>
      <td> sll:ip:tcp:http</td>
    </tr>
    <tr>
      <th>85</th>
      <td>    1200</td>
      <td>        weather.yahooapis.com</td>
      <td>   80</td>
      <td> sll:ip:tcp:http</td>
    </tr>
    <tr>
      <th>86</th>
      <td>    1100</td>
      <td>               push.parse.com</td>
      <td> 8253</td>
      <td> sll:ip:tcp:data</td>
    </tr>
    <tr>
      <th>87</th>
      <td>    1075</td>
      <td>              e2.whatsapp.net</td>
      <td> 5222</td>
      <td> sll:ip:tcp:xmpp</td>
    </tr>
    <tr>
      <th>88</th>
      <td>    1000</td>
      <td>        apresolve.spotify.com</td>
      <td>   80</td>
      <td> sll:ip:tcp:http</td>
    </tr>
    <tr>
      <th>89</th>
      <td>    1000</td>
      <td>               gwp.nuggad.net</td>
      <td>   80</td>
      <td> sll:ip:tcp:http</td>
    </tr>
    <tr>
      <th>90</th>
      <td>     950</td>
      <td>               www.google.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>91</th>
      <td>     925</td>
      <td>             e13.whatsapp.net</td>
      <td> 5222</td>
      <td> sll:ip:tcp:xmpp</td>
    </tr>
    <tr>
      <th>92</th>
      <td>     900</td>
      <td>   android.clients.google.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>93</th>
      <td>     900</td>
      <td>             www.theverge.com</td>
      <td>   80</td>
      <td> sll:ip:tcp:http</td>
    </tr>
    <tr>
      <th>94</th>
      <td>     900</td>
      <td>                tags.w55c.net</td>
      <td>   80</td>
      <td> sll:ip:tcp:http</td>
    </tr>
    <tr>
      <th>95</th>
      <td>     825</td>
      <td>              ssl.gstatic.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>96</th>
      <td>     825</td>
      <td>             intelcrawler.com</td>
      <td>   80</td>
      <td> sll:ip:tcp:http</td>
    </tr>
    <tr>
      <th>97</th>
      <td>     800</td>
      <td>               www.google.com</td>
      <td>  443</td>
      <td>  sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>98</th>
      <td>     750</td>
      <td>                pbs.twimg.com</td>
      <td>   80</td>
      <td> sll:ip:tcp:http</td>
    </tr>
    <tr>
      <th>99</th>
      <td>     750</td>
      <td>               images.zeit.de</td>
      <td>   80</td>
      <td> sll:ip:tcp:http</td>
    </tr>
  </tbody>
</table>
</div>




```

```


```
p_testing = pdsql.read_frame(""" 
    SELECT  frame_number, frame_protocols
    FROM connection
    WHERE frame_protocols LIKE 'sll:ip:tcp%xml%'
    GROUP by frame_protocols
    ORDER by 1 DESC
""", con)
#print(p1.head(100).to_string())
p_testing.head(100)
```




<div style="max-height:1000px;max-width:1500px;overflow:auto;">
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>frame_number</th>
      <th>frame_protocols</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td> 111438</td>
      <td>                     sll:ip:tcp:xmpp:xml</td>
    </tr>
    <tr>
      <th>1</th>
      <td>  98738</td>
      <td>           sll:ip:tcp:http:data:data:xml</td>
    </tr>
    <tr>
      <th>2</th>
      <td>  98624</td>
      <td> sll:ip:tcp:http:data:data:data:data:xml</td>
    </tr>
    <tr>
      <th>3</th>
      <td>  83057</td>
      <td>                     sll:ip:tcp:http:xml</td>
    </tr>
  </tbody>
</table>
</div>




```

```

# Used protocols


```
p_proto = pdsql.read_frame(""" 
    SELECT COUNT(frame_protocols), frame_protocols
    FROM connection
    GROUP by frame_protocols
    ORDER BY 1 DESC
""", con)
p_proto.head(100)
```




<div style="max-height:1000px;max-width:1500px;overflow:auto;">
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>COUNT(frame_protocols)</th>
      <th>frame_protocols</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0 </th>
      <td> 529265</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        sll:ip:tcp</td>
    </tr>
    <tr>
      <th>1 </th>
      <td> 103200</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    sll:ip:tcp:ssl</td>
    </tr>
    <tr>
      <th>2 </th>
      <td>  19620</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   sll:ip:tcp:http</td>
    </tr>
    <tr>
      <th>3 </th>
      <td>  15055</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    sll:ip:udp:dns</td>
    </tr>
    <tr>
      <th>4 </th>
      <td>   9130</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                sll:ip:tcp:ssl:ssl</td>
    </tr>
    <tr>
      <th>5 </th>
      <td>   3710</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   sll:ip:tcp:xmpp</td>
    </tr>
    <tr>
      <th>6 </th>
      <td>   2785</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   sll:ip:tcp:data</td>
    </tr>
    <tr>
      <th>7 </th>
      <td>   1935</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        sll:ip:tcp:http:image-jfif</td>
    </tr>
    <tr>
      <th>8 </th>
      <td>   1910</td>
      <td>         sll:ip:tcp:ssl:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:x509ce:pkix1explicit:x509ce:x509ce:pkix1implicit:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:pkix1implicit:x509ce:x509ce:pkix1explicit:pkix1implicit:x509ce:x509ce:logotypecertextn:x509ce:x509sat:x509ce:x509ce:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:pkix1explicit:x509ce:logotypecertextn:pkix1implicit:x509ce:pkcs-1:ssl</td>
    </tr>
    <tr>
      <th>9 </th>
      <td>   1100</td>
      <td>                                                                                                                                                                                  sll:ip:tcp:ssl:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:pkix1implicit:x509ce:x509ce:x509ce:x509ce:x509ce:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:x509ce:pkix1implicit:x509ce:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:x509ce:x509ce:pkix1explicit:pkcs-1:ssl</td>
    </tr>
    <tr>
      <th>10</th>
      <td>    870</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   sll:ip:tcp:http:data-text-lines</td>
    </tr>
    <tr>
      <th>11</th>
      <td>    505</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             sll:ip:tcp:http:media</td>
    </tr>
    <tr>
      <th>12</th>
      <td>    480</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               sll:ip:tcp:http:png</td>
    </tr>
    <tr>
      <th>13</th>
      <td>    395</td>
      <td>                                       sll:ip:tcp:ssl:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:x509ce:x509ce:x509ce:pkix1explicit:pkix1implicit:pkix1implicit:x509ce:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:pkix1explicit:pkix1implicit:x509ce:pkix1implicit:x509ce:x509ce:x509ce:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:pkix1implicit:x509ce:x509ce:pkix1explicit:x509ce:x509ce:x509ce:pkcs-1:ssl</td>
    </tr>
    <tr>
      <th>14</th>
      <td>    335</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                               sll:ip:tcp:ssl:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:pkcs-1</td>
    </tr>
    <tr>
      <th>15</th>
      <td>    320</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         sll:ip:tcp:http:image-gif</td>
    </tr>
    <tr>
      <th>16</th>
      <td>    265</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            sll:ip:icmp:ip:udp:dns</td>
    </tr>
    <tr>
      <th>17</th>
      <td>    205</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              sll:ip:tcp:http:data</td>
    </tr>
    <tr>
      <th>18</th>
      <td>    165</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     sll:ip:tcp:http:data:data:xml</td>
    </tr>
    <tr>
      <th>19</th>
      <td>    145</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         sll:ip:tcp:http:data:data:data-text-lines</td>
    </tr>
    <tr>
      <th>20</th>
      <td>    130</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    sll:ip:tcp:http:data:data:json</td>
    </tr>
    <tr>
      <th>21</th>
      <td>     95</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              sll:ip:tcp:http:json</td>
    </tr>
    <tr>
      <th>22</th>
      <td>     85</td>
      <td>                                                                                                                                                            sll:ip:tcp:ssl:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:x509ce:x509ce:x509ce:pkix1implicit:x509ce:pkix1explicit:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:x509ce:pkix1implicit:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:x509ce:x509ce:pkix1explicit:pkcs-1:ssl</td>
    </tr>
    <tr>
      <th>23</th>
      <td>     85</td>
      <td>                                                                                                                                                                             sll:ip:tcp:ssl:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:x509ce:pkix1explicit:x509ce:x509ce:pkix1implicit:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:pkix1implicit:x509ce:x509ce:pkix1explicit:pkix1implicit:x509ce:x509ce:logotypecertextn:x509ce:x509sat:x509ce:x509ce:pkcs-1:ssl</td>
    </tr>
    <tr>
      <th>24</th>
      <td>     75</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           sll:ip:tcp:http:data:data:data:data:xml</td>
    </tr>
    <tr>
      <th>25</th>
      <td>     65</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    sll:ip:tcp:http:data:data:data:data-text-lines</td>
    </tr>
    <tr>
      <th>26</th>
      <td>     60</td>
      <td>                                                                                                                                                                           sll:ip:tcp:ssl:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:pkix1implicit:x509ce:x509ce:x509ce:x509ce:x509ce:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:x509ce:pkix1implicit:x509ce:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:x509ce:x509ce:pkix1explicit:pkcs-1:ssl</td>
    </tr>
    <tr>
      <th>27</th>
      <td>     55</td>
      <td>                                                                                                                                                  sll:ip:tcp:ssl:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:x509ce:x509ce:ns_cert_exts:x509ce:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:pkix1explicit:x509ce:x509ce:x509ce:x509ce:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:pkix1explicit:x509ce:x509ce:x509sat:x509sat:x509sat:x509sat:x509ce:pkcs-1:ssl</td>
    </tr>
    <tr>
      <th>28</th>
      <td>     55</td>
      <td>                                                                                                      sll:ip:tcp:ssl:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:x509ce:x509ce:pkix1explicit:x509ce:x509ce:pkix1implicit:logotypecertextn:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:pkix1explicit:x509ce:x509ce:ns_cert_exts:logotypecertextn:x509ce:x509sat:pkix1implicit:x509ce:pkcs-1:ssl</td>
    </tr>
    <tr>
      <th>29</th>
      <td>     45</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               sll:ip:tcp:http:xml</td>
    </tr>
    <tr>
      <th>30</th>
      <td>     40</td>
      <td>                                                                                                                                                                                      sll:ip:tcp:ssl:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:pkix1implicit:x509ce:x509ce:x509ce:x509ce:x509ce:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:x509ce:pkix1implicit:x509ce:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:x509ce:x509ce:pkix1explicit:pkcs-1</td>
    </tr>
    <tr>
      <th>31</th>
      <td>     35</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               sll:ip:tcp:xmpp:xml</td>
    </tr>
    <tr>
      <th>32</th>
      <td>     30</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          sll:ip:tcp:http:data:data:data:image-gif</td>
    </tr>
    <tr>
      <th>33</th>
      <td>     30</td>
      <td>                                                                                                                                                                                     sll:ip:tcp:ssl:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:x509ce:pkix1explicit:x509ce:x509ce:pkix1implicit:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:pkix1implicit:x509ce:x509ce:pkix1explicit:pkix1implicit:x509ce:x509ce:logotypecertextn:x509ce:x509sat:x509ce:x509ce:pkcs-1:ssl</td>
    </tr>
    <tr>
      <th>34</th>
      <td>     25</td>
      <td>                                                                                                                                                                                                                                                                                         sll:ip:tcp:ssl:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:x509ce:x509ce:x509ce:pkix1implicit:x509ce:pkix1explicit:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:x509ce:pkix1implicit:pkcs-1:ssl</td>
    </tr>
    <tr>
      <th>35</th>
      <td>     20</td>
      <td>                                                                                                                                                                                                                sll:ip:tcp:ssl:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:x509ce:x509ce:x509ce:pkix1explicit:pkix1implicit:pkix1implicit:x509ce:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:pkix1explicit:pkix1implicit:x509ce:pkix1implicit:x509ce:x509ce:x509ce:pkcs-1:ssl</td>
    </tr>
    <tr>
      <th>36</th>
      <td>     15</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               sll:ip:tcp:http:data:data:data:data:data-text-lines</td>
    </tr>
    <tr>
      <th>37</th>
      <td>     15</td>
      <td>                                                                                                                                                 sll:ip:tcp:ssl:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:x509ce:x509ce:ns_cert_exts:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:pkix1explicit:x509ce:x509ce:x509ce:x509ce:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:pkix1explicit:x509ce:x509ce:x509sat:x509sat:x509sat:x509sat:x509ce:pkcs-1:ssl</td>
    </tr>
    <tr>
      <th>38</th>
      <td>     15</td>
      <td>                                                                                           sll:ip:tcp:ssl:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:pkix1explicit:x509ce:x509ce:x509ce:x509ce:pkix1implicit:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:pkix1implicit:x509ce:x509ce:x509ce:x509ce:x509sat:x509ce:x509ce:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:pkix1explicit:x509ce:x509ce:x509ce:pkcs-1:ssl</td>
    </tr>
    <tr>
      <th>39</th>
      <td>     15</td>
      <td>                                                                                                                                                                                                                          sll:ip:tcp:ssl:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:x509ce:x509ce:pkix1explicit:x509ce:pkix1implicit:x509ce:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:x509ce:x509ce:pkix1implicit:pkcs-1:ssl</td>
    </tr>
    <tr>
      <th>40</th>
      <td>     15</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    sll:ip:tcp:ulp</td>
    </tr>
    <tr>
      <th>41</th>
      <td>     10</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               sll:ip:tcp:http:data:data:data:json</td>
    </tr>
    <tr>
      <th>42</th>
      <td>     10</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              sll:ip:tcp:http:data:data:data:media</td>
    </tr>
    <tr>
      <th>43</th>
      <td>     10</td>
      <td>                                                                                                                                                                                                                                                                  sll:ip:tcp:ssl:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:x509ce:x509ce:pkix1explicit:x509ce:pkix1implicit:x509ce:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:x509ce:x509ce:pkix1implicit:pkcs-1:ssl</td>
    </tr>
    <tr>
      <th>44</th>
      <td>     10</td>
      <td>                                                                                                                                                                    sll:ip:tcp:ssl:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:x509ce:x509ce:x509ce:pkix1implicit:x509ce:pkix1explicit:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:x509ce:pkix1implicit:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:x509ce:x509ce:pkix1explicit:pkcs-1:ssl</td>
    </tr>
    <tr>
      <th>45</th>
      <td>     10</td>
      <td>                                 sll:ip:tcp:ssl:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:x509ce:pkix1explicit:pkix1implicit:x509ce:x509ce:x509ce:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:pkix1implicit:x509ce:x509ce:pkix1explicit:x509ce:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509sat:x509sat:x509sat:x509sat:x509sat:x509ce:pkix1implicit:x509ce:x509ce:pkix1explicit:x509ce:pkcs-1:ssl</td>
    </tr>
    <tr>
      <th>46</th>
      <td>     10</td>
      <td>                                                            sll:ip:tcp:ssl:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:x509ce:x509ce:x509ce:pkix1explicit:pkix1implicit:pkix1implicit:x509ce:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:pkix1explicit:pkix1implicit:x509ce:pkix1implicit:x509ce:x509ce:x509ce:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:pkix1implicit:x509ce:x509ce:x509ce:x509ce:x509ce:pkcs-1:ssl</td>
    </tr>
    <tr>
      <th>47</th>
      <td>     10</td>
      <td>                                                                                                                                                                                                                        sll:ip:tcp:ssl:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:x509ce:x509ce:x509ce:pkix1explicit:pkix1implicit:pkix1implicit:x509ce:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:pkix1explicit:pkix1implicit:x509ce:pkix1implicit:x509ce:x509ce:x509ce:pkcs-1:ssl</td>
    </tr>
    <tr>
      <th>48</th>
      <td>     10</td>
      <td> sll:ip:tcp:ssl:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:pkix1explicit:x509ce:x509ce:pkix1implicit:x509ce:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:pkix1implicit:x509ce:x509ce:pkix1explicit:pkix1implicit:x509ce:x509ce:logotypecertextn:x509ce:x509sat:x509ce:x509ce:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:pkix1explicit:x509ce:logotypecertextn:pkix1implicit:x509ce:pkcs-1:ssl</td>
    </tr>
    <tr>
      <th>49</th>
      <td>     10</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    sll:ip:udp:ntp</td>
    </tr>
    <tr>
      <th>50</th>
      <td>      5</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     sll:ip:tcp:http:data:data:data:data:data:data:data-text-lines</td>
    </tr>
    <tr>
      <th>51</th>
      <td>      5</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                sll:ip:tcp:http:data:data:data:data:data:data:data:data-text-lines</td>
    </tr>
    <tr>
      <th>52</th>
      <td>      5</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                        sll:ip:tcp:http:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data-text-lines</td>
    </tr>
    <tr>
      <th>53</th>
      <td>      5</td>
      <td>                                                                                                                                                                                                                                                                                   sll:ip:tcp:http:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:png</td>
    </tr>
    <tr>
      <th>54</th>
      <td>      5</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              sll:ip:tcp:http:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:data:json</td>
    </tr>
    <tr>
      <th>55</th>
      <td>      5</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            sll:ip:tcp:http:data:data:data:data:data:data:data:data:data:data:json</td>
    </tr>
    <tr>
      <th>56</th>
      <td>      5</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 sll:ip:tcp:http:data:data:data:data:data:data:data:data:data:json</td>
    </tr>
    <tr>
      <th>57</th>
      <td>      5</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                sll:ip:tcp:http:data:data:data:data:data:data:json</td>
    </tr>
    <tr>
      <th>58</th>
      <td>      5</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               sll:ip:tcp:http:data:data:image-gif</td>
    </tr>
    <tr>
      <th>59</th>
      <td>      5</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     sll:ip:tcp:http:data:data:png</td>
    </tr>
    <tr>
      <th>60</th>
      <td>      5</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              sll:ip:tcp:http:json:data-text-lines</td>
    </tr>
    <tr>
      <th>61</th>
      <td>      5</td>
      <td>                                                                                                                                                                                                                                                                                                 sll:ip:tcp:ssl:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:x509ce:x509ce:x509ce:pkix1implicit:x509ce:pkix1explicit:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:x509ce:pkix1implicit:pkcs-1:ssl</td>
    </tr>
    <tr>
      <th>62</th>
      <td>      5</td>
      <td>                                                                                                                                                                                                                                                                                             sll:ip:tcp:ssl:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:x509ce:x509ce:x509ce:pkix1implicit:x509ce:pkix1explicit:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:x509ce:pkix1implicit:pkcs-1</td>
    </tr>
    <tr>
      <th>63</th>
      <td>      5</td>
      <td>             sll:ip:tcp:ssl:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:x509ce:pkix1explicit:x509ce:x509ce:pkix1implicit:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:pkix1implicit:x509ce:x509ce:pkix1explicit:pkix1implicit:x509ce:x509ce:logotypecertextn:x509ce:x509sat:x509ce:x509ce:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:pkix1explicit:x509ce:x509ce:logotypecertextn:pkix1implicit:pkcs-1</td>
    </tr>
    <tr>
      <th>64</th>
      <td>      5</td>
      <td>                                           sll:ip:tcp:ssl:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:x509ce:x509ce:x509ce:pkix1explicit:pkix1implicit:pkix1implicit:x509ce:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:pkix1explicit:pkix1implicit:x509ce:pkix1implicit:x509ce:x509ce:x509ce:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:pkix1implicit:x509ce:x509ce:pkix1explicit:x509ce:x509ce:x509ce:pkcs-1</td>
    </tr>
    <tr>
      <th>65</th>
      <td>      5</td>
      <td>                                                                                                                                                                     sll:ip:tcp:ssl:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:x509ce:x509ce:x509ce:pkix1explicit:pkix1explicit:pkix1implicit:pkix1implicit:x509ce:pkix1implicit:x509ce:pkcs-1:pkcs-1:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:x509sat:pkcs-1:x509ce:x509ce:x509ce:x509ce:pkix1implicit:x509ce:x509ce:pkix1explicit:pkix1explicit:pkcs-1:ssl</td>
    </tr>
    <tr>
      <th>66</th>
      <td>      5</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          sll:ipv6</td>
    </tr>
  </tbody>
</table>
</div>




```

```

# Used destination ports


```
p_ports = pdsql.read_frame(""" 
    SELECT COUNT(c.dstport), c.dstport
    FROM connection AS c
    JOIN dns AS d ON c.dst = d.dns_response
    GROUP by c.dstport
    ORDER by 1 DESC
""", con)
#print(p1.head(100).to_string())
p_ports.head(100)
```




<div style="max-height:1000px;max-width:1500px;overflow:auto;">
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>COUNT(c.dstport)</th>
      <th>dstport</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td> 18673312</td>
      <td>  443</td>
    </tr>
    <tr>
      <th>1</th>
      <td>  1879360</td>
      <td>   80</td>
    </tr>
    <tr>
      <th>2</th>
      <td>    61568</td>
      <td> 5228</td>
    </tr>
    <tr>
      <th>3</th>
      <td>     9760</td>
      <td>  993</td>
    </tr>
    <tr>
      <th>4</th>
      <td>     7712</td>
      <td> 5222</td>
    </tr>
    <tr>
      <th>5</th>
      <td>     4512</td>
      <td> 8253</td>
    </tr>
    <tr>
      <th>6</th>
      <td>     2368</td>
      <td>  995</td>
    </tr>
    <tr>
      <th>7</th>
      <td>      144</td>
      <td> 7276</td>
    </tr>
    <tr>
      <th>8</th>
      <td>      112</td>
      <td> 7275</td>
    </tr>
    <tr>
      <th>9</th>
      <td>        0</td>
      <td>  NaN</td>
    </tr>
  </tbody>
</table>
</div>




```

```

# HTTP Connections

## HTTP Methods


```
p_http_methods = pdsql.read_frame(""" 
    SELECT COUNT(request_method), request_method
    FROM http
    GROUP by request_method
    ORDER by 1 DESC
""", con)
#print(p1.head(100).to_string())
p_http_methods.head(100)
```




<div style="max-height:1000px;max-width:1500px;overflow:auto;">
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>COUNT(request_method)</th>
      <th>request_method</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td> 1345</td>
      <td>  GET</td>
    </tr>
    <tr>
      <th>1</th>
      <td>    8</td>
      <td> POST</td>
    </tr>
  </tbody>
</table>
</div>



## User Agents


```
p_user_agents = pdsql.read_frame(""" 
    SELECT COUNT(user_agent), user_agent
    FROM http
    GROUP by user_agent
    ORDER by 1 DESC
""", con)
#print(p1.head(100).to_string())
p_user_agents.head(100)
```




<div style="max-height:1000px;max-width:1500px;overflow:auto;">
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>COUNT(user_agent)</th>
      <th>user_agent</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0 </th>
      <td> 2388</td>
      <td>                                                                                                                                                                  null (FlipboardProxy/1.1; +http://flipboard.com/browserproxy)</td>
    </tr>
    <tr>
      <th>1 </th>
      <td> 1088</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>2 </th>
      <td>  500</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>3 </th>
      <td>  368</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>4 </th>
      <td>  328</td>
      <td>                                                                                                                                                                                                              Ultimate DayDream</td>
    </tr>
    <tr>
      <th>5 </th>
      <td>  212</td>
      <td>                                                                                                                                                       Mozilla/5.0 (Windows NT 6.1; WOW64; rv:23.0) Gecko/20100101 Firefox/23.0</td>
    </tr>
    <tr>
      <th>6 </th>
      <td>  148</td>
      <td>                                                                                                                                                                                                                      SDK/4.0.2</td>
    </tr>
    <tr>
      <th>7 </th>
      <td>  112</td>
      <td>                                                                                                                                                                                                     Spotify/70400610 (6; 2; 7)</td>
    </tr>
    <tr>
      <th>8 </th>
      <td>   72</td>
      <td>                                                                                                                                                                  Dalvik/1.6.0 (Linux; U; Android 4.3.1; GT-N7000 Build/JLS36I)</td>
    </tr>
    <tr>
      <th>9 </th>
      <td>   60</td>
      <td>                                                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 (Mobile; afma-sdk-a-v6.4.1)</td>
    </tr>
    <tr>
      <th>10</th>
      <td>   28</td>
      <td>                                                                                                                                                                 android-async-http/1.3.1 (http://loopj.com/android-async-http)</td>
    </tr>
    <tr>
      <th>11</th>
      <td>   24</td>
      <td> Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100/4.3.1(18)/samsung/GT-N7000</td>
    </tr>
    <tr>
      <th>12</th>
      <td>   20</td>
      <td>                                                                                                                                  com.google.android.youtube/5.3.32(Linux; U; Android 4.3.1; de_DE; GT-N7000 Build/JLS36I) gzip</td>
    </tr>
    <tr>
      <th>13</th>
      <td>    8</td>
      <td>                                                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 (Mobile; afma-sdk-a-v4.1.1)</td>
    </tr>
    <tr>
      <th>14</th>
      <td>    8</td>
      <td>                                                                                                                                                                 android-async-http/1.4.1 (http://loopj.com/android-async-http)</td>
    </tr>
    <tr>
      <th>15</th>
      <td>    8</td>
      <td>                                                                                                                                       com.google.android.youtube/5.3.32(Linux; U; Android 4.3.1; de_DE; GT-N7000 Build/JLS36I)</td>
    </tr>
    <tr>
      <th>16</th>
      <td>    4</td>
      <td>                                                                                                                                                                                                                        Android</td>
    </tr>
    <tr>
      <th>17</th>
      <td>    4</td>
      <td>                                                                                                                                                  GoogleAnalytics/1.4.2 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I)</td>
    </tr>
    <tr>
      <th>18</th>
      <td>    4</td>
      <td>                                                                                                                                                                 android-async-http/1.4.3 (http://loopj.com/android-async-http)</td>
    </tr>
    <tr>
      <th>19</th>
      <td>    4</td>
      <td>                                                                                                                                                                                          stagefright/1.2 (Linux;Android 4.3.1)</td>
    </tr>
    <tr>
      <th>20</th>
      <td>    0</td>
      <td>                                                                                                                                                                                                                           None</td>
    </tr>
  </tbody>
</table>
</div>




```

```

## GET Requests


```
p3 = pdsql.read_frame(""" 
    SELECT h.frame_number, h.ip_dst, d.dns_query, h.request_method, h.request_uri, h.user_agent FROM http AS  h
    JOIN dns AS d ON h.ip_dst = d.dns_response
    WHERE lower(h.request_method) == 'get' AND
        -- Filter all rubish
        (h.request_uri NOT LIKE '%.gif'  AND 
         h.request_uri NOT LIKE '%.jpg'  AND
         h.request_uri NOT LIKE '%.jpeg' AND
         h.request_uri NOT LIKE '%.png'  AND
         h.request_uri NOT LIKE '%.gif'  AND
         h.request_uri NOT LIKE '%.css'  AND 
         h.request_uri NOT LIKE '%.html' AND
         h.request_uri NOT LIKE '%.js') 
    AND
        (d.dns_query NOT LIKE '%amazon%'   AND
         d.dns_query NOT LIKE '%fahrinfo%' AND
         d.dns_query NOT LIKE '%faz.net%'  AND
         d.dns_query NOT LIKE '%heute.de%' AND
         d.dns_query NOT LIKE '%twitter%'  AND
         d.dns_query NOT LIKE '%sueddeutsche%')
    
    GROUP by h.request_uri
    ORDER by d.dns_query
""", con)
p3.head(500)
```




<div style="max-height:1000px;max-width:1500px;overflow:auto;">
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>frame_number</th>
      <th>ip_dst</th>
      <th>dns_query</th>
      <th>request_method</th>
      <th>request_uri</th>
      <th>user_agent</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0  </th>
      <td>  95383</td>
      <td>    217.79.188.8</td>
      <td>                   adfarm1.adition.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       /js?wp_id=2501167</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>1  </th>
      <td>  39785</td>
      <td>   217.163.21.41</td>
      <td>                         ads.yahoo.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         /cms/v1?esig=1~b9bada6fffbf45c1ffda7783879fb5715486894a&amp;nwid=10000922750&amp;sigv=1</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>2  </th>
      <td>  44272</td>
      <td>      5.10.81.84</td>
      <td>                adx.fe02-sl.manage.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                        /2/win?_bi=4bq4p7Cn9VXzc3XTEz1wocSUpKU%3D&amp;_ei=10411&amp;_ecost1000000_adx=Utq7uQAM5S8K3tKEAABJJbJHrnHwdXabfQqUjg&amp;-mf=2&amp;-fi=86400&amp;age=0&amp;app=&amp;appi=&amp;appv=&amp;pt=app&amp;pi=com.iudesk.android.photo.editor&amp;p=com.iudesk.android.photo.editor&amp;zid=&amp;pcat=&amp;lat=&amp;lon=&amp;country=DEU&amp;gender=%3F&amp;isp=carrier&amp;netspd=dial-up&amp;model=gt-n7000&amp;os=Android&amp;osv=4.3.1&amp;region=&amp;zip=&amp;dma=0&amp;si=4&amp;_ua=Mozilla%2F5.0+%28Linux%3B+U%3B+Android+4.3.1%3B+de-de%3B+GT-N7000+Build%2FJLS36I%29+AppleWebKit%2F534.30+%28KHTML%2C+like+Gecko%29+Version%2F4.0+Mobile+Safari%2F534.30+%28Mobile%3B+afma-sdk-a-v6.4.1%29%2Cgzip%28gfe%29&amp;_uh=xid%3ACAESEDLJ4tolP4xNFA9ZOWuBZNM&amp;idx=2&amp;ai=209646&amp;_bid=0.00117&amp;sub5=fe02-sl</td>
      <td>                                                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 (Mobile; afma-sdk-a-v6.4.1)</td>
    </tr>
    <tr>
      <th>3  </th>
      <td>  43930</td>
      <td>    5.153.15.196</td>
      <td>                adx.fe08-sl.manage.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                        /2/win?_bi=HOq1iXrqnKD4Wtb8FdrWjdqewso%3D&amp;_ei=10411&amp;_ecost1000000_adx=Utq7BgAGYa0K3sdHAAAWKarWI_oJGLrPHIcJKg&amp;-mf=2&amp;-fi=86400&amp;age=0&amp;app=&amp;appi=&amp;appv=&amp;pt=app&amp;pi=com.iudesk.android.photo.editor&amp;p=com.iudesk.android.photo.editor&amp;zid=&amp;pcat=&amp;lat=&amp;lon=&amp;country=DEU&amp;gender=%3F&amp;isp=carrier&amp;netspd=dial-up&amp;model=gt-n7000&amp;os=Android&amp;osv=4.3.1&amp;region=&amp;zip=&amp;dma=0&amp;si=4&amp;_ua=Mozilla%2F5.0+%28Linux%3B+U%3B+Android+4.3.1%3B+de-de%3B+GT-N7000+Build%2FJLS36I%29+AppleWebKit%2F534.30+%28KHTML%2C+like+Gecko%29+Version%2F4.0+Mobile+Safari%2F534.30+%28Mobile%3B+afma-sdk-a-v6.4.1%29%2Cgzip%28gfe%29&amp;_uh=xid%3ACAESEDLJ4tolP4xNFA9ZOWuBZNM&amp;idx=1&amp;ai=209646&amp;_bid=0.00117&amp;sub5=fe08-sl</td>
      <td>                                                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 (Mobile; afma-sdk-a-v6.4.1)</td>
    </tr>
    <tr>
      <th>4  </th>
      <td>    130</td>
      <td> 173.194.116.169</td>
      <td>            android.clients.google.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           /generate_204</td>
      <td>                                                                                                                                                                  Dalvik/1.6.0 (Linux; U; Android 4.3.1; GT-N7000 Build/JLS36I)</td>
    </tr>
    <tr>
      <th>5  </th>
      <td>  90548</td>
      <td>  91.215.101.182</td>
      <td>                    andropit.ivwbox.de</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           /cgi-bin/ivw/CP/forum;?r=&amp;d=59106.27518314868</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>6  </th>
      <td>  43440</td>
      <td>    37.58.73.181</td>
      <td>                 api.geo.kontagent.net</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               /api/v1/0d868f5ce9434bdcafd869f2b11adae8/cpu/?os=android_18&amp;v_maj=4.4.2.254&amp;d=GT-N7000&amp;ts=1390065565&amp;s=218949477293337144&amp;c=o2+-+de&amp;kt_v=a1.3.1&amp;m=samsung</td>
      <td>                                                                                                                                                                 android-async-http/1.3.1 (http://loopj.com/android-async-http)</td>
    </tr>
    <tr>
      <th>7  </th>
      <td>  43478</td>
      <td>    37.58.73.181</td>
      <td>                 api.geo.kontagent.net</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             /api/v1/0d868f5ce9434bdcafd869f2b11adae8/evt/?n=Keyboard_Average_Daily_Time&amp;ts=1390065565&amp;s=218949477293337144&amp;kt_v=a1.3.1&amp;st1=KeyboardUses</td>
      <td>                                                                                                                                                                 android-async-http/1.3.1 (http://loopj.com/android-async-http)</td>
    </tr>
    <tr>
      <th>8  </th>
      <td>  43465</td>
      <td>    37.58.73.181</td>
      <td>                 api.geo.kontagent.net</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               /api/v1/0d868f5ce9434bdcafd869f2b11adae8/evt/?n=Keyboard_Total_Daily_Time&amp;ts=1390065565&amp;s=218949477293337144&amp;kt_v=a1.3.1&amp;st1=KeyboardUses</td>
      <td>                                                                                                                                                                 android-async-http/1.3.1 (http://loopj.com/android-async-http)</td>
    </tr>
    <tr>
      <th>9  </th>
      <td>  43453</td>
      <td>    37.58.73.181</td>
      <td>                 api.geo.kontagent.net</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               /api/v1/0d868f5ce9434bdcafd869f2b11adae8/evt/?n=Keyboard_Total_Daily_Uses&amp;ts=1390065565&amp;s=218949477293337144&amp;kt_v=a1.3.1&amp;st1=KeyboardUses</td>
      <td>                                                                                                                                                                 android-async-http/1.3.1 (http://loopj.com/android-async-http)</td>
    </tr>
    <tr>
      <th>10 </th>
      <td>  43488</td>
      <td>    37.58.73.181</td>
      <td>                 api.geo.kontagent.net</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            /api/v1/0d868f5ce9434bdcafd869f2b11adae8/pgr/?ts=1390065565&amp;s=218949477293337144&amp;kt_v=a1.3.1</td>
      <td>                                                                                                                                                                 android-async-http/1.3.1 (http://loopj.com/android-async-http)</td>
    </tr>
    <tr>
      <th>11 </th>
      <td>  43548</td>
      <td>    37.58.73.182</td>
      <td>                 api.geo.kontagent.net</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            /api/v1/0d868f5ce9434bdcafd869f2b11adae8/pgr/?ts=1390065632&amp;s=218949477293337144&amp;kt_v=a1.3.1</td>
      <td>                                                                                                                                                                 android-async-http/1.3.1 (http://loopj.com/android-async-http)</td>
    </tr>
    <tr>
      <th>12 </th>
      <td>  61181</td>
      <td>  54.228.232.253</td>
      <td>                        api.tunigo.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        /v3/space/genres?order=desc&amp;field=releaseDate_tdt&amp;suppress404=1&amp;product=&amp;per_page=100&amp;page=0&amp;suppress_response_codes=1&amp;region=DE</td>
      <td>                                                                                                                                                                 android-async-http/1.4.1 (http://loopj.com/android-async-http)</td>
    </tr>
    <tr>
      <th>13 </th>
      <td> 117707</td>
      <td>    78.31.12.120</td>
      <td>                 apresolve.spotify.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       /</td>
      <td>                                                                                                                                                                                                     Spotify/70400610 (6; 2; 7)</td>
    </tr>
    <tr>
      <th>14 </th>
      <td>  39796</td>
      <td>    2.23.186.235</td>
      <td>                     bh.contextweb.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        /bh/rtset?pid=557477&amp;ev=&amp;rurl=http%3A%2F%2Fs.amazon-adsystem.com%2Fecm3%3Fid%3D%25%25ENCRYPTED_VGUID%25%25%26ex%3Dpulsepoint.com</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>15 </th>
      <td>  39784</td>
      <td>   173.241.240.6</td>
      <td>                         bid.openx.net</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     /cm?pid=e818ca1e-0c23-caa8-0dd3-096b0ada08b7&amp;dst=http%3A%2F%2Fs.amazon-adsystem.com%2Fecm3%3Fex%3Dopenx.com%26id%3D</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>16 </th>
      <td>  34169</td>
      <td>   54.230.94.185</td>
      <td>                     cdn.flipboard.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    /flipmag?url=http%3A%2F%2Fcdn.flipboard.com%2Fstern.de%2Finlineaml_3Dtrue%2F26e36cfec35abad0c372f74d1c472f84912677b0%2F849604d1e7bde34b05ed7967d066a6ccdcdb400e%2Farticle.html&amp;campaignTarget=flipboard%2Fmix%252F30924883&amp;partner=rss-stern&amp;tml=templates%2Fiphone%2Fgeneric-9690bc.html&amp;section=flipboard%2Fmix%252F30924883&amp;fallbackTml=templates%2Fiphone%2Fgeneric-9690bc.html&amp;formFactor=phone</td>
      <td> Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100/4.3.1(18)/samsung/GT-N7000</td>
    </tr>
    <tr>
      <th>17 </th>
      <td>  89725</td>
      <td>  74.125.128.120</td>
      <td>                       csi.gstatic.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            /csi?v=3&amp;s=gmob&amp;action=&amp;rt=crf.1146,cri.3167</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>18 </th>
      <td>  89618</td>
      <td>  74.125.128.120</td>
      <td>                       csi.gstatic.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              /csi?v=3&amp;s=gmob&amp;action=&amp;rt=crf.12,cri.1029</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>19 </th>
      <td>  20874</td>
      <td>    23.21.95.178</td>
      <td>                     d.shareaholic.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 /dough/1.0/mixer.gif?p_name=AN&amp;p_id=7789992519211014773</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>20 </th>
      <td>  20818</td>
      <td>    23.21.95.178</td>
      <td>                     d.shareaholic.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      /dough/1.0/oven/?referrer=http%3A%2F%2Fflipboard.com%2Fredirect%3Furl%3Dhttp%253A%252F%252Fintelcrawler.com%252Fabout%252Fpress07&amp;platform=website</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>21 </th>
      <td>  90562</td>
      <td>   91.215.103.65</td>
      <td>                            de.ioam.de</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 /tx.io?st=andropit&amp;cp=forum&amp;pt=CP&amp;rf=&amp;r2=&amp;ur=www.androidpit.de&amp;xy=800x1280x32&amp;lo=DE%2Fn.a.&amp;cb=0001&amp;vr=303&amp;id=2gf46s&amp;lt=1390123647701&amp;ev=&amp;cs=eytiao&amp;mo=1</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>22 </th>
      <td> 136930</td>
      <td>   91.215.103.65</td>
      <td>                            de.ioam.de</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 /tx.io?st=mobfaz&amp;cp=222F000006E6&amp;sv=mo&amp;co=kommentar&amp;pt=CP&amp;rf=&amp;r2=&amp;ur=m.faz.net&amp;xy=800x1280x32&amp;lo=DE%2Fn.a.&amp;cb=0001&amp;vr=303&amp;id=y6dim4&amp;lt=1390147720004&amp;ev=&amp;cs=o2c483&amp;mo=1</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>23 </th>
      <td>  12723</td>
      <td>   91.215.103.65</td>
      <td>                            de.ioam.de</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 /tx.io?st=mobfaz&amp;cp=222F000006E7&amp;sv=mo&amp;co=kommentar&amp;pt=CP&amp;rf=&amp;r2=&amp;ur=m.faz.net&amp;xy=800x1280x32&amp;lo=DE%2Fn.a.&amp;cb=0004&amp;vr=303&amp;id=vngwhf&amp;lt=1390051123113&amp;ev=&amp;cs=aooae9&amp;mo=1</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>24 </th>
      <td>  11760</td>
      <td>   91.215.103.65</td>
      <td>                            de.ioam.de</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 /tx.io?st=mobheute&amp;cp=%2FZH%2Fheutede&amp;co=%2Fbeitrag%2FBlitzeinschlag%3A.Christus-Statue.verliert.Finger%2F31536732&amp;pt=CP&amp;rf=&amp;r2=&amp;ur=m.heute.de&amp;xy=800x1280x32&amp;lo=DE%2Fn.a.&amp;cb=0007&amp;vr=303&amp;id=vngwhf&amp;lt=1390051093712&amp;ev=&amp;cs=dbhkky&amp;mo=1</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>25 </th>
      <td>  16038</td>
      <td>   91.215.103.65</td>
      <td>                            de.ioam.de</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         /tx.io?st=mobsued&amp;cp=spracheDE%2FformatTXT%2FerzeugerRED%2FhomepageNO%2FauslieferungMOB%2FappNO%2FpaidNO%2FinhaltDIGITAL&amp;pt=CP&amp;rf=flipboard.com&amp;r2=http%3A%2F%2Fflipboard.com%2Fredirect%3Furl%3Dhttp%253A%252F%252Fwww.sueddeutsche.de%252Fdigital%252Fstreamseite-redtube-loechriges-gutachten-bringt-porno-abmahner-in-bedraengnis-1.1866025&amp;ur=www.sueddeutsche.de&amp;xy=800x1280x32&amp;lo=DE%2Fn.a.&amp;cb=0004&amp;vr=303&amp;id=vngwhf&amp;lt=1390051326056&amp;ev=&amp;cs=cn5je0&amp;mo=0</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>26 </th>
      <td> 132412</td>
      <td>   91.215.103.65</td>
      <td>                            de.ioam.de</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       /tx.io?st=mobsued&amp;cp=spracheDE%2FformatTXT%2FerzeugerRED%2FhomepageNO%2FauslieferungMOB%2FappNO%2FpaidNO%2FinhaltKARRIERE&amp;pt=CP&amp;rf=flipboard.com&amp;r2=http%3A%2F%2Fflipboard.com%2Fredirect%3Furl%3Dhttp%253A%252F%252Fwww.sueddeutsche.de%252Fkarriere%252Fstudie-hunderttausende-akademiker-arbeiten-fuer-niedrigloehne-1.1866212&amp;ur=www.sueddeutsche.de&amp;xy=800x1280x32&amp;lo=DE%2Fn.a.&amp;cb=0001&amp;vr=303&amp;id=y6dim4&amp;lt=1390147627064&amp;ev=&amp;cs=nkfe26&amp;mo=0</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>27 </th>
      <td>   3835</td>
      <td>   91.215.103.65</td>
      <td>                            de.ioam.de</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     /tx.io?st=mobsued&amp;cp=spracheDE%2FformatTXT%2FerzeugerRED%2FhomepageNO%2FauslieferungMOB%2FappNO%2FpaidNO%2FinhaltMUENCHEN&amp;pt=CP&amp;rf=flipboard.com&amp;r2=http%3A%2F%2Fflipboard.com%2Fredirect%3Furl%3Dhttp%253A%252F%252Fwww.sueddeutsche.de%252Fmuenchen%252Fmuenchen-haidhausen-ploetzlich-zehn-meter-tiefes-loch-im-gehweg-1.1866074&amp;ur=www.sueddeutsche.de&amp;xy=800x1280x32&amp;lo=DE%2Fn.a.&amp;cb=0004&amp;vr=303&amp;id=vngwhf&amp;lt=1390050885098&amp;ev=&amp;cs=oshi9b&amp;mo=0</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>28 </th>
      <td>  16134</td>
      <td>   77.72.116.154</td>
      <td>                       de.sitestat.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          /sueddeutsche/sueddeutsche/s?mobile.digital.thema.streaming.artikel.streamseite-redtube-loechriges-gutachten-bringt-porno-abmahner-in-bedraengnis&amp;ns__t=1390051326068&amp;ads=y&amp;ns_referrer=http%3A//flipboard.com/redirect%3Furl%3Dhttp%253A%252F%252Fwww.sueddeutsche.de%252Fdigital%252Fstreamseite-redtube-loechriges-gutachten-bringt-porno-abmahner-in-bedraengnis-1.1866025</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>29 </th>
      <td> 132425</td>
      <td>   77.72.118.154</td>
      <td>                       de.sitestat.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      /sueddeutsche/sueddeutsche/s?mobile.karriere.thema.hochschulen.artikel.studie-hunderttausende-akademiker-arbeiten-fuer-niedrigloehne&amp;ns__t=1390147627074&amp;ads=y&amp;ns_referrer=http%3A//flipboard.com/redirect%3Furl%3Dhttp%253A%252F%252Fwww.sueddeutsche.de%252Fkarriere%252Fstudie-hunderttausende-akademiker-arbeiten-fuer-niedrigloehne-1.1866212</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>30 </th>
      <td>   4128</td>
      <td>   77.72.112.154</td>
      <td>                       de.sitestat.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       /sueddeutsche/sueddeutsche/s?mobile.muenchen.thema.unfall.artikel.muenchen-haidhausen-ploetzlich-zehn-meter-tiefes-loch-im-gehweg&amp;ns__t=1390050885114&amp;ads=y&amp;ns_referrer=http%3A//flipboard.com/redirect%3Furl%3Dhttp%253A%252F%252Fwww.sueddeutsche.de%252Fmuenchen%252Fmuenchen-haidhausen-ploetzlich-zehn-meter-tiefes-loch-im-gehweg-1.1866074</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>31 </th>
      <td>   4555</td>
      <td>   77.72.112.154</td>
      <td>                       de.sitestat.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               /sueddeutsche/sueddeutsche/s?mobile.muenchen.thema.unfall.artikel.muenchen-haidhausen-ploetzlich-zehn-meter-tiefes-loch-im-gehweg&amp;ns_m2=yes&amp;ns_setsiteck=52DA7E4843FD03B2&amp;ns__t=1390050885114&amp;ads=y&amp;ns_referrer=http%3A//flipboard.com/redirect%3Furl%3Dhttp%253A%252F%252Fwww.sueddeutsche.de%252Fmuenchen%252Fmuenchen-haidhausen-ploetzlich-zehn-meter-tiefes-loch-im-gehweg-1.1866074</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>32 </th>
      <td>  73954</td>
      <td>  173.194.112.46</td>
      <td>                         dl.google.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           /dl/android/tts/patts/patts_metadata_19.proto</td>
      <td>                                                                                                                                                                  Dalvik/1.6.0 (Linux; U; Android 4.3.1; GT-N7000 Build/JLS36I)</td>
    </tr>
    <tr>
      <th>33 </th>
      <td>  18084</td>
      <td>   209.49.108.71</td>
      <td>                         e.apsalar.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          /api/v1/event?a=Flipboard&amp;av=2.2.2&amp;e=%7B%7D&amp;i=flipboard.app&amp;n=end_session&amp;p=Android&amp;rt=json&amp;s=12c8430f-d6e8-4b8b-a81b-37d42dc6bf6f&amp;sdk=4.0.2&amp;t=781.191&amp;u=19ba7bd21bb3cfa3&amp;lag=0.001&amp;h=3eb6859c2b7b4872d0903a5bd5b73e46d79997aa</td>
      <td>                                                                                                                                                                                                                      SDK/4.0.2</td>
    </tr>
    <tr>
      <th>34 </th>
      <td>  46752</td>
      <td>  205.158.23.232</td>
      <td>                         e.apsalar.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           /api/v1/event?a=Flipboard&amp;av=2.2.2&amp;e=%7B%7D&amp;i=flipboard.app&amp;n=end_session&amp;p=Android&amp;rt=json&amp;s=4ed8a8b6-82c0-4232-a5ce-0ff0acf87c0b&amp;sdk=4.0.2&amp;t=80.056&amp;u=19ba7bd21bb3cfa3&amp;lag=0.001&amp;h=e8da70f8d71b5ac6e44efe3651611d6ee9284ad5</td>
      <td>                                                                                                                                                                                                                      SDK/4.0.2</td>
    </tr>
    <tr>
      <th>35 </th>
      <td>  22734</td>
      <td>   209.49.108.66</td>
      <td>                         e.apsalar.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          /api/v1/event?a=Flipboard&amp;av=2.2.2&amp;e=%7B%7D&amp;i=flipboard.app&amp;n=end_session&amp;p=Android&amp;rt=json&amp;s=5ad3eb54-8955-40e7-8108-c558e6adc919&amp;sdk=4.0.2&amp;t=194.835&amp;u=19ba7bd21bb3cfa3&amp;lag=0.001&amp;h=705f56c0c458b75d9907a3d50af5a2ad0c01e307</td>
      <td>                                                                                                                                                                                                                      SDK/4.0.2</td>
    </tr>
    <tr>
      <th>36 </th>
      <td>  87872</td>
      <td>  205.158.23.245</td>
      <td>                         e.apsalar.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               /api/v1/event?a=Flipboard&amp;av=2.2.2&amp;e=%7B%7D&amp;i=flipboard.app&amp;n=end_session&amp;p=Android&amp;rt=json&amp;s=7cd33003-f7df-4eeb-b1c5-572fb46798f1&amp;sdk=4.0.2&amp;t=140.42000000000002&amp;u=19ba7bd21bb3cfa3&amp;lag=0.001&amp;h=409ba731c26ccb1509051b0b00a8fe83cb893026</td>
      <td>                                                                                                                                                                                                                      SDK/4.0.2</td>
    </tr>
    <tr>
      <th>37 </th>
      <td>  34245</td>
      <td>  205.158.23.246</td>
      <td>                         e.apsalar.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                /api/v1/event?a=Flipboard&amp;av=2.2.2&amp;e=%7B%7D&amp;i=flipboard.app&amp;n=end_session&amp;p=Android&amp;rt=json&amp;s=8e65194d-96a8-407c-9df6-893a56160c2a&amp;sdk=4.0.2&amp;t=1.390057933191E9&amp;u=19ba7bd21bb3cfa3&amp;lag=83.558&amp;h=250884806d5e537fcebc7f11f751441409667f4c</td>
      <td>                                                                                                                                                                                                                      SDK/4.0.2</td>
    </tr>
    <tr>
      <th>38 </th>
      <td>  32709</td>
      <td>  205.158.23.239</td>
      <td>                         e.apsalar.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          /api/v1/event?a=Flipboard&amp;av=2.2.2&amp;e=%7B%7D&amp;i=flipboard.app&amp;n=end_session&amp;p=Android&amp;rt=json&amp;s=8e65194d-96a8-407c-9df6-893a56160c2a&amp;sdk=4.0.2&amp;t=246.213&amp;u=19ba7bd21bb3cfa3&amp;lag=0.002&amp;h=ba36888f3bdbc623ae733fe6ddb4a7e9d3970329</td>
      <td>                                                                                                                                                                                                                      SDK/4.0.2</td>
    </tr>
    <tr>
      <th>39 </th>
      <td>  32913</td>
      <td>  205.158.23.230</td>
      <td>                         e.apsalar.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         /api/v1/event?a=Flipboard&amp;av=2.2.2&amp;e=%7B%7D&amp;i=flipboard.app&amp;n=end_session&amp;p=Android&amp;rt=json&amp;s=8e65194d-96a8-407c-9df6-893a56160c2a&amp;sdk=4.0.2&amp;t=246.213&amp;u=19ba7bd21bb3cfa3&amp;lag=17.977&amp;h=f656c2496cc7e5754b5a481eaa5e1301149f00a7</td>
      <td>                                                                                                                                                                                                                      SDK/4.0.2</td>
    </tr>
    <tr>
      <th>40 </th>
      <td>  91401</td>
      <td>  205.158.23.245</td>
      <td>                         e.apsalar.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               /api/v1/event?a=Flipboard&amp;av=2.2.2&amp;e=%7B%7D&amp;i=flipboard.app&amp;n=end_session&amp;p=Android&amp;rt=json&amp;s=96e5aa98-f272-4435-be3f-06d014cd8a7b&amp;sdk=4.0.2&amp;t=100.32600000000001&amp;u=19ba7bd21bb3cfa3&amp;lag=0.002&amp;h=23a34f980019b660ae6d68cea5d60d495d3b513c</td>
      <td>                                                                                                                                                                                                                      SDK/4.0.2</td>
    </tr>
    <tr>
      <th>41 </th>
      <td> 116489</td>
      <td>  205.158.23.232</td>
      <td>                         e.apsalar.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  /api/v1/event?a=Flipboard&amp;av=2.2.2&amp;e=%7B%7D&amp;i=flipboard.app&amp;n=end_session&amp;p=Android&amp;rt=json&amp;s=e9ae671b-3968-48bd-bbf6-87c60f5c0e40&amp;sdk=4.0.2&amp;t=86.96000000000001&amp;u=19ba7bd21bb3cfa3&amp;lag=0.0&amp;h=a662c61a8e06173f3bbb43d2dd03509ca773877c</td>
      <td>                                                                                                                                                                                                                      SDK/4.0.2</td>
    </tr>
    <tr>
      <th>42 </th>
      <td>  12218</td>
      <td>  205.158.23.239</td>
      <td>                         e.apsalar.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  /api/v1/event?a=Flipboard&amp;av=2.2.2&amp;e=&amp;i=flipboard.app&amp;n=heartbeat&amp;p=Android&amp;rt=json&amp;s=12c8430f-d6e8-4b8b-a81b-37d42dc6bf6f&amp;sdk=4.0.2&amp;t=301.022&amp;u=19ba7bd21bb3cfa3&amp;lag=0.029&amp;h=29e3483b07cf05a365a247e4820f61a1b75159c7</td>
      <td>                                                                                                                                                                                                                      SDK/4.0.2</td>
    </tr>
    <tr>
      <th>43 </th>
      <td> 137318</td>
      <td>  205.158.23.230</td>
      <td>                         e.apsalar.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  /api/v1/event?a=Flipboard&amp;av=2.2.2&amp;e=&amp;i=flipboard.app&amp;n=heartbeat&amp;p=Android&amp;rt=json&amp;s=4f544310-2c2f-4dcf-9bef-762535fcb4c1&amp;sdk=4.0.2&amp;t=301.277&amp;u=19ba7bd21bb3cfa3&amp;lag=0.001&amp;h=4c805327cfb1d98f8dcba5ea9b4a09aba7be887b</td>
      <td>                                                                                                                                                                                                                      SDK/4.0.2</td>
    </tr>
    <tr>
      <th>44 </th>
      <td>  34520</td>
      <td>  205.158.23.246</td>
      <td>                         e.apsalar.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      /api/v1/event?u=-1</td>
      <td>                                                                                                                                                                                                                      SDK/4.0.2</td>
    </tr>
    <tr>
      <th>45 </th>
      <td>   1334</td>
      <td>  205.158.23.239</td>
      <td>                         e.apsalar.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       /api/v1/start?a=Flipboard&amp;ab=armeabi-v7a&amp;av=2.2.2&amp;br=Samsung&amp;c=wwan&amp;de=GT-N7000&amp;i=flipboard.app&amp;ma=samsung&amp;mo=GT-N7000&amp;n=Flipboard&amp;p=Android&amp;pr=GT-N7000&amp;rt=json&amp;s=12c8430f-d6e8-4b8b-a81b-37d42dc6bf6f&amp;sdk=4.0.2&amp;u=19ba7bd21bb3cfa3&amp;v=4.3.1&amp;lag=0.976&amp;h=13e2981c856f8d5b03df533875ab0e7051b16ad4</td>
      <td>                                                                                                                                                                                                                      SDK/4.0.2</td>
    </tr>
    <tr>
      <th>46 </th>
      <td> 121056</td>
      <td>   209.49.108.65</td>
      <td>                         e.apsalar.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       /api/v1/start?a=Flipboard&amp;ab=armeabi-v7a&amp;av=2.2.2&amp;br=Samsung&amp;c=wwan&amp;de=GT-N7000&amp;i=flipboard.app&amp;ma=samsung&amp;mo=GT-N7000&amp;n=Flipboard&amp;p=Android&amp;pr=GT-N7000&amp;rt=json&amp;s=4c161362-9275-473d-9068-14098d15ef54&amp;sdk=4.0.2&amp;u=19ba7bd21bb3cfa3&amp;v=4.3.1&amp;lag=1.732&amp;h=d285ad812ebea1d8d0a0682f54d618c3bf6900b9</td>
      <td>                                                                                                                                                                                                                      SDK/4.0.2</td>
    </tr>
    <tr>
      <th>47 </th>
      <td>  45215</td>
      <td>  205.158.23.232</td>
      <td>                         e.apsalar.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       /api/v1/start?a=Flipboard&amp;ab=armeabi-v7a&amp;av=2.2.2&amp;br=Samsung&amp;c=wwan&amp;de=GT-N7000&amp;i=flipboard.app&amp;ma=samsung&amp;mo=GT-N7000&amp;n=Flipboard&amp;p=Android&amp;pr=GT-N7000&amp;rt=json&amp;s=4ed8a8b6-82c0-4232-a5ce-0ff0acf87c0b&amp;sdk=4.0.2&amp;u=19ba7bd21bb3cfa3&amp;v=4.3.1&amp;lag=1.494&amp;h=a56e9b60daae1674ec4c759d4601521221e2f58a</td>
      <td>                                                                                                                                                                                                                      SDK/4.0.2</td>
    </tr>
    <tr>
      <th>48 </th>
      <td> 126436</td>
      <td>  205.158.23.230</td>
      <td>                         e.apsalar.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       /api/v1/start?a=Flipboard&amp;ab=armeabi-v7a&amp;av=2.2.2&amp;br=Samsung&amp;c=wwan&amp;de=GT-N7000&amp;i=flipboard.app&amp;ma=samsung&amp;mo=GT-N7000&amp;n=Flipboard&amp;p=Android&amp;pr=GT-N7000&amp;rt=json&amp;s=4f544310-2c2f-4dcf-9bef-762535fcb4c1&amp;sdk=4.0.2&amp;u=19ba7bd21bb3cfa3&amp;v=4.3.1&amp;lag=1.244&amp;h=5603e16f6b981f61f47be74396dc7879580d401a</td>
      <td>                                                                                                                                                                                                                      SDK/4.0.2</td>
    </tr>
    <tr>
      <th>49 </th>
      <td>  18474</td>
      <td>   209.49.108.71</td>
      <td>                         e.apsalar.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       /api/v1/start?a=Flipboard&amp;ab=armeabi-v7a&amp;av=2.2.2&amp;br=Samsung&amp;c=wwan&amp;de=GT-N7000&amp;i=flipboard.app&amp;ma=samsung&amp;mo=GT-N7000&amp;n=Flipboard&amp;p=Android&amp;pr=GT-N7000&amp;rt=json&amp;s=5ad3eb54-8955-40e7-8108-c558e6adc919&amp;sdk=4.0.2&amp;u=19ba7bd21bb3cfa3&amp;v=4.3.1&amp;lag=1.178&amp;h=7e5b2e6faf5f4e13e071e19f7b18a2036e4f8c99</td>
      <td>                                                                                                                                                                                                                      SDK/4.0.2</td>
    </tr>
    <tr>
      <th>50 </th>
      <td>  99004</td>
      <td>   209.49.108.66</td>
      <td>                         e.apsalar.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       /api/v1/start?a=Flipboard&amp;ab=armeabi-v7a&amp;av=2.2.2&amp;br=Samsung&amp;c=wwan&amp;de=GT-N7000&amp;i=flipboard.app&amp;ma=samsung&amp;mo=GT-N7000&amp;n=Flipboard&amp;p=Android&amp;pr=GT-N7000&amp;rt=json&amp;s=6760c71d-2ef1-4482-b465-f07bb91abe81&amp;sdk=4.0.2&amp;u=19ba7bd21bb3cfa3&amp;v=4.3.1&amp;lag=0.165&amp;h=1ab03e483d1330b35abba17936a9f516f4455f37</td>
      <td>                                                                                                                                                                                                                      SDK/4.0.2</td>
    </tr>
    <tr>
      <th>51 </th>
      <td>  83526</td>
      <td>  205.158.23.245</td>
      <td>                         e.apsalar.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       /api/v1/start?a=Flipboard&amp;ab=armeabi-v7a&amp;av=2.2.2&amp;br=Samsung&amp;c=wwan&amp;de=GT-N7000&amp;i=flipboard.app&amp;ma=samsung&amp;mo=GT-N7000&amp;n=Flipboard&amp;p=Android&amp;pr=GT-N7000&amp;rt=json&amp;s=7cd33003-f7df-4eeb-b1c5-572fb46798f1&amp;sdk=4.0.2&amp;u=19ba7bd21bb3cfa3&amp;v=4.3.1&amp;lag=1.351&amp;h=f520aae0f0556292cbb16e64e13a1945509fd257</td>
      <td>                                                                                                                                                                                                                      SDK/4.0.2</td>
    </tr>
    <tr>
      <th>52 </th>
      <td>  27685</td>
      <td>  205.158.23.231</td>
      <td>                         e.apsalar.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       /api/v1/start?a=Flipboard&amp;ab=armeabi-v7a&amp;av=2.2.2&amp;br=Samsung&amp;c=wwan&amp;de=GT-N7000&amp;i=flipboard.app&amp;ma=samsung&amp;mo=GT-N7000&amp;n=Flipboard&amp;p=Android&amp;pr=GT-N7000&amp;rt=json&amp;s=8e65194d-96a8-407c-9df6-893a56160c2a&amp;sdk=4.0.2&amp;u=19ba7bd21bb3cfa3&amp;v=4.3.1&amp;lag=1.564&amp;h=9e389c83ed0ad2fc6cfb55483654aed3857f5603</td>
      <td>                                                                                                                                                                                                                      SDK/4.0.2</td>
    </tr>
    <tr>
      <th>53 </th>
      <td>  89800</td>
      <td>  205.158.23.245</td>
      <td>                         e.apsalar.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       /api/v1/start?a=Flipboard&amp;ab=armeabi-v7a&amp;av=2.2.2&amp;br=Samsung&amp;c=wwan&amp;de=GT-N7000&amp;i=flipboard.app&amp;ma=samsung&amp;mo=GT-N7000&amp;n=Flipboard&amp;p=Android&amp;pr=GT-N7000&amp;rt=json&amp;s=96e5aa98-f272-4435-be3f-06d014cd8a7b&amp;sdk=4.0.2&amp;u=19ba7bd21bb3cfa3&amp;v=4.3.1&amp;lag=0.232&amp;h=8bc0f1a369ef2190d4be0d19776c98e81b4c2e1f</td>
      <td>                                                                                                                                                                                                                      SDK/4.0.2</td>
    </tr>
    <tr>
      <th>54 </th>
      <td> 112905</td>
      <td>  205.158.23.232</td>
      <td>                         e.apsalar.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          /api/v1/start?a=Flipboard&amp;ab=armeabi-v7a&amp;av=2.2.2&amp;br=Samsung&amp;c=wwan&amp;de=GT-N7000&amp;i=flipboard.app&amp;ma=samsung&amp;mo=GT-N7000&amp;n=Flipboard&amp;p=Android&amp;pr=GT-N7000&amp;rt=json&amp;s=e9ae671b-3968-48bd-bbf6-87c60f5c0e40&amp;sdk=4.0.2&amp;u=19ba7bd21bb3cfa3&amp;v=4.3.1&amp;lag=1.2610000000000001&amp;h=9e3ccea7d91a68c3817076e79398c8575f547e07</td>
      <td>                                                                                                                                                                                                                      SDK/4.0.2</td>
    </tr>
    <tr>
      <th>55 </th>
      <td>   4119</td>
      <td>    176.9.103.51</td>
      <td>                       farm.plista.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            /getuid?origin=http%3A%2F%2Fwww.sueddeutsche.de&amp;publickey=a279c87dd4de76f6f1bf200a&amp;mode=test</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>56 </th>
      <td>  16440</td>
      <td>    176.9.103.51</td>
      <td>                       farm.plista.com</td>
      <td> GET</td>
      <td>         /tinyPlistaGetRendered.php?publickey=a279c87dd4de76f6f1bf200a&amp;widgetname=mobile&amp;c=digital&amp;pxr=1.6699999570846558&amp;isid=%20undefined&amp;item%5Bobjectid%5D=m1866025&amp;item%5Bcreated_at%5D=1390035621&amp;item%5Burl%5D=http%3A%2F%2Fwww.sueddeutsche.de%2Fdigital%2Fstreamseite-redtube-loechriges-gutachten-bringt-porno-abmahner-in-bedraengnis-1.1866025&amp;item%5Bkicker%5D=Streamseite%20Redtube&amp;item%5Btitle%5D=L%C3%B6chriges%20Gutachten%20bringt%20Porno-Abmahner%20in%20Bedr%C3%A4ngnis&amp;item%5Btext%5D=Wie%20kamen%20sie%20an%20die%20IP-Adressen%20der%20Redtube-Nutzer%3F%20Ein%20jetzt%20aufgetauchtes%2C%20fragw%C3%BCrdiges%20Gutachten%20birgt%20neuen%20%C3%84rger%20f%C3%BCr%20die%20Hinterm%C3%A4nner%20der%20Abmahnwelle.%20Doch%20auch%20f%C3%BCr%20einige%20K%C3%B6lner%20Richter%20ist%20das%20Papier%20eine%20Blamage.&amp;item%5Bimg%5D=http%3A%2F%2Fpolpix.sueddeutsche.com%2Fbild%2F1.1839719.1389206254%2F560x315%2Fredtube-abmahnung.jpg&amp;item%5Bcategory%5D=digital&amp;instanceID=&amp;Pookie=Q2C1zHwmoPb4ncSlaUvJGQ%3D%3D</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>57 </th>
      <td>   4136</td>
      <td>    176.9.103.51</td>
      <td>                       farm.plista.com</td>
      <td> GET</td>
      <td>                                                              /tinyPlistaGetRendered.php?publickey=a279c87dd4de76f6f1bf200a&amp;widgetname=mobile&amp;c=muenchen&amp;pxr=1.6699999570846558&amp;isid=%20undefined&amp;item%5Bobjectid%5D=m1866074&amp;item%5Bcreated_at%5D=1390047141&amp;item%5Burl%5D=http%3A%2F%2Fwww.sueddeutsche.de%2Fmuenchen%2Fmuenchen-haidhausen-ploetzlich-zehn-meter-tiefes-loch-im-gehweg-1.1866074&amp;item%5Bkicker%5D=M%C3%BCnchen-Haidhausen&amp;item%5Btitle%5D=Pl%C3%B6tzlich%20zehn%20Meter%20tiefes%20Loch%20im%20Gehweg&amp;item%5Btext%5D=T%C3%BCckische%20Falle%20in%20Haidhausen%3A%20Auf%20einem%20Gehsteig%20in%20M%C3%BCnchen%20ist%20ein%20Mann%20fast%20in%20ein%20zehn%20Meter%20tiefes%20Loch%20eingebrochen.%20Jetzt%20r%C3%A4tseln%20die%20Beh%C3%B6rden%2C%20wozu%20der%20gemauerte%20Schacht%20dienen%20k%C3%B6nnte.&amp;item%5Bimg%5D=http%3A%2F%2Fpolpix.sueddeutsche.com%2Fpolopoly_fs%2F1.1866075.1390044549!%2FhttpImage%2Fimage.jpg_gen%2Fderivatives%2F560x315%2Fimage.jpg&amp;item%5Bcategory%5D=muenchen&amp;instanceID=&amp;Pookie=</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>58 </th>
      <td> 136960</td>
      <td>   193.46.63.233</td>
      <td>                         faz.ivwbox.de</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       /cgi-bin/ivw/CP/szmmobil_222F000006E6;faz.net/aktuell/mobil/ressorts/gesellschaft?n=&amp;d=1390147719</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>59 </th>
      <td>  12765</td>
      <td>   193.46.63.233</td>
      <td>                         faz.ivwbox.de</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         /cgi-bin/ivw/CP/szmmobil_222F000006E7;faz.net/aktuell/mobil/ressorts/wirtschaft?n=&amp;d=1390051122</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>60 </th>
      <td>  34317</td>
      <td>   107.20.177.34</td>
      <td>                  fbprod.flipboard.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  /init3.php?callback=callbackTable.jsonpCallback1146518</td>
      <td> Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100/4.3.1(18)/samsung/GT-N7000</td>
    </tr>
    <tr>
      <th>61 </th>
      <td>  35821</td>
      <td>   107.20.177.34</td>
      <td>                  fbprod.flipboard.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   /load?app=aml&amp;action=load&amp;page=1&amp;sess=3352901904944345600.1390058020.s&amp;id=3743464895410673152.1390039154.u&amp;ts=1390058021.101&amp;tz=-60&amp;url=http%253A%252F%252Fwww.stern.de%252Fpolitik%252Fdeutschland%252Fwahlen-zum-ministerpraesidenten-in-hessen-volker-bouffier-setzt-sich-gegen-max-mustermann-durch-2083964.html%2523utm_source%253Dstandard%252526utm_medium%253Drss-feed%252526utm_campaign%253Dalle&amp;fr=fl&amp;articleType=article&amp;totalPages=1&amp;section=flipboard%2Fmix%252F30924883&amp;pr=rss-stern&amp;dv=aphone&amp;amv=2.4</td>
      <td> Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100/4.3.1(18)/samsung/GT-N7000</td>
    </tr>
    <tr>
      <th>62 </th>
      <td>  98600</td>
      <td>  173.194.70.121</td>
      <td>                     feeds.reuters.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      /Reuters/worldNews</td>
      <td>                                                                                                                                                                                                              Ultimate DayDream</td>
    </tr>
    <tr>
      <th>63 </th>
      <td>  73977</td>
      <td>     2.16.216.19</td>
      <td>                      gllto.glpals.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          /rtistatus.dat</td>
      <td>                                                                                                                                                                                                                           None</td>
    </tr>
    <tr>
      <th>64 </th>
      <td>  43894</td>
      <td> 173.194.116.185</td>
      <td>           googleads.g.doubleclick.net</td>
      <td> GET</td>
      <td>                                                                                                                /mads/gma?preqs=0&amp;session_id=17592708045346502934&amp;u_sd=1.6750001&amp;seq_num=1&amp;u_w=477&amp;msid=com.iudesk.android.photo.editor&amp;js=afma-sdk-a-v6.4.1&amp;ms=nb-L0MAMQe8GvfY_GF6rij7OVhr7yp8iklRfdZEsobLfPN2V1HAwhr3fZaYYsV8OvnBAI7zvDSK59SGWlN8KYfs6k4fUhLp8gwe1zJEHx3aqI1SDtGvoMoDutEe208dqebTP_5d2Ydk4yTNoeVXbACMjJRSOmtoMcMr-P84vo-d1J-36mfPUt4gIueReT9-a1nSfXwrGJ2asIUygSe5Z6OG2q805BRqRtNkbyhnefM7MheC_wWGiqgvdJHjrKa5AZu78GZhAyaseI89idFJ7Qm8Tp4ngsn93gewdu0PP_xJnsQp1DTgrzZMJINW9n2AiZO0CZz5d7vxXMqtPlnNReA&amp;mv=80240021.com.android.vending&amp;bas_off=0&amp;format=320x50_mb&amp;oar=0&amp;net=ed&amp;app_name=2014010100.android.com.iudesk.android.photo.editor&amp;hl=de&amp;gnt=8&amp;u_h=764&amp;carrier=26207&amp;bas_on=0&amp;ptime=0&amp;u_audio=3&amp;imbf=8009&amp;u_so=p&amp;output=html&amp;region=mobile_app&amp;u_tz=60&amp;client_sdk=1&amp;ex=1&amp;slotname=a14ecccef2eb8b3&amp;gsb=4g&amp;caps=inlineVideo_interactiveVideo_mraid1_th_mediation_sdkAdmobApiForAds_di&amp;eid=46621027&amp;jsv=66&amp;urll=935</td>
      <td>                                                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 (Mobile; afma-sdk-a-v6.4.1)</td>
    </tr>
    <tr>
      <th>65 </th>
      <td>  44015</td>
      <td> 173.194.116.185</td>
      <td>           googleads.g.doubleclick.net</td>
      <td> GET</td>
      <td>                                                                                             /mads/gma?preqs=1&amp;session_id=17592708045346502934&amp;seq_num=2&amp;u_w=477&amp;msid=com.iudesk.android.photo.editor&amp;js=afma-sdk-a-v6.4.1&amp;prnl=9113&amp;bas_off=0&amp;imbf=8009&amp;net=ed&amp;app_name=2014010100.android.com.iudesk.android.photo.editor&amp;hl=de&amp;gnt=8&amp;carrier=26207&amp;u_audio=3&amp;u_sd=1.6750001&amp;ms=9yd99ZXvdmEJUHLeuHhY3u41mO_tOfndaTotwt2F-DVGft5m9EnXHzmLRD4RgOdlrS79cEhF2TGnDLGU0yj7ZzSMp8TS0MCClasMlEOLyViG8uYbFKmnHxqgdV3_FLSnwqHN7_us4Zr2azrucwql5_9qW_5so47ZR9XHBJYGiVcJy0B6aYPDbvad-njT6YVf0U5IqZIAjoZ20jX1ojaFE-pu0rpUdANjwxYgkh0UEJXhZHgF5lo_Msi3AW3UMa6K_Xk5HqVR3TeRMwwOr9qfkNTiUDyUEwqGqnCkWUzWkmdfanS64UprjTGxmQ675siWdWmE-AeqzfaRVcseiw74mw&amp;mv=80240021.com.android.vending&amp;format=320x50_mb&amp;oar=0&amp;u_h=764&amp;bas_on=0&amp;ptime=69277&amp;prl=11406&amp;u_so=p&amp;output=html&amp;region=mobile_app&amp;u_tz=60&amp;client_sdk=1&amp;ex=1&amp;slotname=a14ecccef2eb8b3&amp;askip=1&amp;gsb=4g&amp;caps=inlineVideo_interactiveVideo_mraid1_th_mediation_sdkAdmobApiForAds_di&amp;jsv=66&amp;urll=935</td>
      <td>                                                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 (Mobile; afma-sdk-a-v6.4.1)</td>
    </tr>
    <tr>
      <th>66 </th>
      <td>  44250</td>
      <td> 173.194.116.185</td>
      <td>           googleads.g.doubleclick.net</td>
      <td> GET</td>
      <td>                                                                                                                /mads/gma?preqs=2&amp;session_id=17592708045346502934&amp;seq_num=3&amp;u_w=477&amp;msid=com.iudesk.android.photo.editor&amp;js=afma-sdk-a-v6.4.1&amp;bas_off=0&amp;imbf=8009&amp;net=ed&amp;app_name=2014010100.android.com.iudesk.android.photo.editor&amp;hl=de&amp;gnt=8&amp;carrier=26207&amp;u_audio=3&amp;u_sd=1.6750001&amp;ms=XkHxq-pxBucbuAFEkgVz2ud3dAVCQKuG51SBPj7bZfgF7bIgIAKWjPjzuzEbPRCoG9YdIIdfS0XIF080Ae7KZffsMMq3RNME_iiMIZ8MTwRDB-YeW4zvjEsnKvpBx8I2fWNbmGW0_Kp2QCrSz09jfVNkogEkRcEKO-cGqLraPZRP6abz1c17ArgCPJbF8m591KXGAud04Sgts4WNz0_xe85Jg-yh1z3bsQIE_l1mFOfYp9O2Acb2MOUlY8Op0xl4oAhyVjHcwXEOSvcgAngio5TzMdlLwvRYDbJw3Az9gc4Q6qb8ivHK0hqLibrlhhWYIDCjFFvi9WchF64W0hvVxg&amp;mv=80240021.com.android.vending&amp;format=320x50_mb&amp;oar=0&amp;u_h=764&amp;bas_on=0&amp;ptime=182048&amp;u_so=p&amp;output=html&amp;region=mobile_app&amp;u_tz=60&amp;client_sdk=1&amp;ex=1&amp;slotname=a14ecccef2eb8b3&amp;askip=2&amp;gsb=4g&amp;caps=inlineVideo_interactiveVideo_mraid1_th_mediation_sdkAdmobApiForAds_di&amp;jsv=66&amp;urll=916</td>
      <td>                                                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 (Mobile; afma-sdk-a-v6.4.1)</td>
    </tr>
    <tr>
      <th>67 </th>
      <td>  44262</td>
      <td> 173.194.116.185</td>
      <td>           googleads.g.doubleclick.net</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              /pagead/adview?ai=C4oveubvaUq_KM4Sl-walkoHgDrvKzaYEi4T6sk7AjbcBEAEgAFCAx-HEBGCVAoIBHmNhLW1iLWFwcC1wdWItMzY5ODg4OTAwNjYzNzE0NcgBCagDAaoE4QFP0NsZQDgdR6m6-UsNs3NVOfzWrEARwv7eNFrr-tHmgBdGDZ6KgYOfKLRHPVClkG1Tb2rikEmy2-99FD1WSc63202JSQF0wr8_ulyVw6VMd8qYGzYkpXEDPBS6WpcCLNBw2LI9YtZme6wOTtdjRKLRKzi1NTv0wPeC-RBzCUgbEGhY9n4jMkE-LSry1ijzbh_bmzt9omLv-rRcJKmN3lxR4HsdoEGLDkydEv4KkDlBE0o1q9Qr4ANgAyIVUBeIebKS492NihSJaqggq5ty4cs_w-FEotQjnDtOm0nKiESJJr-ABsy73YTZq8KRHKAGIQ&amp;sigh=ktzmIelvDAY</td>
      <td>                                                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 (Mobile; afma-sdk-a-v6.4.1)</td>
    </tr>
    <tr>
      <th>68 </th>
      <td>  43921</td>
      <td> 173.194.116.185</td>
      <td>           googleads.g.doubleclick.net</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              /pagead/adview?ai=CFehGBrvaUq3DGceO-waprICADrvKzaYEi4T6sk7AjbcBEAEgAFCAx-HEBGCVAoIBHmNhLW1iLWFwcC1wdWItMzY5ODg4OTAwNjYzNzE0NcgBCagDAaoE4QFP0B_pKoVqRzGQjrH8fOm0S6WhhXyS0bjy79z88fOE1v8xwyfxVHI748bWF7lKJl8WaoC5QvD5uU2-W4C4s0mB0-GY6tgV4Qk_yBBU86_CNmH4QSD1GKrp9qKCoxDptbkCfRtWlzlk4GhFFBQUYpE3hemX5nduj1f-5hkaXYuSPoDF4QqPTXL8zACO6EUIHSY2_I1QeeVj1iqrEHmOqQbgU24nHiNCvMVee1A5tJOYlqPc4Plh0th8mdcLuvBYAn6Q-UJTVexCneBJLjL6XhlFduPecycLn-ITziOuF4ip9oOABsy73YTZq8KRHKAGIQ&amp;sigh=DWUbGB2Sr7A</td>
      <td>                                                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 (Mobile; afma-sdk-a-v6.4.1)</td>
    </tr>
    <tr>
      <th>69 </th>
      <td>  39775</td>
      <td> 173.194.116.185</td>
      <td>           googleads.g.doubleclick.net</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       /pixel?google_nid=a9&amp;google_cm&amp;ex=doubleclick.net</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>70 </th>
      <td>   9698</td>
      <td>  91.215.101.109</td>
      <td>                        gsea.ivwbox.de</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        /cgi-bin/ivw/CP/0114_05?r=http%3A//flipboard.com/redirect%3Furl%3Dhttp%253A%252F%252Fwww.tagesschau.de%252Fschlusslicht%252Finternet242.html&amp;d=36300.35824608058</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>71 </th>
      <td> 132318</td>
      <td>    80.82.201.85</td>
      <td>                        gwp.nuggad.net</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  /rc?nuggn=480104072&amp;nuggsid=1248589405</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>72 </th>
      <td> 136834</td>
      <td>    80.82.201.85</td>
      <td>                        gwp.nuggad.net</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  /rc?nuggn=480104072&amp;nuggsid=1364201110</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>73 </th>
      <td>  20857</td>
      <td>  37.252.162.217</td>
      <td>                          ib.adnxs.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   /bounce?%2Fgetuid%3Fhttp%253A%252F%252Fib.adnxs.com%252Fgetuid%253Fhttp%25253A%25252F%25252Fd.shareaholic.com%25252Fdough%25252F1.0%25252Fmixer.gif%25253Fp_name%25253DAN%252526p_id%25253D%252524UID</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>74 </th>
      <td>  20865</td>
      <td>  37.252.162.217</td>
      <td>                          ib.adnxs.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          /getuid?http%3A%2F%2Fd.shareaholic.com%2Fdough%2F1.0%2Fmixer.gif%3Fp_name%3DAN%26p_id%3D%24UID</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>75 </th>
      <td>  20841</td>
      <td>  37.252.162.217</td>
      <td>                          ib.adnxs.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               /getuid?http%3A%2F%2Fib.adnxs.com%2Fgetuid%3Fhttp%253A%252F%252Fd.shareaholic.com%252Fdough%252F1.0%252Fmixer.gif%253Fp_name%253DAN%2526p_id%253D%2524UID</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>76 </th>
      <td>  39779</td>
      <td>  37.252.162.214</td>
      <td>                          ib.adnxs.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       /getuid?http://s.amazon-adsystem.com/ecm3?id=$UID&amp;ex=appnexus.com</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>77 </th>
      <td>  39788</td>
      <td>     2.16.216.40</td>
      <td>                   image5.pubmatic.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               /AdServer/usersync/usersync.html?predirect=http%3A%2F%2Fs.amazon-adsystem.com%2Fecm3%3Fid%3DPM_UID%26ex%3Dpubmatic.com&amp;userIdMacro=PM_UID</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>78 </th>
      <td>  42816</td>
      <td>    178.236.4.60</td>
      <td>                 images.waskochich.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 /rezept_des_tages/v1/18.01.2014/recipe.json?vcode=14&amp;sdk=18&amp;lang=de-DE&amp;platform=android</td>
      <td>                                                                                                                                                                 android-async-http/1.4.3 (http://loopj.com/android-async-http)</td>
    </tr>
    <tr>
      <th>79 </th>
      <td> 103828</td>
      <td>  194.232.190.70</td>
      <td>                images03.futurezone.at</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     /entordnungsmaschine.jpg/46.491.152</td>
      <td>                                                                                                                                                                  null (FlipboardProxy/1.1; +http://flipboard.com/browserproxy)</td>
    </tr>
    <tr>
      <th>80 </th>
      <td>  19517</td>
      <td>   88.198.24.175</td>
      <td>                      intelcrawler.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          /about/press07</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>81 </th>
      <td>   4808</td>
      <td>  91.103.142.129</td>
      <td>              mobile.smartadserver.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         /call2/pubmj/31924/220174/13500/S/689547290/unfall%3Bundefined?</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>82 </th>
      <td>   5118</td>
      <td>  91.103.142.129</td>
      <td>              mobile.smartadserver.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         /call2/pubmj/31924/220174/13501/S/689547290/unfall%3Bundefined?</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>83 </th>
      <td>   4810</td>
      <td>  91.103.142.129</td>
      <td>              mobile.smartadserver.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         /call2/pubmj/31924/220174/13531/M/689547290/unfall%3Bundefined?</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>84 </th>
      <td>  16308</td>
      <td>  91.103.142.194</td>
      <td>              mobile.smartadserver.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         /call2/pubmj/31924/220217/13500/S/9074574292/streaming%3Bngx%3D1%3Bnd_agr%3D6%3Bnd_gnd%3D1%3Bnd_hsh%3D1%3Bnd_dcb%3D1%3Bnd_dcd%3D1%3Bnd_dcp%3D1%3Bnd_dcs%3D6%3B?</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>85 </th>
      <td>  16306</td>
      <td>  91.103.142.194</td>
      <td>              mobile.smartadserver.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         /call2/pubmj/31924/220217/13501/S/9074574292/streaming%3Bngx%3D1%3Bnd_agr%3D6%3Bnd_gnd%3D1%3Bnd_hsh%3D1%3Bnd_dcb%3D1%3Bnd_dcd%3D1%3Bnd_dcp%3D1%3Bnd_dcs%3D6%3B?</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>86 </th>
      <td>  16304</td>
      <td>  91.103.142.194</td>
      <td>              mobile.smartadserver.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         /call2/pubmj/31924/220217/13531/M/9074574292/streaming%3Bngx%3D1%3Bnd_agr%3D6%3Bnd_gnd%3D1%3Bnd_hsh%3D1%3Bnd_dcb%3D1%3Bnd_dcd%3D1%3Bnd_dcp%3D1%3Bnd_dcs%3D6%3B?</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>87 </th>
      <td> 132498</td>
      <td>  91.103.142.194</td>
      <td>              mobile.smartadserver.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       /call2/pubmj/31924/220236/13500/S/4907709071/hochschulen%3Bngx%3D1%3Bnd_agr%3D6%3Bnd_gnd%3D1%3Bnd_hsh%3D1%3Bnd_dcb%3D1%3Bnd_dcd%3D1%3Bnd_dcp%3D1%3Bnd_dcs%3D6%3B?</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>88 </th>
      <td> 132509</td>
      <td>  91.103.142.194</td>
      <td>              mobile.smartadserver.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       /call2/pubmj/31924/220236/13501/S/4907709071/hochschulen%3Bngx%3D1%3Bnd_agr%3D6%3Bnd_gnd%3D1%3Bnd_hsh%3D1%3Bnd_dcb%3D1%3Bnd_dcd%3D1%3Bnd_dcp%3D1%3Bnd_dcs%3D6%3B?</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>89 </th>
      <td> 132496</td>
      <td>  91.103.142.194</td>
      <td>              mobile.smartadserver.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       /call2/pubmj/31924/220236/13531/M/4907709071/hochschulen%3Bngx%3D1%3Bnd_agr%3D6%3Bnd_gnd%3D1%3Bnd_hsh%3D1%3Bnd_dcb%3D1%3Bnd_dcd%3D1%3Bnd_dcp%3D1%3Bnd_dcs%3D6%3B?</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>90 </th>
      <td>  12696</td>
      <td>  91.103.140.193</td>
      <td>              mobile.smartadserver.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     /call2/pubmj/42361/286422/13500/S/3367962420/ngx%3D1%3Bnd_agr%3D6%3Bnd_gnd%3D1%3Bnd_hsh%3D1%3Bnd_dcb%3D1%3Bnd_dcd%3D1%3Bnd_dcp%3D1%3Bnd_dcs%3D1%3B?</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>91 </th>
      <td>  12698</td>
      <td>  91.103.140.193</td>
      <td>              mobile.smartadserver.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     /call2/pubmj/42361/286422/13501/S/3367962420/ngx%3D1%3Bnd_agr%3D6%3Bnd_gnd%3D1%3Bnd_hsh%3D1%3Bnd_dcb%3D1%3Bnd_dcd%3D1%3Bnd_dcp%3D1%3Bnd_dcs%3D1%3B?</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>92 </th>
      <td>  12694</td>
      <td>  91.103.140.193</td>
      <td>              mobile.smartadserver.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     /call2/pubmj/42361/286422/13531/M/3367962420/ngx%3D1%3Bnd_agr%3D6%3Bnd_gnd%3D1%3Bnd_hsh%3D1%3Bnd_dcb%3D1%3Bnd_dcd%3D1%3Bnd_dcp%3D1%3Bnd_dcs%3D1%3B?</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>93 </th>
      <td> 136889</td>
      <td>  91.103.142.194</td>
      <td>              mobile.smartadserver.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     /call2/pubmj/42361/286438/13500/S/5189938149/ngx%3D1%3Bnd_agr%3D6%3Bnd_gnd%3D1%3Bnd_hsh%3D1%3Bnd_dcb%3D1%3Bnd_dcd%3D1%3Bnd_dcp%3D1%3Bnd_dcs%3D6%3B?</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>94 </th>
      <td> 136891</td>
      <td>  91.103.142.194</td>
      <td>              mobile.smartadserver.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     /call2/pubmj/42361/286438/13501/S/5189938149/ngx%3D1%3Bnd_agr%3D6%3Bnd_gnd%3D1%3Bnd_hsh%3D1%3Bnd_dcb%3D1%3Bnd_dcd%3D1%3Bnd_dcp%3D1%3Bnd_dcs%3D6%3B?</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>95 </th>
      <td> 136893</td>
      <td>  91.103.142.194</td>
      <td>              mobile.smartadserver.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     /call2/pubmj/42361/286438/13531/M/5189938149/ngx%3D1%3Bnd_agr%3D6%3Bnd_gnd%3D1%3Bnd_hsh%3D1%3Bnd_dcb%3D1%3Bnd_dcd%3D1%3Bnd_dcp%3D1%3Bnd_dcs%3D6%3B?</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>96 </th>
      <td> 136866</td>
      <td>    193.46.63.58</td>
      <td>                           mqs.ioam.de</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   /?mobfaz//CP//222F000006E6//VIA_SZMNG</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>97 </th>
      <td>  79988</td>
      <td>   85.13.149.111</td>
      <td>                  otaslim.slimroms.net</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                /ota.xml</td>
      <td>                                                                                                                                                                  Dalvik/1.6.0 (Linux; U; Android 4.3.1; GT-N7000 Build/JLS36I)</td>
    </tr>
    <tr>
      <th>98 </th>
      <td>    108</td>
      <td> 173.194.116.186</td>
      <td>         pagead2.googlesyndication.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 /mads/gma?preqs=0&amp;u_sd=1.6750001&amp;u_h=764&amp;u_w=477&amp;msid=com.icecoldapps.sshserver&amp;js=afma-sdk-a-v4.1.1&amp;format=320x50_mb&amp;net=ed&amp;app_name=6.android.com.icecoldapps.sshserver&amp;u_audio=3&amp;hl=de&amp;u_so=p&amp;output=html&amp;region=mobile_app&amp;u_tz=60&amp;client_sdk=1&amp;ex=1&amp;slotname=a1503fa97c18f71&amp;caps=th_sdkAdmobApiForAds_di&amp;eid=46621027&amp;eisu=YqvG8bb1HRSjHT6fGSlcIGDpDNkVBUb9f6gFzqmi9KKfTIqGDqHqvKRVSjVInYJT89PFhEXFazxoGTMgh8XJGbsG3oecaOzbv8-2l35NcfO9gAwABQhGCOMtM6TYYwID&amp;et=16&amp;jsv=66&amp;urll=499</td>
      <td>                                                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 (Mobile; afma-sdk-a-v4.1.1)</td>
    </tr>
    <tr>
      <th>99 </th>
      <td>  84341</td>
      <td>    2.23.181.210</td>
      <td>                         pbs.twimg.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        /media/Bd5jXUqCIAAz9SB.png:large</td>
      <td>                                                                                                                                                                  null (FlipboardProxy/1.1; +http://flipboard.com/browserproxy)</td>
    </tr>
    <tr>
      <th>100</th>
      <td>  45625</td>
      <td>   68.232.35.139</td>
      <td>                         pbs.twimg.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        /media/BeR4oFsIAAAld5J.jpg:large</td>
      <td>                                                                                                                                                                  null (FlipboardProxy/1.1; +http://flipboard.com/browserproxy)</td>
    </tr>
    <tr>
      <th>101</th>
      <td> 114951</td>
      <td>   68.232.35.139</td>
      <td>                         pbs.twimg.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        /media/BeVn43ACIAErkDj.jpg:large</td>
      <td>                                                                                                                                                                  null (FlipboardProxy/1.1; +http://flipboard.com/browserproxy)</td>
    </tr>
    <tr>
      <th>102</th>
      <td>  89510</td>
      <td>   91.215.101.32</td>
      <td>                          qs.ivwbox.de</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   /?andropit//CP//forum</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>103</th>
      <td>  89714</td>
      <td>  176.34.124.190</td>
      <td>                   r.skimresources.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         /api/?callback=skimlinksApplyHandlers&amp;data=%7B%22pubcode%22%3A%2236706X955308%22%2C%22domains%22%3A%5B%22androidpit.com%22%2C%22androidpit.es%22%2C%22androidpit.ru%22%2C%22androidpit.com.br%22%2C%22androidpit.fr%22%2C%22androidpit.com.tr%22%2C%22androidpit.it%22%2C%22facebook.com%22%2C%22plus.google.com%22%2C%22twitter.com%22%5D%2C%22page%22%3A%22http%3A%2F%2Fwww.androidpit.de%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3%22%7D</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>104</th>
      <td>  62938</td>
      <td>   85.182.250.17</td>
      <td> r6---sn-i5onxoxu-q0nl.googlevideo.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                  /videoplayback?ipbits=0&amp;clen=6565357&amp;sver=3&amp;signature=97BF5AD3E8F190923D6357415BCCA26206AC87CB.98F902F2BF9A3C6AD31B8656D8985D9803C55355&amp;upn=145Xdgf925M&amp;id=1a862b8c290ddd0e&amp;sparams=algorithm%2Cburst%2Cclen%2Cdur%2Cfactor%2Cgir%2Cid%2Cip%2Cipbits%2Citag%2Clmt%2Csource%2Cupn%2Cexpire&amp;ms=au&amp;mv=m&amp;mt=1390068284&amp;key=yt5&amp;ip=89.204.137.61&amp;burst=40&amp;source=youtube&amp;lmt=1389950553436400&amp;mime=video%2F3gpp&amp;expire=1390092857&amp;gir=yes&amp;algorithm=throttle-factor&amp;fexp=933901%2C924614%2C916623%2C936119%2C940607%2C924616%2C936910%2C936913%2C907231%2C921090&amp;itag=36&amp;dur=231.410&amp;factor=1.25&amp;dnc=1&amp;cpn=gO8O40lo6VtiEb9S</td>
      <td>                                                                                                                                                                                          stagefright/1.2 (Linux;Android 4.3.1)</td>
    </tr>
    <tr>
      <th>105</th>
      <td>  62803</td>
      <td>  173.194.70.148</td>
      <td>                           s0.2mdn.net</td>
      <td> GET</td>
      <td> /N4061/pfadx/app.ytpwatch.entertainment/main_8938;dc_kt=AM_2AqHYZ2t6UuW96Ij1LXARDLXamWPArT5qYCXdWdyUCDtpMHFXlTu4GTOjWhX86Meh8fEBDQZuhXDopY43XkUFDcHwp6hyOrzu9GmpYXhJqPfO5kfxRx4_Pr26_98;adtest=nodebugip;sz=480x360,480x361;kvid=GoYrjCkN3Q4;kpu=kontor;kpeid=b3tJ5NKw7mDxyaQ73mwbRg;kpid=8938;mpvid=AATwQoLYU5dkv_Ym;afv=1;afvbase=eJydlEuTojoYhn9Ns9MKd1iwQM_BVtvp9toym1SECFEgMReUfz9p6Jqyz_JQVIU3yXdNHlTTEnzHOWRUEEloA4VEXEamkSkhYYGbHHOtWpJjCs-U10hGtmdUFJM8MjqZ45ZkuNWb3LE9ti2jQpmMLNcMjEbVEOVCW4v82kZo_L0jqwhuZJShEVOnkWeZYWCavuMDJ7T978CowJEJgGcoXkWllOzFjl-sRL_3-33cUSXVCY8zWuuZPjc9zmjKL9PrL3vtGFmJmgZX0Yo0U1Y7AXj4YIeFNF-sCTq3kDRCcoy0-eSAuSQZqqD9Q7g_lPesLNN8lm4QPEvP_OHIdEDwn6Awx3qmk7CtERu-aqargHG8u6_pW7p3dcNgWg9rmV4JQjsYVEOhzZD4K1okZS-Gk-ireDoWODS9n2QC1vREKozYEBZXOhWJSMV0vw3dVKZk9Kgr7VRIS58uZDKKP052YoXX19v6vpiaqKsEKC7kvh9t4Xa5KctlttjNUMrebh8hlA6t0_X7r_Lc3OjsvPxcOtvXWZJcnBvFTvjAaPOWqHxh7i-FkLf9ftJc-MG16iW6rt732WqLiwannRKzx2p__QBrpDarLuzQDCS_T5jvjhMYu5vjEZxFPUs9Z64O0-J-iJdZIb25r_zrKU7_4WfHNx9TkAoCyOzg...</td>
      <td>                                                                                                                                  com.google.android.youtube/5.3.32(Linux; U; Android 4.3.1; de_DE; GT-N7000 Build/JLS36I) gzip</td>
    </tr>
    <tr>
      <th>106</th>
      <td> 136837</td>
      <td>    79.125.16.23</td>
      <td>                   s95.research.de.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        /bb-iqm/get?fp=1</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>107</th>
      <td> 136969</td>
      <td>    79.125.16.23</td>
      <td>                   s95.research.de.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    /bb-iqm/get?fp=2&amp;if=Languages%3D2212301001%26display%3D3352655169%26cpu%3D3611081436%26ajax%3D1%26general%3D1912588871%26dotnet%3D410499862%26mathlog%3D747073866%26timezone%3D060%26mimetypes%3D410499862%26silverlight%3D410499862%26pdfplugin%3D0&amp;du=&amp;iu=&amp;ji=6B833F8C-74B7-6A7B-0241-D82D86F0482F</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>108</th>
      <td>  16501</td>
      <td>    79.125.16.23</td>
      <td>                   s95.research.de.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     /bb-iqm/get?fp=2&amp;if=Languages%3D2212301001%26display%3D3352655169%26cpu%3D3611081436%26ajax%3D1%26general%3D281224174%26dotnet%3D410499862%26mathlog%3D747073866%26timezone%3D060%26mimetypes%3D410499862%26silverlight%3D410499862%26pdfplugin%3D0&amp;du=&amp;iu=&amp;ji=6B833F8C-74B7-6A7B-0241-D82D86F0482F</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>109</th>
      <td>  87979</td>
      <td>    176.9.190.38</td>
      <td>                  st02.androidpit.info</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               /js/libs/modernizr.js?v=2</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>110</th>
      <td>  87978</td>
      <td>    176.9.190.38</td>
      <td>                  st02.androidpit.info</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  /style/style.css?v=184</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>111</th>
      <td>  87968</td>
      <td>    176.9.190.38</td>
      <td>                  st02.androidpit.info</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           /styles/basic-migrate.css?v=4</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>112</th>
      <td>  89374</td>
      <td>    176.9.190.38</td>
      <td>                  st02.androidpit.info</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               /styles/font/selection_androidpit.ttf?v=3</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>113</th>
      <td>  87977</td>
      <td>    176.9.190.38</td>
      <td>                  st02.androidpit.info</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   /styles/main.css?v=73</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>114</th>
      <td>  87967</td>
      <td>    176.9.190.38</td>
      <td>                  st02.androidpit.info</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    /styles/selection_androidpit.css?v=3</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>115</th>
      <td>  88019</td>
      <td>     176.9.200.6</td>
      <td>                  st03.androidpit.info</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     /js/common.js?v=129</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>116</th>
      <td>  88022</td>
      <td>     176.9.200.6</td>
      <td>                  st03.androidpit.info</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       /js/forum.js?v=42</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>117</th>
      <td>  88999</td>
      <td>     2.16.216.72</td>
      <td>                static.ak.facebook.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      /connect/xd_arbiter.php?version=28</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>118</th>
      <td>  16734</td>
      <td>   178.63.27.165</td>
      <td>                     static.plista.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         /oba/icon.php?format=gif&amp;color=777777&amp;height=26</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>119</th>
      <td>  90075</td>
      <td>    50.19.234.49</td>
      <td>                    stats.pagefair.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      /stats/page_view_event/DF62727623B74063/a.gif?i_hid=false&amp;i_rem=false&amp;i_blk=false&amp;if_hid=false&amp;if_rem=false&amp;s_rem=false&amp;s_blk=false&amp;new_daily=true</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>120</th>
      <td>   3963</td>
      <td>  91.215.101.185</td>
      <td>                    sueddeut.ivwbox.de</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 /cgi-bin/ivw/CP/szmmobil_N061AMucArtM?r=http%3A//flipboard.com/redirect%3Furl%3Dhttp%253A%252F%252Fwww.sueddeutsche.de%252Fmuenchen%252Fmuenchen-haidhausen-ploetzlich-zehn-meter-tiefes-loch-im-gehweg-1.1866074&amp;d=1390050885081_71244</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>121</th>
      <td>  16063</td>
      <td>  91.215.101.185</td>
      <td>                    sueddeut.ivwbox.de</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    /cgi-bin/ivw/CP/szmmobil_N124ADigArtM?r=http%3A//flipboard.com/redirect%3Furl%3Dhttp%253A%252F%252Fwww.sueddeutsche.de%252Fdigital%252Fstreamseite-redtube-loechriges-gutachten-bringt-porno-abmahner-in-bedraengnis-1.1866025&amp;d=1390051326027_63702</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>122</th>
      <td> 132413</td>
      <td>  91.215.101.185</td>
      <td>                    sueddeut.ivwbox.de</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   /cgi-bin/ivw/CP/szmmobil_N157AKarArtM?r=http%3A//flipboard.com/redirect%3Furl%3Dhttp%253A%252F%252Fwww.sueddeutsche.de%252Fkarriere%252Fstudie-hunderttausende-akademiker-arbeiten-fuer-niedrigloehne-1.1866212&amp;d=1390147627053_94457</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>123</th>
      <td> 132333</td>
      <td>   193.46.63.198</td>
      <td>                      sz.met.vgwort.de</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    /na/0a0657787bea4892820a8834ad37ca54</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>124</th>
      <td>   3809</td>
      <td>   193.46.63.198</td>
      <td>                      sz.met.vgwort.de</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    /na/58296e1bbe8446cd8396b668ab180d75</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>125</th>
      <td>  16035</td>
      <td>   193.46.63.198</td>
      <td>                      sz.met.vgwort.de</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    /na/eb98d3d2996f41f5941c53e733c4db8b</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>126</th>
      <td>   9699</td>
      <td>   91.215.101.81</td>
      <td>                    tagessch.ivwbox.de</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       /cgi-bin/ivw/CP/tagesschau/tagesschau;page=/schlusslicht/internet242.html?r=http%3A//flipboard.com/redirect%3Furl%3Dhttp%253A%252F%252Fwww.tagesschau.de%252Fschlusslicht%252Finternet242.html&amp;d=80627.9287673533</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>127</th>
      <td>  16423</td>
      <td>    37.58.68.190</td>
      <td>                         tags.w55c.net</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  /match-result?id=8bb138bc0446417c9a4df9a0136d0caf8a93328592bf4d059bfc856c256fbc33&amp;ei=GOOGLE&amp;euid=&amp;google_gid=CAESEB5v8HfUGT2_1i1y9vNdT4c&amp;google_cver=1</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>128</th>
      <td>  16424</td>
      <td>    37.58.68.190</td>
      <td>                         tags.w55c.net</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  /match-result?id=8bb138bc0446417c9a4df9a0136d0caf8a93328592bf4d059bfc856c256fbc33&amp;ei=GOOGLE&amp;euid=&amp;google_gid=CAESECkZd52UzYAgxK8IiL5RJDk&amp;google_cver=1</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>129</th>
      <td> 132414</td>
      <td>    37.58.68.190</td>
      <td>                         tags.w55c.net</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            /rs?id=27f879b4032245c49b707e45f0c1a11b&amp;t=checkout&amp;tx=$TRANSACTION_ID&amp;sku=$SKUS&amp;price=$price</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>130</th>
      <td> 132411</td>
      <td>    37.58.68.190</td>
      <td>                         tags.w55c.net</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      /rs?id=9092f72a92594747b09a1f9d78921f2d&amp;t=homepage</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>131</th>
      <td>  39793</td>
      <td>     69.25.24.26</td>
      <td>                tap.rubiconproject.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     /oz/feeds/amazon-rtb/tokens/?rt=img</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>132</th>
      <td>  95516</td>
      <td>   193.46.63.196</td>
      <td>                     taz.met.vgwort.de</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    /na/1239043821a44d96a088d86545a3ff51</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>133</th>
      <td>    946</td>
      <td>  173.194.70.132</td>
      <td>          themes.googleusercontent.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       /5GKRInj6vlWTBQ3qIHmAY92S3AaO4PlSJFBLsQ2lUMHp-XwkAwcBjXWzgRfbuUdoGQ7MDjFfnitQ_LEo7vN58KNMcrI=s143</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>134</th>
      <td>    942</td>
      <td>  173.194.70.132</td>
      <td>          themes.googleusercontent.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     /XTjCnWNjnmjszjQJR2qqOcmHQ1Irp0L1rI3cMnDMhvjSI8Bxu5DZL7jFOKRAaPg8J20J7rWwtHWk64UyZDrd_MQZkXM=s694-c</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>135</th>
      <td> 102154</td>
      <td>  173.194.70.132</td>
      <td>          themes.googleusercontent.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       /s2/favicons?domain=casadefazdeconta.com&amp;alt=feed</td>
      <td>                                                                                                                                                                  null (FlipboardProxy/1.1; +http://flipboard.com/browserproxy)</td>
    </tr>
    <tr>
      <th>136</th>
      <td> 101006</td>
      <td>  173.194.70.132</td>
      <td>          themes.googleusercontent.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            /s2/favicons?domain=dinheirovivo.pt&amp;alt=feed</td>
      <td>                                                                                                                                                                  null (FlipboardProxy/1.1; +http://flipboard.com/browserproxy)</td>
    </tr>
    <tr>
      <th>137</th>
      <td> 101007</td>
      <td>  173.194.70.132</td>
      <td>          themes.googleusercontent.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 /s2/favicons?domain=tumblr.com&amp;alt=feed</td>
      <td>                                                                                                                                                                  null (FlipboardProxy/1.1; +http://flipboard.com/browserproxy)</td>
    </tr>
    <tr>
      <th>138</th>
      <td>  28674</td>
      <td>  173.194.70.132</td>
      <td>          themes.googleusercontent.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 /s2/favicons?domain=www.mdr.de&amp;alt=feed</td>
      <td>                                                                                                                                                                  null (FlipboardProxy/1.1; +http://flipboard.com/browserproxy)</td>
    </tr>
    <tr>
      <th>139</th>
      <td> 127813</td>
      <td>  173.194.70.132</td>
      <td>          themes.googleusercontent.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 /s2/favicons?domain=www.ndr.de&amp;alt=feed</td>
      <td>                                                                                                                                                                  null (FlipboardProxy/1.1; +http://flipboard.com/browserproxy)</td>
    </tr>
    <tr>
      <th>140</th>
      <td> 127814</td>
      <td>  173.194.70.132</td>
      <td>          themes.googleusercontent.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         /s2/favicons?domain=www1.sportschau.de&amp;alt=feed</td>
      <td>                                                                                                                                                                  null (FlipboardProxy/1.1; +http://flipboard.com/browserproxy)</td>
    </tr>
    <tr>
      <th>141</th>
      <td>  28675</td>
      <td>  173.194.70.132</td>
      <td>          themes.googleusercontent.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                /s2/favicons?domain=www1.wdr.de&amp;alt=feed</td>
      <td>                                                                                                                                                                  null (FlipboardProxy/1.1; +http://flipboard.com/browserproxy)</td>
    </tr>
    <tr>
      <th>142</th>
      <td>  19796</td>
      <td>  173.194.70.132</td>
      <td>          themes.googleusercontent.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               /static/fonts/opensans/v7/MTP_ySUJH_bn48VBG8sNSndckgy16U_L-eNUgMz0EAk.ttf</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>143</th>
      <td>  19795</td>
      <td>  173.194.70.132</td>
      <td>          themes.googleusercontent.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               /static/fonts/opensans/v7/RjgO7rYTmqiVp7vzi-Q5USZ2oysoEQEeKwjgmXLRnTc.ttf</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>144</th>
      <td>  90070</td>
      <td>  173.194.70.132</td>
      <td>          themes.googleusercontent.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                /static/fonts/roboto/v10/Hgo13k-tfSpn0qi1SFdUfSZ2oysoEQEeKwjgmXLRnTc.ttf</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>145</th>
      <td> 105738</td>
      <td> 194.232.116.172</td>
      <td>                         tvthek.orf.at</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   /dynamic/get_asset.php?a=orf_programs%2Flogo%2F1915503.jpg&amp;h=98169862358ff9a5497768a7b86aca9df89aa99a</td>
      <td>                                                                                                                                                                  null (FlipboardProxy/1.1; +http://flipboard.com/browserproxy)</td>
    </tr>
    <tr>
      <th>146</th>
      <td>  98306</td>
      <td>  98.137.204.103</td>
      <td>                 weather.yahooapis.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              /forecastrss?w=2345496&amp;u=c</td>
      <td>                                                                                                                                                                                                              Ultimate DayDream</td>
    </tr>
    <tr>
      <th>147</th>
      <td>  90543</td>
      <td>    176.9.190.33</td>
      <td>                     www.androidpit.de</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                /apps/app2-teaser-popup?xl=true&amp;ooc=true</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>148</th>
      <td>  87890</td>
      <td>    176.9.190.33</td>
      <td>                     www.androidpit.de</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      /de/android/forum/thread/573726/slimbean-Build-4-3</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>149</th>
      <td>  90540</td>
      <td>    176.9.190.33</td>
      <td>                     www.androidpit.de</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        /favicon.ico?v=3</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>150</th>
      <td>  89663</td>
      <td>    176.9.190.33</td>
      <td>                     www.androidpit.de</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        /nagScreen/popup</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>151</th>
      <td>  39831</td>
      <td>    216.10.120.7</td>
      <td>                      www.burstnet.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        /user/3/?redirect=http%3A%2F%2Fs.amazon-adsystem.com%2Fecm3%3Fid%3D%24UID%26ex%3Dadconductor.com</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>152</th>
      <td>  39774</td>
      <td>    31.13.81.128</td>
      <td>                      www.facebook.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               /fr/u.php?p=221790734642435&amp;m=3ltDx98WRvqCEwbUdtkJbQ&amp;r=us</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>153</th>
      <td>   5676</td>
      <td>    31.13.81.144</td>
      <td>                      www.facebook.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                    /plugins/like.php?action=recommend&amp;api_key=268419256515542&amp;channel_url=http%3A%2F%2Fstatic.ak.facebook.com%2Fconnect%2Fxd_arbiter.php%3Fversion%3D28%23cb%3Df1786c6af4%26domain%3Dwww.sueddeutsche.de%26origin%3Dhttp%253A%252F%252Fwww.sueddeutsche.de%252Ff633042fc%26relation%3Dparent.parent&amp;colorscheme=light&amp;extended_social_context=false&amp;font=arial&amp;href=http%3A%2F%2Fwww.sueddeutsche.de%2Fmuenchen%2Fmuenchen-haidhausen-ploetzlich-zehn-meter-tiefes-loch-im-gehweg-1.1866074&amp;layout=box_count&amp;locale=de_DE&amp;node_type=link&amp;sdk=joey&amp;send=false&amp;show_faces=false&amp;width=115</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>154</th>
      <td> 132771</td>
      <td>     31.13.81.81</td>
      <td>                      www.facebook.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                      /plugins/like.php?action=recommend&amp;api_key=268419256515542&amp;channel_url=http%3A%2F%2Fstatic.ak.facebook.com%2Fconnect%2Fxd_arbiter.php%3Fversion%3D28%23cb%3Df2ed5bc97%26domain%3Dwww.sueddeutsche.de%26origin%3Dhttp%253A%252F%252Fwww.sueddeutsche.de%252Ff194ee9f04%26relation%3Dparent.parent&amp;colorscheme=light&amp;extended_social_context=false&amp;font=arial&amp;href=http%3A%2F%2Fwww.sueddeutsche.de%2Fkarriere%2Fstudie-hunderttausende-akademiker-arbeiten-fuer-niedrigloehne-1.1866212&amp;layout=box_count&amp;locale=de_DE&amp;node_type=link&amp;sdk=joey&amp;send=false&amp;show_faces=false&amp;width=115</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>155</th>
      <td>  16882</td>
      <td>    31.13.81.128</td>
      <td>                      www.facebook.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                       /plugins/like.php?action=recommend&amp;api_key=268419256515542&amp;channel_url=http%3A%2F%2Fstatic.ak.facebook.com%2Fconnect%2Fxd_arbiter.php%3Fversion%3D28%23cb%3Dfe08343b8%26domain%3Dwww.sueddeutsche.de%26origin%3Dhttp%253A%252F%252Fwww.sueddeutsche.de%252Ff33f5d0024%26relation%3Dparent.parent&amp;colorscheme=light&amp;extended_social_context=false&amp;font=arial&amp;href=http%3A%2F%2Fwww.sueddeutsche.de%2Fdigital%2Fstreamseite-redtube-loechriges-gutachten-bringt-porno-abmahner-in-bedraengnis-1.1866025&amp;layout=box_count&amp;locale=de_DE&amp;node_type=link&amp;sdk=joey&amp;send=false&amp;show_faces=false&amp;width=115</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>156</th>
      <td>    877</td>
      <td>     65.19.138.1</td>
      <td>                        www.feedly.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                /config-overlay.v5.json?ck=1390050786306</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>157</th>
      <td>    912</td>
      <td>     65.19.138.1</td>
      <td>                        www.feedly.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                /v3/markers/counts?ck=1390050791248&amp;ct=feedly.mobile.android.1&amp;cv=18.0.4</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>158</th>
      <td>    913</td>
      <td>     65.19.138.1</td>
      <td>                        www.feedly.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      /v3/mixes/contents?streamId=user%2F66d95ad3-e977-4150-b00a-8c5d808ecdda%2Fcategory%2FBlogs&amp;count=6&amp;ck=1390050791276&amp;backfill=true&amp;boostMustRead=true&amp;hours=14&amp;ct=feedly.mobile.android.1&amp;cv=18.0.4&amp;unreadOnly=true</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>159</th>
      <td>    929</td>
      <td>     65.19.138.1</td>
      <td>                        www.feedly.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                /v3/mixes/contents?streamId=user%2F66d95ad3-e977-4150-b00a-8c5d808ecdda%2Fcategory%2FDeutschland&amp;count=6&amp;ck=1390050792054&amp;backfill=true&amp;boostMustRead=true&amp;hours=14&amp;ct=feedly.mobile.android.1&amp;cv=18.0.4&amp;unreadOnly=true</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>160</th>
      <td>    880</td>
      <td>     65.19.138.1</td>
      <td>                        www.feedly.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   /v3/preferences?ck=1390050786725&amp;ct=feedly.mobile.android.1&amp;cv=18.0.4</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>161</th>
      <td>    883</td>
      <td>     65.19.138.1</td>
      <td>                        www.feedly.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       /v3/profile?ck=1390050786734&amp;ct=feedly.mobile.android.1&amp;cv=18.0.4</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>162</th>
      <td>    886</td>
      <td>     65.19.138.1</td>
      <td>                        www.feedly.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 /v3/subscriptions?ck=1390050786739&amp;ct=feedly.mobile.android.1&amp;cv=18.0.4</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>163</th>
      <td>   1242</td>
      <td>  173.194.70.113</td>
      <td>              www.google-analytics.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        /__utm.gif?utmwv=4.8.1ma&amp;utmn=319752051&amp;utme=8(1!clientType*2!feedlyVersion*3!wave*4!logged*5!transition)9(1!android.1*2!18.0.4*3!2013.17*4!yes*5!stack)11(1!1*2!1*3!1*4!1*5!1)&amp;utmcs=UTF-8&amp;utmsr=800x1280&amp;utmul=de-DE&amp;utmp=%2Fmy&amp;utmac=UA-46940058-1&amp;utmcc=__utma%3D1.580923361.1368709109.1389969064.1390050791.142%3B&amp;utmhid=1408137172&amp;aip=1&amp;utmht=1390050791286&amp;utmqt=10062</td>
      <td>                                                                                                                                                  GoogleAnalytics/1.4.2 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I)</td>
    </tr>
    <tr>
      <th>164</th>
      <td>  20744</td>
      <td>  173.194.70.102</td>
      <td>              www.google-analytics.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                 /__utm.gif?utmwv=5.4.6&amp;utms=1&amp;utmn=1693448053&amp;utmhn=intelcrawler.com&amp;utmcs=UTF-8&amp;utmsr=800x1280&amp;utmvp=479x710&amp;utmsc=32-bit&amp;utmul=de-de&amp;utmje=0&amp;utmfl=-&amp;utmdt=IntelCrawler%20-%20Multi-tier%20Intelligence%20Aggregator%20-%20%22Decebal%22%20Point-of-Sale%20Malware%20-%20400%20lines%20of%20VBScript%20code%20from%20Romania%2C%20researchers%20warns%20about%20evolution%20of%20threats%20and%20interests%20to%20modern%20retailers&amp;utmhid=622979055&amp;utmr=http%3A%2F%2Fflipboard.com%2Fredirect%3Furl%3Dhttp%253A%252F%252Fintelcrawler.com%252Fabout%252Fpress07&amp;utmp=%2Fabout%2Fpress07&amp;utmht=1390051703933&amp;utmac=UA-12964573-5&amp;utmcc=__utma%3D238268888.570751254.1390051692.1390051704.1390051704.1%3B%2B__utmz%3D238268888.1390051704.1.1.utmcsr%3Dflipboard.com%7Cutmccn%3D(referral)%7Cutmcmd%3Dreferral%7Cutmcct%3D%2Fredirect%3B&amp;utmu=CAAgAAAAACAAAAAAAAAB~</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>165</th>
      <td>  89794</td>
      <td>  173.194.70.100</td>
      <td>              www.google-analytics.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       /__utm.gif?utmwv=5.4.6&amp;utms=1&amp;utmn=1835366899&amp;utmhn=www.androidpit.de&amp;utmt=var&amp;utmht=1390123642976&amp;utmac=UA-7489116-13&amp;utmcc=__utma%3D228547149.678182810.1388960726.1389614896.1390123639.3%3B%2B__utmz%3D228547149.1388960730.1.1.utmcsr%3D(direct)%7Cutmccn%3D(direct)%7Cutmcmd%3D(none)%3B%2B__utmv%3D228547149.st_teaser_bar_v3%2520%253D%25203%3B&amp;utmu=oQAQAAAAAAAAAAAAAAQ~</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>166</th>
      <td> 136926</td>
      <td> 173.194.116.168</td>
      <td>              www.google-analytics.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                               /__utm.gif?utmwv=5.4.6&amp;utms=1&amp;utmn=541863565&amp;utmhn=m.faz.net&amp;utmcs=UTF-8&amp;utmsr=800x1280&amp;utmvp=479x710&amp;utmsc=32-bit&amp;utmul=de-de&amp;utmje=0&amp;utmfl=-&amp;utmdt=Nach%2048%20Tagen%3A%20Sechzehnj%C3%A4hriger%20erreicht%20S%C3%BCdpol%20auf%20Skiern%20-%20Menschen%20-%20FAZ&amp;utmhid=2126014730&amp;utmr=-&amp;utmp=%2Faktuell%2Fgesellschaft%2Fmenschen%2Fnach-48-tagen-sechzehnjaehriger-erreicht-suedpol-auf-skiern-12759067.html&amp;utmht=1390147721385&amp;utmac=UA-579018-29&amp;utmcc=__utma%3D176063486.1784137468.1390039726.1390051124.1390147721.4%3B%2B__utmz%3D176063486.1390039726.1.1.utmcsr%3D(direct)%7Cutmccn%3D(direct)%7Cutmcmd%3D(none)%3B&amp;utmu=q~</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>167</th>
      <td>  12729</td>
      <td>  173.194.70.100</td>
      <td>              www.google-analytics.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                    /__utm.gif?utmwv=5.4.6&amp;utms=1&amp;utmn=929417289&amp;utmhn=m.faz.net&amp;utmcs=UTF-8&amp;utmsr=800x1280&amp;utmvp=479x710&amp;utmsc=32-bit&amp;utmul=de-de&amp;utmje=0&amp;utmfl=-&amp;utmdt=Sozialleistungen%3A%20Neuer%20Streit%20um%20Hartz%20IV%20f%C3%BCr%20Rum%C3%A4nen%20und%20Bulgaren%20-%20Wirtschaft%20-%20FAZ&amp;utmhid=1516003805&amp;utmr=-&amp;utmp=%2Faktuell%2Fwirtschaft%2Fsozialleistungen-neuer-streit-um-hartz-iv-fuer-rumaenen-und-bulgaren-12757096.html&amp;utmht=1390051124276&amp;utmac=UA-579018-29&amp;utmcc=__utma%3D176063486.1784137468.1390039726.1390044476.1390051124.3%3B%2B__utmz%3D176063486.1390039726.1.1.utmcsr%3D(direct)%7Cutmccn%3D(direct)%7Cutmcmd%3D(none)%3B&amp;utmu=q~</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>168</th>
      <td>  89863</td>
      <td>  173.194.70.100</td>
      <td>              www.google-analytics.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                 /__utm.gif?utmwv=5.4.6&amp;utms=2&amp;utmn=1853522898&amp;utmhn=www.androidpit.de&amp;utme=8(st_teaser_bar_v3_%5Buser%5D*5!st_teaser_bar_v3_%5Bsession%5D*st_teaser_bar_v3_%5Bpage%5D)9(3*5!3*3)11(1*5!2)&amp;utmcs=UTF-8&amp;utmsr=800x1280&amp;utmvp=320x240&amp;utmsc=32-bit&amp;utmul=de-de&amp;utmje=0&amp;utmfl=-&amp;utmdt=slimbean%20Build%204.3%20%E2%80%94%20Android%20Forum%20-%20AndroidPIT&amp;utmhid=1042539821&amp;utmr=-&amp;utmp=%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3&amp;utmht=1390123643001&amp;utmac=UA-7489116-13&amp;utmcc=__utma%3D228547149.678182810.1388960726.1389614896.1390123639.3%3B%2B__utmz%3D228547149.1388960730.1.1.utmcsr%3D(direct)%7Cutmccn%3D(direct)%7Cutmcmd%3D(none)%3B%2B__utmv%3D228547149.st_teaser_bar_v3%2520%253D%25203%3B&amp;utmu=qQAQAAAAAAAAAAAAAAQ~</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>169</th>
      <td>  89909</td>
      <td>  173.194.70.100</td>
      <td>              www.google-analytics.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            /__utm.gif?utmwv=5.4.6&amp;utms=3&amp;utmn=2092754937&amp;utmhn=www.androidpit.de&amp;utmt=var&amp;utmht=1390123643057&amp;utmac=UA-7489116-1&amp;utmcc=__utma%3D228547149.678182810.1388960726.1389614896.1390123639.3%3B%2B__utmz%3D228547149.1388960730.1.1.utmcsr%3D(direct)%7Cutmccn%3D(direct)%7Cutmcmd%3D(none)%3B%2B__utmv%3D228547149.st_teaser_bar_v3%2520%253D%25203%3B&amp;utmmt=1&amp;utmu=qQAwAAAAAAAAAAAAAAQAAAB~</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>170</th>
      <td>  89910</td>
      <td>  173.194.70.100</td>
      <td>              www.google-analytics.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                       /__utm.gif?utmwv=5.4.6&amp;utms=4&amp;utmn=937544652&amp;utmhn=www.androidpit.de&amp;utme=8(st_teaser_bar_v3_%5Buser%5D*5!st_teaser_bar_v3_%5Bsession%5D*st_teaser_bar_v3_%5Bpage%5D)9(3*5!3*3)11(1*5!2)&amp;utmcs=UTF-8&amp;utmsr=800x1280&amp;utmvp=320x240&amp;utmsc=32-bit&amp;utmul=de-de&amp;utmje=0&amp;utmfl=-&amp;utmdt=slimbean%20Build%204.3%20%E2%80%94%20Android%20Forum%20-%20AndroidPIT&amp;utmhid=1042539821&amp;utmr=-&amp;utmp=%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3&amp;utmht=1390123643073&amp;utmac=UA-7489116-1&amp;utmcc=__utma%3D228547149.678182810.1388960726.1389614896.1390123639.3%3B%2B__utmz%3D228547149.1388960730.1.1.utmcsr%3D(direct)%7Cutmccn%3D(direct)%7Cutmcmd%3D(none)%3B%2B__utmv%3D228547149.st_teaser_bar_v3%2520%253D%25203%3B&amp;utmmt=1&amp;utmu=qQAwAAAAAAAAAAAAAAQAAAB~</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>171</th>
      <td>  89911</td>
      <td>  173.194.70.100</td>
      <td>              www.google-analytics.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            /__utm.gif?utmwv=5.4.6&amp;utms=5&amp;utmn=519479110&amp;utmhn=www.androidpit.de&amp;utmt=var&amp;utmht=1390123643111&amp;utmac=UA-7489116-21&amp;utmcc=__utma%3D228547149.678182810.1388960726.1389614896.1390123639.3%3B%2B__utmz%3D228547149.1388960730.1.1.utmcsr%3D(direct)%7Cutmccn%3D(direct)%7Cutmcmd%3D(none)%3B%2B__utmv%3D228547149.st_teaser_bar_v3%2520%253D%25203%3B&amp;utmmt=1&amp;utmu=qQAwAAAAAAAAAAAAAAQAAAB~</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>172</th>
      <td>  89912</td>
      <td>  173.194.70.100</td>
      <td>              www.google-analytics.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                            /__utm.gif?utmwv=5.4.6&amp;utms=6&amp;utmn=431677047&amp;utmhn=www.androidpit.de&amp;utme=8(st_teaser_bar_v3_%5Buser%5D*3!newsNavigationCount*5!st_teaser_bar_v3_%5Bsession%5D*st_teaser_bar_v3_%5Bpage%5D)9(3*3!0*5!3*3)11(1*5!2)&amp;utmcs=UTF-8&amp;utmsr=800x1280&amp;utmvp=320x240&amp;utmsc=32-bit&amp;utmul=de-de&amp;utmje=0&amp;utmfl=-&amp;utmdt=slimbean%20Build%204.3%20%E2%80%94%20Android%20Forum%20-%20AndroidPIT&amp;utmhid=1042539821&amp;utmr=-&amp;utmp=%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3&amp;utmht=1390123643127&amp;utmac=UA-7489116-21&amp;utmcc=__utma%3D228547149.678182810.1388960726.1389614896.1390123639.3%3B%2B__utmz%3D228547149.1388960730.1.1.utmcsr%3D(direct)%7Cutmccn%3D(direct)%7Cutmcmd%3D(none)%3B%2B__utmv%3D228547149.st_teaser_bar_v3%2520%253D%25203%3B&amp;utmmt=1&amp;utmu=qQAwAAAAAAAAAAAAAAQAAAB~</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>173</th>
      <td>  19997</td>
      <td>  173.194.70.102</td>
      <td>              www.google-analytics.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                        /collect?v=1&amp;_v=j15&amp;a=622979055&amp;t=pageview&amp;_s=1&amp;dl=http%3A%2F%2Fintelcrawler.com%2Fabout%2Fpress07&amp;dr=http%3A%2F%2Fflipboard.com%2Fredirect%3Furl%3Dhttp%253A%252F%252Fintelcrawler.com%252Fabout%252Fpress07&amp;ul=de-de&amp;de=UTF-8&amp;dt=IntelCrawler%20-%20Multi-tier%20Intelligence%20Aggregator%20-%20%22Decebal%22%20Point-of-Sale%20Malware%20-%20400%20lines%20of%20VBScript%20code%20from%20Romania%2C%20researchers%20warns%20about%20evolution%20of%20threats%20and%20interests%20to%20modern%20retailers&amp;sd=32-bit&amp;sr=800x1280&amp;vp=479x710&amp;je=0&amp;_u=ME~&amp;cid=570751254.1390051692&amp;tid=UA-46122210-1&amp;z=910916350</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>174</th>
      <td> 132676</td>
      <td> 173.194.116.168</td>
      <td>              www.google-analytics.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                    /collect?v=1&amp;_v=j15&amp;aip=1&amp;a=1403566109&amp;t=pageview&amp;_s=1&amp;dl=http%3A%2F%2Fwww.sueddeutsche.de%2Fkarriere%2Fstudie-hunderttausende-akademiker-arbeiten-fuer-niedrigloehne-1.1866212&amp;dr=http%3A%2F%2Fflipboard.com%2Fredirect%3Furl%3Dhttp%253A%252F%252Fwww.sueddeutsche.de%252Fkarriere%252Fstudie-hunderttausende-akademiker-arbeiten-fuer-niedrigloehne-1.1866212&amp;ul=de-de&amp;de=UTF-8&amp;dt=Hunderttausende%20Akademiker%20arbeiten%20zu%20Niederl%C3%B6hnen%20-%20Karriere%20-%20S%C3%BCddeutsche.de&amp;sd=32-bit&amp;sr=800x1280&amp;vp=479x710&amp;je=0&amp;_utma=6611437.1403719128.1390050886.1390050886.1390147627.2&amp;_utmz=6611437.1390147627.2.2.utmcsr%3Dflipboard.com%7Cutmccn%3D(referral)%7Cutmcmd%3Dreferral%7Cutmcct%3D%2Fredirect&amp;_utmht=1390147630325&amp;_u=cACC~&amp;cid=1403719128.1390050886&amp;tid=UA-19474199-5&amp;cd1=200&amp;z=484400949</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>175</th>
      <td>  16406</td>
      <td>  173.194.70.100</td>
      <td>              www.google-analytics.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                        /collect?v=1&amp;_v=j15&amp;aip=1&amp;a=2138069351&amp;t=pageview&amp;_s=1&amp;dl=http%3A%2F%2Fwww.sueddeutsche.de%2Fdigital%2Fstreamseite-redtube-loechriges-gutachten-bringt-porno-abmahner-in-bedraengnis-1.1866025&amp;dr=http%3A%2F%2Fflipboard.com%2Fredirect%3Furl%3Dhttp%253A%252F%252Fwww.sueddeutsche.de%252Fdigital%252Fstreamseite-redtube-loechriges-gutachten-bringt-porno-abmahner-in-bedraengnis-1.1866025&amp;ul=de-de&amp;de=UTF-8&amp;dt=Redtube%3A%20Gutachten%20setzt%20Porno-Abmahner%20unter%20Druck%20-%20Digital%20-%20S%C3%BCddeutsche.de&amp;sd=32-bit&amp;sr=800x1280&amp;vp=479x710&amp;je=0&amp;_utma=6611437.1403719128.1390050886.1390050886.1390050886.1&amp;_utmz=6611437.1390050886.1.1.utmcsr%3Dflipboard.com%7Cutmccn%3D(referral)%7Cutmcmd%3Dreferral%7Cutmcct%3D%2Fredirect&amp;_utmht=1390051329333&amp;_u=cACC~&amp;cid=1403719128.1390050886&amp;tid=UA-19474199-5&amp;cd1=200&amp;z=283053957</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>176</th>
      <td>   4969</td>
      <td>  173.194.70.113</td>
      <td>              www.google-analytics.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                     /collect?v=1&amp;_v=j15&amp;aip=1&amp;a=725159496&amp;t=pageview&amp;_s=1&amp;dl=http%3A%2F%2Fwww.sueddeutsche.de%2Fmuenchen%2Fmuenchen-haidhausen-ploetzlich-zehn-meter-tiefes-loch-im-gehweg-1.1866074&amp;dr=http%3A%2F%2Fflipboard.com%2Fredirect%3Furl%3Dhttp%253A%252F%252Fwww.sueddeutsche.de%252Fmuenchen%252Fmuenchen-haidhausen-ploetzlich-zehn-meter-tiefes-loch-im-gehweg-1.1866074&amp;ul=de-de&amp;de=UTF-8&amp;dt=M%C3%BCnchen-Haidhausen%20-%20Zehn%20Meter%20tiefes%20Loch%20im%20Gehweg%20-%20M%C3%BCnchen%20-%20S%C3%BCddeutsche.de&amp;sd=32-bit&amp;sr=800x1280&amp;vp=479x710&amp;je=0&amp;_utma=6611437.1403719128.1390050886.1390050886.1390050886.1&amp;_utmz=6611437.1390050886.1.1.utmcsr%3Dflipboard.com%7Cutmccn%3D(referral)%7Cutmcmd%3Dreferral%7Cutmcct%3D%2Fredirect&amp;_utmht=1390050891510&amp;_u=cQAC~&amp;cid=1403719128.1390050886&amp;tid=UA-19474199-5&amp;cd1=200&amp;z=859363407</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>177</th>
      <td> 132320</td>
      <td>  173.194.70.154</td>
      <td>              www.googleadservices.com</td>
      <td> GET</td>
      <td> /__utm.gif?utmwv=5.4.6dc&amp;utms=1&amp;utmn=1993705442&amp;utmhn=www.sueddeutsche.de&amp;utme=8(Vermarktbar*Thema*Ressort*Dokumenttyp*URL)9(y*hochschulen*karriere*artikel*http%3A%2F%2Fwww.sueddeutsche.de%2Fkarriere%2Fstudie-hunderttausende-akademiker-arbeiten-fuer-niedrigloehne-1.1866212)&amp;utmcs=UTF-8&amp;utmsr=800x1280&amp;utmvp=479x710&amp;utmsc=32-bit&amp;utmul=de-de&amp;utmje=0&amp;utmfl=-&amp;utmdt=Hunderttausende%20Akademiker%20arbeiten%20zu%20Niederl%C3%B6hnen%20-%20Karriere%20-%20S%C3%BCddeutsche.de&amp;utmhid=1403566109&amp;utmr=http%3A%2F%2Fflipboard.com%2Fredirect%3Furl%3Dhttp%253A%252F%252Fwww.sueddeutsche.de%252Fkarriere%252Fstudie-hunderttausende-akademiker-arbeiten-fuer-niedrigloehne-1.1866212&amp;utmp=%2Fnachrichten_mobile%2Fkarriere%2Fthema%2Fhochschulen%2Fartikel%2Fstudie-hunderttausende-akademiker-arbeiten-fuer-niedrigloehne&amp;utmht=1390147627125&amp;utmac=UA-19474199-2&amp;utmcc=__utma%3D6611437.1403719128.1390050886.1390050886.1390147627.2%3B%2B__utmz%3D6611437.1390147627.2.2.utmcsr%3Dflipboard.com%7Cutmccn%3D(referral)%7Cutm...</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>178</th>
      <td>  16173</td>
      <td>  173.194.70.154</td>
      <td>              www.googleadservices.com</td>
      <td> GET</td>
      <td> /__utm.gif?utmwv=5.4.6dc&amp;utms=2&amp;utmn=1670436209&amp;utmhn=www.sueddeutsche.de&amp;utme=8(Vermarktbar*Thema*Ressort*Dokumenttyp*URL)9(y*streaming*digital*artikel*http%3A%2F%2Fwww.sueddeutsche.de%2Fdigital%2Fstreamseite-redtube-loechriges-gutachten-bringt-porno-abmahner-in-bedraengnis-1.1866025)&amp;utmcs=UTF-8&amp;utmsr=800x1280&amp;utmvp=479x710&amp;utmsc=32-bit&amp;utmul=de-de&amp;utmje=0&amp;utmfl=-&amp;utmdt=Redtube%3A%20Gutachten%20setzt%20Porno-Abmahner%20unter%20Druck%20-%20Digital%20-%20S%C3%BCddeutsche.de&amp;utmhid=2138069351&amp;utmr=http%3A%2F%2Fflipboard.com%2Fredirect%3Furl%3Dhttp%253A%252F%252Fwww.sueddeutsche.de%252Fdigital%252Fstreamseite-redtube-loechriges-gutachten-bringt-porno-abmahner-in-bedraengnis-1.1866025&amp;utmp=%2Fnachrichten_mobile%2Fdigital%2Fthema%2Fstreaming%2Fartikel%2Fstreamseite-redtube-loechriges-gutachten-bringt-porno-abmahner-in-bedraengnis&amp;utmht=1390051327076&amp;utmac=UA-19474199-2&amp;utmcc=__utma%3D6611437.1403719128.1390050886.1390050886.1390050886.1%3B%2B__utmz%3D6611437.1390050886.1.1.utmcsr%3Dfli...</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>179</th>
      <td>  89059</td>
      <td>  173.194.70.156</td>
      <td>              www.googleadservices.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                        /gampad/ads?gdfp_req=1&amp;correlator=2717019624439808&amp;output=json_html&amp;callback=window.parent.googletag.impl.pubads.setAdContentsBySlotForAsync&amp;impl=fifs&amp;json_a=1&amp;iu_parts=3467634%2CNews_960x250%2CForum_728x90_below_2000px%2CForum_160x600%2CForum_300x250&amp;enc_prev_ius=%2F0%2F1%2C%2F0%2F2%2C%2F0%2F3%2C%2F0%2F4&amp;prev_iu_szs=960x250%2C728x90%2C160x600%2C300x250&amp;cookie=ID%3D255c5e010379289e%3AT%3D1388960731%3AS%3DALNI_MY6lVEnV1B2yGODKsTz1EtTNK_Lkw&amp;lmt=1390120036&amp;dt=1390123636720&amp;cc=33&amp;biw=320&amp;bih=240&amp;oid=3&amp;gut=v2&amp;ifi=1&amp;u_tz=60&amp;u_his=3&amp;u_h=1280&amp;u_w=800&amp;u_ah=1280&amp;u_aw=800&amp;u_cd=32&amp;u_sd=1.67&amp;flash=0&amp;url=http%3A%2F%2Fwww.androidpit.de%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3&amp;adks=2176111127%2C1806238677%2C1358297623%2C956443525&amp;vrg=32&amp;vrp=32&amp;ga_vid=678182810.1388960726&amp;ga_sid=1390123637&amp;ga_hid=587405764&amp;ga_fc=true</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>180</th>
      <td>  89245</td>
      <td>  173.194.70.154</td>
      <td>              www.googleadservices.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                      /pagead/ads?client=ca-pub-1817266450476915&amp;output=html&amp;h=15&amp;slotname=4078688437&amp;adk=2218119946&amp;w=760&amp;lmt=1389611295&amp;color_bg=fbfbfb&amp;color_border=fbfbfb&amp;color_link=43a8da&amp;flash=0&amp;url=http%3A%2F%2Fwww.androidpit.de%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3&amp;dt=1389614895459&amp;shv=r20140107&amp;cbv=r20140107&amp;saldr=sb&amp;correlator=1389614893677&amp;frm=20&amp;ga_vid=678182810.1388960726&amp;ga_sid=1389614896&amp;ga_hid=2144196175&amp;ga_fc=1&amp;u_tz=60&amp;u_his=3&amp;u_java=0&amp;u_h=1280&amp;u_w=800&amp;u_ah=1280&amp;u_aw=800&amp;u_cd=32&amp;u_nplug=0&amp;u_nmime=0&amp;dff=arial&amp;dfs=13&amp;adx=169&amp;ady=1303&amp;biw=320&amp;bih=240&amp;eid=33895331%2C317150312&amp;oid=3&amp;unviewed_position_start=1&amp;rx=0&amp;fc=2&amp;vis=0&amp;fu=0&amp;ifi=6&amp;xpc=9WAELiVzU0&amp;p=http%3A//www.androidpit.de&amp;dtd=57</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>181</th>
      <td>  89240</td>
      <td>  173.194.70.154</td>
      <td>              www.googleadservices.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                 /pagead/ads?client=ca-pub-1817266450476915&amp;output=html&amp;h=600&amp;slotname=2883975723&amp;adk=345326614&amp;w=160&amp;lmt=1388957132&amp;ea=0&amp;flash=0&amp;url=http%3A%2F%2Fwww.androidpit.de%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3&amp;dt=1388960732211&amp;shv=r20131210&amp;cbv=r20131209&amp;saldr=sb&amp;correlator=1388960732235&amp;frm=23&amp;ga_vid=678182810.1388960726&amp;ga_sid=1388960726&amp;ga_hid=2129303418&amp;ga_fc=1&amp;u_tz=60&amp;u_his=3&amp;u_java=0&amp;u_h=1280&amp;u_w=800&amp;u_ah=1280&amp;u_aw=800&amp;u_cd=32&amp;u_nplug=0&amp;u_nmime=0&amp;dff=sans-serif&amp;dfs=16&amp;adx=-160&amp;ady=545&amp;biw=980&amp;bih=1410&amp;isw=160&amp;ish=600&amp;ifk=3896278517&amp;eid=317150311&amp;oid=3&amp;rs=0&amp;frmn=0&amp;vis=0&amp;fu=4&amp;ifi=1&amp;dtd=90</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>182</th>
      <td>  89334</td>
      <td>  173.194.70.154</td>
      <td>              www.googleadservices.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                /pagead/ads?client=ca-pub-1817266450476915&amp;output=html&amp;h=90&amp;slotname=9765689251&amp;adk=1289075668&amp;w=728&amp;lmt=1388957132&amp;ea=0&amp;flash=0&amp;url=http%3A%2F%2Fwww.androidpit.de%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3&amp;dt=1388960732054&amp;shv=r20131210&amp;cbv=r20131209&amp;saldr=sb&amp;correlator=1388960732091&amp;frm=23&amp;ga_vid=678182810.1388960726&amp;ga_sid=1388960726&amp;ga_hid=2105133366&amp;ga_fc=1&amp;u_tz=60&amp;u_his=3&amp;u_java=0&amp;u_h=1280&amp;u_w=800&amp;u_ah=1280&amp;u_aw=800&amp;u_cd=32&amp;u_nplug=0&amp;u_nmime=0&amp;dff=sans-serif&amp;dfs=16&amp;adx=144&amp;ady=3786&amp;biw=980&amp;bih=1410&amp;isw=728&amp;ish=90&amp;ifk=82575363&amp;eid=317150313&amp;oid=3&amp;rs=0&amp;brdim=0%2C129%2C0%2C129%2C800%2C0%2C800%2C1151%2C728%2C90&amp;vis=0&amp;fu=4&amp;ifi=1&amp;dtd=104</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>183</th>
      <td>  62291</td>
      <td>  173.194.70.157</td>
      <td>              www.googleadservices.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         /pagead/adview?ai=B6BlkasLaUuL8KO3xyAPQpIDYCLX2uJoGAAAAEAEgADgAWL3F_pWHAWCVAoIBF2NhLXB1Yi0yNjE0NjY2MjYxNTc5NzQxsgEYd3d3LmRjbGstZGVmYXVsdC1yZWYuY29tugEJZ2ZwX2ltYWdlyAEJ2gEgaHR0cDovL3d3dy5kY2xrLWRlZmF1bHQtcmVmLmNvbS_AAgLgAgDqAhg0MDYxL2FwcC55dGhvbWUvX2RlZmF1bHT4Av3RHoADAZADjAaYA6QDqAMB4AQBoAYg2AYC&amp;sigh=ccaofuJWBm0&amp;adurl=</td>
      <td>                                                                                                                                  com.google.android.youtube/5.3.32(Linux; U; Android 4.3.1; de_DE; GT-N7000 Build/JLS36I) gzip</td>
    </tr>
    <tr>
      <th>184</th>
      <td>  62854</td>
      <td>  173.194.70.157</td>
      <td>              www.googleadservices.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          /pagead/adview?ai=B6rsTicLaUoXYAo2i-gbf94GQCq25_c0EAAAAEAEgADgAUOaLpZ74_____wFY9b6FpWtglQKCARdjYS1wdWItMjYxNDY2NjI2MTU3OTc0MbIBGHd3dy5kY2xrLWRlZmF1bHQtcmVmLmNvbboBCWdmcF9pbWFnZcgBAtoBIGh0dHA6Ly93d3cuZGNsay1kZWZhdWx0LXJlZi5jb20vwAIC4AIA6gIpNDA2MS9hcHAueXRwd2F0Y2guZW50ZXJ0YWlubWVudC9tYWluXzg5Mzj4Av3RHpADjAaYA6QDqAMB0ASQTuAEAaAGMtgGAg&amp;sigh=Vq7JIfuxoVI</td>
      <td>                                                                                                                                  com.google.android.youtube/5.3.32(Linux; U; Android 4.3.1; de_DE; GT-N7000 Build/JLS36I) gzip</td>
    </tr>
    <tr>
      <th>185</th>
      <td>  23972</td>
      <td>  173.194.70.154</td>
      <td>              www.googleadservices.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       /pagead/conversion/1001680686/?label=4dahCKKczAYQrt7R3QM&amp;value=&amp;muid=myTNNlwjHP2x7sOPdZUceA&amp;bundleid=com.google.android.youtube&amp;appversion=5.3.32&amp;osversion=4.3.1&amp;sdkversion=ct-sdk-a-v1.1.0&amp;remarketing_only=1&amp;timestamp=1390052022&amp;data=screen_name%3D%3CAndroid_YT_Open_App%3E</td>
      <td>                                                                                                                                                                  Dalvik/1.6.0 (Linux; U; Android 4.3.1; GT-N7000 Build/JLS36I)</td>
    </tr>
    <tr>
      <th>186</th>
      <td>  25754</td>
      <td>  173.194.70.157</td>
      <td>              www.googleadservices.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       /pagead/conversion/1001680686/?label=4dahCKKczAYQrt7R3QM&amp;value=&amp;muid=myTNNlwjHP2x7sOPdZUceA&amp;bundleid=com.google.android.youtube&amp;appversion=5.3.32&amp;osversion=4.3.1&amp;sdkversion=ct-sdk-a-v1.1.0&amp;remarketing_only=1&amp;timestamp=1390053879&amp;data=screen_name%3D%3CAndroid_YT_Open_App%3E</td>
      <td>                                                                                                                                                                  Dalvik/1.6.0 (Linux; U; Android 4.3.1; GT-N7000 Build/JLS36I)</td>
    </tr>
    <tr>
      <th>187</th>
      <td>  61969</td>
      <td>  173.194.70.156</td>
      <td>              www.googleadservices.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       /pagead/conversion/1001680686/?label=4dahCKKczAYQrt7R3QM&amp;value=&amp;muid=myTNNlwjHP2x7sOPdZUceA&amp;bundleid=com.google.android.youtube&amp;appversion=5.3.32&amp;osversion=4.3.1&amp;sdkversion=ct-sdk-a-v1.1.0&amp;remarketing_only=1&amp;timestamp=1390068090&amp;data=screen_name%3D%3CAndroid_YT_Open_App%3E</td>
      <td>                                                                                                                                                                  Dalvik/1.6.0 (Linux; U; Android 4.3.1; GT-N7000 Build/JLS36I)</td>
    </tr>
    <tr>
      <th>188</th>
      <td>  69160</td>
      <td>  173.194.70.156</td>
      <td>              www.googleadservices.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       /pagead/conversion/1001680686/?label=4dahCKKczAYQrt7R3QM&amp;value=&amp;muid=myTNNlwjHP2x7sOPdZUceA&amp;bundleid=com.google.android.youtube&amp;appversion=5.3.32&amp;osversion=4.3.1&amp;sdkversion=ct-sdk-a-v1.1.0&amp;remarketing_only=1&amp;timestamp=1390068519&amp;data=screen_name%3D%3CAndroid_YT_Open_App%3E</td>
      <td>                                                                                                                                                                  Dalvik/1.6.0 (Linux; U; Android 4.3.1; GT-N7000 Build/JLS36I)</td>
    </tr>
    <tr>
      <th>189</th>
      <td>  77062</td>
      <td>  173.194.70.157</td>
      <td>              www.googleadservices.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       /pagead/conversion/1001680686/?label=4dahCKKczAYQrt7R3QM&amp;value=&amp;muid=myTNNlwjHP2x7sOPdZUceA&amp;bundleid=com.google.android.youtube&amp;appversion=5.3.32&amp;osversion=4.3.1&amp;sdkversion=ct-sdk-a-v1.1.0&amp;remarketing_only=1&amp;timestamp=1390083647&amp;data=screen_name%3D%3CAndroid_YT_Open_App%3E</td>
      <td>                                                                                                                                                                  Dalvik/1.6.0 (Linux; U; Android 4.3.1; GT-N7000 Build/JLS36I)</td>
    </tr>
    <tr>
      <th>190</th>
      <td> 138476</td>
      <td>  173.194.70.157</td>
      <td>              www.googleadservices.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       /pagead/conversion/1001680686/?label=4dahCKKczAYQrt7R3QM&amp;value=&amp;muid=myTNNlwjHP2x7sOPdZUceA&amp;bundleid=com.google.android.youtube&amp;appversion=5.3.32&amp;osversion=4.3.1&amp;sdkversion=ct-sdk-a-v1.1.0&amp;remarketing_only=1&amp;timestamp=1390148833&amp;data=screen_name%3D%3CAndroid_YT_Open_App%3E</td>
      <td>                                                                                                                                                                  Dalvik/1.6.0 (Linux; U; Android 4.3.1; GT-N7000 Build/JLS36I)</td>
    </tr>
    <tr>
      <th>191</th>
      <td>  16190</td>
      <td>  173.194.70.157</td>
      <td>              www.googleadservices.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  /pixel?google_nid=9675309&amp;google_hm=bnRnR1JQd0IzMVlhMThxY2xKQlJkZFFRYVBNcnhnTFo%3D&amp;google_cm&amp;google_sc</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>192</th>
      <td>  16302</td>
      <td>  173.194.70.157</td>
      <td>              www.googleadservices.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     /pixel?google_nid=9675309&amp;google_hm=bnRnR1JQd0IzMVlhMThxY2xKQlJkZFFRYVBNcnhnTFo%3D&amp;google_cm=&amp;google_sc=&amp;google_tc=</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>193</th>
      <td>  89554</td>
      <td>  173.194.70.154</td>
      <td>              www.googleadservices.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            /simgad/16975570946260456591</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>194</th>
      <td>  89337</td>
      <td>  173.194.70.154</td>
      <td>              www.googleadservices.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            /simgad/17705960718182275898</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>195</th>
      <td>  19576</td>
      <td>   173.194.70.95</td>
      <td>                    www.googleapis.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     /css?family=Open+Sans:400,600&amp;subset=latin,cyrillic</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>196</th>
      <td>  89612</td>
      <td>   173.194.70.95</td>
      <td>                    www.googleapis.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  /css?family=Roboto:300</td>
      <td>                                                                                    Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30</td>
    </tr>
    <tr>
      <th>197</th>
      <td>  74599</td>
      <td>   173.194.70.95</td>
      <td>                    www.googleapis.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      /maps/api/elevation/xml?locations=52.501904,13.342198&amp;sensor=false</td>
      <td>                                                                                                                                                                                                                           None</td>
    </tr>
    <tr>
      <th>198</th>
      <td> 132446</td>
      <td> 173.194.116.190</td>
      <td>              www.googletagmanager.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   /gtm.js?id=GTM-PXNL5Z</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>199</th>
      <td>   3885</td>
      <td>  173.194.70.155</td>
      <td>             www.googletagservices.com</td>
      <td> GET</td>
      <td> /__utm.gif?utmwv=5.4.6dc&amp;utms=1&amp;utmn=1807714930&amp;utmhn=www.sueddeutsche.de&amp;utme=8(Vermarktbar*Thema*Ressort*Dokumenttyp*URL)9(y*unfall*muenchen*artikel*http%3A%2F%2Fwww.sueddeutsche.de%2Fmuenchen%2Fmuenchen-haidhausen-ploetzlich-zehn-meter-tiefes-loch-im-gehweg-1.1866074)&amp;utmcs=UTF-8&amp;utmsr=800x1280&amp;utmvp=479x710&amp;utmsc=32-bit&amp;utmul=de-de&amp;utmje=0&amp;utmfl=-&amp;utmdt=M%C3%BCnchen-Haidhausen%20-%20Zehn%20Meter%20tiefes%20Loch%20im%20Gehweg%20-%20M%C3%BCnchen%20-%20S%C3%BCddeutsche.de&amp;utmhid=725159496&amp;utmr=http%3A%2F%2Fflipboard.com%2Fredirect%3Furl%3Dhttp%253A%252F%252Fwww.sueddeutsche.de%252Fmuenchen%252Fmuenchen-haidhausen-ploetzlich-zehn-meter-tiefes-loch-im-gehweg-1.1866074&amp;utmp=%2Fnachrichten_mobile%2Fmuenchen%2Fthema%2Funfall%2Fartikel%2Fmuenchen-haidhausen-ploetzlich-zehn-meter-tiefes-loch-im-gehweg&amp;utmht=1390050886104&amp;utmac=UA-19474199-2&amp;utmcc=__utma%3D6611437.1403719128.1390050886.1390050886.1390050886.1%3B%2B__utmz%3D6611437.1390050886.1.1.utmcsr%3Dflipboard.com%7Cutmccn%3D(referral...</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>200</th>
      <td>  28309</td>
      <td>  195.246.160.36</td>
      <td>                      www.hr-online.de</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 /servlet/de.hr.cms.servlet.IMS?enc=d3M9aHJteXNxbCZibG9iSWQ9MTg3NTgyMTQmaWQ9NTA1OTg2ODU_</td>
      <td>                                                                                                                                                                  null (FlipboardProxy/1.1; +http://flipboard.com/browserproxy)</td>
    </tr>
    <tr>
      <th>201</th>
      <td> 103826</td>
      <td>    83.223.85.61</td>
      <td>              www.neues-deutschland.de</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            /img/t/86771</td>
      <td>                                                                                                                                                                  null (FlipboardProxy/1.1; +http://flipboard.com/browserproxy)</td>
    </tr>
    <tr>
      <th>202</th>
      <td>   9514</td>
      <td>    2.23.186.240</td>
      <td>                     www.tagesschau.de</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      /resources/framework/css/fonts/TheSans_LT_TT5_.svg</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>203</th>
      <td>   9529</td>
      <td>    2.23.186.240</td>
      <td>                     www.tagesschau.de</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      /resources/framework/css/fonts/TheSans_LT_TT5i.svg</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>204</th>
      <td>   9521</td>
      <td>    2.23.186.240</td>
      <td>                     www.tagesschau.de</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      /resources/framework/css/fonts/TheSans_LT_TT7_.svg</td>
      <td>                            Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100</td>
    </tr>
    <tr>
      <th>205</th>
      <td>  94881</td>
      <td>   193.104.220.6</td>
      <td>                            www.taz.de</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           /Essay-zur-Zuwanderung-aus-Osteuropa/!131209/</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>206</th>
      <td>  95323</td>
      <td>   193.104.220.6</td>
      <td>                            www.taz.de</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         /Essay-zur-Zuwanderung-aus-Osteuropa/!131209;m/</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>207</th>
      <td>  95594</td>
      <td>   193.104.220.6</td>
      <td>                            www.taz.de</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 /digitaz/cntres/szmmobil_Debatte-Artikel/ecnt/4702537358.taz/countergif</td>
      <td>                        Mozilla/5.0 (Linux; U; Android 4.3.1; de-de; GT-N7000 Build/JLS36I) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30 Flipboard/2.2.2/2070,2.2.2.2070,2014-01-16 17:55, +0100, de</td>
    </tr>
    <tr>
      <th>208</th>
      <td>  98714</td>
      <td>   185.31.17.185</td>
      <td>                      www.theverge.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          /rss/index.xml</td>
      <td>                                                                                                                                                                                                              Ultimate DayDream</td>
    </tr>
    <tr>
      <th>209</th>
      <td>  62133</td>
      <td>  173.194.70.136</td>
      <td>              www.youtube-nocookie.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    /device_204?app_anon_id=6988a4be-80bf-4a77-9581-f98c234a176f&amp;firstactive=1389027600&amp;firstactivegeo=DE&amp;firstlogin=1389027600&amp;prevactive=1390003200&amp;prevlogin=1390003200&amp;loginstate=1&amp;cplatform=mobile&amp;c=android&amp;cver=5.3.32&amp;cos=Android&amp;cosver=4.3.1&amp;cbr=com.google.android.youtube&amp;cbrver=5.3.32&amp;cbrand=samsung&amp;cmodel=GT-N7000&amp;cnetwork=o2%20-%20de</td>
      <td>                                                                                                                                       com.google.android.youtube/5.3.32(Linux; U; Android 4.3.1; de_DE; GT-N7000 Build/JLS36I)</td>
    </tr>
    <tr>
      <th>210</th>
      <td>  62049</td>
      <td> 173.194.116.167</td>
      <td>                       www.youtube.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     /leanback_ajax?action_environment=1</td>
      <td>                                                                                                                                  com.google.android.youtube/5.3.32(Linux; U; Android 4.3.1; de_DE; GT-N7000 Build/JLS36I) gzip</td>
    </tr>
    <tr>
      <th>211</th>
      <td>  64130</td>
      <td> 173.194.116.167</td>
      <td>                       www.youtube.com</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          /ptracking?ptk=KontorRecords&amp;video_id=GoYrjCkN3Q4&amp;ptchn=b3tJ5NKw7mDxyaQ73mwbRg&amp;plid=AATwQoLNVKjFDu_5&amp;oid=SqRrmZwFybZNrAc1Oh_HdQ&amp;pltype=content</td>
      <td>                                                                                                                                       com.google.android.youtube/5.3.32(Linux; U; Android 4.3.1; de_DE; GT-N7000 Build/JLS36I)</td>
    </tr>
    <tr>
      <th>212</th>
      <td>  73978</td>
      <td>  54.240.184.218</td>
      <td>                  xtra2.gpsonextra.net</td>
      <td> GET</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               /xtra.bin</td>
      <td>                                                                                                                                                                                                                        Android</td>
    </tr>
  </tbody>
</table>
</div>




```

```


```

```

## POST Requests


```
p3 = pdsql.read_frame(""" 
    SELECT h.frame_number, d.dns_query, h.request_uri, h.data, h.text FROM http AS  h
    JOIN dns AS d ON h.ip_dst = d.dns_response
    WHERE lower(h.request_method) == 'post'
    ORDER by h.ip_dst    
""", con)
p3.head(500)
```




<div style="max-height:1000px;max-width:1500px;overflow:auto;">
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>frame_number</th>
      <th>dns_query</th>
      <th>request_uri</th>
      <th>data</th>
      <th>text</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0  </th>
      <td> 25716</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32971737, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>1  </th>
      <td> 25716</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32971737, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>2  </th>
      <td> 25716</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32971737, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>3  </th>
      <td> 25716</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32971737, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>4  </th>
      <td> 25716</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32971737, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>5  </th>
      <td> 25716</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32971737, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>6  </th>
      <td> 25716</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32971737, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>7  </th>
      <td> 25716</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32971737, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>8  </th>
      <td> 25724</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32972126, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>9  </th>
      <td> 25724</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32972126, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>10 </th>
      <td> 25724</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32972126, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>11 </th>
      <td> 25724</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32972126, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>12 </th>
      <td> 25724</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32972126, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>13 </th>
      <td> 25724</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32972126, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>14 </th>
      <td> 25724</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32972126, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>15 </th>
      <td> 25724</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32972126, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>16 </th>
      <td> 25833</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"ca3318438b295ab61a34b2a10b960a1c682","timestamp":13900538811,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"364989804263bd8af6146c078eed4850"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973358, TSecr 191670484,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>17 </th>
      <td> 25833</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"ca3318438b295ab61a34b2a10b960a1c682","timestamp":13900538811,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"364989804263bd8af6146c078eed4850"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973358, TSecr 191670484,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>18 </th>
      <td> 25833</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"ca3318438b295ab61a34b2a10b960a1c682","timestamp":13900538811,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"364989804263bd8af6146c078eed4850"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973358, TSecr 191670484,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>19 </th>
      <td> 25833</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"ca3318438b295ab61a34b2a10b960a1c682","timestamp":13900538811,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"364989804263bd8af6146c078eed4850"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973358, TSecr 191670484,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>20 </th>
      <td> 25833</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"ca3318438b295ab61a34b2a10b960a1c682","timestamp":13900538811,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"364989804263bd8af6146c078eed4850"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973358, TSecr 191670484,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>21 </th>
      <td> 25833</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"ca3318438b295ab61a34b2a10b960a1c682","timestamp":13900538811,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"364989804263bd8af6146c078eed4850"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973358, TSecr 191670484,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>22 </th>
      <td> 25833</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"ca3318438b295ab61a34b2a10b960a1c682","timestamp":13900538811,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"364989804263bd8af6146c078eed4850"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973358, TSecr 191670484,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>23 </th>
      <td> 25833</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"ca3318438b295ab61a34b2a10b960a1c682","timestamp":13900538811,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"364989804263bd8af6146c078eed4850"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973358, TSecr 191670484,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>24 </th>
      <td> 25868</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td> {"action":"getDeviceMessages","getDeviceMessages":{"queryType":"Regular","latestMessageDate":"2014-01-18T12:51:31.836","key":"19ba7bd21bb3cfa3"},"auth":{"random":"851868430692926395b96bcc6c62b869916","timestamp":13900538825,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"c5881a2819930f43af0b88c8c0f83c05"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                             No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973422, TSecr 191670577,POST /api/ HTTP/1.1\r\n,Cookie2: $Version=1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>25 </th>
      <td> 25868</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td> {"action":"getDeviceMessages","getDeviceMessages":{"queryType":"Regular","latestMessageDate":"2014-01-18T12:51:31.836","key":"19ba7bd21bb3cfa3"},"auth":{"random":"851868430692926395b96bcc6c62b869916","timestamp":13900538825,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"c5881a2819930f43af0b88c8c0f83c05"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                             No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973422, TSecr 191670577,POST /api/ HTTP/1.1\r\n,Cookie2: $Version=1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>26 </th>
      <td> 25868</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td> {"action":"getDeviceMessages","getDeviceMessages":{"queryType":"Regular","latestMessageDate":"2014-01-18T12:51:31.836","key":"19ba7bd21bb3cfa3"},"auth":{"random":"851868430692926395b96bcc6c62b869916","timestamp":13900538825,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"c5881a2819930f43af0b88c8c0f83c05"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                             No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973422, TSecr 191670577,POST /api/ HTTP/1.1\r\n,Cookie2: $Version=1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>27 </th>
      <td> 25868</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td> {"action":"getDeviceMessages","getDeviceMessages":{"queryType":"Regular","latestMessageDate":"2014-01-18T12:51:31.836","key":"19ba7bd21bb3cfa3"},"auth":{"random":"851868430692926395b96bcc6c62b869916","timestamp":13900538825,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"c5881a2819930f43af0b88c8c0f83c05"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                             No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973422, TSecr 191670577,POST /api/ HTTP/1.1\r\n,Cookie2: $Version=1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>28 </th>
      <td> 25868</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td> {"action":"getDeviceMessages","getDeviceMessages":{"queryType":"Regular","latestMessageDate":"2014-01-18T12:51:31.836","key":"19ba7bd21bb3cfa3"},"auth":{"random":"851868430692926395b96bcc6c62b869916","timestamp":13900538825,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"c5881a2819930f43af0b88c8c0f83c05"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                             No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973422, TSecr 191670577,POST /api/ HTTP/1.1\r\n,Cookie2: $Version=1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>29 </th>
      <td> 25868</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td> {"action":"getDeviceMessages","getDeviceMessages":{"queryType":"Regular","latestMessageDate":"2014-01-18T12:51:31.836","key":"19ba7bd21bb3cfa3"},"auth":{"random":"851868430692926395b96bcc6c62b869916","timestamp":13900538825,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"c5881a2819930f43af0b88c8c0f83c05"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                             No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973422, TSecr 191670577,POST /api/ HTTP/1.1\r\n,Cookie2: $Version=1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>30 </th>
      <td> 25868</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td> {"action":"getDeviceMessages","getDeviceMessages":{"queryType":"Regular","latestMessageDate":"2014-01-18T12:51:31.836","key":"19ba7bd21bb3cfa3"},"auth":{"random":"851868430692926395b96bcc6c62b869916","timestamp":13900538825,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"c5881a2819930f43af0b88c8c0f83c05"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                             No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973422, TSecr 191670577,POST /api/ HTTP/1.1\r\n,Cookie2: $Version=1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>31 </th>
      <td> 25868</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td> {"action":"getDeviceMessages","getDeviceMessages":{"queryType":"Regular","latestMessageDate":"2014-01-18T12:51:31.836","key":"19ba7bd21bb3cfa3"},"auth":{"random":"851868430692926395b96bcc6c62b869916","timestamp":13900538825,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"c5881a2819930f43af0b88c8c0f83c05"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                             No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973422, TSecr 191670577,POST /api/ HTTP/1.1\r\n,Cookie2: $Version=1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>32 </th>
      <td> 25716</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32971737, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>33 </th>
      <td> 25716</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32971737, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>34 </th>
      <td> 25716</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32971737, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>35 </th>
      <td> 25716</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32971737, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>36 </th>
      <td> 25716</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32971737, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>37 </th>
      <td> 25716</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32971737, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>38 </th>
      <td> 25716</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32971737, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>39 </th>
      <td> 25716</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32971737, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>40 </th>
      <td> 25724</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32972126, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>41 </th>
      <td> 25724</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32972126, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>42 </th>
      <td> 25724</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32972126, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>43 </th>
      <td> 25724</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32972126, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>44 </th>
      <td> 25724</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32972126, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>45 </th>
      <td> 25724</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32972126, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>46 </th>
      <td> 25724</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32972126, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>47 </th>
      <td> 25724</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32972126, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>48 </th>
      <td> 25833</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"ca3318438b295ab61a34b2a10b960a1c682","timestamp":13900538811,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"364989804263bd8af6146c078eed4850"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973358, TSecr 191670484,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>49 </th>
      <td> 25833</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"ca3318438b295ab61a34b2a10b960a1c682","timestamp":13900538811,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"364989804263bd8af6146c078eed4850"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973358, TSecr 191670484,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>50 </th>
      <td> 25833</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"ca3318438b295ab61a34b2a10b960a1c682","timestamp":13900538811,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"364989804263bd8af6146c078eed4850"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973358, TSecr 191670484,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>51 </th>
      <td> 25833</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"ca3318438b295ab61a34b2a10b960a1c682","timestamp":13900538811,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"364989804263bd8af6146c078eed4850"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973358, TSecr 191670484,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>52 </th>
      <td> 25833</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"ca3318438b295ab61a34b2a10b960a1c682","timestamp":13900538811,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"364989804263bd8af6146c078eed4850"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973358, TSecr 191670484,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>53 </th>
      <td> 25833</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"ca3318438b295ab61a34b2a10b960a1c682","timestamp":13900538811,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"364989804263bd8af6146c078eed4850"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973358, TSecr 191670484,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>54 </th>
      <td> 25833</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"ca3318438b295ab61a34b2a10b960a1c682","timestamp":13900538811,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"364989804263bd8af6146c078eed4850"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973358, TSecr 191670484,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>55 </th>
      <td> 25833</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"ca3318438b295ab61a34b2a10b960a1c682","timestamp":13900538811,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"364989804263bd8af6146c078eed4850"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973358, TSecr 191670484,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>56 </th>
      <td> 25868</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td> {"action":"getDeviceMessages","getDeviceMessages":{"queryType":"Regular","latestMessageDate":"2014-01-18T12:51:31.836","key":"19ba7bd21bb3cfa3"},"auth":{"random":"851868430692926395b96bcc6c62b869916","timestamp":13900538825,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"c5881a2819930f43af0b88c8c0f83c05"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                             No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973422, TSecr 191670577,POST /api/ HTTP/1.1\r\n,Cookie2: $Version=1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>57 </th>
      <td> 25868</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td> {"action":"getDeviceMessages","getDeviceMessages":{"queryType":"Regular","latestMessageDate":"2014-01-18T12:51:31.836","key":"19ba7bd21bb3cfa3"},"auth":{"random":"851868430692926395b96bcc6c62b869916","timestamp":13900538825,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"c5881a2819930f43af0b88c8c0f83c05"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                             No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973422, TSecr 191670577,POST /api/ HTTP/1.1\r\n,Cookie2: $Version=1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>58 </th>
      <td> 25868</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td> {"action":"getDeviceMessages","getDeviceMessages":{"queryType":"Regular","latestMessageDate":"2014-01-18T12:51:31.836","key":"19ba7bd21bb3cfa3"},"auth":{"random":"851868430692926395b96bcc6c62b869916","timestamp":13900538825,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"c5881a2819930f43af0b88c8c0f83c05"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                             No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973422, TSecr 191670577,POST /api/ HTTP/1.1\r\n,Cookie2: $Version=1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>59 </th>
      <td> 25868</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td> {"action":"getDeviceMessages","getDeviceMessages":{"queryType":"Regular","latestMessageDate":"2014-01-18T12:51:31.836","key":"19ba7bd21bb3cfa3"},"auth":{"random":"851868430692926395b96bcc6c62b869916","timestamp":13900538825,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"c5881a2819930f43af0b88c8c0f83c05"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                             No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973422, TSecr 191670577,POST /api/ HTTP/1.1\r\n,Cookie2: $Version=1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>60 </th>
      <td> 25868</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td> {"action":"getDeviceMessages","getDeviceMessages":{"queryType":"Regular","latestMessageDate":"2014-01-18T12:51:31.836","key":"19ba7bd21bb3cfa3"},"auth":{"random":"851868430692926395b96bcc6c62b869916","timestamp":13900538825,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"c5881a2819930f43af0b88c8c0f83c05"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                             No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973422, TSecr 191670577,POST /api/ HTTP/1.1\r\n,Cookie2: $Version=1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>61 </th>
      <td> 25868</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td> {"action":"getDeviceMessages","getDeviceMessages":{"queryType":"Regular","latestMessageDate":"2014-01-18T12:51:31.836","key":"19ba7bd21bb3cfa3"},"auth":{"random":"851868430692926395b96bcc6c62b869916","timestamp":13900538825,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"c5881a2819930f43af0b88c8c0f83c05"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                             No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973422, TSecr 191670577,POST /api/ HTTP/1.1\r\n,Cookie2: $Version=1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>62 </th>
      <td> 25868</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td> {"action":"getDeviceMessages","getDeviceMessages":{"queryType":"Regular","latestMessageDate":"2014-01-18T12:51:31.836","key":"19ba7bd21bb3cfa3"},"auth":{"random":"851868430692926395b96bcc6c62b869916","timestamp":13900538825,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"c5881a2819930f43af0b88c8c0f83c05"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                             No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973422, TSecr 191670577,POST /api/ HTTP/1.1\r\n,Cookie2: $Version=1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>63 </th>
      <td> 25868</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td> {"action":"getDeviceMessages","getDeviceMessages":{"queryType":"Regular","latestMessageDate":"2014-01-18T12:51:31.836","key":"19ba7bd21bb3cfa3"},"auth":{"random":"851868430692926395b96bcc6c62b869916","timestamp":13900538825,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"c5881a2819930f43af0b88c8c0f83c05"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                             No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973422, TSecr 191670577,POST /api/ HTTP/1.1\r\n,Cookie2: $Version=1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>64 </th>
      <td> 25716</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32971737, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>65 </th>
      <td> 25716</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32971737, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>66 </th>
      <td> 25716</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32971737, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>67 </th>
      <td> 25716</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32971737, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>68 </th>
      <td> 25716</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32971737, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>69 </th>
      <td> 25716</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32971737, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>70 </th>
      <td> 25716</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32971737, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>71 </th>
      <td> 25716</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32971737, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>72 </th>
      <td> 25724</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32972126, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>73 </th>
      <td> 25724</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32972126, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>74 </th>
      <td> 25724</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32972126, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>75 </th>
      <td> 25724</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32972126, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>76 </th>
      <td> 25724</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32972126, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>77 </th>
      <td> 25724</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32972126, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>78 </th>
      <td> 25724</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32972126, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>79 </th>
      <td> 25724</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32972126, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>80 </th>
      <td> 25833</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"ca3318438b295ab61a34b2a10b960a1c682","timestamp":13900538811,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"364989804263bd8af6146c078eed4850"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973358, TSecr 191670484,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>81 </th>
      <td> 25833</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"ca3318438b295ab61a34b2a10b960a1c682","timestamp":13900538811,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"364989804263bd8af6146c078eed4850"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973358, TSecr 191670484,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>82 </th>
      <td> 25833</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"ca3318438b295ab61a34b2a10b960a1c682","timestamp":13900538811,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"364989804263bd8af6146c078eed4850"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973358, TSecr 191670484,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>83 </th>
      <td> 25833</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"ca3318438b295ab61a34b2a10b960a1c682","timestamp":13900538811,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"364989804263bd8af6146c078eed4850"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973358, TSecr 191670484,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>84 </th>
      <td> 25833</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"ca3318438b295ab61a34b2a10b960a1c682","timestamp":13900538811,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"364989804263bd8af6146c078eed4850"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973358, TSecr 191670484,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>85 </th>
      <td> 25833</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"ca3318438b295ab61a34b2a10b960a1c682","timestamp":13900538811,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"364989804263bd8af6146c078eed4850"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973358, TSecr 191670484,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>86 </th>
      <td> 25833</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"ca3318438b295ab61a34b2a10b960a1c682","timestamp":13900538811,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"364989804263bd8af6146c078eed4850"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973358, TSecr 191670484,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>87 </th>
      <td> 25833</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"ca3318438b295ab61a34b2a10b960a1c682","timestamp":13900538811,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"364989804263bd8af6146c078eed4850"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973358, TSecr 191670484,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>88 </th>
      <td> 25868</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td> {"action":"getDeviceMessages","getDeviceMessages":{"queryType":"Regular","latestMessageDate":"2014-01-18T12:51:31.836","key":"19ba7bd21bb3cfa3"},"auth":{"random":"851868430692926395b96bcc6c62b869916","timestamp":13900538825,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"c5881a2819930f43af0b88c8c0f83c05"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                             No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973422, TSecr 191670577,POST /api/ HTTP/1.1\r\n,Cookie2: $Version=1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>89 </th>
      <td> 25868</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td> {"action":"getDeviceMessages","getDeviceMessages":{"queryType":"Regular","latestMessageDate":"2014-01-18T12:51:31.836","key":"19ba7bd21bb3cfa3"},"auth":{"random":"851868430692926395b96bcc6c62b869916","timestamp":13900538825,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"c5881a2819930f43af0b88c8c0f83c05"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                             No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973422, TSecr 191670577,POST /api/ HTTP/1.1\r\n,Cookie2: $Version=1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>90 </th>
      <td> 25868</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td> {"action":"getDeviceMessages","getDeviceMessages":{"queryType":"Regular","latestMessageDate":"2014-01-18T12:51:31.836","key":"19ba7bd21bb3cfa3"},"auth":{"random":"851868430692926395b96bcc6c62b869916","timestamp":13900538825,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"c5881a2819930f43af0b88c8c0f83c05"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                             No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973422, TSecr 191670577,POST /api/ HTTP/1.1\r\n,Cookie2: $Version=1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>91 </th>
      <td> 25868</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td> {"action":"getDeviceMessages","getDeviceMessages":{"queryType":"Regular","latestMessageDate":"2014-01-18T12:51:31.836","key":"19ba7bd21bb3cfa3"},"auth":{"random":"851868430692926395b96bcc6c62b869916","timestamp":13900538825,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"c5881a2819930f43af0b88c8c0f83c05"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                             No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973422, TSecr 191670577,POST /api/ HTTP/1.1\r\n,Cookie2: $Version=1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>92 </th>
      <td> 25868</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td> {"action":"getDeviceMessages","getDeviceMessages":{"queryType":"Regular","latestMessageDate":"2014-01-18T12:51:31.836","key":"19ba7bd21bb3cfa3"},"auth":{"random":"851868430692926395b96bcc6c62b869916","timestamp":13900538825,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"c5881a2819930f43af0b88c8c0f83c05"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                             No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973422, TSecr 191670577,POST /api/ HTTP/1.1\r\n,Cookie2: $Version=1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>93 </th>
      <td> 25868</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td> {"action":"getDeviceMessages","getDeviceMessages":{"queryType":"Regular","latestMessageDate":"2014-01-18T12:51:31.836","key":"19ba7bd21bb3cfa3"},"auth":{"random":"851868430692926395b96bcc6c62b869916","timestamp":13900538825,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"c5881a2819930f43af0b88c8c0f83c05"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                             No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973422, TSecr 191670577,POST /api/ HTTP/1.1\r\n,Cookie2: $Version=1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>94 </th>
      <td> 25868</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td> {"action":"getDeviceMessages","getDeviceMessages":{"queryType":"Regular","latestMessageDate":"2014-01-18T12:51:31.836","key":"19ba7bd21bb3cfa3"},"auth":{"random":"851868430692926395b96bcc6c62b869916","timestamp":13900538825,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"c5881a2819930f43af0b88c8c0f83c05"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                             No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973422, TSecr 191670577,POST /api/ HTTP/1.1\r\n,Cookie2: $Version=1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>95 </th>
      <td> 25868</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td> {"action":"getDeviceMessages","getDeviceMessages":{"queryType":"Regular","latestMessageDate":"2014-01-18T12:51:31.836","key":"19ba7bd21bb3cfa3"},"auth":{"random":"851868430692926395b96bcc6c62b869916","timestamp":13900538825,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"c5881a2819930f43af0b88c8c0f83c05"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                             No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973422, TSecr 191670577,POST /api/ HTTP/1.1\r\n,Cookie2: $Version=1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>96 </th>
      <td> 25716</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32971737, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>97 </th>
      <td> 25716</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32971737, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>98 </th>
      <td> 25716</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32971737, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>99 </th>
      <td> 25716</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32971737, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>100</th>
      <td> 25716</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32971737, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>101</th>
      <td> 25716</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32971737, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>102</th>
      <td> 25716</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32971737, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>103</th>
      <td> 25716</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32971737, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>104</th>
      <td> 25724</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32972126, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>105</th>
      <td> 25724</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32972126, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>106</th>
      <td> 25724</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32972126, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>107</th>
      <td> 25724</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32972126, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>108</th>
      <td> 25724</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32972126, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>109</th>
      <td> 25724</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32972126, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>110</th>
      <td> 25724</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32972126, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>111</th>
      <td> 25724</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"1119413a297389c129790915258b4825171","timestamp":13900538708,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"fdfc1bbba1ab6eb97a59e08c49e3271a"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32972126, TSecr 191668474,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>112</th>
      <td> 25833</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"ca3318438b295ab61a34b2a10b960a1c682","timestamp":13900538811,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"364989804263bd8af6146c078eed4850"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973358, TSecr 191670484,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>113</th>
      <td> 25833</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"ca3318438b295ab61a34b2a10b960a1c682","timestamp":13900538811,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"364989804263bd8af6146c078eed4850"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973358, TSecr 191670484,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>114</th>
      <td> 25833</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"ca3318438b295ab61a34b2a10b960a1c682","timestamp":13900538811,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"364989804263bd8af6146c078eed4850"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973358, TSecr 191670484,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>115</th>
      <td> 25833</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"ca3318438b295ab61a34b2a10b960a1c682","timestamp":13900538811,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"364989804263bd8af6146c078eed4850"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973358, TSecr 191670484,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>116</th>
      <td> 25833</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"ca3318438b295ab61a34b2a10b960a1c682","timestamp":13900538811,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"364989804263bd8af6146c078eed4850"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973358, TSecr 191670484,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>117</th>
      <td> 25833</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"ca3318438b295ab61a34b2a10b960a1c682","timestamp":13900538811,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"364989804263bd8af6146c078eed4850"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973358, TSecr 191670484,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>118</th>
      <td> 25833</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"ca3318438b295ab61a34b2a10b960a1c682","timestamp":13900538811,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"364989804263bd8af6146c078eed4850"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973358, TSecr 191670484,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>119</th>
      <td> 25833</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td>                                                                                                                        {"action":"getServerTime","auth":{"random":"ca3318438b295ab61a34b2a10b960a1c682","timestamp":13900538811,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"364989804263bd8af6146c078eed4850"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                                                     No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973358, TSecr 191670484,POST /api/ HTTP/1.1\r\n,\r\n,HTTP request 1/1</td>
    </tr>
    <tr>
      <th>120</th>
      <td> 25868</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td> {"action":"getDeviceMessages","getDeviceMessages":{"queryType":"Regular","latestMessageDate":"2014-01-18T12:51:31.836","key":"19ba7bd21bb3cfa3"},"auth":{"random":"851868430692926395b96bcc6c62b869916","timestamp":13900538825,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"c5881a2819930f43af0b88c8c0f83c05"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                             No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973422, TSecr 191670577,POST /api/ HTTP/1.1\r\n,Cookie2: $Version=1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>121</th>
      <td> 25868</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td> {"action":"getDeviceMessages","getDeviceMessages":{"queryType":"Regular","latestMessageDate":"2014-01-18T12:51:31.836","key":"19ba7bd21bb3cfa3"},"auth":{"random":"851868430692926395b96bcc6c62b869916","timestamp":13900538825,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"c5881a2819930f43af0b88c8c0f83c05"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                             No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973422, TSecr 191670577,POST /api/ HTTP/1.1\r\n,Cookie2: $Version=1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>122</th>
      <td> 25868</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td> {"action":"getDeviceMessages","getDeviceMessages":{"queryType":"Regular","latestMessageDate":"2014-01-18T12:51:31.836","key":"19ba7bd21bb3cfa3"},"auth":{"random":"851868430692926395b96bcc6c62b869916","timestamp":13900538825,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"c5881a2819930f43af0b88c8c0f83c05"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                             No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973422, TSecr 191670577,POST /api/ HTTP/1.1\r\n,Cookie2: $Version=1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>123</th>
      <td> 25868</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td> {"action":"getDeviceMessages","getDeviceMessages":{"queryType":"Regular","latestMessageDate":"2014-01-18T12:51:31.836","key":"19ba7bd21bb3cfa3"},"auth":{"random":"851868430692926395b96bcc6c62b869916","timestamp":13900538825,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"c5881a2819930f43af0b88c8c0f83c05"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                             No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973422, TSecr 191670577,POST /api/ HTTP/1.1\r\n,Cookie2: $Version=1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>124</th>
      <td> 25868</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td> {"action":"getDeviceMessages","getDeviceMessages":{"queryType":"Regular","latestMessageDate":"2014-01-18T12:51:31.836","key":"19ba7bd21bb3cfa3"},"auth":{"random":"851868430692926395b96bcc6c62b869916","timestamp":13900538825,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"c5881a2819930f43af0b88c8c0f83c05"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                             No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973422, TSecr 191670577,POST /api/ HTTP/1.1\r\n,Cookie2: $Version=1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>125</th>
      <td> 25868</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td> {"action":"getDeviceMessages","getDeviceMessages":{"queryType":"Regular","latestMessageDate":"2014-01-18T12:51:31.836","key":"19ba7bd21bb3cfa3"},"auth":{"random":"851868430692926395b96bcc6c62b869916","timestamp":13900538825,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"c5881a2819930f43af0b88c8c0f83c05"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                             No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973422, TSecr 191670577,POST /api/ HTTP/1.1\r\n,Cookie2: $Version=1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>126</th>
      <td> 25868</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td> {"action":"getDeviceMessages","getDeviceMessages":{"queryType":"Regular","latestMessageDate":"2014-01-18T12:51:31.836","key":"19ba7bd21bb3cfa3"},"auth":{"random":"851868430692926395b96bcc6c62b869916","timestamp":13900538825,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"c5881a2819930f43af0b88c8c0f83c05"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                             No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973422, TSecr 191670577,POST /api/ HTTP/1.1\r\n,Cookie2: $Version=1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>127</th>
      <td> 25868</td>
      <td>    saas.appoxee.com</td>
      <td>               /api/</td>
      <td> {"action":"getDeviceMessages","getDeviceMessages":{"queryType":"Regular","latestMessageDate":"2014-01-18T12:51:31.836","key":"19ba7bd21bb3cfa3"},"auth":{"random":"851868430692926395b96bcc6c62b869916","timestamp":13900538825,"AppSDKKey":"3ec0fb21-759c-4169-9fed-44efda1ea246","signature":"c5881a2819930f43af0b88c8c0f83c05"}}</td>
      <td>                                                                                                                                                                                                                                                                                                                                                             No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 32973422, TSecr 191670577,POST /api/ HTTP/1.1\r\n,Cookie2: $Version=1\r\n,\r\n,HTTP request 2/2</td>
    </tr>
    <tr>
      <th>128</th>
      <td> 39736</td>
      <td>      www.amazon.com</td>
      <td> /gp/anywhere/badges</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td>                                                                                                                                                                                                                                                                                                   POST /gp/anywhere/badges HTTP/1.1\r\n,Origin: http://www.amazon.com\r\n,X-Requested-With: XMLHttpRequest\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 4/4,badges=[["111860864X"]]</td>
    </tr>
    <tr>
      <th>129</th>
      <td> 39736</td>
      <td>      www.amazon.com</td>
      <td> /gp/anywhere/badges</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td>                                                                                                                                                                                                                                                                                                   POST /gp/anywhere/badges HTTP/1.1\r\n,Origin: http://www.amazon.com\r\n,X-Requested-With: XMLHttpRequest\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 4/4,badges=[["111860864X"]]</td>
    </tr>
    <tr>
      <th>130</th>
      <td> 39736</td>
      <td>      www.amazon.com</td>
      <td> /gp/anywhere/badges</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td>                                                                                                                                                                                                                                                                                                   POST /gp/anywhere/badges HTTP/1.1\r\n,Origin: http://www.amazon.com\r\n,X-Requested-With: XMLHttpRequest\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 4/4,badges=[["111860864X"]]</td>
    </tr>
    <tr>
      <th>131</th>
      <td> 39736</td>
      <td>      www.amazon.com</td>
      <td> /gp/anywhere/badges</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td>                                                                                                                                                                                                                                                                                                   POST /gp/anywhere/badges HTTP/1.1\r\n,Origin: http://www.amazon.com\r\n,X-Requested-With: XMLHttpRequest\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 4/4,badges=[["111860864X"]]</td>
    </tr>
    <tr>
      <th>132</th>
      <td> 40174</td>
      <td>      www.amazon.com</td>
      <td> /gp/anywhere/badges</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td>                                                                                                                                                                                                                                                                                                 POST /gp/anywhere/badges HTTP/1.1\r\n,Origin: http://www.amazon.com\r\n,X-Requested-With: XMLHttpRequest\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 12/12,badges=[["111860864X"]]</td>
    </tr>
    <tr>
      <th>133</th>
      <td> 40174</td>
      <td>      www.amazon.com</td>
      <td> /gp/anywhere/badges</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td>                                                                                                                                                                                                                                                                                                 POST /gp/anywhere/badges HTTP/1.1\r\n,Origin: http://www.amazon.com\r\n,X-Requested-With: XMLHttpRequest\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 12/12,badges=[["111860864X"]]</td>
    </tr>
    <tr>
      <th>134</th>
      <td> 40174</td>
      <td>      www.amazon.com</td>
      <td> /gp/anywhere/badges</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td>                                                                                                                                                                                                                                                                                                 POST /gp/anywhere/badges HTTP/1.1\r\n,Origin: http://www.amazon.com\r\n,X-Requested-With: XMLHttpRequest\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 12/12,badges=[["111860864X"]]</td>
    </tr>
    <tr>
      <th>135</th>
      <td> 40174</td>
      <td>      www.amazon.com</td>
      <td> /gp/anywhere/badges</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td>                                                                                                                                                                                                                                                                                                 POST /gp/anywhere/badges HTTP/1.1\r\n,Origin: http://www.amazon.com\r\n,X-Requested-With: XMLHttpRequest\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 12/12,badges=[["111860864X"]]</td>
    </tr>
    <tr>
      <th>136</th>
      <td> 39736</td>
      <td>      www.amazon.com</td>
      <td> /gp/anywhere/badges</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td>                                                                                                                                                                                                                                                                                                   POST /gp/anywhere/badges HTTP/1.1\r\n,Origin: http://www.amazon.com\r\n,X-Requested-With: XMLHttpRequest\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 4/4,badges=[["111860864X"]]</td>
    </tr>
    <tr>
      <th>137</th>
      <td> 39736</td>
      <td>      www.amazon.com</td>
      <td> /gp/anywhere/badges</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td>                                                                                                                                                                                                                                                                                                   POST /gp/anywhere/badges HTTP/1.1\r\n,Origin: http://www.amazon.com\r\n,X-Requested-With: XMLHttpRequest\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 4/4,badges=[["111860864X"]]</td>
    </tr>
    <tr>
      <th>138</th>
      <td> 39736</td>
      <td>      www.amazon.com</td>
      <td> /gp/anywhere/badges</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td>                                                                                                                                                                                                                                                                                                   POST /gp/anywhere/badges HTTP/1.1\r\n,Origin: http://www.amazon.com\r\n,X-Requested-With: XMLHttpRequest\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 4/4,badges=[["111860864X"]]</td>
    </tr>
    <tr>
      <th>139</th>
      <td> 39736</td>
      <td>      www.amazon.com</td>
      <td> /gp/anywhere/badges</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td>                                                                                                                                                                                                                                                                                                   POST /gp/anywhere/badges HTTP/1.1\r\n,Origin: http://www.amazon.com\r\n,X-Requested-With: XMLHttpRequest\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 4/4,badges=[["111860864X"]]</td>
    </tr>
    <tr>
      <th>140</th>
      <td> 40174</td>
      <td>      www.amazon.com</td>
      <td> /gp/anywhere/badges</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td>                                                                                                                                                                                                                                                                                                 POST /gp/anywhere/badges HTTP/1.1\r\n,Origin: http://www.amazon.com\r\n,X-Requested-With: XMLHttpRequest\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 12/12,badges=[["111860864X"]]</td>
    </tr>
    <tr>
      <th>141</th>
      <td> 40174</td>
      <td>      www.amazon.com</td>
      <td> /gp/anywhere/badges</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td>                                                                                                                                                                                                                                                                                                 POST /gp/anywhere/badges HTTP/1.1\r\n,Origin: http://www.amazon.com\r\n,X-Requested-With: XMLHttpRequest\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 12/12,badges=[["111860864X"]]</td>
    </tr>
    <tr>
      <th>142</th>
      <td> 40174</td>
      <td>      www.amazon.com</td>
      <td> /gp/anywhere/badges</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td>                                                                                                                                                                                                                                                                                                 POST /gp/anywhere/badges HTTP/1.1\r\n,Origin: http://www.amazon.com\r\n,X-Requested-With: XMLHttpRequest\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 12/12,badges=[["111860864X"]]</td>
    </tr>
    <tr>
      <th>143</th>
      <td> 40174</td>
      <td>      www.amazon.com</td>
      <td> /gp/anywhere/badges</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td>                                                                                                                                                                                                                                                                                                 POST /gp/anywhere/badges HTTP/1.1\r\n,Origin: http://www.amazon.com\r\n,X-Requested-With: XMLHttpRequest\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 12/12,badges=[["111860864X"]]</td>
    </tr>
    <tr>
      <th>144</th>
      <td> 39736</td>
      <td>      www.amazon.com</td>
      <td> /gp/anywhere/badges</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td>                                                                                                                                                                                                                                                                                                   POST /gp/anywhere/badges HTTP/1.1\r\n,Origin: http://www.amazon.com\r\n,X-Requested-With: XMLHttpRequest\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 4/4,badges=[["111860864X"]]</td>
    </tr>
    <tr>
      <th>145</th>
      <td> 39736</td>
      <td>      www.amazon.com</td>
      <td> /gp/anywhere/badges</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td>                                                                                                                                                                                                                                                                                                   POST /gp/anywhere/badges HTTP/1.1\r\n,Origin: http://www.amazon.com\r\n,X-Requested-With: XMLHttpRequest\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 4/4,badges=[["111860864X"]]</td>
    </tr>
    <tr>
      <th>146</th>
      <td> 39736</td>
      <td>      www.amazon.com</td>
      <td> /gp/anywhere/badges</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td>                                                                                                                                                                                                                                                                                                   POST /gp/anywhere/badges HTTP/1.1\r\n,Origin: http://www.amazon.com\r\n,X-Requested-With: XMLHttpRequest\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 4/4,badges=[["111860864X"]]</td>
    </tr>
    <tr>
      <th>147</th>
      <td> 39736</td>
      <td>      www.amazon.com</td>
      <td> /gp/anywhere/badges</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td>                                                                                                                                                                                                                                                                                                   POST /gp/anywhere/badges HTTP/1.1\r\n,Origin: http://www.amazon.com\r\n,X-Requested-With: XMLHttpRequest\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 4/4,badges=[["111860864X"]]</td>
    </tr>
    <tr>
      <th>148</th>
      <td> 40174</td>
      <td>      www.amazon.com</td>
      <td> /gp/anywhere/badges</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td>                                                                                                                                                                                                                                                                                                 POST /gp/anywhere/badges HTTP/1.1\r\n,Origin: http://www.amazon.com\r\n,X-Requested-With: XMLHttpRequest\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 12/12,badges=[["111860864X"]]</td>
    </tr>
    <tr>
      <th>149</th>
      <td> 40174</td>
      <td>      www.amazon.com</td>
      <td> /gp/anywhere/badges</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td>                                                                                                                                                                                                                                                                                                 POST /gp/anywhere/badges HTTP/1.1\r\n,Origin: http://www.amazon.com\r\n,X-Requested-With: XMLHttpRequest\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 12/12,badges=[["111860864X"]]</td>
    </tr>
    <tr>
      <th>150</th>
      <td> 40174</td>
      <td>      www.amazon.com</td>
      <td> /gp/anywhere/badges</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td>                                                                                                                                                                                                                                                                                                 POST /gp/anywhere/badges HTTP/1.1\r\n,Origin: http://www.amazon.com\r\n,X-Requested-With: XMLHttpRequest\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 12/12,badges=[["111860864X"]]</td>
    </tr>
    <tr>
      <th>151</th>
      <td> 40174</td>
      <td>      www.amazon.com</td>
      <td> /gp/anywhere/badges</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td>                                                                                                                                                                                                                                                                                                 POST /gp/anywhere/badges HTTP/1.1\r\n,Origin: http://www.amazon.com\r\n,X-Requested-With: XMLHttpRequest\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 12/12,badges=[["111860864X"]]</td>
    </tr>
    <tr>
      <th>152</th>
      <td> 39736</td>
      <td>      www.amazon.com</td>
      <td> /gp/anywhere/badges</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td>                                                                                                                                                                                                                                                                                                   POST /gp/anywhere/badges HTTP/1.1\r\n,Origin: http://www.amazon.com\r\n,X-Requested-With: XMLHttpRequest\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 4/4,badges=[["111860864X"]]</td>
    </tr>
    <tr>
      <th>153</th>
      <td> 39736</td>
      <td>      www.amazon.com</td>
      <td> /gp/anywhere/badges</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td>                                                                                                                                                                                                                                                                                                   POST /gp/anywhere/badges HTTP/1.1\r\n,Origin: http://www.amazon.com\r\n,X-Requested-With: XMLHttpRequest\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 4/4,badges=[["111860864X"]]</td>
    </tr>
    <tr>
      <th>154</th>
      <td> 39736</td>
      <td>      www.amazon.com</td>
      <td> /gp/anywhere/badges</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td>                                                                                                                                                                                                                                                                                                   POST /gp/anywhere/badges HTTP/1.1\r\n,Origin: http://www.amazon.com\r\n,X-Requested-With: XMLHttpRequest\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 4/4,badges=[["111860864X"]]</td>
    </tr>
    <tr>
      <th>155</th>
      <td> 39736</td>
      <td>      www.amazon.com</td>
      <td> /gp/anywhere/badges</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td>                                                                                                                                                                                                                                                                                                   POST /gp/anywhere/badges HTTP/1.1\r\n,Origin: http://www.amazon.com\r\n,X-Requested-With: XMLHttpRequest\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 4/4,badges=[["111860864X"]]</td>
    </tr>
    <tr>
      <th>156</th>
      <td> 40174</td>
      <td>      www.amazon.com</td>
      <td> /gp/anywhere/badges</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td>                                                                                                                                                                                                                                                                                                 POST /gp/anywhere/badges HTTP/1.1\r\n,Origin: http://www.amazon.com\r\n,X-Requested-With: XMLHttpRequest\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 12/12,badges=[["111860864X"]]</td>
    </tr>
    <tr>
      <th>157</th>
      <td> 40174</td>
      <td>      www.amazon.com</td>
      <td> /gp/anywhere/badges</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td>                                                                                                                                                                                                                                                                                                 POST /gp/anywhere/badges HTTP/1.1\r\n,Origin: http://www.amazon.com\r\n,X-Requested-With: XMLHttpRequest\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 12/12,badges=[["111860864X"]]</td>
    </tr>
    <tr>
      <th>158</th>
      <td> 40174</td>
      <td>      www.amazon.com</td>
      <td> /gp/anywhere/badges</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td>                                                                                                                                                                                                                                                                                                 POST /gp/anywhere/badges HTTP/1.1\r\n,Origin: http://www.amazon.com\r\n,X-Requested-With: XMLHttpRequest\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 12/12,badges=[["111860864X"]]</td>
    </tr>
    <tr>
      <th>159</th>
      <td> 40174</td>
      <td>      www.amazon.com</td>
      <td> /gp/anywhere/badges</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td>                                                                                                                                                                                                                                                                                                 POST /gp/anywhere/badges HTTP/1.1\r\n,Origin: http://www.amazon.com\r\n,X-Requested-With: XMLHttpRequest\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 12/12,badges=[["111860864X"]]</td>
    </tr>
    <tr>
      <th>160</th>
      <td> 89723</td>
      <td> t.skimresources.com</td>
      <td>           /api/link</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td> No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 44629076, TSecr 1273499825,POST /api/link HTTP/1.1\r\n,Origin: http://www.androidpit.de\r\n,X-Requested-With: com.android.browser\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 1/1,[truncated] data=%7B%22pub%22%3A%2236706X955308%22%2C%22pag%22%3A%22http%3A%2F%2Fwww.androidpit.de%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3%22%2C%22dl%22%3A%5B%22androidpit.com%22%2C%22androidpit.es%22%2C%22a...</td>
    </tr>
    <tr>
      <th>161</th>
      <td> 89723</td>
      <td> t.skimresources.com</td>
      <td>           /api/link</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td> No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 44629076, TSecr 1273499825,POST /api/link HTTP/1.1\r\n,Origin: http://www.androidpit.de\r\n,X-Requested-With: com.android.browser\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 1/1,[truncated] data=%7B%22pub%22%3A%2236706X955308%22%2C%22pag%22%3A%22http%3A%2F%2Fwww.androidpit.de%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3%22%2C%22dl%22%3A%5B%22androidpit.com%22%2C%22androidpit.es%22%2C%22a...</td>
    </tr>
    <tr>
      <th>162</th>
      <td> 89723</td>
      <td> t.skimresources.com</td>
      <td>           /api/link</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td> No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 44629076, TSecr 1273499825,POST /api/link HTTP/1.1\r\n,Origin: http://www.androidpit.de\r\n,X-Requested-With: com.android.browser\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 1/1,[truncated] data=%7B%22pub%22%3A%2236706X955308%22%2C%22pag%22%3A%22http%3A%2F%2Fwww.androidpit.de%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3%22%2C%22dl%22%3A%5B%22androidpit.com%22%2C%22androidpit.es%22%2C%22a...</td>
    </tr>
    <tr>
      <th>163</th>
      <td> 89723</td>
      <td> t.skimresources.com</td>
      <td>           /api/link</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td> No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 44629076, TSecr 1273499825,POST /api/link HTTP/1.1\r\n,Origin: http://www.androidpit.de\r\n,X-Requested-With: com.android.browser\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 1/1,[truncated] data=%7B%22pub%22%3A%2236706X955308%22%2C%22pag%22%3A%22http%3A%2F%2Fwww.androidpit.de%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3%22%2C%22dl%22%3A%5B%22androidpit.com%22%2C%22androidpit.es%22%2C%22a...</td>
    </tr>
    <tr>
      <th>164</th>
      <td> 89860</td>
      <td> t.skimresources.com</td>
      <td>      /api/track.php</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td> No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 44629497, TSecr 1273499850,POST /api/track.php HTTP/1.1\r\n,Origin: http://www.androidpit.de\r\n,X-Requested-With: com.android.browser\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 2/2,[truncated] data=%7B%22pag%22%3A%22http%3A%2F%2Fwww.androidpit.de%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3%22%2C%22phr%22%3A%7B%7D%2C%22pub%22%3A%2236706X955308%22%2C%22slc%22%3A0%2C%22swc%22%3A0%2C%22js...</td>
    </tr>
    <tr>
      <th>165</th>
      <td> 89860</td>
      <td> t.skimresources.com</td>
      <td>      /api/track.php</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td> No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 44629497, TSecr 1273499850,POST /api/track.php HTTP/1.1\r\n,Origin: http://www.androidpit.de\r\n,X-Requested-With: com.android.browser\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 2/2,[truncated] data=%7B%22pag%22%3A%22http%3A%2F%2Fwww.androidpit.de%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3%22%2C%22phr%22%3A%7B%7D%2C%22pub%22%3A%2236706X955308%22%2C%22slc%22%3A0%2C%22swc%22%3A0%2C%22js...</td>
    </tr>
    <tr>
      <th>166</th>
      <td> 89860</td>
      <td> t.skimresources.com</td>
      <td>      /api/track.php</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td> No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 44629497, TSecr 1273499850,POST /api/track.php HTTP/1.1\r\n,Origin: http://www.androidpit.de\r\n,X-Requested-With: com.android.browser\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 2/2,[truncated] data=%7B%22pag%22%3A%22http%3A%2F%2Fwww.androidpit.de%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3%22%2C%22phr%22%3A%7B%7D%2C%22pub%22%3A%2236706X955308%22%2C%22slc%22%3A0%2C%22swc%22%3A0%2C%22js...</td>
    </tr>
    <tr>
      <th>167</th>
      <td> 89860</td>
      <td> t.skimresources.com</td>
      <td>      /api/track.php</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td> No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 44629497, TSecr 1273499850,POST /api/track.php HTTP/1.1\r\n,Origin: http://www.androidpit.de\r\n,X-Requested-With: com.android.browser\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 2/2,[truncated] data=%7B%22pag%22%3A%22http%3A%2F%2Fwww.androidpit.de%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3%22%2C%22phr%22%3A%7B%7D%2C%22pub%22%3A%2236706X955308%22%2C%22slc%22%3A0%2C%22swc%22%3A0%2C%22js...</td>
    </tr>
    <tr>
      <th>168</th>
      <td> 89723</td>
      <td> t.skimresources.com</td>
      <td>           /api/link</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td> No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 44629076, TSecr 1273499825,POST /api/link HTTP/1.1\r\n,Origin: http://www.androidpit.de\r\n,X-Requested-With: com.android.browser\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 1/1,[truncated] data=%7B%22pub%22%3A%2236706X955308%22%2C%22pag%22%3A%22http%3A%2F%2Fwww.androidpit.de%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3%22%2C%22dl%22%3A%5B%22androidpit.com%22%2C%22androidpit.es%22%2C%22a...</td>
    </tr>
    <tr>
      <th>169</th>
      <td> 89723</td>
      <td> t.skimresources.com</td>
      <td>           /api/link</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td> No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 44629076, TSecr 1273499825,POST /api/link HTTP/1.1\r\n,Origin: http://www.androidpit.de\r\n,X-Requested-With: com.android.browser\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 1/1,[truncated] data=%7B%22pub%22%3A%2236706X955308%22%2C%22pag%22%3A%22http%3A%2F%2Fwww.androidpit.de%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3%22%2C%22dl%22%3A%5B%22androidpit.com%22%2C%22androidpit.es%22%2C%22a...</td>
    </tr>
    <tr>
      <th>170</th>
      <td> 89723</td>
      <td> t.skimresources.com</td>
      <td>           /api/link</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td> No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 44629076, TSecr 1273499825,POST /api/link HTTP/1.1\r\n,Origin: http://www.androidpit.de\r\n,X-Requested-With: com.android.browser\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 1/1,[truncated] data=%7B%22pub%22%3A%2236706X955308%22%2C%22pag%22%3A%22http%3A%2F%2Fwww.androidpit.de%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3%22%2C%22dl%22%3A%5B%22androidpit.com%22%2C%22androidpit.es%22%2C%22a...</td>
    </tr>
    <tr>
      <th>171</th>
      <td> 89723</td>
      <td> t.skimresources.com</td>
      <td>           /api/link</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td> No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 44629076, TSecr 1273499825,POST /api/link HTTP/1.1\r\n,Origin: http://www.androidpit.de\r\n,X-Requested-With: com.android.browser\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 1/1,[truncated] data=%7B%22pub%22%3A%2236706X955308%22%2C%22pag%22%3A%22http%3A%2F%2Fwww.androidpit.de%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3%22%2C%22dl%22%3A%5B%22androidpit.com%22%2C%22androidpit.es%22%2C%22a...</td>
    </tr>
    <tr>
      <th>172</th>
      <td> 89860</td>
      <td> t.skimresources.com</td>
      <td>      /api/track.php</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td> No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 44629497, TSecr 1273499850,POST /api/track.php HTTP/1.1\r\n,Origin: http://www.androidpit.de\r\n,X-Requested-With: com.android.browser\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 2/2,[truncated] data=%7B%22pag%22%3A%22http%3A%2F%2Fwww.androidpit.de%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3%22%2C%22phr%22%3A%7B%7D%2C%22pub%22%3A%2236706X955308%22%2C%22slc%22%3A0%2C%22swc%22%3A0%2C%22js...</td>
    </tr>
    <tr>
      <th>173</th>
      <td> 89860</td>
      <td> t.skimresources.com</td>
      <td>      /api/track.php</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td> No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 44629497, TSecr 1273499850,POST /api/track.php HTTP/1.1\r\n,Origin: http://www.androidpit.de\r\n,X-Requested-With: com.android.browser\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 2/2,[truncated] data=%7B%22pag%22%3A%22http%3A%2F%2Fwww.androidpit.de%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3%22%2C%22phr%22%3A%7B%7D%2C%22pub%22%3A%2236706X955308%22%2C%22slc%22%3A0%2C%22swc%22%3A0%2C%22js...</td>
    </tr>
    <tr>
      <th>174</th>
      <td> 89860</td>
      <td> t.skimresources.com</td>
      <td>      /api/track.php</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td> No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 44629497, TSecr 1273499850,POST /api/track.php HTTP/1.1\r\n,Origin: http://www.androidpit.de\r\n,X-Requested-With: com.android.browser\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 2/2,[truncated] data=%7B%22pag%22%3A%22http%3A%2F%2Fwww.androidpit.de%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3%22%2C%22phr%22%3A%7B%7D%2C%22pub%22%3A%2236706X955308%22%2C%22slc%22%3A0%2C%22swc%22%3A0%2C%22js...</td>
    </tr>
    <tr>
      <th>175</th>
      <td> 89860</td>
      <td> t.skimresources.com</td>
      <td>      /api/track.php</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td> No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 44629497, TSecr 1273499850,POST /api/track.php HTTP/1.1\r\n,Origin: http://www.androidpit.de\r\n,X-Requested-With: com.android.browser\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 2/2,[truncated] data=%7B%22pag%22%3A%22http%3A%2F%2Fwww.androidpit.de%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3%22%2C%22phr%22%3A%7B%7D%2C%22pub%22%3A%2236706X955308%22%2C%22slc%22%3A0%2C%22swc%22%3A0%2C%22js...</td>
    </tr>
    <tr>
      <th>176</th>
      <td> 89723</td>
      <td> t.skimresources.com</td>
      <td>           /api/link</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td> No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 44629076, TSecr 1273499825,POST /api/link HTTP/1.1\r\n,Origin: http://www.androidpit.de\r\n,X-Requested-With: com.android.browser\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 1/1,[truncated] data=%7B%22pub%22%3A%2236706X955308%22%2C%22pag%22%3A%22http%3A%2F%2Fwww.androidpit.de%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3%22%2C%22dl%22%3A%5B%22androidpit.com%22%2C%22androidpit.es%22%2C%22a...</td>
    </tr>
    <tr>
      <th>177</th>
      <td> 89723</td>
      <td> t.skimresources.com</td>
      <td>           /api/link</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td> No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 44629076, TSecr 1273499825,POST /api/link HTTP/1.1\r\n,Origin: http://www.androidpit.de\r\n,X-Requested-With: com.android.browser\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 1/1,[truncated] data=%7B%22pub%22%3A%2236706X955308%22%2C%22pag%22%3A%22http%3A%2F%2Fwww.androidpit.de%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3%22%2C%22dl%22%3A%5B%22androidpit.com%22%2C%22androidpit.es%22%2C%22a...</td>
    </tr>
    <tr>
      <th>178</th>
      <td> 89723</td>
      <td> t.skimresources.com</td>
      <td>           /api/link</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td> No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 44629076, TSecr 1273499825,POST /api/link HTTP/1.1\r\n,Origin: http://www.androidpit.de\r\n,X-Requested-With: com.android.browser\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 1/1,[truncated] data=%7B%22pub%22%3A%2236706X955308%22%2C%22pag%22%3A%22http%3A%2F%2Fwww.androidpit.de%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3%22%2C%22dl%22%3A%5B%22androidpit.com%22%2C%22androidpit.es%22%2C%22a...</td>
    </tr>
    <tr>
      <th>179</th>
      <td> 89723</td>
      <td> t.skimresources.com</td>
      <td>           /api/link</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td> No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 44629076, TSecr 1273499825,POST /api/link HTTP/1.1\r\n,Origin: http://www.androidpit.de\r\n,X-Requested-With: com.android.browser\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 1/1,[truncated] data=%7B%22pub%22%3A%2236706X955308%22%2C%22pag%22%3A%22http%3A%2F%2Fwww.androidpit.de%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3%22%2C%22dl%22%3A%5B%22androidpit.com%22%2C%22androidpit.es%22%2C%22a...</td>
    </tr>
    <tr>
      <th>180</th>
      <td> 89860</td>
      <td> t.skimresources.com</td>
      <td>      /api/track.php</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td> No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 44629497, TSecr 1273499850,POST /api/track.php HTTP/1.1\r\n,Origin: http://www.androidpit.de\r\n,X-Requested-With: com.android.browser\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 2/2,[truncated] data=%7B%22pag%22%3A%22http%3A%2F%2Fwww.androidpit.de%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3%22%2C%22phr%22%3A%7B%7D%2C%22pub%22%3A%2236706X955308%22%2C%22slc%22%3A0%2C%22swc%22%3A0%2C%22js...</td>
    </tr>
    <tr>
      <th>181</th>
      <td> 89860</td>
      <td> t.skimresources.com</td>
      <td>      /api/track.php</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td> No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 44629497, TSecr 1273499850,POST /api/track.php HTTP/1.1\r\n,Origin: http://www.androidpit.de\r\n,X-Requested-With: com.android.browser\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 2/2,[truncated] data=%7B%22pag%22%3A%22http%3A%2F%2Fwww.androidpit.de%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3%22%2C%22phr%22%3A%7B%7D%2C%22pub%22%3A%2236706X955308%22%2C%22slc%22%3A0%2C%22swc%22%3A0%2C%22js...</td>
    </tr>
    <tr>
      <th>182</th>
      <td> 89860</td>
      <td> t.skimresources.com</td>
      <td>      /api/track.php</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td> No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 44629497, TSecr 1273499850,POST /api/track.php HTTP/1.1\r\n,Origin: http://www.androidpit.de\r\n,X-Requested-With: com.android.browser\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 2/2,[truncated] data=%7B%22pag%22%3A%22http%3A%2F%2Fwww.androidpit.de%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3%22%2C%22phr%22%3A%7B%7D%2C%22pub%22%3A%2236706X955308%22%2C%22slc%22%3A0%2C%22swc%22%3A0%2C%22js...</td>
    </tr>
    <tr>
      <th>183</th>
      <td> 89860</td>
      <td> t.skimresources.com</td>
      <td>      /api/track.php</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td> No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 44629497, TSecr 1273499850,POST /api/track.php HTTP/1.1\r\n,Origin: http://www.androidpit.de\r\n,X-Requested-With: com.android.browser\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 2/2,[truncated] data=%7B%22pag%22%3A%22http%3A%2F%2Fwww.androidpit.de%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3%22%2C%22phr%22%3A%7B%7D%2C%22pub%22%3A%2236706X955308%22%2C%22slc%22%3A0%2C%22swc%22%3A0%2C%22js...</td>
    </tr>
    <tr>
      <th>184</th>
      <td> 89723</td>
      <td> t.skimresources.com</td>
      <td>           /api/link</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td> No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 44629076, TSecr 1273499825,POST /api/link HTTP/1.1\r\n,Origin: http://www.androidpit.de\r\n,X-Requested-With: com.android.browser\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 1/1,[truncated] data=%7B%22pub%22%3A%2236706X955308%22%2C%22pag%22%3A%22http%3A%2F%2Fwww.androidpit.de%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3%22%2C%22dl%22%3A%5B%22androidpit.com%22%2C%22androidpit.es%22%2C%22a...</td>
    </tr>
    <tr>
      <th>185</th>
      <td> 89723</td>
      <td> t.skimresources.com</td>
      <td>           /api/link</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td> No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 44629076, TSecr 1273499825,POST /api/link HTTP/1.1\r\n,Origin: http://www.androidpit.de\r\n,X-Requested-With: com.android.browser\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 1/1,[truncated] data=%7B%22pub%22%3A%2236706X955308%22%2C%22pag%22%3A%22http%3A%2F%2Fwww.androidpit.de%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3%22%2C%22dl%22%3A%5B%22androidpit.com%22%2C%22androidpit.es%22%2C%22a...</td>
    </tr>
    <tr>
      <th>186</th>
      <td> 89723</td>
      <td> t.skimresources.com</td>
      <td>           /api/link</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td> No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 44629076, TSecr 1273499825,POST /api/link HTTP/1.1\r\n,Origin: http://www.androidpit.de\r\n,X-Requested-With: com.android.browser\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 1/1,[truncated] data=%7B%22pub%22%3A%2236706X955308%22%2C%22pag%22%3A%22http%3A%2F%2Fwww.androidpit.de%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3%22%2C%22dl%22%3A%5B%22androidpit.com%22%2C%22androidpit.es%22%2C%22a...</td>
    </tr>
    <tr>
      <th>187</th>
      <td> 89723</td>
      <td> t.skimresources.com</td>
      <td>           /api/link</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td> No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 44629076, TSecr 1273499825,POST /api/link HTTP/1.1\r\n,Origin: http://www.androidpit.de\r\n,X-Requested-With: com.android.browser\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 1/1,[truncated] data=%7B%22pub%22%3A%2236706X955308%22%2C%22pag%22%3A%22http%3A%2F%2Fwww.androidpit.de%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3%22%2C%22dl%22%3A%5B%22androidpit.com%22%2C%22androidpit.es%22%2C%22a...</td>
    </tr>
    <tr>
      <th>188</th>
      <td> 89860</td>
      <td> t.skimresources.com</td>
      <td>      /api/track.php</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td> No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 44629497, TSecr 1273499850,POST /api/track.php HTTP/1.1\r\n,Origin: http://www.androidpit.de\r\n,X-Requested-With: com.android.browser\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 2/2,[truncated] data=%7B%22pag%22%3A%22http%3A%2F%2Fwww.androidpit.de%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3%22%2C%22phr%22%3A%7B%7D%2C%22pub%22%3A%2236706X955308%22%2C%22slc%22%3A0%2C%22swc%22%3A0%2C%22js...</td>
    </tr>
    <tr>
      <th>189</th>
      <td> 89860</td>
      <td> t.skimresources.com</td>
      <td>      /api/track.php</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td> No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 44629497, TSecr 1273499850,POST /api/track.php HTTP/1.1\r\n,Origin: http://www.androidpit.de\r\n,X-Requested-With: com.android.browser\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 2/2,[truncated] data=%7B%22pag%22%3A%22http%3A%2F%2Fwww.androidpit.de%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3%22%2C%22phr%22%3A%7B%7D%2C%22pub%22%3A%2236706X955308%22%2C%22slc%22%3A0%2C%22swc%22%3A0%2C%22js...</td>
    </tr>
    <tr>
      <th>190</th>
      <td> 89860</td>
      <td> t.skimresources.com</td>
      <td>      /api/track.php</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td> No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 44629497, TSecr 1273499850,POST /api/track.php HTTP/1.1\r\n,Origin: http://www.androidpit.de\r\n,X-Requested-With: com.android.browser\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 2/2,[truncated] data=%7B%22pag%22%3A%22http%3A%2F%2Fwww.androidpit.de%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3%22%2C%22phr%22%3A%7B%7D%2C%22pub%22%3A%2236706X955308%22%2C%22slc%22%3A0%2C%22swc%22%3A0%2C%22js...</td>
    </tr>
    <tr>
      <th>191</th>
      <td> 89860</td>
      <td> t.skimresources.com</td>
      <td>      /api/track.php</td>
      <td>                                                                                                                                                                                                                                                                                                                                None</td>
      <td> No-Operation (NOP),No-Operation (NOP),Timestamps: TSval 44629497, TSecr 1273499850,POST /api/track.php HTTP/1.1\r\n,Origin: http://www.androidpit.de\r\n,X-Requested-With: com.android.browser\r\n,Accept-Charset: utf-8, iso-8859-1, utf-16, *;q=0.7\r\n,\r\n,HTTP request 2/2,[truncated] data=%7B%22pag%22%3A%22http%3A%2F%2Fwww.androidpit.de%2Fde%2Fandroid%2Fforum%2Fthread%2F573726%2Fslimbean-Build-4-3%22%2C%22phr%22%3A%7B%7D%2C%22pub%22%3A%2236706X955308%22%2C%22slc%22%3A0%2C%22swc%22%3A0%2C%22js...</td>
    </tr>
  </tbody>
</table>
</div>




```

```
