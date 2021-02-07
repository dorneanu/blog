+++
title = "Migrate this blog from Octopress to Pelican"
date = "2014-06-18"
category = "blog"
tags = ["blog", "ipython", "python", "pelican", "octopress"]
author = "Victor Dorneanu"
ipython = "true"
+++

A few weeks ago I'be migrated my whole blog from Wordpress to Octopress. Meanwhile I've discovered `Pelican` which is the Pythonic alternative to Octopress. To be honest: The main reason I'm using Pelican instead of Octopress is the ability to import/include `IPython notebooks`. 

After I've set up my blog using Octopress I only had a bunge of `Markdown` files. So let's get started.

## Generate metadata for content


```bash
%%bash
cp ~/work/blog/octopress/source/_posts/*.markdown ~/work/blog/pelican/content/markdown/
```


```bash
%%bash
ls -c ~/work/blog/pelican/content/markdown/ | head -n 10
```

    2014-05-27-berlinsides-0x05.markdown
    2014-06-02-googles-xss-game-solutions.markdown
    2014-05-20-howto-write-pentest-reports-the-easy-way.markdown
    2014-05-15-test2.markdown
    2014-01-31-links-of-the-week-25-2.markdown
    2014-02-07-links-of-the-week-26.markdown
    2014-02-14-links-of-the-week-27.markdown
    2014-03-07-unfancy-dashboard-using-matplotlib.markdown
    2014-05-04-howto-create-docs-with-sphinx.markdown
    2014-01-23-24h-android-sniffing-using-tcpdump.markdown


## AWK script for doing the main job


```
%%writefile ~/work/blog/pelican/content/transform.awk
{
    # Date
    if ( $0 ~ /^date(.*)$/ ) {
        # Get date
        match($0, /^date: ([0-9]{4}\-[0-9]{2}\-[0-9]{2}).*$/, ary)
        print "Date: " ary[1]; 

    # Title 
    } else if ( $0 ~ /^title(.*)$/) {
        match($0, /^title: (.*)$/, ary)

        # Remove single/double quotes
        gsub(/'/, "", ary[1]);
        gsub(/"/, "", ary[1]);
        print "Title: " ary[1];

    # Author
    } else if ( $0 ~ /^author(.*)$/) {
        match($0, /^author: (.*)$/, ary)
        print "Author: " ary[1];

    # Handle available categories as tags
    } else if ($0 ~ /^categories:.*$/) {
        printf "Tags: "
        
        # Array index
        i = 0;

        # Read next line until new meta tag is found
        while ((getline line ) > 0) {
            # Read until new meta tag is found
            if ((line !~ /^.*\-.*$/) || (line ~ /^\-\-\-$/)) {
                output_string = ""
                # Print categories and the next exit loop
                for (j=0; j<i; j++)
                    
                    # Is this the last category
                    if (j+1 < i) 
                        output_string = output_string tolower(categories[j]) ", "

                    # Last category
                    else
                        output_string = output_string tolower(categories[j])
       
                # Remove last "," and add default category
                printf "%s\n", output_string
                printf "Category: blog\n\n"
                break
            }

            # Extract category
            match(line, /^.*\- (.*)$/, ary)
            categories[i] = ary[1]

            # Increase index
            i++;
        }

    }
}

```

    Overwriting /home/victor/work/blog/pelican/content/transform.awk


## Extract the metdata and generate the meta files


```bash
%%bash
cd ~/work/blog/pelican/
for i in content/markdown/*.markdown; do 
    cat $i | gawk -f content/transform.awk > $i-meta
done

ls -c content/markdown/*-meta | head -n 10
```

    content/markdown/blogging-with-the-ipython-notebook-example.markdown-meta
    content/markdown/2014-06-02-googles-xss-game-solutions.markdown-meta
    content/markdown/2014-05-27-berlinsides-0x05.markdown-meta
    content/markdown/2014-05-20-howto-write-pentest-reports-the-easy-way.markdown-meta
    content/markdown/2014-05-15-test2.markdown-meta
    content/markdown/2014-05-04-howto-create-docs-with-sphinx.markdown-meta
    content/markdown/2014-03-07-unfancy-dashboard-using-matplotlib.markdown-meta
    content/markdown/2014-02-14-links-of-the-week-27.markdown-meta
    content/markdown/2014-02-07-links-of-the-week-26.markdown-meta
    content/markdown/2014-01-31-links-of-the-week-25-2.markdown-meta


## Sample meta data output


```bash
%%bash

find ~/work/blog/pelican/content/markdown/*-meta -name "2014-05-*" -exec cat {} \;
```

    Title: HowTo: Create docs with sphinx
    Author: Victor
    Date: 2014-05-04
    Tags: coding, howto
    Category: blog
    
    Title: Test2
    Date: 2014-05-15
    Tags: 
    Category: blog
    
    Title: HowTo: Write pentest reports the easy way
    Date: 2014-05-20
    Tags: 
    Category: blog
    
    Title: BerlinSides 0x05
    Date: 2014-05-27
    Tags: events, hacking, security
    Category: blog
    


## Delete old metadata


```bash
%%bash
cd ~/work/blog/pelican/content/markdown
for i in *.markdown; do
    cat $i | sed '/^---$/,/^---$/d' > $i-sed
done
```

## Insert new metadata info file


```bash
%%bash
cd ~/work/blog/pelican/content/markdown
for i in *.markdown; do
    cat $i-meta > $i-final; cat $i-sed >> $i-final;
done
```

## Sample final output


```bash
%%bash
cd ~/work/blog/pelican/content/markdown
find . -name "2014-05*.markdown-final" -exec head -n 10 {} \;
```

    Title: Test2
    Date: 2014-05-15
    Tags: 
    Category: blog
    
    
    
    # Motivation
    
    I've started this little project since I was mainly interested in the data my
    Title: HowTo: Create docs with sphinx
    Author: Victor
    Date: 2014-05-04
    Tags: coding, howto
    Category: blog
    
    
    In this post I&#8217;d like to show some handy way to improve your process of documentating your project.
    Since we all know documentation is a **must** you might have wondered how to handle that
    without any big efforts. In fact it would be great if you could write your code along with the
    Title: HowTo: Write pentest reports the easy way
    Date: 2014-05-20
    Tags: 
    Category: blog
    
    
    In this post I'll try to share an idea I've had regarding pentest reports. Most of you surely have
    their own methods and tools to create nice looking reports after have done some pentesting.
    Since I try to keep things simple I'll give you a rough idea how this could be done without Excel & Co.
    
    Title: BerlinSides 0x05
    Date: 2014-05-27
    Tags: events, hacking, security
    Category: blog
    
    
    The [**BerlinSides**](http://berlinsides.org/) is a conference from hacker for hacker. This years motto was: **...you ain't listening**.
    All my greetings go to:
    
    * [nullsecurity.net](http://nullsecurity.net)


## Replace some strings


```bash
%%bash
cd ~/work/blog/pelican/content/markdown

# Insert some dummy text for missing attributes in img tags
for i in *.markdown-final; do
    sed -i 's/alt=\"\"/alt=\"image description\"/g' $i
done
```

## Rename files and delete bullshit


```bash
%%bash
cd ~/work/blog/pelican/content/markdown
rm *.markdown-sed
rm *.markdown-meta
rm *.markdown

for i in *.markdown-final; do
    mv $i `basename $i ".markdown-final"`.markdown
done

```

## Generate new content

Supposing you have already setup your pelican blog now you can run: 


```bash
%%bash
cd ~/work/blog/pelican/

source env/bin/activate
make html
```

    pelican /home/victor/work/blog/pelican/content -o /home/victor/work/blog/pelican/output -s /home/victor/work/blog/pelican/pelicanconf.py 
    
     ** Writing styles to _nb_header.html: this should be included in the theme. **
    
    Done: Processed 124 articles and 1 pages in 6.38 seconds.


## The End

I hope you have enjoyed this one. If you have any questions regarding the process, don't hesitate and leave a comment.
