+++
title = "Convert IP ranges to list"
author = "Victor"
date = "2013-12-04"
tags = ["coding", "networking"]
category = "notes"
+++

If you got IP ranges in this layout: x.x.x.1-255, y.y.y.42-120 etc., you could easily use this code to generate full IP adresses without any ranges:

~~~.python
ips = """
x.x.x.1-23
y.y.y.56-12
"""

buf = StringIO.StringIO(ips)

while True:
    line = buf.readline()
    if line == '':
        break
    else:
        import re
        m = re.search('(.*)\.(.*)\.(.*)\.(.*)', line)
        if m:
            ip_range = m.group(4).split('-')

            if len(ip_range) == 2:
                ip_addr = range(int(ip_range[0]), int(ip_range[1])+1)
                for i in ip_addr:
                    print "%s.%s.%s.%s" % (m.group(1), m.group(2), m.group(3), i)
            else:
                print "%s.%s.%s.%s" % (m.group(1), m.group(2), m.group(3), m.group(4))

~~~
