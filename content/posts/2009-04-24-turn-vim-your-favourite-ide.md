+++
title = "Turn VIM into your favourite IDE"
author = "Victor"
date = "2009-04-24"
tags = ["coding", "misc", "vim"]
category = "blog"
+++

Before you start reading this I'd recommand you to ask your best friend Google™ for the most common (platform independent) [IDE][1]s (Integrated Development Environment). If you want some top 10 of most featured/used/known/whatever IDEs go to [Wikipedia][2] and satisfy your needs. So don't get me wrong: This article is NOT supposed to give you some comparison nor to influence your oppinion. I'll just satisfy MY needs and give you some kind of reviews in using <a title="Read more about VIM" href="http://en.wikipedia.org/wiki/Vim_(text_editor)" rel="external">VIM</a> for complex projects and daily coding tasks.

So why using VIM at all? Isn't that some ancient Unix editor used by the most geeks out there? Well like other many other things in this world, VIM seems to be some kind of ageless editor. I really tried to get some sincere answer why I'm still addicted to VIM. When dealing with software development most coders will mention [Eclipse][3] or [Netbeans][4]. The competition between them is quite intense because those products have the most active communities of user. Of the primary players out there (including [InteliJ IDEA][5] of Oracle) only Eclipse and Netbeans are free and open source. I've been using Netbeans for a long time. My oppionion: A really good (open source) IDE. I really disliked Eclipse in cause of its extremly bloated look. But the main reason for using Netbeans instead of Eclipse was my 12.1" Laptop.If I had some larger display maybe I'll be using Eclipse too. It has a big potential and some really cool features. Ok, I think I wrote enough about the so called big "primary players*. Let us take a look at VIM, the lighty IDE with cool features. Since VIMs [mouse][7] support things became a lot easier. You can use contoll VIM by your mouse! It works under xterm and other several terminals. All you'll have to to is to set following option:

~~~.shell
:set mouse=a
~~~

First of all let me show you what VIM is capable of. Left to this text you have some screenshot I made on my Debian/Linux. I splitted the main window into several windows and loaded source codes into them. Before doing that I activated the mouse support (see above) in order to simplify the file loading process. On the left most side of the screen you see some files listes in the current working directory. Once I've clicked on some item in the the current working window, it splitted horizontally (default behaviour) and loaded the selected file. In order to spn lit vertically you'll have to use the `vsp` command. Fur further info just take a look at the documentation. There are a lot of information shown in each splitted window like e.g. the lines number, file name, current cursor position etc. Here you have my VIM configuration file `~/.vimrc`:

~~~.shell
set t_Co=256
syntax on
colorscheme leo
set tabstop=3
set shiftwidth=3
set expandtab
set number
~~~

If you really like my colorscheme just download it at [http://www.vim.org/scripts/script.php?script_id=2156][8]. Put it into `~/.vim/colors/` and then activate it using `:colorscheme leo`. It really has cool colors and preserves your tired eyes and boosts your motivation why programming. The mentioned file manager is called **NERDTree** and can be downloaded [here][10]. Once you have activated the mouse support and created several windows splits you can now select the splits by mouse or resize them. In order to do that just simply select the splits border (the blue line in the left screenshot) and move it vertically to your desired position. I hope you'll have fun playing with VIM (take your time like I did) and discover its (unknown?) IDE capabilities. You'll soon be fascinated by the vast posibilities this editor offers you. Feel free to [Google][11] for some other blog posts. I'm glad I'm not the only one geek out there addicted to VIM. 

 [1]: http://en.wikipedia.org/wiki/Integrated_development_environment "Wiki IDE"
 [2]: http://en.wikipedia.org/wiki/Comparison_of_integrated_development_environments "Comparison of IDEs"
 [3]: http://www.eclipse.org/ "More about Eclipse"
 [4]: http://www.netbeans.org/ "More about Netbeans"
 [5]: http://www.jetbrains.com/idea/ "More about IntelliJ IDEA"
 [7]: http://www.vim.org/htmldoc/term.html#mouse-using "VIM Mouse support"
 [8]: http://www.vim.org/scripts/script.php?script_id=2156 "colorscheme leo"
 [10]: http://www.vim.org/scripts/script.php?script_id=1658
 [11]: http://www.google.com/search?hl=en&q=vim+IDE
