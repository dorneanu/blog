+++
title = "Speed up Drupal by preloading the page cache"
author = "Victor"
date = "2010-09-04"
tags = ["web", "drupal", "admin"]
category = "notes"
+++

If you need some technical background, have a look [here][1]. The preload cache script I've been using for a couple a months:

~~~.shell
#!/bin/bash
#
# Preload a web site's cache
#

site="dornea.nu"
tmp="downloads"
log="log.txt"

echo "Crawling $site."

# Remove any prior downloaded files.
rm -rf $tmp

# Clear the page cache first.
wget --quiet --delete-after http://$site/[insert reset cache script here].php

# Crawl the site
#
# Crawl arguments:
# --recursive Crawl the site
# --domains=example.com Only crawl pages from the site
# --level=inf Continue to infinite depth
#
# Temp file arguments:
# --directory-prefix=downloads Save tmp files to the 'downloads' directory
# --force-directories Create directories for downloaded pages
# --delete-after Delete downloaded files afterwards
#
# Verbosity arguments:
# --output-file=log.txt Write a log to 'log.txt'
# --no-verbose Minimize log file output
#

wget
--recursive
--level=inf
--delete-after
--output-file=$log
--domains=$site
--force-directories
--directory-prefix=$tmp
--no-verbose

http://$site/

# When the crawl is done, the download files are removed.
# Now remove the leftover directories too
rm -rf $tmp

echo
echo "Done. A log of the crawl is in '$log'."
~~~

The php script:

~~~.php
<?php
/**
* Clears the page cache.
*/
include_once './includes/bootstrap.inc';
drupal_bootstrap(DRUPAL_BOOTSTRAP_FULL);
cache_clear_all( '*', 'cache_page', TRUE );
?>
~~~

It really improves your sites speed! Feel free to adapt the script(s) to your needs.

 [1]: http://nadeausoftware.com/node/98
