+++
title = "HowTo: Create docs with sphinx"
author = "Victor"
date = "2014-05-04"
tags = ["coding", "howto", "python"]
category = "blog"
+++


In this post I'd like to show some handy way to improve your process of documentating your project.
Since we all know documentation is a **must** you might have wondered how to handle that
without any big efforts. In fact it would be great if you could write your code along with the
documentation and extract it later on for publishing.

## Meet <a href="http://sphinx-doc.org">sphinx</a>

It is a tool that you'll love! Being more technical:

> It was originally created for the new Python documentation,
> and it has excellent facilities for the documentation of Python projects,
> but C/C++ is already supported as well, and it is planned to add special support for other languages as well.

I have found this tool reading some documentation on [readthedocs.org][1]. I was very impressed
how [easy][2] you could document your code and build a documentation format upon on your
needs:

*   [LatexPDF][3]
*   [SingleHTML][4]
*   [EPUB][5]
*   and many [more][6]

## Quickstart

### Install tools

First of create a new [virtualenv][7] environment:

~~~ shell
$ mkdir doku
$ virtualenv doku
Using base prefix &#039;/usr&#039;
New python executable in doku/bin/python3
Also creating executable in doku/bin/python
Installing setuptools, pip...done.
~~~

Then activate it:

~~~ shell
$ source doku/bin/activate
â  tmp  source doku/bin/activate
(doku)â  tmp  cd doku
(doku)â  doku  ls -l
total 12
drwxr-xr-x 2 victor users 4096 May  4 13:37 bin
drwxr-xr-x 2 victor users 4096 May  4 13:37 include
drwxr-xr-x 3 victor users 4096 May  4 13:37 lib
~~~

Now you'll have to install **sphinx** using **pip**:

~~~ shell
(doku) pip install sphinx
Downloading/unpacking sphinx
  Downloading Sphinx-1.2.2-py33-none-any.whl (1.1MB): 1.1MB downloaded
Downloading/unpacking docutils>=0.10 (from sphinx)
  Downloading docutils-0.11.tar.gz (1.6MB): 1.6MB downloaded
  Running setup.py (path:/home/victor/tmp/doku/build/docutils/setup.py) egg_info for package docutils

warning: no files found matching 'MANIFEST'
warning: no files found matching '*' under directory 'extras'
warning: no previously-included files matching '.cvsignore' found under directory '*'
warning: no previously-included files matching '*.pyc' found under directory '*'
warning: no previously-included files matching '*~' found under directory '*'
warning: no previously-included files matching '.DS_Store' found under directory '*'
Downloading/unpacking Jinja2>=2.3 (from sphinx)
  Downloading Jinja2-2.7.2.tar.gz (378kB): 378kB downloaded
  Running setup.py (path:/home/victor/tmp/doku/build/Jinja2/setup.py) egg_info for package Jinja2

warning: no files found matching '*' under directory 'custom_fixers'
warning: no previously-included files matching '*' found under directory 'docs/_build'
warning: no previously-included files matching '*.pyc' found under directory 'jinja2'
warning: no previously-included files matching '*.pyc' found under directory 'docs'
warning: no previously-included files matching '*.pyo' found under directory 'jinja2'
warning: no previously-included files matching '*.pyo' found under directory 'docs'
Downloading/unpacking Pygments>=1.2 (from sphinx)
  Downloading Pygments-1.6.tar.gz (1.4MB): 1.4MB downloaded
  Running setup.py (path:/home/victor/tmp/doku/build/Pygments/setup.py) egg_info for package Pygments

Downloading/unpacking markupsafe (from Jinja2>=2.3->sphinx)
  Downloading MarkupSafe-0.21.tar.gz
  Running setup.py (path:/home/victor/tmp/doku/build/markupsafe/setup.py) egg_info for package markupsafe

Installing collected packages: sphinx, docutils, Jinja2, Pygments, markupsafe
  Running setup.py install for docutils
Skipping implicit fixer: buffer
Skipping implicit fixer: idioms
Skipping implicit fixer: set_literal
Skipping implicit fixer: ws_comma
copy/convert test suite
changing mode of build/scripts-3.4/rst2html.py from 644 to 755
changing mode of build/scripts-3.4/rst2s5.py from 644 to 755
changing mode of build/scripts-3.4/rst2latex.py from 644 to 755
changing mode of build/scripts-3.4/rst2xetex.py from 644 to 755
changing mode of build/scripts-3.4/rst2man.py from 644 to 755
changing mode of build/scripts-3.4/rst2xml.py from 644 to 755
changing mode of build/scripts-3.4/rst2pseudoxml.py from 644 to 755
changing mode of build/scripts-3.4/rstpep2html.py from 644 to 755
changing mode of build/scripts-3.4/rst2odt.py from 644 to 755
changing mode of build/scripts-3.4/rst2odt_prepstyles.py from 644 to 755

warning: no files found matching 'MANIFEST'
warning: no files found matching '*' under directory 'extras'
warning: no previously-included files matching '.cvsignore' found under directory '*'
warning: no previously-included files matching '*.pyc' found under directory '*'
warning: no previously-included files matching '*~' found under directory '*'
warning: no previously-included files matching '.DS_Store' found under directory '*'
changing mode of /home/victor/tmp/doku/bin/rstpep2html.py to 755
changing mode of /home/victor/tmp/doku/bin/rst2xml.py to 755
changing mode of /home/victor/tmp/doku/bin/rst2pseudoxml.py to 755
changing mode of /home/victor/tmp/doku/bin/rst2html.py to 755
changing mode of /home/victor/tmp/doku/bin/rst2odt_prepstyles.py to 755
changing mode of /home/victor/tmp/doku/bin/rst2latex.py to 755
changing mode of /home/victor/tmp/doku/bin/rst2man.py to 755
changing mode of /home/victor/tmp/doku/bin/rst2odt.py to 755
changing mode of /home/victor/tmp/doku/bin/rst2xetex.py to 755
changing mode of /home/victor/tmp/doku/bin/rst2s5.py to 755
  Running setup.py install for Jinja2

warning: no files found matching '*' under directory 'custom_fixers'
warning: no previously-included files matching '*' found under directory 'docs/_build'
warning: no previously-included files matching '*.pyc' found under directory 'jinja2'
warning: no previously-included files matching '*.pyc' found under directory 'docs'
warning: no previously-included files matching '*.pyo' found under directory 'jinja2'
warning: no previously-included files matching '*.pyo' found under directory 'docs'
  Running setup.py install for Pygments
Skipping implicit fixer: buffer
Skipping implicit fixer: idioms
Skipping implicit fixer: set_literal
Skipping implicit fixer: ws_comma

Installing pygmentize script to /home/victor/tmp/doku/bin
  Running setup.py install for markupsafe

building 'markupsafe._speedups' extension
gcc -pthread -Wno-unused-result -Werror=declaration-after-statement -DDYNAMIC_ANNOTATIONS_ENABLED=1 -DNDEBUG -g -fwrapv -O3 -Wall -Wstrict-prototypes -march=x86-64 -mtune=generic -O2 -pipe -fstack-protector --param=ssp-buffer-size=4 -fPIC -I/usr/include/python3.4m -c markupsafe/_speedups.c -o build/temp.linux-x86_64-3.4/markupsafe/_speedups.o
gcc -pthread -shared -Wl,-O1,--sort-common,--as-needed,-z,relro build/temp.linux-x86_64-3.4/markupsafe/_speedups.o -L/usr/lib -lpython3.4m -o build/lib.linux-x86_64-3.4/markupsafe/_speedups.cpython-34m.so
Successfully installed sphinx docutils Jinja2 Pygments markupsafe
Cleaning up...
(doku) doku
~~~


Now you should be ready to go.

### Create new documentation dir structure

~~~ shell
(doku)â  doku  mkdir my_documentation
(doku)â  doku  sphinx-quickstart
Welcome to the Sphinx 1.2.2 quickstart utility.

Please enter values for the following settings (just press Enter to
accept a default value, if one is given in brackets).

Enter the root path for documentation.
> Root path for the documentation [.]: my_documentation

You have two options for placing the build directory for Sphinx output.
Either, you use a directory "_build" within the root path, or you separate
"source" and "build" directories within the root path.
> Separate source and build directories (y/n) [n]: n

Inside the root directory, two more directories will be created; "_templates"
for custom HTML templates and "_static" for custom stylesheets and other static
files. You can enter another prefix (such as ".") to replace the underscore.
> Name prefix for templates and static dir [_]:

The project name will occur in several places in the built documentation.
> Project name: My Documentation
> Author name(s): Victor

Sphinx has the notion of a "version" and a "release" for the
software. Each version can have multiple releases. For example, for
Python the version is something like 2.5 or 3.0, while the release is
something like 2.5.1 or 3.0a1.  If you don't need this dual structure,
just set both to the same value.
> Project version: 0.1
> Project release [0.1]: 0.1.0

The file name suffix for source files. Commonly, this is either ".txt"
or ".rst".  Only files with this suffix are considered documents.
> Source file suffix [.rst]:

One document is special in that it is considered the top node of the
"contents tree", that is, it is the root of the hierarchical structure
of the documents. Normally, this is "index", but if your "index"
document is a custom template, you can also set this to another filename.
> Name of your master document (without suffix) [index]:

Sphinx can also add configuration for epub output:
> Do you want to use the epub builder (y/n) [n]: n

Please indicate if you want to use one of the following Sphinx extensions:
> autodoc: automatically insert docstrings from modules (y/n) [n]: y
> doctest: automatically test code snippets in doctest blocks (y/n) [n]: n
> intersphinx: link between Sphinx documentation of different projects (y/n) [n]: n
> todo: write "todo" entries that can be shown or hidden on build (y/n) [n]: n
> coverage: checks for documentation coverage (y/n) [n]: n
> pngmath: include math, rendered as PNG images (y/n) [n]: n
> mathjax: include math, rendered in the browser by MathJax (y/n) [n]: n
> ifconfig: conditional inclusion of content based on config values (y/n) [n]: n
> viewcode: include links to the source code of documented Python objects (y/n) [n]: n

A Makefile and a Windows command file can be generated for you so that you
only have to run e.g. `make html' instead of invoking sphinx-build
directly.
> Create Makefile? (y/n) [y]:
> Create Windows command file? (y/n) [y]: n

Creating file my_documentation/conf.py.
Creating file my_documentation/index.rst.
Creating file my_documentation/Makefile.

Finished: An initial directory structure has been created.

You should now populate your master file my_documentation/index.rst and create other documentation
source files. Use the Makefile to build the docs, like so:
   make builder
where "builder" is one of the supported builders, e.g. html, latex or linkcheck.
~~~

### Create some builds

Now you can call **make** to build your desired documentation format:

~~~ shell
(doku)â  my_documentation  make
Please use `make <target>' where <target> is one of
  html       to make standalone HTML files
  dirhtml    to make HTML files named index.html in directories
  singlehtml to make a single large HTML file
  pickle     to make pickle files
  json       to make JSON files
  htmlhelp   to make HTML files and a HTML help project
  qthelp     to make HTML files and a qthelp project
  devhelp    to make HTML files and a Devhelp project
  epub       to make an epub
  latex      to make LaTeX files, you can set PAPER=a4 or PAPER=letter
  latexpdf   to make LaTeX files and run them through pdflatex
  latexpdfja to make LaTeX files and run them through platex/dvipdfmx
  text       to make text files
  man        to make manual pages
  texinfo    to make Texinfo files
  info       to make Texinfo files and run them through makeinfo
  gettext    to make PO message catalogs
  changes    to make an overview of all changed/added/deprecated items
  xml        to make Docutils-native XML files
  pseudoxml  to make pseudoxml-XML files for display purposes
  linkcheck  to check all external links for integrity
  doctest    to run all doctests embedded in the documentation (if enabled)
~~~

Let's try with **html**:

~~~ shell
(doku)â  my_documentation  make html
sphinx-build -b html -d _build/doctrees   . _build/html
Making output directory...
Running Sphinx v1.2.2
loading pickled environment... failed: [Errno 2] No such file or directory: '/home/victor/tmp/doku/my_documentation/_build/doctrees/environment.pickle'
building [html]: targets for 1 source files that are out of date
updating environment: 1 added, 0 changed, 0 removed
reading sources... [100%] index
looking for now-outdated files... none found
pickling environment... done
checking consistency... done
preparing documents... done
writing output... [100%] index
writing additional files... genindex search
copying static files... done
copying extra files... done
dumping search index... done
dumping object inventory... done
build succeeded.

Build finished. The HTML pages are in _build/html.
~~~

How about **PDF**?

 ~~~ shell
(doku)â  my_documentation  make latexpdf
sphinx-build -b latex -d _build/doctrees   . _build/latex
Making output directory...
Running Sphinx v1.2.2
loading pickled environment... done
building [latex]: all documents
updating environment: 0 added, 0 changed, 0 removed
looking for now-outdated files... none found
processing MyDocumentation.tex... index
resolving references...
writing... done
copying TeX support files...
done
build succeeded.
Running LaTeX files through pdflatex...
make -C _build/latex all-pdf
make[1]: Entering directory '/home/victor/tmp/doku/my_documentation/_build/latex'
...
Transcript written on MyDocumentation.log.
make[1]: Leaving directory '/home/victor/tmp/doku/my_documentation/_build/latex'
pdflatex finished; the PDF files are in _build/latex.
~~~

You can find you **builds** inside the **_build** folder:

~~~ shell
(doku)â  my_documentation  tree _build
_build
âââ doctrees
â   âââ environment.pickle
â   âââ index.doctree
âââ html
â   âââ genindex.html
â   âââ index.html
â   âââ objects.inv
â   âââ search.html
â   âââ searchindex.js
â   âââ _sources
â   â   âââ index.txt
â   âââ _static
â       âââ ajax-loader.gif
â       âââ basic.css
â       âââ comment-bright.png
â       âââ comment-close.png
â       âââ comment.png
â       âââ default.css
â       âââ doctools.js
â       âââ down.png
â       âââ down-pressed.png
â       âââ file.png
â       âââ jquery.js
â       âââ minus.png
â       âââ plus.png
â       âââ pygments.css
â       âââ searchtools.js
â       âââ sidebar.js
â       âââ underscore.js
â       âââ up.png
â       âââ up-pressed.png
â       âââ websupport.js
âââ latex
    âââ fncychap.sty
    âââ Makefile
    âââ MyDocumentation.aux
    âââ MyDocumentation.idx
    âââ MyDocumentation.ilg
    âââ MyDocumentation.ind
    âââ MyDocumentation.log
    âââ MyDocumentation.out
    âââ MyDocumentation.pdf
    âââ MyDocumentation.tex
    âââ MyDocumentation.toc
    âââ python.ist
    âââ sphinxhowto.cls
    âââ sphinxmanual.cls
    âââ sphinx.sty
    âââ tabulary.sty
~~~

You can easily customize the output of your PDF (when dealing with LaTeX). Just have a look at Pedros [tips][8]
how to do that. However if you don't want to use LaTeX to generate your PDF, you could also have a look at [rst2pdf][9]
which will convert your RST file into some PDF. **Attention**: **rst2pdf** is **not** available for Python **3**.x!

## Themes

Although I like to use PDFs when generating my documentation, HTML file are also fine. Make sure you have a look at [how][10]
themes are used. There are some basic themes provided within sphinx itself, but you can also create your own [ones][11].
Also search for themes: [GitHub is your friend!][12]

## Conclusion

You can use **sphinx** to generate all kind of documentation. Examples:

*   [Reports][13]
*   [Books][8]
*   [Presentations][14] (using [impress.js][15])
*   Create diagrams: [graphviz][16] or [blockdiag][17]

 [1]: https://readthedocs.org/
 [2]: http://sphinx-doc.org/tutorial.html
 [3]: http://sphinx-doc.org/latest/builders.html#sphinx.builders.latex.LaTeXBuilder
 [4]: http://sphinx-doc.org/latest/builders.html#sphinx.builders.html.SingleFileHTMLBuilder
 [5]: http://sphinx-doc.org/latest/builders.html#sphinx.builders.epub.EpubBuilder
 [6]: http://sphinx-doc.org/latest/builders.html
 [7]: http://www.virtualenv.org/en/latest/
 [8]: http://pedrokroger.net/using-sphinx-write-technical-books/
 [9]: https://code.google.com/p/rst2pdf/
 [10]: http://sphinx-doc.org/theming.html
 [11]: http://sphinx-doc.org/theming.html#creating-themes
 [12]: https://github.com/search?q=sphinx+theme&ref=cmdform
 [13]: https://github.com/AndreasHeger/sphinx-report
 [14]: http://bartaz.github.io/impress.js/#/bored
 [15]: https://github.com/bartaz/impress.js/
 [16]: http://sphinx-doc.org/ext/graphviz.html
 [17]: http://blockdiag.com/en/blockdiag/sphinxcontrib.html
