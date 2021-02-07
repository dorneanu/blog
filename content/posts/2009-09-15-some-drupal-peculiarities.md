+++
title = "Some Drupal peculiarities"
author = "Victor"
date = "2009-09-15"
tags = ["coding", "web", "drupal"]
category = "notes"
+++

Add Lightbox2 functionalities to WYSIWYG editor TinyMCE - who thought this would cost me about 6 hours of work? In fact that was the easiest part: I just followed the instructions on <http://drupal.org/node/252153> and everything worked well! Before being able to do that, some upgrades were necessary. On <http://drupal.org/project/tinymce> I was told that the module was deprecated and replaced by the [Wysiwyg API][1]. So I had to remove the old TinyMCE module, install the new one and add at least one editor library as described on <http://drupal.org/node/371459>. The installation went **almost** fine. I was able to create a new WYSIWYG profile and adjust settings on *admin/settings/wysiwyg/profile*. Then I was curios enought to test it using *node/add/articles*. Nothing happened... No TinyMCE... No WYS*&%SHIT!

So what went wrong? You won't believe me! The main cause was a missing:

~~~.shell
<?php print $closure; >
~~~

in the **page.tpl.php**. What the heck?! Finally the whole voodoo thing developed into a struggle and I was on the verge of a nervous breakdown. After hours of errors seeking I was able to diagnose the 2nd main cause: The whole caching system was kind of messy. I came into Drupals [drupal_rebuild_theme_registry()][2] function and cleaned up the theme registry. What came next? TinyMCE's JavaScript files were successfully loaded into the page!!! **HAPPY END**!

[1]: http://drupal.org/project/wysiwyg
[2]: http://api.drupal.org/api/function/drupal_rebuild_theme_registry/6
