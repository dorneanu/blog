+++
title = "GUIfy your Apps using Flask"
author = "Victor Dorneanu"
date = "2015-02-05"
tags = ["python", "flask"]
category = "blog"
status = "draft"
+++

If you follow this blog, you might have noticed that I'm mainly interested in #infosec, #hacking and so on. 
The main reason for writing this post was to encourage people to look behind the plate and make 
their life more enjoyable (and still stay inside their comfort zone :). Ok, "WTF?" you're probably asking 
yourself. Let me first start with a more detailed motivation behind this writing. 

## Motivation

Being involved in data analysis on a daily basis, I have to read and modify data in a quick and easy way.
Since I'm the only person accessing the data I don't have to concern about multi-user, concurrency and such
stuff. Even if it's a simple SQLite DB, I just have my client - I recommend [sqlitestudio](http://sqlitestudio.pl/) - 
and there you go. Well this works if you don't really want to share your data with your team, allow them to modify
it or even allow reports to be generated. This approach is a more single-user one.

Well in the past few months (functional) requirements have changed. Among these:

* multi-user data access
* multiple roles for accessing the data (read, write etc.)
* easy data access due to additional software installation restrictions
* charts!

At the first moment this sounded very challenging and for somebody (like /me) who mainly just *uses*
some tools sth was clear: I have to do it on myself. Why reinvent the wheel? For me it was clear that 
my ambitious plan had to be finished in reasonable amount of time. I didn't want to reinvent the wheel.
I just wanted to "form" it in such way to fullfil my very specific needs and requirements. 

## Data!

If you open your data analysis bibel you'll read: "[...] and at the beginning the was a **lot** of data!"
And when I'm talking about data think of sth very complex that has to be first re-structured in order 
to understand it. And because I use [RDBMS](http://en.wikipedia.org/wiki/Relational_database_management_system)
I like to structure my data in:

* **entities** and
* **relationships**

This way to you should be able to get a more high-level overview on your data. Try to think of useful
entities which should reflect the nature of your data. Besides that try to look for connections/relationships
between your data and define meaningful and deductive relations between your data entities. Once you have that 
you can model your DB schema using a more high-level approach. I've found [SQLAlchemy](http://www.sqlalchemy.org/)
to be a very powerful framework to build SQL DB in a Pythonic way.

## Define your models




### Define your models

this is has to be written! :)
