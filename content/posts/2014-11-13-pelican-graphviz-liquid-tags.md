+++
title = "Using Graphviz with Pelican and liquid tags"
author = "Victor Dorneanu"
date = "2014-11-13"
tags = ["pelican", "graphviz", "viz", "python"]
category = "blog"
+++


I really like keeping things simple. And I also like generating figures from code using `Graphviz`. And since there was no Graphviz **plugin** for **pelican** I wrote my own one. 

Using [liquid tags](https://github.com/getpelican/pelican-plugins/tree/master/liquid_tags) I wanted to get my graphviz code rendered and automatically included as a **base64 encoded** image in my HTML code. I've created a [pull request](https://github.com/getpelican/pelican-plugins/pull/356) but you can find a fork at [dorneanu-pelican](https://github.com/dorneanu/pelican-plugins).

Basically the tags works as follows:

```
{% graphviz 
	<program> {
		<DOT CODE>
	}
%}
```

`program` could be `dot`, `neato`, `twopi`, `circo` etc. The `DOT CODE` is simply sent to the binary utility and the output (PNG data) is saved into the document.

This is some minimal example:

```
{% graphviz 
	dot { 
			digraph graphname { 
				a -> b -> c; 
				b -> d; 
				e -> f;	
			} 
		}
%}
```

which will be rendered to:

{% graphviz 
	dot { 
			digraph graphname { 
				a -> b -> c; 
				b -> d; 
				e -> f;	
			} 
		}
%}

You could then use `neato` instead of `dot`:

```
{% graphviz 
	neato { 
			digraph graphname { 
				a -> b -> c; 
				b -> d; 
				e -> f;	
			} 
		}
%}
```

...which will be rendered to:

{% graphviz 
	neato { 
			digraph graphname { 
				a -> b -> c; 
				b -> d; 
				e -> f;	
			} 
		}
%}


Some other examples:

* dot
	- digraph

{% graphviz 
	dot {
		digraph g {
			node [fontname=Verdana,fontsize=12]
			node [style=filled]
		 	node [fillcolor="#EEEEEE"]
		 	node [color="#EEEEEE"]
		 	edge [color="#31CEF0"]
			node [shape = record,height=.1];
			node0[label = " | G| "];
			node1[label = " | E| "];
			node2[label = " | B| "];
			node3[label = " | F| "];
			node4[label = " | R| "];
			node5[label = " | H| "];
			node6[label = " | Y| "];
			node7[label = " | A| "];
			node8[label = " | C| "];
			"node0":f2 -> "node4":f1;
			"node0":f0 -> "node1":f1;
			"node1":f0 -> "node2":f1;
			"node1":f2 -> "node3":f1;
			"node2":f2 -> "node8":f1;
			"node2":f0 -> "node7":f1;
			"node4":f2 -> "node6":f1;
			"node4":f0 -> "node5":f1;
		}
	}
%}

* dot
	- subgraphs

{% graphviz
	dot {
		digraph G {
			node [fontname=Verdana,fontsize=12]
			node [style=filled]
		 	node [fillcolor="#EEEEEE"]
		 	node [color="#EEEEEE"]
		 	edge [color="#31CEF0"]

			subgraph cluster_0 {
				label = "hello world";
				a -> b;
				a -> c;
				color = hot_pink;
			}

			subgraph cluster_1 {
				label = "MSDOT";
				style= "dashed";
				color=purple;
				x -> y;
				x -> z;
				y -> z;
				y -> q;
			}

			top -> a;
			top -> y;
			y -> b;
		}
	}
%}

* neato

{% graphviz 
	neato {
		graph G
		{

		  node [color=Red]

		  r01
		  r02

		  r03

		  r04
		  r05

		  r06
		  r07
		  r08
		  r09

		  r10
		  r11

		  node [color=Blue]

		  p01
		  p02

		  p03

		  p04
		  p05
		  p06

		  p07
		  p08
		  p09
		  p10
		  p11

		  p12
		  p13

		  r01 -- r02
		  r01 -- p01
		  r01 -- p02
		  r02 -- p01
		  r02 -- p02
		  p01 -- p02

		  r03 -- p03

		  r04 -- r05
		  r04 -- p04
		  r04 -- p05
		  r04 -- p06
		  r05 -- p04
		  r05 -- p06
		  p04 -- p05
		  p04 -- p06

		  r06 -- r07
		  r06 -- r08
		  r06 -- r09
		  r06 -- p07
		  r06 -- p08
		  r06 -- p09
		  r06 -- p10
		  r06 -- p11
		  r07 -- r08
		  r07 -- r09
		  r07 -- p07
		  r07 -- p08
		  r07 -- p09
		  r07 -- p10
		  r07 -- p11
		  r08 -- r09
		  r08 -- p07
		  r08 -- p08
		  r08 -- p09
		  r08 -- p10
		  r08 -- p11
		  r09 -- p07
		  r09 -- p08
		  r09 -- p09
		  r09 -- p10
		  r09 -- p11
		  p07 -- p08
		  p07 -- p09
		  p07 -- p10
		  p07 -- p11
		  p08 -- p09
		  p08 -- p10
		  p08 -- p11
		  p09 -- p10
		  p09 -- p11
		  p10 -- p11

		  r10 -- r11
		  r10 -- p12
		  r10 -- p13
		  r11 -- p12
		  r11 -- p13
		  p12 -- p13
		}
	}
%}

{% graphviz
	neato {
		graph ER {
			node [shape=box]; course; institute; student;
			node [shape=ellipse]; {node [label="name"] name0; name1; name2;}
				code; grade; number;
			node [shape=diamond,style=filled,color=lightgrey]; "C-I"; "S-C"; "S-I";

			name0 -- course;
			code -- course;
			course -- "C-I" [label="n",len=1.00];
			"C-I" -- institute [label="1",len=1.00];
			institute -- name1;
			institute -- "S-I" [label="1",len=1.00];
			"S-I" -- student [label="n",len=1.00];
			student -- grade;
			student -- name2;
			student -- number;
			student -- "S-C" [label="m",len=1.00];
			"S-C" -- course [label="n",len=1.00];

			label = "\n\nEntity Relation Diagram\ndrawn by NEATO";
			fontsize=20;
		}
	}
%}



* twopi

{% graphviz
	twopi {
		digraph G
		{
		        center = v21;

		        center -> v11;
		        center -> v12;
		        center -> v13;

		        v11 -> v21;
		        v11 -> v22;
		        v11 -> v23;

		        v21 -> v22;
		        v22 -> v23;
		        v23 -> v21;

		        v21 -> v31;
		        v21 -> v32;
		        v21 -> v33;

		        v32 -> v41;
		        v32 -> v42;
		        v33 -> v43;
		}
	}
%}


* circo

{%graphviz
	circo {
		digraph g1 {
		    node [shape = doublecircle]; N4 N6;
		    node [shape = circle];
		    edge[label="{1,0}"];
		    N0 -> N1 -> N2 -> N3 -> N4 -> N5 -> N6 -> N0;
		}
	}
%}


* misc

{%graphviz
	dot {
		digraph G {
		 node [fontname=Verdana,fontsize=12]
		 node [style=filled]
		 node [fillcolor="#EEEEEE"]
		 node [color="#EEEEEE"]
		 edge [color="#31CEF0"]
		 
		 main -> parse -> execute
		 main -> init
		 main -> cleanup
		 execute -> make_string
		 execute -> printf
		 init -> make_string
		 main -> printf
		 execute -> compare
		}
	}
%}
