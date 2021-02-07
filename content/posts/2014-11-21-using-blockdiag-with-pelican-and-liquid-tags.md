+++
title = "Using Blockdiag with Pelican and liquid tags"
author = "Victor"
date = "2014-11-21"
tags = ["blockdiag", "viz", "pelican", "python"]
category = "blog"
+++

After writing the [previous article](/2014/11/13/using-graphviz-with-pelican-and-liquid-tags/) I thought I should share some `Blockdiag` plugin for Pelican. You can also check out the [**pull request**](https://github.com/getpelican/pelican-plugins/pull/356). 

## blockdiag
 
It's basically a `graphviz` like utility with its own language (similar to DOT). You can create:
 
* [block diagrams](http://blockdiag.com/en/blockdiag/)
* [sequence diagrams](http://blockdiag.com/en/seqdiag/)
* [activity diagrams](http://blockdiag.com/en/actdiag/)
* [network diagrams](http://blockdiag.com/en/nwdiag/)
* [rack diagrams](http://blockdiag.com/en/nwdiag/rackdiag-examples.html)
* [packet diagrams](http://blockdiag.com/en/nwdiag/packetdiag-examples.html)
 
It can save you a lot of time and has a pretty simple syntax. You can always test your code **online** using blockdiag's interactive [shell](http://interactive.blockdiag.com/).
 
#### Extensions
 
There are also several contributions made to `blockdiag`. Among these:
 
* [blockdiagcontrib-math](https://pypi.python.org/pypi/blockdiagcontrib-math)
* [blockdiagcontrib-tex](https://pypi.python.org/pypi/blockdiagcontrib-tex/)
* [blockdiagcontrib-octicons](http://pythonhosted.org//blockdiagcontrib-octicons/)
* [blockdiagcontrib-cisco](https://pythonhosted.org/blockdiagcontrib-cisco/)
* [blockdiagcontrib-class](https://pypi.python.org/pypi/blockdiagcontrib-class)
 
## pelican plugin
 
In general the syntax is pretty simple:
 
```
{% blockdiag
    <diagram type> {
        <code>
    }
%}
```
 
As already mentioned the `diagram type` could be one of the following:
 
* blockdiag
* seqdiag
* actdiag
* nwdiag
* rackdiag
* packetdiag
 
Just a few examples:
 
```
{% blockdiag
    blockdiag {
        A -> B -> C;
        B -> D;
    }
%}
```

will render to 

{% blockdiag
    blockdiag {
        A -> B -> C;
        B -> D;
    }
%}

 
 
```
{% blockdiag
    nwdiag {
      network dmz {
        web01;
        web02;
        stg01;
      }
 
      network internal {
        web01;
        web02;
        db01;
        db02;
      }
    }
%}
```

will render to

{% blockdiag
    nwdiag {
      network dmz {
        web01;
        web02;
        stg01;
      }
 
      network internal {
        web01;
        web02;
        db01;
        db02;
      }
    }
%}


## Fonts
Regarding the **font**: You can add following to your `~/.blockdiagrc`:

~~~
[blockdiag]
fontpath = /usr/share/fonts/TTF/DejaVuSerif.ttf 
~~~


## Playground

Let's look at some other examples:


### blockdiag

~~~
{% blockdiag
	blockdiag admin {
	  index [label = "List of FOOs"];
	  add [label = "Add FOO"];
	  add_confirm [label = "Add FOO (confirm)"];
	  edit [label = "Edit FOO"];
	  edit_confirm [label = "Edit FOO (confirm)"];
	  show [label = "Show FOO"];
	  delete_confirm [label = "Delete FOO (confirm)"];

	  index -> add  -> add_confirm  -> index;
	  index -> edit -> edit_confirm -> index;
	  index -> show -> index;
	  index -> delete_confirm -> index;
	}
%}
~~~

{% blockdiag
	blockdiag admin {
	  index [label = "List of FOOs"];
	  add [label = "Add FOO"];
	  add_confirm [label = "Add FOO (confirm)"];
	  edit [label = "Edit FOO"];
	  edit_confirm [label = "Edit FOO (confirm)"];
	  show [label = "Show FOO"];
	  delete_confirm [label = "Delete FOO (confirm)"];

	  index -> add  -> add_confirm  -> index;
	  index -> edit -> edit_confirm -> index;
	  index -> show -> index;
	  index -> delete_confirm -> index;
	}
%}


~~~
{% blockdiag
	blockdiag {
	   // Set labels to nodes.
	   A [label = "foo"];
	   B [label = "bar"];
	   // And set text-color
	   C [label = "baz", numbered = 99];

	   // Set labels to edges. (short text only)
	   A -> B [label = "click bar", textcolor="red"];
	   B -> C [label = "click baz"];
	   C -> A;
	}
%}
~~~

{% blockdiag
	blockdiag {
	   // Set labels to nodes.
	   A [label = "foo"];
	   B [label = "bar"];
	   // And set text-color
	   C [label = "baz", numbered = 99];

	   // Set labels to edges. (short text only)
	   A -> B [label = "click bar", textcolor="red"];
	   B -> C [label = "click baz"];
	   C -> A;
	}
%}

~~~
{% blockdiag
	blockdiag {
	  A -> B -> C -> D -> E;

	  // fold edge at C to D (D will be layouted at top level; left side)
	  C -> D [folded];
	}
%}
~~~

{% blockdiag
	blockdiag {
	  A -> B -> C -> D -> E;

	  // fold edge at C to D (D will be layouted at top level; left side)
	  C -> D [folded];
	}
%}

~~~
{% blockdiag
	blockdiag {
	  // node shapes for flowcharts
	  condition [shape = flowchart.condition];
	  database [shape = flowchart.database];
	  terminator [shape = flowchart.terminator];
	  input [shape = flowchart.input];

	  condition -> database -> terminator -> input;
	}
%}
~~~

{% blockdiag
	blockdiag {
	  // node shapes for flowcharts
	  condition [shape = flowchart.condition];
	  database [shape = flowchart.database];
	  terminator [shape = flowchart.terminator];
	  input [shape = flowchart.input];

	  condition -> database -> terminator -> input;
	}
%}



#### blockdiagcontrib-cisco

~~~
{% blockdiag 
	diagram admin {
	  A [shape = "cisco.router"];
	  B [shape = "cisco.ups"];

	  A -> B;
	}
%}
~~~

> If you get an exception like `AttributeError: close` have a look at this [issue](https://bitbucket.org/blockdiag/blockdiag/issue/63/attributeerror-close)

{% blockdiag 
	diagram admin {
	  A [shape = "cisco.router"];
	  B [shape = "cisco.ups"];

	  A -> B;
	}
%}




#### blockdiagcontrib-octicons

~~~
{% blockdiag
	blockdiag {
	  plugin octicons;

	  A [label = "", background = "octicon://mark-github"];
	  B [icon = "octicon://cloud-download?color=red"];
	  C [icon = "octicon://settings?color=green"]
	  A -> B;
	  B -> C;
	}
%}
~~~

> If you have problems generating the **octicons** have a look at this [issue](https://bitbucket.org/blockdiag/blockdiag-contrib/issue/2/blockdiagcontrib-octicons-cannot-open)

{% blockdiag
	blockdiag {
	  plugin octicons;

	  A [label = "", background = "octicon://mark-github"];
	  B [icon = "octicon://cloud-download?color=red"];
	  C [icon = "octicon://settings?color=green"]
	  A -> B;
	  B -> C;
	}
%}



### seqdiag

~~~
{% blockdiag
	seqdiag {
	  browser  -> webserver [label = "GET /index.html"];
	  browser <-- webserver;
	  browser  -> webserver [label = "POST /blog/comment"];
	              webserver  -> database [label = "INSERT comment"];
	              webserver <-- database;
	  browser <-- webserver;
	}
%}
~~~

{% blockdiag
	seqdiag {
	  browser  -> webserver [label = "GET /index.html"];
	  browser <-- webserver;
	  browser  -> webserver [label = "POST /blog/comment"];
	              webserver  -> database [label = "INSERT comment"];
	              webserver <-- database;
	  browser <-- webserver;
	}
%}

### actdiag

~~~
{% blockdiag
	actdiag {
	  A -> B -> C -> D -> E;

	  lane {
	    A; C; E;
	  }
	  lane {
	    B; D;
	  }
	}
%}
~~~

{% blockdiag
	actdiag {
	  A -> B -> C -> D -> E;

	  lane {
	    A; C; E;
	  }
	  lane {
	    B; D;
	  }
	}
%}

### nwdiag

~~~
{% blockdiag
	nwdiag {
	  network dmz {
	      address = "210.x.x.x/24"

	      web01 [address = "210.x.x.1"];
	      web02 [address = "210.x.x.2"];
	  }
	  network internal {
	      address = "172.x.x.x/24";

	      web01 [address = "172.x.x.1"];
	      web02 [address = "172.x.x.2"];
	      db01;
	      db02;
	  }
	}
%}
~~~

{% blockdiag
	nwdiag {
	  network dmz {
	      address = "210.x.x.x/24"

	      web01 [address = "210.x.x.1"];
	      web02 [address = "210.x.x.2"];
	  }
	  network internal {
	      address = "172.x.x.x/24";

	      web01 [address = "172.x.x.1"];
	      web02 [address = "172.x.x.2"];
	      db01;
	      db02;
	  }
	}
%}


#### nwdiag more advanced

~~~
{% blockdiag
	nwdiag {
	class obj_old		[color = lighgray,style = dotted];
	class obj_new		[color = lightblue,style = dotted];
	class obj_null		[style = dotted,stacked];
	class obj_router	[shape = cisco.router];
	class obj_l2sw		[shape = cisco.layer_2_remote_switch];
 	class obj_fw		[shape = cisco.firewall];
	class obj_wlan		[shape = cisco.wireless_router];
	class obj_pc		[shape = cisco.pc];
	class obj_mobile	[shape = cisco.pda];

	network untrust {
		address = "X.X.X.0/28"

		main-router	[address = ".n",class = obj_router];
	}

	network dmz {
		address = "192.168.X.0/24"

		main-router	[address = ".n\ndmz/24 only",class = obj_router];
		debian-fw1	[address = ".n+16",class = obj_fw];
		debian-fw2	[address = ".m+17",class = obj_fw];
	}
	network trust {
		address = "172.X.X.0/24"

		VLAN-Switch	[address = ".n",class = obj_l2sw];
		debian-fw1	[address = ".n+16\n<->VLAN-Switch only",class = obj_fw];
		debian-fw2	[address = ".n+17\n<->VLAN-Switch only",class = obj_fw];
		nat-router	[address = ".n+64\n<->VLAN-Switch only",class = obj_router];
	}
	network wlan-seg {
		address = "10.X.X.0/24"

		nat-router	[address = ".n+64\n<->wlan-router's IP only",class = obj_router];
		wlan-router	[address = ".n\n<->sheeva-debian only\n<->note-debian only",class = obj_wlan];
		sheeva-debian	[address = ".n+16",class = obj_pc];
		note-debian	[address = ".n+17",class = obj_pc];
		iPod		[address = ".n+128",class = obj_mobile];
		Android		[address = ".n+129",class = obj_mobile];
	}
}
%}
~~~

{% blockdiag
	nwdiag {
	class obj_old		[color = lighgray,style = dotted];
	class obj_new		[color = lightblue,style = dotted];
	class obj_null		[style = dotted,stacked];
	class obj_router	[shape = cisco.router];
	class obj_l2sw		[shape = cisco.layer_2_remote_switch];
 	class obj_fw		[shape = cisco.firewall];
	class obj_wlan		[shape = cisco.wireless_router];
	class obj_pc		[shape = cisco.pc];
	class obj_mobile	[shape = cisco.pda];

	network untrust {
		address = "X.X.X.0/28"

		main-router	[address = ".n",class = obj_router];
	}

	network dmz {
		address = "192.168.X.0/24"

		main-router	[address = ".n\ndmz/24 only",class = obj_router];
		debian-fw1	[address = ".n+16",class = obj_fw];
		debian-fw2	[address = ".m+17",class = obj_fw];
	}
	network trust {
		address = "172.X.X.0/24"

		VLAN-Switch	[address = ".n",class = obj_l2sw];
		debian-fw1	[address = ".n+16\n<->VLAN-Switch only",class = obj_fw];
		debian-fw2	[address = ".n+17\n<->VLAN-Switch only",class = obj_fw];
		nat-router	[address = ".n+64\n<->VLAN-Switch only",class = obj_router];
	}
	network wlan-seg {
		address = "10.X.X.0/24"

		nat-router	[address = ".n+64\n<->wlan-router's IP only",class = obj_router];
		wlan-router	[address = ".n\n<->sheeva-debian only\n<->note-debian only",class = obj_wlan];
		sheeva-debian	[address = ".n+16",class = obj_pc];
		note-debian	[address = ".n+17",class = obj_pc];
		iPod		[address = ".n+128",class = obj_mobile];
		Android		[address = ".n+129",class = obj_mobile];
	}
}
%}

### packetdiag

~~~
{% blockdiag 
	packetdiag {
	   0-7: Source Port
	   8-15: Destination Port
	   16-31: Sequence Number
	   32-47: Acknowledgment Number
	}
    
%}
~~~

{% blockdiag 
	packetdiag {
	   0-7: Source Port
	   8-15: Destination Port
	   16-31: Sequence Number
	   32-47: Acknowledgment Number
	}
    
%}

### rackdiag

~~~
{% blockdiag
	rackdiag {
	  24U;

	  1: UPS [3U, 0.5A, 10kg];
	  5: Disk Array [2U, 0.5A];
	  7: DB Master
	  8: DB Mirror (1)
	  9: DB Mirror (2)
	  11: Web Server (1)
	  11: Web Server (2)
	  12: Web Server (3)
	  12: Web Server (4)
	  14: LoadBalancer
	}
%}
~~~

{% blockdiag
	rackdiag {
	  24U;

	  1: UPS [3U, 0.5A, 10kg];
	  5: Disk Array [2U, 0.5A];
	  7: DB Master
	  8: DB Mirror (1)
	  9: DB Mirror (2)
	  11: Web Server (1)
	  11: Web Server (2)
	  12: Web Server (3)
	  12: Web Server (4)
	  14: LoadBalancer
	}
%}
