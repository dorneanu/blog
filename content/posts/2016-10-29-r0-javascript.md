+++
title = "ringzer0 CTF - JavaScript challenges "
author = "Victor Dorneanu"
date = "2016-10-29"
tags = ["ringzer0", "ctf", "wargames", "javascript", "crypto"]
category = "blog"
+++

These challenges were quite tricky since they didn't focus only on the JavaScript language itself but also on
all kind of stuff you can do with JavaScript: Crypto, obfuscation etc. I think they were a good opportunity 
to learn more about the language itself and get some ideas how JavaScript obfuscation techniques work. 

## Level 1: Client side validation is bad!

Let's have a look at the source code:

```.javascript
// Look's like weak JavaScript auth script :)
$(".c_submit").click(function(event) {
    event.preventDefault()
    var u = $("#cuser").val();
    var p = $("#cpass").val();
    if(u == "admin" && p == String.fromCharCode(74,97,118,97,83,99,114,105,112,116,73,115,83,101,99,117,114,101)) {
        if(document.location.href.indexOf("?p=") == -1) {   
            document.location = document.location.href + "?p=" + p;
        }
    } else {
        $("#cresponse").html("<div class='alert alert-danger'>Wrong password sorry.</div>");
    }
});
```

That charcode decodes to: `JavaScriptIsSecure`. So the credentials are `admin:JavaScriptIsSecure`. Login in reveals the flag:
`FLAG-66Jq5u688he0y46564481WRh`.


## Level 2: Hashing is more secure

Again let's have a look at the code:

```.javascript
// Look's like weak JavaScript auth script :)                                                                          
$(".c_submit").click(function(event) {
    event.preventDefault();
    var p = $("#cpass").val();
    if(Sha1.hash(p) == "b89356ff6151527e89c4f3e3d30c8e6586c63962") {
        if(document.location.href.indexOf("?p=") == -1) {   
            document.location = document.location.href + "?p=" + p;
        }
    } else {
        $("#cresponse").html("<div class='alert alert-danger'>Wrong password sorry.</div>");
    }
});
```

All I had to do is to search for secret string whose hash (SHA1) is `b89356ff6151527e89c4f3e3d30c8e6586c63962`.
Here you go: http://sha1.gromweb.com/?hash=b89356ff6151527e89c4f3e3d30c8e6586c63962. And the value is: `adminz`.
And finally the flag: `FLAG-bXNsYg9tLCaIX6h1UiQMmMYB`.  


## Level 3: Then obfuscation is more secure 

The source code:

```.javascript
// Look's like weak JavaScript auth script :)

var _0xc360=["\x76\x61\x6C","\x23\x63\x70\x61\x73\x73","\x61\x6C\x6B\x33","\x30\x32\x6C\x31","\x3F\x70\x3D","\x69\x6E\x64\x65\x78\x4F\x66","\x68\x72\x65\x66","\x6C\x6F\x63\x61\x74\x69\x6F\x6E","\x3C\x64\x69\x76\x20\x63\x6C\x61\x73\x73\x3D\x27\x65\x72\x72\x6F\x72\x27\x3E\x57\x72\x6F\x6E\x67\x20\x70\x61\x73\x73\x77\x6F\x72\x64\x20\x73\x6F\x72\x72\x79\x2E\x3C\x2F\x64\x69\x76\x3E","\x68\x74\x6D\x6C","\x23\x63\x72\x65\x73\x70\x6F\x6E\x73\x65","\x63\x6C\x69\x63\x6B","\x2E\x63\x5F\x73\x75\x62\x6D\x69\x74"];$(_0xc360[12])[_0xc360[11]](function (){var _0xf382x1=$(_0xc360[1])[_0xc360[0]]();var _0xf382x2=_0xc360[2];if(_0xf382x1==_0xc360[3]+_0xf382x2){if(document[_0xc360[7]][_0xc360[6]][_0xc360[5]](_0xc360[4])==-1){document[_0xc360[7]]=document[_0xc360[7]][_0xc360[6]]+_0xc360[4]+_0xf382x1;} ;} else {$(_0xc360[10])[_0xc360[9]](_0xc360[8]);} ;} );
```

Let's try to **deobfuscate** that using https://puzzlefiles.com/Deobfuscate/:

```.javascript
$('.c_submit')['click'](function () {
    var _0xf382x1 = $('#cpass')['val']();
    var _0xf382x2 = 'alk3';
    if (_0xf382x1 == '02l1' + _0xf382x2) {
        if (document['location']['href']['indexOf']('?p=') == -1) {
            document['location'] = document['location']['href'] + '?p=' + _0xf382x1;
        };
    } else {
        $('#cresponse')['html']('<div class=\'error\'>Wrong password sorry.</div>');
    };
});
```

So the password is `02l1alk3` which leaves to the flag: `FLAG-5PJne3T8d73UGv4SCqN44DXj`.

## Level 4: Why not?

The source code:

```.javascript
// Look's like weak JavaScript auth script :)
$(".c_submit").click(function(event) {
    event.preventDefault();
    var k = new Array(176,214,205,246,264,255,227,237,242,244,265,270,283);
    var u = $("#cuser").val();
    var p = $("#cpass").val();
    var t = true;

    if(u == "administrator") {
        for(i = 0; i < u.length; i++) {
            if((u.charCodeAt(i) + p.charCodeAt(i) + i * 10) != k[i]) {
                $("#cresponse").html("<div class='alert alert-danger'>Wrong password sorry.</div>");
                t = false;
                break;
            }
        }
    } else {
        $("#cresponse").html("<div class='alert alert-danger'>Wrong password sorry.</div>");
        t = false;
    }
    if(t) {
        if(document.location.href.indexOf("?p=") == -1) {
            document.location = document.location.href + "?p=" + p;
            }
    }
});
``` 
                                                                                                                       
If you look closely at the code, you'll see follwoing algorithm:

```
k: 176,214,205,246,264,255,227,237,242,244,265,270,283
u: 97,100,109,105,110,105,115,116,114,97,116,111,114

u[i] + p[i] + i*10 = k[i]
```

So we have to find out `p`:

```
p[i] = k[i] - u[i] - i*10
```

Let's write some python code:

```.python
k = [176,214,205,246,264,255,227,237,242,244,265,270,283]
u = [97,100,109,105,110,105,115,116,114,97,116,111,114]
p = {}

s = "administrator"

for i in range(0, len(s)):
    p[i] = k[i] - u[i] - i*10

L = list(tuple(p.values()))
print(''.join(chr(i) for i in L))
```

Which gives me `OhLord4309111`. That in turn reveals the flag: `FLAG-65t23674o6N2NehA44272G24`.


## Level 5: Valid key required

First let's have a look at the JavaScript:

```.javascript
function curry( orig_func ) {
    var ap = Array.prototype, args = arguments;

    function fn() {
        ap.push.apply( fn.args, arguments ); 
        return fn.args.length < orig_func.length ? fn : orig_func.apply( this, fn.args );
    }

    return function() {
        fn.args = ap.slice.call( args, 1 );
        return fn.apply( this, arguments );
    };
}

function callback(x,y,i,a) {
    return !y.call(x, a[a["length"]-1-i].toString().slice(19,21)) ? x : {};
}

var ref = {T : "BG8",J : "jep",j : "M2L",K : "L23",H : "r1A"};

function validatekey()
{
    e = false;
    var _strKey = "";
    try {
        _strKey = document.getElementById("key").value;
        var a = _strKey.split("-");
        if(a.length !== 5)
            e = true;

        var o=a.map(genFunc).reduceRight(callback, new (genFunc(a[4]))(Function));

        if(!equal(o,ref))
            e = true;

    }catch(e){
        e = true;
    }

    if(!e) {
        if(document.location.href.indexOf("?p=") == -1) {
            document.location = document.location.href + "?p=" + _strKey;
        }
    } else {
        $("#cresponse").html("<div class='alert alert-danger'>Wrong password sorry.</div>");
    }   
}

function equal(o,o1)
{
    var keys1 = Object.keys(o1);
    var keys = Object.keys(o);
    if(keys1.length != keys.length)
        return false;

    for(var i=0;i<keys.length;i++)
        if(keys[i] != keys1[i] || o[keys[i]] != o1[keys1[i]])
            return false;

    return true;

}

function hook(f1,f2,f3) {
    return function(x) { return f2(f1(x),f3(x));};
}

var h = curry(hook);
var fn = h(function(x) {return x >= 48;},new Function("a","b","return a && b;"));
function genFunc(_part) {
    if(!_part || !(_part.length) || _part.length !== 4)
        return function() {};

    return new Function(_part.substring(1,3), "this." + _part[3] + "=" + _part.slice(1,3) + "+" + (fn(function(y){return y<=57})(_part.charCodeAt(0)) ?  _part[0] : "'"+ _part[0] + "'"));
}
```

Now lets break this down to some functional parts:

```.javascript
[...]
_strKey = document.getElementById("key").value;
var a = _strKey.split("-");
if(a.length !== 5)
    e = true;
[...]
```

Obvisouly the input has to be sth like this: "AAAA-BBBB-CCCC-DDDD-EEEE".


```.javascript
var h = curry(hook);
var fn = h(function(x) {return x >= 48;},new Function("a","b","return a && b;"));
function genFunc(_part) {
    if(!_part || !(_part.length) || _part.length !== 4)
        return function() {};

    return new Function(_part.substring(1,3), "this." + _part[3] + "=" + _part.slice(1,3) + "+" + (fn(function(y){return y<=57})(_part.charCodeAt(0)) ?  _part[0] : "'"+ _part[0] + "'"));
}

```

Having done JavaScript debugging in the browser, this is what `genFunc()` does:

* it takes a string of 4 characters as input
* it takes the first character of the input as ASCII code (`_part.charCodeAt(0)`) and checks if:
  - ASCII code >= 48
  - ASCII code <= 57
  - if you check the [ASCII table](http://www.asciitable.com) you'll notice that this is the range for **digits**
  - depending wether the character is digit or not a new **function** will be build.

> And btw: This is the whole magic behind the *curry-hook-magic-function-javascript-voodoo*. 

Supposing the input is sth like "ABCD" then a new JavaScript function is being created:

```.javascript
function new_function (bc) {
    this.d = bc + 'a'  
}
```

If we had sth like "ABC1" then the function would have been created like this:

```.javascript
function new_function (bc) {
    this.d = bc + 1 
}
```

Let's continue analyzing the code:

```.javascript
var o=a.map(genFunc).reduceRight(callback, new (genFunc(a[4]))(Function));
```

After splitting the input "AAAA-BBBB-CCCC-DDDD-EEEE" to an array ... 

```.javascript
a = ['AAAA', 'BBBB', 'CCCC', 'DDDD', 'EEEE'] 
```

... `genFunc()` is then being applied to all elements inside the array. 

> Remember? genFunc will simply return a function as described above. 

In the next step `reduceRight()` is being called with a `callback` and an initial value.
The syntax for `reduceRight` looks like this:


```.javascript
arr.reduceRight(callback[, initialValue])
```

as stated [here](https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Global_Objects/Array/reduceRight).
And the syntax for the `callback` function:

```.javascript
function(previousValue, currentValue, index, array)
```

You can try to understand the `callback` function what it really does in JavaScript **or** you reverse it and build it **Python**. 
Before doing that let's build `genFunc` in Python:


```.python
def genFunc(part):
    # Assume that length of part is 4
    c = ''
    
    # Check if first character is a digit
    if part[0].isdigit():
        c = part[0]
    else: 
        c = '"' + part[0] + '"'
        
    # Create functions 
    def f_part(p,d):
        """
            p: parameter
            d: dictionary
        """
        
        # This will concatenate the first character of part with p
        # e.g. if part = 'abcd' and p='k' then a new dictionary will
        # be created: 
        #    dict['d'] = 'bc' + 'k'
        #   
        d[part[3]] = ''.join(p) + ''.join(part[0])
        
        return d
    
    return {'func': f_part}
```

Calling `genFunc` for a list of paremeters would then give you a list of functions:

```.python
IN: a = ['abcd','efgh','ijkl','mnoq', 'prts']
    funcs = [genFunc(list(x)) for x in a]

Out: [{'func': <function __main__.f_part>},
      {'func': <function __main__.f_part>},
      {'func': <function __main__.f_part>},
      {'func': <function __main__.f_part>},
      {'func': <function __main__.f_part>}]
```

And now comes the `callback` aka the **magic** function:


```.python
def magic_function(a):
    
    # Do a "reverse" loop: Starting from the length of input array go down to 0.
    # e.g. if len(a) = 5 then i will have following values: 4,3,2,1,0
    for i in range(len(a)-1, -1, -1):
        j = len(a) - 1 - i
        
        """
            Basically the algo looks like this:
            
            d = {}
            d[a[i][3]] = a[j][1:3] + a[i][0]
        """
        
        # Pickup 2nd and 3rd character from the part where a[i] is pointing to
        b = ''.join(a[i][1:3])
        
        # Pickup the function
        y = funcs[i]['func']
        
        # Pickup 2nd and 3rd character from the part where a[len(a) - 1 -i] is pointing to
        p = ''.join(a[j][1:3])

        # Call the function 
        x = y(p, y(b, {}))

        print("i:%d\tj:%d\ta[j][1:3]:%s\ta[i][0]:%s\tdict:%s" % (i, j, p, a[i][0], x))
```

Let's call this for some dummy list:

```.python
In: a = ['abcd','efgh','ijkl','mnoq', 'prts']
    magic_function(a)

Out: 
i:4 j:0 a[j][1:3]:bc    a[i][0]:p   dict:{'s': 'bcp'}
i:3 j:1 a[j][1:3]:fg    a[i][0]:m   dict:{'q': 'fgm'}
i:2 j:2 a[j][1:3]:jk    a[i][0]:i   dict:{'l': 'jki'}
i:1 j:3 a[j][1:3]:no    a[i][0]:e   dict:{'h': 'noe'}
i:0 j:4 a[j][1:3]:rt    a[i][0]:a   dict:{'d': 'rta'}
```

So for `a` as an input you'll get a dictionary:

```.python
dict:{'s': 'bcp', 'q': 'fgm', 'l': 'jki', 'h': 'noe', 'd': 'rta'}
```

If you pay attention how the characters of the elements in `a` have been arranged, 
you'll be able to find an array as input so that the generated result looks like this:

```.python
ref = {'T' : "BG8", 'J' : "jep", 'j' : "M2L", 'K' : "L23", 'H' : "r1A"};
```

And the final key is:

```.python
In: a = ['ABGH', '3jeK', 'LM2j', 'pL2J', '8r1T']
    magic_function(a)

Out:
i:4 j:0 a[j][1:3]:BG    a[i][0]:8   dict:{'T': 'BG8'}
i:3 j:1 a[j][1:3]:je    a[i][0]:p   dict:{'J': 'jep'}
i:2 j:2 a[j][1:3]:M2    a[i][0]:L   dict:{'j': 'M2L'}
i:1 j:3 a[j][1:3]:L2    a[i][0]:3   dict:{'K': 'L23'}
i:0 j:4 a[j][1:3]:r1    a[i][0]:A   dict:{'H': 'r1A'}
```

Bingo! So the key is `ABGH-3jeK-LM2j-pL2J-8r1T` which in turn reveals the flag: 
`FLAG-ONj755sYn2Js8C96h2L662Jz`.  


## Level 6: Most Secure Crypto Algo

As always let's have a look at the code:

```.javascript
$(".c_submit").click(function(event) {
    event.preventDefault();
    var k = CryptoJS.SHA256("\x93\x39\x02\x49\x83\x02\x82\xf3\x23\xf8\xd3\x13\x37");
    var u = $("#cuser").val();
    var p = $("#cpass").val();
    var t = true;

    if(u == "\x68\x34\x78\x30\x72") {
        if(!CryptoJS.AES.encrypt(p, CryptoJS.enc.Hex.parse(k.toString().substring(0,32)), { iv: CryptoJS.enc.Hex.parse(k.toString().substring(32,64)) }) == "ob1xQz5ms9hRkPTx+ZHbVg==") {
            t = false;
        }
        } else {
            $("#cresponse").html("<div class='alert alert-danger'>Wrong password sorry.</div>");
            t = false;
        }

    if(t) {
        if(document.location.href.indexOf("?p=") == -1) {
            document.location = document.location.href + "?p=" + p;
        }
    }
});
```

So it's an **AES** encryption in **CBC** mode with an **IV**. Let's transcript that code to some **node JS** code:

```.javascript
!/usr/bin/env node
var CryptoJS = require("crypto-js");

// Simple function to convert a hex string to ascii
function hex_to_ascii(str1) {  
    var hex  = str1.toString();  
    var str = '';  
    for (var n = 0; n < hex.length; n += 2) {  
        str += String.fromCharCode(parseInt(hex.substr(n, 2), 16));  
    }  
    return str;  
}  

// This is what we have
var user = "\x68\x34\x78\x30\x72";
var k = CryptoJS.SHA256("\x93\x39\x02\x49\x83\x02\x82\xf3\x23\xf8\xd3\x13\x37");
var key = CryptoJS.enc.Hex.parse(k.toString().substring(0,32));
var iv = CryptoJS.enc.Hex.parse(k.toString().substring(32,64));
var encrypted = "ob1xQz5ms9hRkPTx+ZHbVg==";

// Do the decryption
p = CryptoJS.AES.decrypt(encrypted, key, {iv: iv})

// Convert word array to (hex) string
k = '' + p;

console.log(user, hex_to_ascii(k));
``` 

I think the main difficulty was to convert the word array to sth useful. Anyway: Using `h4x0r PassW0RD!289%!*`
as username/password will reveal the flag: `FLAG-gYtLBa66178DG7l28Uu5lW45CR`.


## Level 7: Why not be more secure?

This challenge was indeed more fun. Let's have a look why:

```.javascript
1 var u = $("#cpass").val();
2 var k = $("#cuser").val();
3 var func = "\x2B\x09\x4A\x03\x49\x0F\x0E\x14\x15\x1A\x00\x10\x3F\x1A\x71\x5C\x5B\x5B\x00\x1A\x16\x38\x06\x46\x66\x5A\x55\x30\x0A\x03\x1D\x08\x50\x5F\x51\x15\x6B\x4F\x19\x56\x00\x54\x1B\x50\x58\x21\x1A\x0F\x13\x07\x46\x1D\x58\x58\x21\x0E\x16\x1F\x06\x5C\x1D\x5C\x45\x27\x09\x4C\x1F\x07\x56\x56\x4C\x78\x24\x47\x40\x49\x19\x0F\x11\x1D\x17\x7F\x52\x42\x5B\x58\x1B\x13\x4F\x17\x26\x00\x01\x03\x04\x57\x5D\x40\x19\x2E\x00\x01\x17\x1D\x5B\x5C\x5A\x17\x7F\x4F\x06\x19\x0A\x47\x5E\x51\x59\x36\x41\x0E\x19\x0A\x53\x47\x5D\x58\x2C\x41\x0A\x04\x0C\x54\x13\x1F\x17\x60\x50\x12\x4B\x4B\x12\x18\x14\x42\x79\x4F\x1F\x56\x14\x12\x56\x58\x44\x27\x4F\x19\x56\x49\x16\x1B\x16\x14\x21\x1D\x07\x05\x19\x5D\x5D\x47\x52\x60\x46\x4C\x1E\x1D\x5F\x5F\x1C\x15\x7E\x0B\x0B\x00\x49\x51\x5F\x55\x44\x31\x52\x45\x13\x1B\x40\x5C\x46\x10\x7C\x38\x10\x19\x07\x55\x13\x44\x56\x31\x1C\x15\x19\x1B\x56\x13\x47\x58\x30\x1D\x1B\x58\x55\x1D\x57\x5D\x41\x7C\x4D\x4B\x4D\x49\x4F";
4 buf = "";
5 if(k.length == 9) {
6     for(i = 0, j = 0; i < func.length; i++) {
7         c = parseInt(func.charCodeAt(i));
8         c = c ^ k.charCodeAt(j);
9         if(++j == k.length) {
10             j = 0;
11         }
12         buf += eval('"' + a(x(c)) + '"');
13     }
14     eval(buf);
15 } else {
16     $("#cresponse").html("<div class='alert alert-danger'>Wrong password sorry.</div>");
17 }
18 });
19 
20 function a(h) {
21     if(h.length != 2) {
22         h = "\x30" + h;
23     }
24     return "\x5c\x78" + h;
25 }
26 
27 function x(d) {
28     if(d < 0) {
29         d = 0xFFFFFFFF + d + 1;
30     }
31     return d.toString(16).toUpperCase();
32 }
```

As we can see in line 5 the key has to have a length of 9. Futhermore we can see that the key (k) is being **XOR'ed**
with characters of `func`. In lines 9-11 we can see that `j` is resetted to 0 if it exceeds the key's length. That means
characters of `k` are used **multiple** times in the XOR operation. So let's stop for a minute and think about what we've 
got:

* XOR operation
* small key length 
* the key is being used multiple times to perform the decryption

### Polyalphabetic ciphers 

Hmmm... That smells like [polyalphabetic ciphers](https://en.wikipedia.org/wiki/Polyalphabetic_cipher) which are
[substitution ciphers](https://en.wikipedia.org/wiki/Substitution_cipher)! (No shit! That was indeed my first idea :).
Although the number of possible keys is very large, these ciphers are not very strong due to following reasons: By
having a reasonable length of an (encrypted) message, one could do a **frequency analysis**. That means, by having a
look at the frequency distribution of symbols (characters inside the encrypted text), one could deduce the meaning of
the most common symbol. In the English language for example the most common (3 letter) word would be "the". Let's say
you have an encrypted text and you know that the text was originally written in English. Then you could look for a
**sequence** of letters (let's say CHZ) in your ciphertext. If this sequence has the most distribution in the
ciphertext, then you have probably found the encrypted text for "the". Afterwards you can find the corresponding
alphabet which was used to encrypt the message, just by "shifting around". Let's have a look what that means.


### Some example

Let's say our message is sth like `THIS IS A VERY LONG MESSAGE`. As an alphabet let's take the English one (A-Z 
which are 26 letters). The encryption process will look like this:

```
Alphabet    ABCDEFGHIJKLMNOPQRSTUVWXYZ 
Plaintext   THISISAVERYLONGMESSAGE

Formular for ciphertext:
En(x) = (x + n) mod 26

 
With a shift of 3 (n = 3), the encryption of letter "T" (position 19 in the alphabet) will result in:

En("T") = (19 + 3) mod 26
        = 22
        = "W"
```

The *decryption* works almost the same way:

```
Dn(x) = (x - n) mod 26

where:

n: how many letters has the alphabet been shifted
x: position of letter to be decrypted in the alphabet
```

For the example we had above let's do the decryption:

```
Dn("W") = (22 - 3) mod 26
        = 19
        = "T"
```

### Kasiski analysis 

For the further cryptanalysis it is important to determine the key length. The
([Kasiski](https://en.wikipedia.org/wiki/Kasiski_examination)) examination involves looking for sequence of letters that
are repeated in the ciphertext. Then if the distances between consecutive sequences of letters are likely to be
multiples of the length of the key. Doing this for different letter sequences narrows down the possible key lengths,
since we can take the GCD (greatest common divisor) of all distances. 

Using some small python utility, I've scanned the ciphertext for occurences of the same letter. Addtionally I've
incremented the offset between the letters and counted the occurences:

```.python

# Counts the occurences in a given text for a specified key length offset 
def kasiski(text, offset):
    c = 0
    for i in range(0, len(text)):
        
        # If we find somewhere else the same character, increment counter
        if text[i] == text[(i + offset) % len(text)]:
            # Hint!
            c += 1
    return c

# Encrypted text
hex = "\x2B\x09\x4A\x03\x49\x0F\x0E\x14\x15\x1A\x00\x10\x3F\x1A\x71\x5C\x5B\x5B\x00\x1A\x16\x38\x06\x46\x66\x5A\x55\x30\x0A\x03\x1D\x08\x50\x5F\x51\x15\x6B\x4F\x19\x56\x00\x54\x1B\x50\x58\x21\x1A\x0F\x13\x07\x46\x1D\x58\x58\x21\x0E\x16\x1F\x06\x5C\x1D\x5C\x45\x27\x09\x4C\x1F\x07\x56\x56\x4C\x78\x24\x47\x40\x49\x19\x0F\x11\x1D\x17\x7F\x52\x42\x5B\x58\x1B\x13\x4F\x17\x26\x00\x01\x03\x04\x57\x5D\x40\x19\x2E\x00\x01\x17\x1D\x5B\x5C\x5A\x17\x7F\x4F\x06\x19\x0A\x47\x5E\x51\x59\x36\x41\x0E\x19\x0A\x53\x47\x5D\x58\x2C\x41\x0A\x04\x0C\x54\x13\x1F\x17\x60\x50\x12\x4B\x4B\x12\x18\x14\x42\x79\x4F\x1F\x56\x14\x12\x56\x58\x44\x27\x4F\x19\x56\x49\x16\x1B\x16\x14\x21\x1D\x07\x05\x19\x5D\x5D\x47\x52\x60\x46\x4C\x1E\x1D\x5F\x5F\x1C\x15\x7E\x0B\x0B\x00\x49\x51\x5F\x55\x44\x31\x52\x45\x13\x1B\x40\x5C\x46\x10\x7C\x38\x10\x19\x07\x55\x13\x44\x56\x31\x1C\x15\x19\x1B\x56\x13\x47\x58\x30\x1D\x1B\x58\x55\x1D\x57\x5D\x41\x7C\x4D\x4B\x4D\x49\x4F"

# Generate offsets: 1 - 20 
offsets = range(1,20)

for o in offsets: 
    print("Offset: %d\tOccurences: %d" % (o, kasiski(hex, o)))

```

And the results:

```
Offset: 1   Occurences: 7
Offset: 2   Occurences: 3
Offset: 3   Occurences: 3
Offset: 4   Occurences: 3
Offset: 5   Occurences: 2
Offset: 6   Occurences: 5
Offset: 7   Occurences: 2
Offset: 8   Occurences: 2
Offset: 9   Occurences: 16
Offset: 10  Occurences: 3
Offset: 11  Occurences: 2
Offset: 12  Occurences: 3
Offset: 13  Occurences: 4
Offset: 14  Occurences: 0
Offset: 15  Occurences: 0
Offset: 16  Occurences: 2
Offset: 17  Occurences: 2
Offset: 18  Occurences: 4
Offset: 19  Occurences: 2
```

As you can see the most occurences have taken place when offset = 9. We can verify this finding by having a look at the 
JavaScript code above:

```.javascript
5 if(k.length == 9) { 
``` 

So the key length **has** to be 9. Okay, let's move on to the next step.


### Frequency analysis  

The big weakness of substitution ciphers is that they don't hide information about statistical characteristics of the 
originating plaintext. We can use this to conduct a [frequency analysis](https://en.wikipedia.org/wiki/Frequency_analysis) 
which will help us finally decrypt the text.

In the next step I'll calculate the frequency distribution of the letters in the encrypted text. So basically I'll count 
how many times each letter appears. Afterwards I'll compare this distribution to the letter frequency distribution of some
JavaScript library. 

#### Letter frequency for D3 (JavaScript)


I'll use JavaScript code (in my case [D3](https://d3js.org/d3.v4.min.js)) in order to have a good comparison (I suppose
the ciphertext is also some JavaScript code as well):

```.python
import collections
import os

def countletters(myfile):
    """ Returns a dictionary containing a occurence frequency of each found character"""
    d = collections.defaultdict(int)
    myfile = open(myfile)
    for line in myfile:
        line = line.rstrip('\n')
        for c in line:
            d[c] += 1
    return d

def get_letters_count(myfile):
    """ Gets amount of characters in myfile """
    with open(myfile) as f:
        c = f.read()
        return len(c)

filename = '/tmp/d3.v4.min.js'
freqs = countletters(filename)
file_size = get_letters_count(filename)

percent_freqs = {}
for k,v in freqs.iteritems():
    # Save ASCII code of letter and its occurence frequency 
    percent_freqs[ord(k)] = "{0:.8f}".format(v/float(file_size))
    
# For all other unoccured letters, store occurence = 0
for i in xrange(0, 256):
    if not i in percent_freqs:
        percent_freqs[i] = "{0:.8f}".format(0)
``` 

And the results (frequency (`occurences / length of text`) of every ASCII code (0-255)):

```
0: '0.00000000',
1: '0.00000000',
2: '0.00000000',
3: '0.00000000',
4: '0.00000000',
5: '0.00000000',
6: '0.00000000',
7: '0.00000000',
8: '0.00000000',
9: '0.00000000',
10: '0.00000000',
11: '0.00000000',
12: '0.00000000',
13: '0.00000000',
14: '0.00000000',
15: '0.00000000',
16: '0.00000000',
17: '0.00000000',
18: '0.00000000',
19: '0.00000000',
20: '0.00000000',
21: '0.00000000',
22: '0.00000000',
23: '0.00000000',
24: '0.00000000',
25: '0.00000000',
26: '0.00000000',
27: '0.00000000',
28: '0.00000000',
29: '0.00000000',
30: '0.00000000',
31: '0.00000000',
32: '0.01812754',
33: '0.00193988',
34: '0.00815033',
35: '0.00004708',
36: '0.00051322',
37: '0.00041905',
38: '0.00636583',
39: '0.00004708',
40: '0.04071399',
41: '0.04069045',
42: '0.00575844',
43: '0.00960524',
44: '0.04891611',
45: '0.00621987',
46: '0.03376902',
47: '0.00278270',
48: '0.01191709',
49: '0.01123437',
50: '0.00605507',
51: '0.00363493',
52: '0.00311700',
53: '0.00340892',
54: '0.00335242',
55: '0.00287686',
56: '0.00314525',
57: '0.00240131',
58: '0.00955816',
59: '0.00938865',
60: '0.00283920',
61: '0.04037027',
62: '0.00172329',
63: '0.00500038',
64: '0.00000471',
65: '0.00191163',
66: '0.00075806',
67: '0.00151141',
68: '0.00075806',
69: '0.00172329',
70: '0.00072510',
71: '0.00051322',
72: '0.00062152',
73: '0.00083810',
74: '0.00045201',
75: '0.00032017',
76: '0.00102173',
77: '0.00336184',
78: '0.00204818',
79: '0.00083340',
80: '0.00110649',
81: '0.00044730',
82: '0.00093698',
83: '0.00211410',
84: '0.00190692',
85: '0.00108765',
86: '0.00052264',
87: '0.00056501',
88: '0.00060739',
89: '0.00084281',
90: '0.00046614',
91: '0.01026914',
92: '0.00071098',
93: '0.01026914',
94: '0.00015538',
95: '0.00870122',
96: '0.00000000',
97: '0.03085449',
98: '0.00537234',
99: '0.02432387',
100: '0.01068819',
101: '0.05399653',
102: '0.02127750',
103: '0.00949695',
104: '0.01913044',
105: '0.03976759',
106: '0.00063564',
107: '0.00203876',
108: '0.02091024',
109: '0.00833867',
110: '0.06739679',
111: '0.03298271',
112: '0.01149804',
113: '0.00092757',
114: '0.04578499',
115: '0.02443687',
116: '0.07868295',
117: '0.03190447',
118: '0.00903552',
119: '0.00426586',
120: '0.00836692',
121: '0.00838105',
122: '0.00147845',
123: '0.01152158',
124: '0.00274032',
125: '0.01152158',
126: '0.00000000',
127: '0.00000000',
128: '0.00000000',
129: '0.00000000',
130: '0.00000000',
131: '0.00000000',
132: '0.00000000',
133: '0.00000000',
134: '0.00000000',
135: '0.00000000',
136: '0.00000000',
137: '0.00000000',
138: '0.00000000',
139: '0.00000000',
140: '0.00000000',
141: '0.00000000',
142: '0.00000000',
143: '0.00000000',
144: '0.00000000',
145: '0.00000000',
146: '0.00000000',
147: '0.00000000',
148: '0.00000000',
149: '0.00000000',
150: '0.00000000',
151: '0.00000000',
152: '0.00000000',
153: '0.00000000',
154: '0.00000000',
155: '0.00000000',
156: '0.00000000',
157: '0.00000000',
158: '0.00000000',
159: '0.00000000',
160: '0.00000000',
161: '0.00000000',
162: '0.00000000',
163: '0.00000000',
164: '0.00000000',
165: '0.00000000',
166: '0.00000000',
167: '0.00000000',
168: '0.00000000',
169: '0.00000000',
170: '0.00000000',
171: '0.00000000',
172: '0.00000000',
173: '0.00000000',
174: '0.00000000',
175: '0.00000000',
176: '0.00000000',
177: '0.00000000',
178: '0.00000000',
179: '0.00000000',
180: '0.00000000',
181: '0.00000471',
182: '0.00000000',
183: '0.00000000',
184: '0.00000000',
185: '0.00000000',
186: '0.00000000',
187: '0.00000000',
188: '0.00000000',
189: '0.00000000',
190: '0.00000000',
191: '0.00000000',
192: '0.00000000',
193: '0.00000000',
194: '0.00000471',
195: '0.00000000',
196: '0.00000000',
197: '0.00000000',
198: '0.00000000',
199: '0.00000000',
200: '0.00000000',
201: '0.00000000',
202: '0.00000000',
203: '0.00000000',
204: '0.00000000',
205: '0.00000000',
206: '0.00000000',
207: '0.00000000',
208: '0.00000000',
209: '0.00000000',
210: '0.00000000',
211: '0.00000000',
212: '0.00000000',
213: '0.00000000',
214: '0.00000000',
215: '0.00000000',
216: '0.00000000',
217: '0.00000000',
218: '0.00000000',
219: '0.00000000',
220: '0.00000000',
221: '0.00000000',
222: '0.00000000',
223: '0.00000000',
224: '0.00000000',
225: '0.00000000',
226: '0.00000000',
227: '0.00000000',
228: '0.00000000',
229: '0.00000000',
230: '0.00000000',
231: '0.00000000',
232: '0.00000000',
233: '0.00000000',
234: '0.00000000',
235: '0.00000000',
236: '0.00000000',
237: '0.00000000',
238: '0.00000000',
239: '0.00000000',
240: '0.00000000',
241: '0.00000000',
242: '0.00000000',
243: '0.00000000',
244: '0.00000000',
245: '0.00000000',
246: '0.00000000',
247: '0.00000000',
248: '0.00000000',
249: '0.00000000',
250: '0.00000000',
251: '0.00000000',
252: '0.00000000',
253: '0.00000000',
254: '0.00000000',
255: '0.00000000'
```  

### Split ciphertext into columns

Now the ciphertext will be splitted into columns:

```.python
def make_columns(text, key_length):
    """ Returns columns of length = key_length for text"""
    blocks = []
    
    # Divide ciphertext into blocks of length = key_length
    for i in xrange(0, len(text)/key_length):
        blocks.append(list(text[key_length*i:key_length*i+key_length]))

    # Create list: [[blocks[0][0], blocks[0][1], ...], [blocks[1][0], blocks[1][1], ...]]
    columns = map(list,zip(*blocks))
    
    # What about remaining text that doesn't fit into one block?
    if len(text) % key_length:
        remaining = text[key_length*(len(text)/key_length)]
        for i in xrange(len(remaining)):
            columns[i].append(remaining[i])
            
    return columns

columns = char_distribution(ciphertext, 9)
```

The columns will look like this:

```
1st column: ['+', '\t', 'J', '\x03', 'I', '\x0f', '\x0e', '\x14', '\x15']
2nd column: ['\x1a', '\x00', '\x10', '?', '\x1a', 'q', '\\', '[', '[']
3rd column: ['\x00', '\x1a', '\x16', '8', '\x06', 'F', 'f', 'Z', 'U']
...
```

Now for every column we'll try to decrypt every single character with every single ASCII code:

```
decrypted = []

for code in ASCII-code table:
    for c in ciphertext:
        decrypted.append(ASCII(c) XOR code)
``` 

Then using the **Chi squared distribution** we'll try to guess the right key.   


### Chi squared

In order to compare the letter distribution in our ciphertext against the one based on the D3 JavaScript code, I'll use
the [Chi-squared test](https://en.wikipedia.org/wiki/Chi-squared_test). The lower the value of the test, the higher the
probability that the decryption was successful. 

> You read more about this test and its application on this [site](https://schoolcodebreaking.com/2015/06/18/using-chi-squared-to-crack-codes/). 

Let's have a look at the function:

```.python
def chi_squared(ciphertext, freqs):
    d = collections.Counter(ciphertext)
    res = []
    
    for k,v in freqs.iteritems():
        c = 0
        decrypted = []
        
        for i in ciphertext:
            # Do the XOR operation
            decrypted.append(chr(k ^ ord(i)))
        
        for l in decrypted:
            # Apply the Chi squared test:
            # 
            #   sum = 0
            #   for every character c in s do:
            #         expected_count = length(ciphertext) * frequency_table(c)
            #         real_count = <number of occurences of c in ciphertext>
            #         sum += (real_count - expected_count) ** 2 / expected_count
            #       
            expected_count = float(len(ciphertext) * float(freqs[ord(l)]))
            real_count = float(d[l])
            
            # Avoid division by 0
            if expected_count > 0:
                c+= (real_count - expected_count ** 2) / expected_count
    
        res.append(c)
        
    return res
``` 

Calling `chi_squared` for 1 column will result in:

```.python

In: res = chi_squared(columns[1], percent_freqs)
    print(res)

Out:
[1204.0071598955076, 132.69115840125667, 156.88989851219517, -0.5120435, -0.31970324999999994, -1.20453925, 197.41879944181383, 151.8388795573118, 503.24009691571695, 411.65284864671304, -0.4913265, -0.597738, -0.442006, -0.9232095, 550.973125350628, -0.9422795000000002, -1.97554875, 112.91112495380644, -1.37063125, 253.89327851000215, 193.27461811570058, 240.8167847502026, 90.26352190725298, 113.79535634950395, -0.8113835, -0.38950650000000003, -1.1428595, -0.53958825, -1.13403175, 724.9582258341832, -0.7774827499999999, 336.2412614397023, -15.37686425, -13.009572250000002, 15.248560533383667, -7.447359500000001, 4.960532266691834, 18.985424033383673, -13.246172249999999, -12.268931749999998, -9.796406249999999, -10.96645725, -8.460382000000001, -4.980248, -8.065697, -3.6118532499999993, -9.84455025, -6.581239749999999, -3.999948, 17.86010353338367, 3.292327766691833, -0.45218773330816175, -13.234165249999998, -11.654832499999998, 5.558857766691837, -6.817603499999999, 35.232116300075496, -3.5466412499999995, -7.71868325, -12.425487750000004, -8.796331, -11.285571499999998, -4.20782625, -4.22630725, -0.87647875, 316.30210052362025, -0.641173, -0.8119722500000001, 191.54275272870169, 190.94972397870168, 548.681857770912, 232.7529211402615, 308.9709771145051, 77.55519354675381, 112.7322042038064, 41.02265209830615, 166.99850270400682, 204.15363525675696, 240.56747225020254, 898.424703306807, 107.35915740825043, -1.6951602499999998, 639.3337544274882, 191.29367522870172, -1.5721524999999998, 383.07185095740346, -2.52726175, -1.3689824999999998, 85.08040990669491, 156.5445342621952, 246.78820900076062, 477.2429975685118, 278.8510253123129, 195.35849744181385, 35.343556302750144, -1.16404675, -5.610121, -10.09044875, -4.324948750000002, -10.18779675, -5.821883999999998, -9.57581525, -10.021117499999997, -12.096838249999998, 35.22731731944197, -14.04272425, 105.1791471900786, -5.272878250000001, -6.86198075, -8.2800495, -16.013682749999997, -18.115417499999996, -4.6716092499999995, -3.1645502500000005, -14.291094750000001, -9.652209999999998, -14.05896775, -7.868530249999998, -3.6054972499999995, 240.36540654546903, -7.772713000000001, 58.91218238168983, -8.7063995, -11.287926749999999, -11.670488249999996, -8.546783249999999, 57.91177537119466, 82.03075531344567, 0, 0, 0, -0.00023549999999999998, -0.00011774999999999999, -0.00011774999999999999, 0, 0, 0, 0, 0, 0, 0, -0.00058875, 0, 0, -0.00023549999999999998, 0, -0.00011774999999999999, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -0.00023549999999999998, -0.00011774999999999999, 0, 0, 0, 0, 0, -0.00023549999999999998, 0, 0, 0, 0, 0, -0.00035324999999999994, 0, 0, 0, 0, 0, -0.00011774999999999999, -0.00023549999999999998, 0, -0.00011774999999999999, -0.00011774999999999999, 0, 0, -0.00035324999999999994, 0, 0, 0, 0, 0, -0.00011774999999999999, -0.00011774999999999999, 0, -0.00023549999999999998, -0.00011774999999999999, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -0.00023549999999999998, 0, 0, 0, 0, 0, -0.00011774999999999999, -0.00023549999999999998, 0, 0, 0, 0, 0, -0.00011774999999999999, 0, -0.00023549999999999998, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -0.00011774999999999999, -0.00011774999999999999, -0.00023549999999999998, 0, 0, 0, 0, 0, -0.00058875, 0, 0, 0, 0, 0]
```

For the test we'll take the lowest value and try to convert that to some character:

```.python
In: print(chr(res.index(min(res))))

Out:
o
```

Now let's apply that for all columns:

```.python
key = ''

for i in columns:
    res = chi_squared(i, percent_freqs)
    key += chr(res.index(min(res)))
```

And the key is ...

```
In: print(key)

Out:
Bobki2347
```

Hmmm...That looks promising. Let's decrypt the message:

```.python
# Adapted from https://gist.github.com/revolunet/2412240
def xor(message,key):
    return ''.join(chr(ord(c)^ord(k)) for c,k in izip(message, cycle(key)))

print(xor(ciphertext, key))
```

... and voila:

```
if(h == "XorTsCoolButSotUnbreavable") {=if(documxnt.locatton.href.tndexOf(""p=") == 01) { dochment.loc|tion = drcument.lrcation.hoef + "?p " + u; }=} else {= $("#crenponse").utml("<dik class='xrror'>Wrrng passwrrd sorry3</div>")& }
```

Well that's **almost** perfect! As you can see, although the key is not the right one, the decrypted message almost reveals the original
text (as I've mentioned above, polyalphabetic ciphers are not secure since even pieces of information about the key could reveal the message). 
However, from the code you can deduce that the key is `XorIsCoolButNotUnbreakable`. And that leads to the flag: `FLAG-rhwMJNczASAJ4WgwfIA7fcJD`.  

## Level 8: WTF Lol!

Yeah,  this challenge was a little bit like "WTF?LOL?!". But first let's have a look at the code:

```.javascript
1 function check_password(password) {
2    var stack = "qwertyuiopasdfghjklzxcvbnm".split("");
3    var tmp = {
4        "t" : 9, "h" : 6, "e" : 5,
5        "f" : 1, "l" : 2, "a" : 3, "g" : 4,
6         "i" : 7, "s" : 8, 
7         "j" : 10, "u" : 11, "m" : 12, "p" : 13,
8         "b" : 14, "r" : 15, "o" : 16, "w" : 17, "n" : 18,
9         "c" : 19, "d" : 20, "j" : 21, "k" : 22, "q" : 23, 
10         "v" : 24, "x" : 25, "z" : 26
11     };
12     var i = 2;
13     
14     var a1 = Number.prototype.valueOf;
15     var a2 = Number.prototype.toString;
16     var a3 = Array.prototype.valueOf;
17     var a4 = Array.prototype.toString;
18     var a5 = Object.prototype.valueOf;
19     var a6 = Object.prototype.toString;
20 
21     function f1() { return stack[ i++ % stack.length ].charCodeAt(0); }
22     function f2() { i += 3; return stack.pop(); }
23     function f3() { 
24         for (k in this) { 
25             if (this.hasOwnProperty(k)) {
26                 i += stack.indexOf(this[k][0]); 
27                 stack.push(this[k]); 
28             } 
29         } 
30         return String.fromCharCode(new Number(stack[ i % stack.length ].charCodeAt(0))); 
31     }
32 
33     Number.prototype.valueOf = Number.prototype.toString = f1;
34     Array.prototype.valueOf  = Array.prototype.toString  = f2;
35     Object.prototype.valueOf = Object.prototype.toString = f3;
36     
37     var a  = (tmp[ [] ] * tmp[ [] ] * 1337 + tmp[ "" + { "wtf": password[1] } ]) / (tmp[ "" + { "wtf": password[0] } ] - tmp[ [] ]);
38     var b  = (tmp[ [] ] * tmp[ [] ] * 7331 + tmp[ "" + { "lol": "o" } ]) / (tmp[ "" + { "wtf": password[1] } ] - tmp[ [] ]);
39     var c  = (tmp[ [] ] * tmp[ [] ] * 1111 + tmp[ "" + { "wtf": password[3] } ]) / (tmp[ "" + { "lol": password[2] } ] - tmp[ [] ]);
40     var d  = (tmp[ [] ] * tmp[ [] ] * 3333 + tmp[ "" + { "wtf": "g" } ]) / (tmp[ "" + { "wtf": password[3] } ] - tmp[ [] ]);
41     var e  = (tmp[ [] ] * tmp[ [] ] * 7777 + tmp[ "" + { "wtf": "a" } ]) / (tmp[ "" + { "wtf": password[7] } ] - tmp[ [] ]);
42     var f  = (tmp[ [] ] * tmp[ [] ] * 2222 + tmp[ "" + { "wtf": password[7] } ]) / (tmp[ "" + { "lol": password[5] } ] - tmp[ [] ]);
43     var g  = (tmp[ [] ] * tmp[ [] ] * 6666 + tmp[ "" + { "lol": password[4] } ]) / (tmp[ "" + { "wtf": password[6] } ] - tmp[ [] ]);
44     var h  = (tmp[ [] ] * tmp[ [] ] * 1234 + tmp[ "" + { "wtf": "a" } ]) / (tmp[ "" + { "wtf": password[4] } ] - tmp[ [] ]);
45     var ii = (tmp[ [] ] * tmp[ [] ] * 2345 + tmp[ "" + { "wtf": "h" } ]) / (tmp[ "" + { "wtf": password[9] } ] - tmp[ [] ]);
46     var j  = (tmp[ [] ] * tmp[ [] ] * 3456 + tmp[ "" + { "wtf": password[9] } ]) / (tmp[ "" + { "lol": password[8] } ] - tmp[ [] ]);
47     var kk = (tmp[ [] ] * tmp[ [] ] * 4567 + tmp[ "" + { "lol": password[11] } ]) / (tmp[ "" + { "wtf": password[10] } ] - tmp[ [] ]);
48     var l  = (tmp[ [] ] * tmp[ [] ] * 9999 + tmp[ "" + { "wtf": "o" } ]) / (tmp[ "" + { "wtf": password[11] } ] - tmp[ [] ]);
49 
50     Number.prototype.valueOf   = a1;
51     Number.prototype.toString  = a2;
52     Array.prototype.valueOf    = a3;
53     Array.prototype.toString   = a4;
54     Object.prototype.valueOf   = a5;
55  
56     Object.prototype.toString  = a6;
57     var m = a === b && b === c && c === d && d === e && e === f && f === g && g === h && h === ii && ii === j && j === kk && kk === l;
58  
59     var n = password[0] != password[1] && password[2] != password[3] && password[4] != password[5]  && password[6] != password[7]  && password[8] != password[9] && password[10] != password[11]
60  
61     return m && n;
62  }
63  
64  function btn_click(value) {
65     try {
66         if (check_password(document.getElementById('pwd').value)) {
67             alert('That\'s the flag !');
68             return;
69         }
70     } catch(e) {}
71         alert('Nope !');
72  }
```

In function `check_password` you have a lot of JavaScript voodoo which looks like some obfuscation techniques. I think the most important lines are 33-35:

```.javascript
33     Number.prototype.valueOf = Number.prototype.toString = f1;
34     Array.prototype.valueOf  = Array.prototype.toString  = f2;
35     Object.prototype.valueOf = Object.prototype.toString = f3;
```

By using their prototypes the behaviour of `Number`, `Array` and `Object` are changed. Every time these prototypes are being used `f1()`, 
`f2()` and `f3()` are called respectively. That means:

* every time a `Number` type calls `valueof()` or `toString()`, `f1` is called
* the same applies to `Array` and `Object` respectively

Later on the "normal" behaviour gets restored:

```.javascript
50     Number.prototype.valueOf   = a1;
51     Number.prototype.toString  = a2;
52     Array.prototype.valueOf    = a3;
53     Array.prototype.toString   = a4;
54     Object.prototype.valueOf   = a5;
```

In lines 37-48 we have some variables with some array operations, string concatenations and some arithmetics. For the sake of simplicity let's
have a look at variable `a`:

```.javascript
37     var a  = (tmp[ [] ] * tmp[ [] ] * 1337 + tmp[ "" + { "wtf": password[1] } ]) / (tmp[ "" + { "wtf": password[0] } ] - tmp[ [] ]);
```  

And now let's split it to its internal operations:

* `tmp[ [] ]`

We remember that the function `valueof()` of `Array` was overridden by `f2()`. `f2()` will

* **pop** some value from the variable `stack` (line 2) 
* increment some index by 3 (line 22)
* the **popped** value from the stack will be then used as an index for `tmp` (line 3-10)
* the return value of the operation will be: `tmp[index]`

Example: The first popped value will be `m`. The value of `tmp['m']` is 12 (line 7). So the return value of the first 
`tmp[ [] ]` operation will be 18.

* `tmp[ [] ] * tmp[ [] ] * 1337`

Here we have another `Array` operation, so the return value will be: `tmp[<popped character from stack>]`. Afterwards the two 
previous values are multiplicated and the result is again multiplicated by `1337`. In this case we have:

```
return value of first Array operation: 12
return value of 2nd Array operation: 18 (the popped value from stack is 'm')

The result will be: 12 * 18 * 1337
```

* `tmp[ "" + { "wtf": password[1] } ]`

Here we have: 

* an Object: `{ "wtf": password[1] }`
* the concatenation of an empty string `""` with an Object

In this case the function `toString()` of the Object will be called, which is `f3()` (see line 35). Now let's have a look at `f3()`:

```.javascript
23     function f3() { 
24         for (k in this) { 
25             if (this.hasOwnProperty(k)) {
26                 i += stack.indexOf(this[k][0]); 
27                 stack.push(this[k]); 
28             } 
29         } 
30         return String.fromCharCode(new Number(stack[ i % stack.length ].charCodeAt(0))); 
31     }
```

If we have an Object like this `{ "wtf": value }`, `f3()` will then increase the iterator (i) by the index of `value` in `stack`.
Afterwards `value` will be then pushed into `stack`. Example: If we had sth like `{ "wtf": "w" }` the iterator will increase by 1
since `w` is at index 1 in `stack`. Afterwards `w` will be pushed into `stack`. So far so good. 

However, line 30 looks very strange. If you look closely, the `valueof()` function of type `Number` is being called. This however
will call `f1()`:

```.javascript
21     function f1() { return stack[ i++ % stack.length ].charCodeAt(0); }
```

So you basically have values that

* get pushed **into** the stack
* depending on their index **in** the stack and some **iterator** return some values from `tmp`

After the calculations of `a`, `b`, `c` etc. the normal behaviour is being restored:

```.javascript
50     Number.prototype.valueOf   = a1;
51     Number.prototype.toString  = a2;
52     Array.prototype.valueOf    = a3;
53     Array.prototype.toString   = a4;
54     Object.prototype.valueOf   = a5;
```

Then you'll have some conditional testing:

```.javascript
57     var m = a === b && b === c && c === d && d === e && e === f && f === g && g === h && h === ii && ii === j && j === kk && kk === l;
```

The `===` operator will return true if the two operands have the same values and also the same type. As we can see `a` and `b` must be from the 
same type and have the same value. The same applies to `b` and `c`, `c` and `d` and so on. At the end the script will check if every single 
character in the supplied password/key is different from the other ones:

```.javascript
59     var n = password[0] != password[1] && password[2] != password[3] && password[4] != password[5]  && password[6] != password[7]  && password[8] != password[9] && password[10] != password[11]
```


### Bruteforce

I think the most naive approach is the bruteforce one. As an alphabet I'll use `abcdefghijklmnopqrstuvwxyz`:

```.javascript
var array1 = 'abcdefghijklmnopqrstuvwxyz'.split()
var array2 = 'abcdefghijklmnopqrstuvwxyz'.split()
```

Now we need to find all possible permutations (of 2 characters) between `array1` and `array2`: 

* aa
* ab
* ac
* ..
* da
* db
* ..
* zz


#### Bruteforce a and b

In order to find out for which combination `a === b`, we'll have to generate all permutations between `array1` and `array2`:


```.javascript
function allPossibleCases(arr) {
    if (arr.length == 1) {
      return arr[0];
    } else {
      var result = [];
      var allCasesOfRest = allPossibleCases(arr.slice(1));  // recur with the rest of array
      for (var i = 0; i < allCasesOfRest.length; i++) {
        for (var j = 0; j < arr[0].length; j++) {
          result.push(arr[0][j] + allCasesOfRest[i]);
        }
      }
      return result;
    } 
}

var array1 = 'abcdefghijklmnopqrstuvwxyz'.split('');
var array2 = 'abcdefghijklmnopqrstuvwxyz'.split('');
var tmp_array = [array1, array2];
var perms = allPossibleCases(tmp_array);
```

Next we can call `check_password` with every permutation. However, you'll have to make sure that only `a === b` is being checked:

```.javascript
[...]

// var m = a === b && b === c && c === d && d === e && e === f && f === g && g === h && h === ii && ii === j && j == kk && kk == l;
var m = a === b;

return m

[...]
```

Now we can bruteforce:

```.javascript
for (var i = 0; i < perms.length; i++) {
      var ret = check_password(perms[i] + "aaaaaaaaaaaa");
      if (ret) {
          console.log(perms[i]);
      }
}
```

And the result was: `dk`.


#### Bruteforce c

In order to calculate `b` and `c` we need the permutations between `dk` and every single character in the alphabet:

```.javascript
[...]
var allArrays = [['dk'], array2];
  
var perms = []                                                                                                                                     
var perms = allPossibleCases(allArrays);
``` 

Again the `check_password` function has to be adapated:

```.javascript
// var m = a === b && b === c && c === d && d === e && e === f && f === g && g === h && h === ii && ii === j && j == kk && kk == l;
var m = a === b && b === c;
```

After running: 

```.javascript
for (var i = 0; i < perms.length; i++) {
      var ret = check_password(perms[i] + "aaaaaaaaaaaa");                                                                                           
      if (ret) {
          console.log(perms[i]);
      }
  }
```

The result was `dkq`. 

#### Bruteforce d

We repeat the the previous steps:

* generate all permutations between `dkq` and every single character in the alphabet
* adapt `check_password` to return `a === b && b === c && c === d`

And the results were: `dkqa` and `dkqs` (pay attention that both combination were valid; actually there were several more). 

Since we got multiple results I had to change the code a little bit:

```.javascript
var perms = [];

for (var i =0; i < array1.length; i++) {
     for (var j = 0; j < array1.length; j++) {
          p = 'dk' + array1[i] + array1[j];
          perms.push(p);
      }
}
```

This time the result was: `dklj`. 


#### Bruteforce e

The calculation of `e` differs from the previous ones:

```
var e  = (tmp[ [] ] * tmp[ [] ] * 7777 + tmp[ "" + { "wtf": "a" } ]) / (tmp[ "" + { "wtf": password[7] } ] - tmp[ [] ]);
```

For the previous values `a`, `b`, `c` and `d` were calculated using `password[0]`, `password[1]`, `password[2]` and `password[3]`. 
However, `e` is calculated using `password[7]` and **not** `password[4]` as we would expect.  Therefore the javascript has to be 
slightly adapated:

```.javascript
for (var i =0; i < array1.length; i++) {                                                                                                           
    for (var j = 0; j < array1.length; j++) {
         p = 'dklj' + 'XXX' + array1[i];
         perms.push(p);
     }
}
```

As you can see the first 4 characters are already known: `dklj`. The next 3 ones (`password[4]`, `password[5]`, `password[6]`) are 
still unknown. So we need to find the 7th one (`password[7]`). And the result is: `dkljXXXj`. So `password[7]` has to be `j`.  

#### Bruteforce f

This time `password[5]` is required:

```.javascript
for (var i =0; i < array1.length; i++) {
     for (var j = 0; j < array1.length; j++) {
          p = 'dklj' + 'X' + array1[i] + 'X' + 'j';                                                                                                  
          perms.push(p);
      }
  }
```

And the result is: `dkljXuXj`. So `password[5]` has to be `u`. 


### Final result

Using this I was able to get 2 final results: `dkljtugjpfrw` and `dkljtugjpfww`. Since every single character has to be unique, the password is: `dkljtugjpfww`.   


## Level 9: Beauty and the beast

This challenge looks like hell:

```.javascript
var c8i=(function B(t,n){var E='',D=decodeURIComponent("%09H%5D%067NI%08Y%7Bi%1E%2C%14%1E%12%3DfNI%3E4Y%5D9%0A%25%117%06%0F%0AoUp%08%1A8%1D%10%3C0%0Fp1y%1Aq%07%16%1B%5D6%06Y%1A%5B%3F6%01%06%0D%176'5%12%12*2O%0CV%5C%22%16%1A%0A%1F%06%3C%17rGL-%00%00'%26%03_%22y%1Aq%1E%15%1DM0%3D%03%0AIi%22%1C-%1F%1F%0F%3B%3F%06KtxdU%1D'%3C%13HEU1%08%25%3D6X%023%00%0E%2FRL%1E%19E%12C%17*d%11%2F%1E%01%18%16%0B!%15R%25O%0E%06%11*r%1AMk%26%11%19I(2WCm%0D%2B%18%06eCm%0D%0F6B%18oj84'*d%11%2F%1E%03%18%0B%04)%15%09%24M%0E%06%15*%23rKs%261%1F%3F04%10%5D.%3A%157%05%04%14%60.%08Bml%1Ej%3C5%5E-C%0E.%16kO%0B%0CNeD%1A%09%3B)%0D%1B%3Dz%1A%0E%1F%1A'%06%04%1D%02%00%3DEbU%1E6%08o%7Fj%03_!%20N%00%0EH%5D%064%02%15Z%1Ck%7BL(%09%0A%03'.%5E%5Bf5BB%13%0C%23_XW40%1A%3C%11%2F7%0F%3B%1C%1C%18(p%17%1Au%00%26'%3Et%10-%26y(%1A%16%3C%0D%255%2F%1B%1F%5E%5Bf4S%40%16%03'%06HEU3!%25%20W%5Eg%08o%7Fj6_yi%08!%09%02%18_4%06%0ADY%7Bi%5CuVG%13%26%3F%106%3F%23XDFNz%3F%5B(03%00%245_%0Fw3%24%3C%3A1m%01%18My%15%1B-O%7B%11%3Ej%12%0A%2CA4!%25%22%08!W%0A%041DlU%5Eh%5D%2FI6DoUp0.*2xoxTR%20%2CZsDJ%01W%22NI%08%03%3B8%1D%3BFUX1%3F%00%02%3F!SBFNz%13%06%06%1F%00'%00%3E%0ENuQ%13oxTP)%20D%3BTXOf%09ZMj%16%2B%0B!%60P%25OqfNI%2B3TC%0E%10-%0D%13");for(var o=0,Z=0;o<D["length"];o++,Z++){if(Z===n["length"]){Z=0;}E+=String["fromCharCode"](D["charCodeAt"](o)^n["charCodeAt"](Z));}var i=E.split('<,>');try{eval(i[39]);return function(){};}catch(p){try{(function(){}).constructor(i[39])();return function(){};}catch(O){}}if(i[38] in eval){return function(){};}var v=typeof window===i[6]&&typeof window[i[40]]!==i[11]?window:global,Z7=function(O){return new v[i[12]](i[41])[i[14]](O)?O[i[42]](1,O[i[3]]-1):O;};try{(function R7(O){if((i[2]+(O/O))[i[3]]!==1||O%20===0){(function(){}).constructor(i[37])();}else{debugger;}R7(++O);}(0))}catch(O){}var y=(function(O7){var N7=function(O,p,K,N){switch(O){case 0:return (p&K)^(~p&N);case 1:return p^K^N;case 2:return (p&K)^(p&N)^(K&N);case 3:return p^K^N;}},k=function(O,p){return (O<<p)|(O>>>(32-p));},R=function(O){var p=i[2],K;for(var N=7;N>=0;N--){K=(O>>>(N*4))&0xf;p+=K[i[9]](16);}return p;},l7=function(O){var p=[];for(var K=O[i[3]]-1,N=0;K>=0;K--){p[N++]=O[K];}return p;},v7=function(O){O=O[i[24]](new v[i[12]](i[25],i[26]),i[27]);var p=i[2];for(var K=0;K<O[i[3]];K++){var N=O[i[5]](K);if(N<128){p+=String[i[4]](N);}else if((N>127)&&(N<2048)){p+=String[i[4]]((N>>6)|192);p+=String[i[4]]((N&63)|128);}else{p+=String[i[4]]((N>>12)|224);p+=String[i[4]](((N>>6)&63)|128);p+=String[i[4]]((N&63)|128);}}return p;},X=typeof v[i[28]]!=i[6]||new v[i[12]](i[29])[i[14]](v[i[28]][i[30]]),G=i[8]===typeof B&&new v[i[12]](i[31],i[26])[i[14]](B+i[2]),r=X,u=!new v[i[12]](i[27])[i[14]](B),K7=r?0x8f1bbcdc:0x10325476,Q=X?0xefcdab89:0x6ed9eba1,J=u,g7=J?0x6ed9eba1:0x98badcfe,W=G?0x98badcfe:0x8f1bbcdc,M=G?0x67452301:0x5a827999,z=u?0xc3d2e1f0:0x67452301,q=J?0x10325476:0xca62c1d6,I7=[r?(J?0x5a827999:M):z,G?(J?g7:0x5a827999):Q,G?(r?K7:W):0x5a827999,J?(G?0xca62c1d6:0x8f1bbcdc):q],V7=function(O,p){O=v7(p?O:O[i[24]](new v[i[12]](i[32],i[26]),i[2])+O[i[24]](new v[i[12]](i[33],i[26]),i[2]));O+=String[i[4]](0x80);var K=O[i[3]]/4+2;var N=Math[i[34]](K/16);var e=new Array(N);for(var I=0;I<N;I++){e[I]=new Array(16);for(var L=0;L<16;L++){e[I][L]=(O[i[5]](I*64+L*4)<<24)|(O[i[5]](I*64+L*4+1)<<16)|(O[i[5]](I*64+L*4+2)<<8)|(O[i[5]](I*64+L*4+3));}}var P=false,Y=false;if(typeof v[i[16]]===i[6]&&v[i[16]][i[17]]&&((typeof v[i[16]][i[18]][i[9]]===i[8]&&v[i[16]][i[18]][i[9]]()[i[19]](i[20])!==-1)||typeof v[i[16]][i[21]](1)===i[22])){P=true;}if(!u){Y=true;}e[N-1][P&&Y?13:14]=((O[i[3]]-1)*8)/Math[i[35]](2,32);e[N-1][P?15:14]=Math[i[36]](e[N-1][14]);e[N-1][Y?14:15]=((O[i[3]]-1)*8)&0xffffffff;var H=Q;var S=q;var m=W;var d=M;var f=z;if(typeof v[i[28]]==i[6]&&!new v[i[12]](i[29])[i[14]](v[i[28]][i[30]])){f=Q;d=W;S=M;m=z;H=q;}var F=new Array(80);var j,s,C,c,A;for(var I=0;I<N;I++){for(var g=0;g<16;g++)F[g]=e[I][g];for(var g=16;g<80;g++)F[g]=k(F[g-3]^F[g-8]^F[g-14]^F[g-16],1);j=d;s=H;C=m;c=S;A=f;for(var g=0;g<80;g++){var T=Math[i[36]](g/20);var p7=(k(j,5)+N7(T,s,C,c)+A+I7[T]+F[g])&0xffffffff;A=c;c=C;C=k(s,30);s=j;j=p7;}d=(d+j)&0xffffffff;H=(H+s)&0xffffffff;m=(m+C)&0xffffffff;S=(S+c)&0xffffffff;f=(f+A)&0xffffffff;}if(typeof v[i[23]]!==i[11]){return R(m)+R(S)+R(d)+R(H)+R(f);}return R(d)+R(H)+R(m)+R(S)+R(f);};return {a:V7,b:O7};})(B);try{var w=i[2];if(typeof v[i[16]]===i[6]&&v[i[16]][i[17]]&&((typeof v[i[16]][i[18]][i[9]]===i[8]&&v[i[16]][i[18]][i[9]]()[i[19]](i[20])!==-1)||typeof v[i[16]][i[21]](1)===i[22])){return function(){};}if(typeof v[i[23]]!==i[11]){throw i[2];}}catch(O){return function(){};}try{/Array.constructor.constructor/;if(!new v[i[12]](i[13])[i[14]](String.prototype.charCodeAt+i[2])||!new v[i[12]](i[15])[i[14]](String[i[4]]+i[2])){return function(){};}}catch(O){return function(){};}try{var x=0,U=23,l=[];l[x]=y[i[0]](Z7(y[i[1]]+i[2]))+i[2];var i7=l[x][i[3]];for(var o=t[i[3]]-1,Z=0;o>=0;o--,Z++){if(Z===i7){Z=0;if(++x===U){x=0;}if(l[i[3]]<U){l[x]=y[i[0]](l[x-1],l[x-1])+i[2];}i7=l[x][i[3]];}w=String[i[4]](t[i[5]](o)^l[x][i[5]](Z))+w;}var V=(0,eval)(w);if(typeof V===i[6]){for(var h in V){if(V[i[7]](h)&&typeof V[h]===i[8]){V[h][i[9]]=V[h][i[10]]=function(){return i[2];};}}}(function x7(O){if(typeof O===i[6]){for(var p in O){if(O[i[7]](p)){if(typeof O[p]===i[8]){O[p][i[9]]=O[p][i[10]]=function(){return i[2];};}else if(typeof O[p]===i[6]){x7(O[p]);}}}}})(V);if(typeof V!==i[11])V[i[9]]=V[i[10]]=function(){return i[2];};return V;}catch(O){return function(){};}})(decodeURIComponent("%10T%14W%00G%5B%0B%0C%10%18%18%11%02y%7B%07M~%00%5C%1EC%2C%03kf1%5BCyu%2C%01%7C%02%17J%14aa%02%7C%2BnXZ%07u%00E%13q%05%00qamZFmX%10%3Cch%242XY%5D%1F%01%3B%0DW%05%05a%5BQv%08U0%24Xw%0FQ%2BQiG%5C~%16%7FfAS%3AMY%20_%5C%09ONEq%7B%03%60%00N%5EHS%07v%5B%11F~yR4w%20Gf%5E%01%0DU%04%0EF%0AS%04cyWZ%17%17%7Fe%1E%01%07q%20%03Vq%40ZtS%22ZA%3A!O%2C%0F%02%0Cu%05R%05~%026jX%11QvFY-%0DNQ'FP%26'F%07A%0C%1AQF%0BQDZ%0C%0A%1E%18%1E%18%15%13%15%02%16%5CTFYV%5CB%07N%1A%1A%17%19%14EB%19AB%11%08H%5DE%00U%18%10%11%11UM%5CWLPWY%11U%1CJ%1E_FZ%00%15X%0EX%11T%18%18%1F%40%1Dn%17%10%15%14%19%19CCD%19FE%17CGM%18NC%1C%17%18kE%19BB%14%12%11%16%14%12EC%19A%16CD%1A%03BWRM%5E%0C%08%13Q%19%08M%10L%1B%1A3%12C%13C%17%13B%16%19%12%15%15%16%15%14%14%10%15%10%18%10YVM%1DDB%1D%1A%0BMZ%1F%1C%16T%5D%08%05L%5C%17%16%5B_%11%08E%1E%1EEZB%15F%02%08%10%5E%0D%0A%18%03%1AC%19A%13n%17%18%12A%11%18%12%17%12%15%11%11C%11%10FDF%10%15EA%15E%17%19%04EXU%16%0A%5CY%1BLKN%18%19RW%5B%11CFG%00GY%13%1F%15WWSM%05%05RA%17%1FJ%18%09%40%1A%3B%14F%18DA%16%18%11%11F%17E%10%17F%19A%13%10B%16HEUYD%07BK%16%1F3%19EF%11B%11%10F%11F%11F%12%15%17%12%19%12%17D%11%11%14%18%17S%06R%11%02%04%04F%03%13HiD%19CC%18%18%17B%17%18%14F%15C%17EFD%16%13%10JDO2%17%17%19CD%13%12F%19%16BEC%11%15F%13F%10%12%13S%11IM%5B%1F%5E%10%1AoB%14C%19%10%18%16E%10%16%15%14D%17%19%15FK%1F%09M%1ED%1BiF%18D%16%15C%13%15%13%15%17%10FL%10%02WFQ%0CJP%1F%13%1E%07HD%07B2Q%5BP%0C%10%15%11%03%15%12%0D%02%07%06%1AN%1A%19%3B%16%11AE%13%13%13E%1BH%1CM%1EM%1F%19R%09PF%08U%5B%15O%00%0DU%40JVII%5C%0DTu%0D%0F%0AQ%11%07%09U%10Y%5C%5CBHRE%04%03%12%03%26%08%04%5DQ%0BD%1AA%04%16%04Z%03%15%19%1BK%07X%0BM%5C%0B%162%5E_WY%15K%0F%16HXD%13%13FH%03BFFE%40%17A%14%1D%15%12%13%19%14B%16%0F_%17%10%16I%16%5C%0E%5EBCX%5C%02V%12A%04Y%08B%12%5E%01%5E%5CZ%15%11F%1F%13%19ANC%07Z%04%10B%0FZ%01%0B%40%16Q%0AU%17LC%0A%5E%0EE%1F_L%0D%01FQW%5C%1E%19BH%14%16%13BF%11%12B%13FQ%00%1E%15%1E%07B_%1F%0D%11XRI%0A%15WRMXH%0D%5C%0BP%16Y%1E%16%07%40%10%1C%5BVGYS%00F%0E%17%1A%14%5CW%16%07%5DGU%1BH%19%18%13%12DB%18%11C%16%13%17%12%12%14%13%0FTL%5D%0BUD%5B%03%5ED%1BQ%0ASM%18BBD%10%13%14%11B%14%13%17F%19%12%12D%14D%10%10R%1F%1A%08%17%14BF%15%18FE%14%12%16F%18A%19%13P%5BDT%15NA%14BE%19%14FFAC%10%12%13%13B%18%11%13B%0A%5BP%0EC%1C%5EVTYVU%12%09EX%08%18%17%11%13%11D%15%12%18CE%12B%17O%11%18E%14E%16%14F%12AJ%12%14%14FF%12%10%1B%13%12%19E%1C%14VRAT%0BK%06%1EB%1FK%18J%1EK%0F%11T%17%40F%0D%12OEE%06%11%0B%03MW%5B%17_%0C%0DJ%7D%1C%16%1EIEV%11GB%5DC%2B%08%0F%5BH%0EN%3FHDf%0E%15%0A%1Bm%09DJ%14%18%0Fv%13_%40P%0F%11MY%0A%5BVC%15%16Q%07%1E%09%5EGZ%5BMQXW%1Bz%1DF%10HF%06%15D%13X%11z%0CA_%1F%3CH%10Z%02%13%03_%16%0D%07M%0F%0A%5B%1F%1COK%40%07Q%5E%40%3APd_%11ATW_LiU%3E%13%12C%05%00%5B%1Dl%08l%02JiJ%14b%05F%5EVBWRM%5B%0C%5DKx%1F%12%1FB%40PACGZ%14%7F%09%0CH%09M%3AI%12%19R%11%08%04%17%5DUAQWVN-%14D%1EL%14%07EL%17%0CB*O%12%0B%1B%3A%14%17%20%09%10%02%11qANDZU%10%02%03Q%1D%1FJ%06%15%0F%00%04O%16wVC%5CV%40%0B%02A%0CZ_J%7F%1AFK%18ARG%10B%5D%11xMH%0E%1F%3D%18%15%1B%05%11%5BQG%5DQEQ%0D%0C%1F%7C%1CFKJ%40%07EDF%08%18%2B%5DF%03L%3BJ%10%0D%08xA%03C_%5B%15X%5EG%1C%12GQE%0ARAWZ%11%0F%5E%0C%19%7FJAOJ%14WAB%40W%12xY%0CA%0FE%3F%1BDdS*D%5B%16KT%00%0C%0A%5D1%0CMVS%40%1B%1FyP%12YQ%10%08%07BZ%5DYN%2B%14G%1EB%11%01GG%14W%16-Y%13%0AHl%1FAF%00%16%0B_%17%08QB%0C%5D_M-%18%13%10KJS%11ED%5B%14%2B%1AI%0E%19%3C%1B%1E%3C%05A%0A%05%13V%07B%5C%0C%5D%1D%7C%19G%19%1FCU%15C%40%5CD-%0B%0BC%5E%1Cl%1BEPR%1F%0CS%16%0B%02M%0BV%5C%10%7D%1BF%1AHJWECC%0FE%7C%19C%5ED%3F%19BY%07y%16%0CA%0E%14I%17VTFX%04DW%07CPVWK%7F%1A%15J(%1CB%11%03B%10FW%12yX%0F%09%11%5EZ(X%19k%1C%13-%06%15%5C%04%11%0BT%12%5B_%5CM%2B%1B%15%10B%17%07%11BC%5D%16-%5C%0A%0A%11X%199%1FAo%08E%5C%00%10Z%06L%5D%09%5B%1A%7C%15DKM%14%5CCM%10%5EFv%5DHYI%3B%1EA%7BW.%1E%5E%175ZC%07uKK%00OD%15%12R%02x%14X%17%10QBD%18B2%0F%1F%0A%00E%0B%5B%17%5E%0C%5DMw%15IJ%19%40%5DLGK%5EB%7CHF%08%1Fl%1D%15-%01)%1F%5C%14kU%07DSAHFm%0E%12Y%03MXREQ%0A%5DMz%15%40%19%19%10V%10AGY%11%7F%09%5C%0F%11%5EIn%1C%11%25W%15%0F%5EG%0FZ%17Z%5D%0AJw%1D%13%1FHEWFAA%08%12%2B%07Z%08A%0D%1B%3A%1C%12%60Q%10%0EW%17W%07DZ%5B_J%7B%1FGOB%40W%10A%16%5E%10%7C%16%0EC%0CIhJ%12RQ*%13%08P%07T%12%01%1F%12V%07%16%0FS%14Z%01%11P%5B%08N.O%40%1BHA%07LDA%5BCz%0A%11%0FO%3B%14%1F%5E%02%16%08R%10WPL%5E%5E%5D%19%2B%19B%11%18%17W%16B%40_%18*%1E%15%0DIl%1EFB%00%13%0E%00%13%5CS%12Z%5DWM.%18E%1ANE%06%17%16E%0CDyX%5E%0B%12%0F%1E%3BO%12%5CU%15%0E%04G%5EUE%0CWW%10%2C%1A%13J%19%40U%12B%40Y%13*%0E%0CCX%19%3C%1DB~%02%7C%12%5EAy%04%10%1C%1EhU)A%09CBJQ%17%23%5E%04%0CM%1AH%1FkR%1E%0B%0B%01%15%14i%01%13%02%08%14%10z%03%12%0BPL%5DW%17%08%5E%0F%1E~%19%40%18%1F%10S%10BB%5B%14vE%13X%193JB%60%02%12%0E%5E%40%0FTCQ%0E%0B%11-ND%1BJDQF%10%11WAy%5E%5BB%5EJ3%1D%1EXSA%09UD%0F%07D%5EV_%11%7DOCJLA%07BL%40%5B%15yID%0FM%3F%1C%1FB%01%17_%0DOBB%00EXUC%5B%5BLQ%09%0C%10%7B%1BGO%19C%5C%11%17%10%0B%13-%0E%5B%40%03Mi%1C%10z%0B%14Y%04%16V%07CQ%5D%0F%19w%1EG%1BNCT%17DB%08D)%16E%5E%1C%3FI%12~R%17%0CP%17%0DPCZ%0A%5E%1B~%1BA%11N%10R%40G%11%5D%16.%18B%08O%3B%14E%2F%00%7C%17%0C%40F%5D%10UB%16J%1F5Y%11%02WD%08T%11YX%08%11.%1F%40KOG%00D%40E%0CB%7F%0A%09I%02%18l%1DEB%03A%0BD%02%0AY%01%04%5ER%06%04F%1D%16q%0C%12%0D%05E%0A%06%17%08%5BV%19%2CO%14%10%18%11%5DLB%10Y%18%7BX%0B%5DG%5E%1Bn%1A%14x%00A%5E%5EBYZ%17%0D%5C%5CNv%1A%12L%18CP%12F%14%5E%12~%0DIY%1B8%1AB~%02BX%16A%15%17b%0FB%0A%14V%5C%01TRs%0DDDMF%1BA%7C%5B)%1F%5E%14R%06G%17%1F%12b%00C%0BV%14XQF%0D%0D%5B%1E%7CI%11OL%10S%12MD%5BC*LIYD8%14%15n%06%14%09%5EG_UE%08%0A%5D%1B%7CII%1CN%17RDCCXF%7CO%15%0BHkME2%03%1E%5EQLWZ%17YY%0BN)%19IJ%1DD%00%40L%40XF~%11%11Y%1BlOC%16%00%13_VG%08%01%10%0CX%08%1A%7F%1E%15HyLBK%00%16%10E_%13y%3C%12jzZ%1En%1F%14%00%07wE%5CD%0CY%15WF%12%17%1E%14P%03-%11%5C%0D%05%01V%09P%0ES%01T%18%16DQvB%5B%1B%07Y%0D%5BTA%18%1ENR%11%5C%1B_V%5CY%11N%126%03%12%5C%01ICS%08%17%5CV%10V%00C%0A%5C%0B%10v%15%13KIJ%5DFLB%0C%13%7BJCY%1B%3B%1EEqA%02%00CZR%12Y%5D%0DL.%10Ms%0F%04K%5EuTL%00P%11n%1Bzc%3D0v(qtdt%12i%5C%7DZ%18%3EH%17bVF%08SM%5C%02M%0A%5C%5CL-%14AJMARFGF%5DF%7DXI_K%3B%1AAu%05%12%09%03BZR%16P%0B%5E%1B%7B%1D%12%1DHE%03MG%40%0A%14%2B%0D%0DC%0CN9%1B%13%10R%12%02%00%10ZQB%0FW%0FL%7C%19G%1EJGP%15A%10%0B%19%7BXX_%13%0BO9%1FEJ%06%14%0F%05%40Z%02%40%5B%5EV%10y%1BA%1BO%17%5CGME_%13~XE%09EiI%15)%0F%7D%16%02GQ%1DBQ%08VC%1B%15x%0CA%5CTE%08PFP%0A%0F%1Cz%1FE%1E%18%11%06C%17%16XE%2CJ%12%0F%1E%3BO%12xU%15%0E%04G%5EUE%0CWW%10%2C%1A%13J%19%40U%12B%40Y%13*%14%40%08%1En%1A%16%14%0A%12%09S%11%0DQC%5B_W%1A-J%16%1A%1AE%5C%40%10%10WA-%04%05%14%03Nk%15%16%7B%05%1E%09%5EGZ%5BMQXW%1Bz%1DF%10HF%06%15D%13X%11z%0CA_%1F%3CH%10R%01%13%03_%16%0D%07M%0F%0A%5B%1Fz%18H%1C%1AERL%14%17WB-%08B%0AK%3E%1EB3%0AF%0CQR%1EBS%0F%16%03Q%16%08PGX%0E%0A%18x%15A%10I%11V%17BA%0C%16v%14E%0EK%3F%18%13u%02%17%02TE%5E%06A%0A%0AX%1A-NC%1FNJ%5DL%13%10V%14xK%16YL3IE%0EQ%14XV%13%5E%5BD%0A_Y%10%7C%1F%13K%18J%01CM%40%0F%11w%0CG%09H%3B%1DDr%08A%5E%00E%5B%06%15%5C%0A%5B%19-%1CF%1A%2CJHEV%11EA_%17~DE%1Ey%0FOi%1F%11%23%06%15%09%10RP%03%10t%5CTS%23E%10N%16Z%06A%02%02%14X%5BEX%09YM%7F%1B%16%10%1AAU%16AG%0B%10z%11%12YM%3E%18%1E%5DWA%0B%04D%5E%05E%0F%5E%08%1Az%1BB%10IE%01EDFV%15xF%40_%18iM%13%7D%02DYP%15D6%0F%1F%0D%04BVW%12%5C%0CYM)HF%1AIE%03%10MEY%19%2C%18C%09%1B3%1AE%0FR%16%0FDl%08tSEP%7B%1B%12WEG%1E%16%02Z%7BD%03%5EMZ%09%1C%11M%0CC%0D_%40%0AUCP%0BYN%7FO%16%11%1FDP%17FG%5D%15xL%14%0AMk%1A%15SRE%0FPF%0B%02%12%5E%0DXNw%1AEJ%1E%13%5C%16L%40V%12x%0AC%08E8%1D%11zTB%09UF%0BZA%5C%0AY%18y%1DFOHA%00D%40%13%0FB-MI_J3%15%1E%08%09%11_D%0B%5CWAJ%11%16%00%1E%08P%13_T%15%0B%09%08K%2BM%40%1D%1EBW%12%17%16%0B%17)%0C%0E%0C%15_Jo%15%1E%13RB%0DWFX%01%16%5D%5B%0FK%2B%1FCONJ%07%12%13%17ZEw%19%16%0EO9%15%13%1B%05A%03%01%14EJ%5E%1E%5B%5E%17ZRF%0FV%0BIvHEKNC%06%40LK%0F%16)%1FE%02H%3D%1FEfZ%7F%12%5C%16%0E%08D%5CC%0A%5BW%1AO%10%04%07B%02_L%0D%01FQW%5C%11%7FNC%1DMA%07%12D%40%0C%13)%04%16%0DI%3BJ%17JVC%5B_C%5B%00%11QY_%19wICLNKUD%17%10%5DD%7B%0BG%0AM%3EM%159%5D%7BC%0A%14%12R%10%19%1FfV%1EYUG%0A%01LX%0CX%1Bx%1EB%1DH%14W%10L%16X%11y%1A%40%0BH9I%10~%05E%03%02E%5DWE%0B%5B%5D%1F)%15B%1B%1FF%01DEAY%13%7C%09%0A%5C%16%0EElI%13P%0EA%02%07%11%5DVC%5E%5E%5B%1D.%18%12LBF%03%12%14%11%5E%12%7C%0D_H%0AN%3FO%12%5ET%13%08WMVUCX%5DZMv%1FH%1EJAT%10%40%40VC*%18%12%0CO%3B%14B%5CU%11%0E%00G%0FTF%5D%5B%08N%7D%1C%16%1AIK%00%15AG%5D%15x%5D%13XJhH%117W%11XR%16_%00A%5D%0C%5C%1C-%1E%40%1FJ%17%5DMM%11XC%2C_%0F%40%5DJ8%1B%14%3C%07%17%09%05%11XR%11QZ%5D%1D%2BOB%1EIB%5CF%17%14%08%13.%1DI%0F%18h%15F%18%0D%1F%5E%5EF%0FZEQ%5CW%1Bw%1ED%11BJRMFG_%16v%0FDX%1C%3BM%11V%02%7F%16%5E%40~%05DXPF%1B%15D4T%1E%5C%03%40YV%40QZ%0F%1Fx%14%11LB%10%07%40GCX%14%7DC%13%02%1C%3COAjRx%1E%0B%1BS%02%12R%11%1DF(%05%10%03WL%5C%00G%0AX%5DJy%15B%1CNDP%40AB%5B%10wN%40%0B%18%3FOBx%06EXUC%5B%5BLQ%09%0C%10%7B%1BGO%19C%5C%11%17%10%0B%13-%0E%5B%40%03Mi%1C%10b%01%14Y%04%16V%07CQ%5D%0F%19w%1EG%1BNCT%17DB%08D)%16E%5E%1C%3FI%12SU%17%0CP%17%0DPCZ%0A%5E%1B~%1BA%11N%10R%40G%11%5D%16.%0BB%08O%3B%14E%2F%07%14%0AP%17_Q%16X%5EZNwH%11%1FCCT%12B%17%5E%17)%07%11%08Mh%18%12%15%07z%10X%40UFFVKK%0CB%40%1D%17%11%08A%0BDPP%07%0A%0DTT%02%01W%05%00%0D%01TT%00SRRU%5E%08Z%00%5CZ%05%05%0D%0AU%06QY%02V%06TQGJCD%0B%7D%10%5CF%5BXYJ%0C%08V%10J%1E~ZBYW%40%08P%12Y%5D_%19vN%16%1BM%17WE%10%10ZCvLH%0D%18%3A%1A%12%7FR%10%03S%11XTM%0DX%08%18%2CJHMMG%06G%40A%5B%17%7FXA%0B%1C%3C%1E%15*Vz%11%09GPH%07L%02D%14%11%7DVB%5B_%17WQL%5BXX%1B%7C%14B%1Dx%1D%17LHAV%11LG%5BExnFox8E%08%18%3A%19F%0C%5BE%0B%1B%3BGKVZ%06CEGJA%7C%09D%5CP%10ZZF_%09_%1F.N%16O%18%16%04DA%17%5E%12)H%14%5EJl%1E%17tQC%0D%03LW%06%16%0CX_%1ByN%12%1DO%13%06%10FA%08%15w%5E%16%5D%18%3EI%1FqTz%15%09%1BU%0EQ%09%1B%1B%1F%17%03A%03R%14E%7F%02%15%5C_%10%0FZ%10%5C%0D%5B%19%2C%18I%10%1AD%03M%40K%5B%17%7CC%08%12%0BHl%18B%2C%05%1F%0A%00E%0B%5B%17%5E%0C%5DMw%15IJ%19%40%5DLGK%5EB%7CHF%08%1Fl%1D%15%2B%01A%02%00CZR%12Y%5D%0DL.%15F%1C%18%17%5DBDCVE%7C%5B%0B%07%40%0B%1Fh%1FCP%0D%10%0BVA%0FQ%15%0C%5B%0A%18yN%11%1BNJW%15L%11%5D%12%2BGH%0A%1E%3C%1F%10B%04%13%09%00G%0AZ%10_%5EXN%7F%1CE%1A%1EEQE%17K%0A%10%7C%1BAYI9%1BAs%03%15%5E%16%0D%5EYG%15%1F%14b%00E%5CSM%08%06%40%5BY%08%10.HC%1CLETA%40%13ZB*%05%08%16%5D%1Ci%1C%15%5B%0AE%02%13%40%5C%04wM%15QA%13%14%1Ft%00%16%08R%10WPL%5E%5E%5D%19%2B%19B%11%18%17W%16B%40_%18*%08%15%0DIl%1EFt%00%13%0E%00%13%5CS%12Z%5DWM.%18E%1F%7B%1B%15J%18E%07%10C%17%0D%16-H%13M-IBXO%3EN%15%7F%0F%16_%1A%7Fy%2Fe%26AN%15rR%10%08QF%0BQDZ%0C%0A%1E~IH%1CHG%01%17GE%5C%10v%17%12%5D%1B9M%10%40%06BX_%14%0CZL%0DW%5DIv%1DH%1ABA%5DFAJW%18x%07%0EE%0AK3%1F%13%00Y~F%0C%13VQ%5D%07%17Z%05CU%17%18%1EnUD%5E_%13%0BVC%5C%5BV%1D.%1BG%11%1A%17%5C%16%17F%5C%11y%12B%5E%1E3M%11%26%5E%15_QL_ZC%0A%09%5D%1B~M%14%19LKTMG%11%5DCx%0E_F%02O%3F%19%11g%0C%7B%17%0F%12%5C%5DwU%11%17OBF%00-E%09%14G%5DHT%07%01%5D%16%1B%10%2BW%16%03%03%17%0C%06G%0B_%08%18w%1C%13%1Cy%11HA%06%16%16J%0A%17w%0C_%0FH%0E%0B%7C%0EL%3BO%16rQ%2BA%0A%17%06%00Y%09%17%1DEd%03%11X%05FYP%11Y%5C_%1F~%14EKLFW%17FD%0F%17%7D%1CB%0AEhN%10C%05%11XWG%0CRE%5D%09VL.%1AH%18J%14R%11EE%08%19.%1E%40YI%3FI%17E%0FEXVAZZM%0C%09_J~%1C%16%18%1DC%03F%40E%5C%19%7D%1D%14%0AL%3E%14%12R%5B%7FC_%17%13A%5D%1DD%22%5D%1EYALWd%16EQZ%01%17O%103SC%0CUGY%05%10QXY%11%2CHC%1B%1DKS%16%10%11_%15)O%16%0BO%3B%1D%1E(%5E%15%0C%03G_%06%16%5D%0CW%18w%1A%15%19MGQ%10BK%5BDy%09%07ZG%5DMiJ%1F3%05%12Y%01%19%14P%0E%17%5E%13%5C%04XUF%0C%40%19%11RPF%5CQ%17X%05L_Z%0DM.%15%12%10IJWCCA%5D%18%7D%0F%08%0F%11%5EN9%1FBU%07zB%0D%12SIU%03CG%0C_%5BCME%16%08%1E%5E%15URJ%0F%5B%5CP%0A%0D_%1BOAX%5D%7B%1E%08%14%03_T%0E%06%03DOC%20%02%13_VG%08%01%10%0CX%08%1A%7F%1E%15ML%17%5CM%10%10%0B%17~%0D%08%5C%12%0FIkOCA%0BA%0F%5E%17%08%05%11%5D%0AV%1C)%19B%1ABF%07B%13KY%18-%16%16%02%1C2N%13%60%05A%03%03%14W%07A%0BZ_K%7B%15IHM%14%5CALGY%13-I%12%0BHl%18B%01%05%1F%0A%00E%0B%5B%17%5E%0C%5DMw%15IO%2C%1BCJWME%10%5D%14yO%12%1A%7F%09%1F9J%1F%08%00%13%0B%00E%5C%00%10%08VX%1D%2CIH%1FJC%5D%11F%17%5B%19%7F%0C%5E%12%08%19%3E%19%10u%06%13%5BT%14%0BW%10YY%0CI%7D%19H%1B%1AK%06GG%16%0C%18~IF%08J8%1E%13rU%15%5E%1B%0DXBB%07%5C%5CPWG%1B%13dZ%1E%5EVFZR%16%5D%5CYNv%1EBHzHF%19HEVGBF%0CFzD%16%19zN%40%5DEkH%14G%0E%10%0B%17S%13%5B%0F%26QU%14%25%0E%07U%10%1F%14%17%00~%14%0FA%60%01C%18%15S%0Aw%11%0D%13T%5D%17%5CQMP%13%1F%16%3D%03%15%02%05%10%5C%01C%5B%5EVM%7BIF%1D%1D%40%04CGFZF)%1D%40%5DN8%15B%03%07%12%09%17%40%0F%06A%1BE%01%07BY%07T%18Dz%5B%12%0E%05GZ%01FYY_Mw%15HJM%11%06%16GB%08%17%7D%1AC%5EO%3A%1FD%01%06%16_%5E%40%5DV%10%0A%5DY%1A%7F%15BK%1D%14V%15BKZE-E%11YD2H%1FFX%1E%0B%1AY%0E%11%14%15b%0E%1E%02QL%5DVE_V%5D%1C%2CMAHMCPDD%16%0C%16%2BK%40%0EI3%15D%12W%1E%5CU%19%10t%0Cw%12%5B%15%5BQ%03G%15E0%06%7D%16%0C%16%1C%0F%10%1BM%11-W%15_%15jyx%06AJ%14u%05.C%0A%1F_DWQ%17Z%0CY%1B!%02v%1BNGSAAF%5E%15%18%5EG%5ES%11%5C%0C%0B%1EpV-%1Fw%01w%11C%14%07LAEYFJWL%0B%01%16%0C%5C%0C%186%04w%19%18BRLFA%0DB%18WPx%02bU~%14P%03%7D%0Fa%05%2C%1DMl_%1B%3A%1CM%07%40%0BVE%0B_X%1E1W%7C%1EH%13QA%11p%05w%19%0F%03%7B%0FS%08P%0EE%1AESC%18%0AVx%0Er%02-%0A_V~%0DgRw%3FCZ%5D_V%12_Gm%0C%0B%0D.%18%1BKOC%04B%15%7DV-%0Du%00v%116R~N%5C%04)%18%5DvR%7D%08Z%06v%0F%0AY%01%0E~%0Cz%0D%24%04%2B%3B)U%7B%03Li%11%01M%16%11V%18pVx%07%5CRzY%16%0DR%2B%0DN8%1E%5D%192%1E%1F%11%05%11%5DQ%12PY%0CM%10%05zJUR%7F%1EU%05vN%05%06yLIG%04%10%14%09%0D%7F%05%04S%0BDP%40%11EW%15%17%02x%11'%03)%1C%09RwM%1BVW%7C%1DU%01x%1C%00%05%7FH%08X%06%2BYH%3C%1AM%11%07E%11S%2FVB%19'%04%15%5CN%11TM%5CTBZ%5CV%1AW%02~H%1EAVG%10K%5B%15M%10%17%1DW%02)%1AhGC%40%03%12%16%10XW%03%15d%11%08O%18PQ)M%12%1EJ%3D%14%09QWUB%0E%13jLSO%5D%1EnH%18%13%3AWW%126%0D%08RT%15%19%1E%03%11Y%06MP%0A%0CMQ%05%7C%1A%06V%7B%1D%1A%11%01GF%14%5B%18%0C%03%11ERQw%1COnV%07viJ%1F%5DD%3D%11NV%13W%02L%0B%5B_%1A5%0D*MTPzKNG%02F%19qUy%5BITKFRz%0CAJc%01)oG%07_YB'DGeKZW%7CL%14%08%0FJ9%10LWaMB%0B%5DS%14nJT%18%09%10V%12M%14X%14yR%7FiA%07%09XDt%17Ge%1Ey%05w%3E%11%09PWWD%0A%40nI%05%1C%0CL%3A%1DZOkL%1CC%06Y%06%03V%04%5DWU%1EJ%1F%15!R%1F%0B%05C%5DTF%5B%5B%5DN%7DHIMMCS%12EB%5B%13*%09D%0A%1F3H%17k%0D%16X%16_%5CUUYXW%16H%17g%06%10%09UBZ%01%12%5CW%08M%7B%1EFOC%13%01G%40EY%11z%09%5DDY%183Il%5DF%19jVw%076r%7DXB%14F%5D'vK%5CTKos%7CPD%07%5EET%7D%5Bex%22Pe%7C%24%2FX%06o%0Ba%7F%07P(%01u%3F%04)%0FUG%40P2%0A%7B%0EduW(%14Bzxlb%2C%0D%05%02%3A%14c%3F%01W%14%7F%2C%5B!xx%1Bfg%12ECOK5%5EQZ!%0E%26%12%13_Z%24VY%7DQ%04W%17%08%1EM%1E%18%5E"),"htq8Ure6eWWrIzyfUZbwXF60zbDctikoSyNkrYoSSTj1EE6O");c8i.G6O=function(b){for(;c8i;)return c8i.F4O.o4O(b);};c8i.C6O=function(h){if(c8i&&h)return c8i.F4O.o4O(h);};c8i.j6O=function(e){while(e)return c8i.F4O.o4O(e);};c8i.f6O=function(e){if(c8i&&e)return c8i.F4O.o4O(e);};c8i.m6O=function(m){while(m)return c8i.F4O.b4O(m);};c8i.S6O=function(n){while(n)return c8i.F4O.b4O(n);};c8i.H6O=function(g){if(c8i&&g)return c8i.F4O.o4O(g);};c8i.o6O=function(h){while(h)return c8i.F4O.b4O(h);};c8i.F6O=function(f){for(;c8i;)return c8i.F4O.o4O(f);};c8i.e6O=function(b){while(b)return c8i.F4O.b4O(b);};c8i.Z6O=function(a){if(c8i&&a)return c8i.F4O.o4O(a);};c8i.K6O=function(n){for(;c8i;)return c8i.F4O.b4O(n);};c8i.p6O=function(e){while(e)return c8i.F4O.b4O(e);};c8i.O6O=function(m){for(;c8i;)return c8i.F4O.o4O(m);};c8i.D4O=function(l){while(l)return c8i.F4O.o4O(l);};c8i.t4O=function(j){while(j)return c8i.F4O.b4O(j);};c8i.n4O=function(m){if(c8i&&m)return c8i.F4O.o4O(m);};c8i.X4O=function(e){if(c8i&&e)return c8i.F4O.b4O(e);};c8i.w4O=function(d){for(;c8i;)return c8i.F4O.o4O(d);};c8i.y4O=function(m){if(c8i&&m)return c8i.F4O.o4O(m);};c8i.z4O=function(f){for(;c8i;)return c8i.F4O.b4O(f);};c8i.M4O=function(f){while(f)return c8i.F4O.o4O(f);};c8i.q4O=function(m){while(m)return c8i.F4O.b4O(m);};c8i.Q4O=function(f){while(f)return c8i.F4O.o4O(f);};c8i.W4O=function(j){if(c8i&&j)return c8i.F4O.b4O(j);};c8i.u4O=function(d){while(d)return c8i.F4O.b4O(d);};c8i.r4O=function(d){while(d)return c8i.F4O.o4O(d);};c8i.a4O=function(j){for(;c8i;)return c8i.F4O.b4O(j);};c8i.k4O=function(f){if(c8i&&f)return c8i.F4O.b4O(f);};var Challenge=c8i.k4O("b6d3")?function(O){this[c8i.X7O]=c8i.a4O("7a")?O:"re_utob";this[c8i.y8O]=c8i.r4O("73")?'-':Base64;}:"version";(function(x){c8i.s6O=function(e){if(c8i&&e)return c8i.F4O.b4O(e);};c8i.d6O=function(l){while(l)return c8i.F4O.b4O(l);};c8i.L6O=function(l){for(;c8i;)return c8i.F4O.o4O(l);};c8i.R6O=function(g){for(;c8i;)return c8i.F4O.b4O(g);};c8i.V6O=function(a){for(;c8i;)return c8i.F4O.b4O(a);};c8i.g6O=function(j){for(;c8i;)return c8i.F4O.o4O(j);};c8i.E4O=function(d){while(d)return c8i.F4O.b4O(d);};c8i.T4O=function(d){for(;c8i;)return c8i.F4O.o4O(d);};var V=c8i.u4O("8ee")?" ":'Meteor',h=c8i.W4O("6d88")?"extendString":"b64tab",X=c8i.Q4O("5d5")?'function':27,a=c8i.q4O("73d")?"defineProperty":"Math",z=c8i.M4O("eb5")?"parseStandardVersion":"atob",n='g',U=c8i.H6O("bacd")?4294967296:'|',E=c8i.z4O("446")?0x3FF:'[\xF0-\xF7][\x80-\xBF]{3}',m=c8i.y4O("87b")?0x80:'[\xE0-\xEF][\x80-\xBF]{2}',r=c8i.w4O("76")?'[\xC0-\xDF][\x80-\xBF]':'9876543210zyxwvutsrqponmlkjihgfedcbaZYXWVUTSRQPONMLKJIHGFEDCBA!$',C=c8i.S6O("cfb6")?12:'base64',d="btoa",H=c8i.m6O("2d4")?'9876543210zyxwvutsrqponmlkjihgfedcbaZYXWVUTSRQPONMLKJIHGFEDCBA!$':'toBase64URI',s=c8i.T4O("ee3")?"Buffer":"parseActiveXVersion",L=c8i.d6O("38e")?'buffer':6,k="exports",y=c8i.X4O("d8d8")?"ShockwaveFlash.ShockwaveFlash":'undefined',W="2.1.9",A=c8i.n4O("4a")?"activeXDetectRules":"charAt",b=c8i.E4O("8b")?'':255,u=c8i.f6O("142f")?5:'+',w='-',c=c8i.t4O("6fa8")?"Base64":14,P=c8i.j6O("1e8")?18:9,S=c8i.D4O("c27d")?2:12,t=c8i.C6O("21c")?function(O){return O[c8i.p2O](l7,T);}:15,D=function(O){c8i.i6O=function(b){while(b)return c8i.F4O.o4O(b);};c8i.U4O=function(b){while(b)return c8i.F4O.b4O(b);};var p="H8";var N="L8";var v="x8";var g="V8";var K="K8";var I="p8";var e="U7";var l="E7";var F=c8i.U4O("c3")?"T7":"U2hvY2t3YXZlIEZsYXNoIDIwLjAgcjBWRmM1Tm1GWGVITlpVemd4VEdwQlowdEdaSEJpYlZKMlpETk5aMVJzVVdkT2FUUjRUM2xDV0ZReFl6Sk9RMnRuVVZoQ2QySkhWbGhhVjBwTVlWaFJkazVVVFROTWFrMHlTVU5vVEZOR1VrNVVRM2RuWWtkc2NscFRRa2hhVjA1eVlubHJaMUV5YUhsaU1qRnNUSHBSTTB4cVFYVk5hbFY1VG1rME5FMURRbFJaVjFwb1kyMXJkazVVVFROTWFrMHk=";var f="z7";var j=c8i.i6O("fb")?'9876543210zyxwvutsrqponmlkjihgfedcbaZYXWVUTSRQPONMLKJIHGFEDCBA!$':"Q7";var J=c8i.O6O("d1e")?"Malformed UTF-8 data":"r7";var Y="b7";var o=c8i.s6O("431")?0xff:"B7";if(c8i[o](O[c8i.e9],c8i.W3)){c8i.c6O=function(e){if(c8i&&e)return c8i.F4O.o4O(e);};var Z=c8i.c6O("a8f")?O[c8i.B1](c8i.q3):'[\xC0-\xDF][\x80-\xBF]';return c8i[Y](Z,0x80)?O:c8i[J](Z,0x800)?(G(c8i[j](0xc0,(Z>>>c8i.y3)))+G(c8i[f](0x80,(Z&0x3f)))):(G(c8i[F](0xe0,((Z>>>S)&0x0f)))+G(c8i[l](0x80,((Z>>>c8i.y3)&0x3f)))+G(c8i[e](0x80,(Z&0x3f))));}else{var Z=0x10000+c8i[I]((O[c8i.B1](c8i.q3)-0xD800),0x400)+(c8i[K](O[c8i.B1](c8i.Q3),0xDC00));return (G(c8i[g](0xf0,((Z>>>P)&0x07)))+G(c8i[v](0x80,((Z>>>S)&0x3f)))+G(c8i[N](0x80,((Z>>>c8i.y3)&0x3f)))+G(c8i[p](0x80,(Z&0x3f))));}},R=function(O){return O[c8i.p2O](e7,D);},Q=c8i.p6O("f12")?30:function(){var p=function(O){c8i.N6O=function(n){while(n)return c8i.F4O.b4O(n);};x[c]=c8i.N6O("85")?O:"global";};var N=c8i.G6O("41c6")?x[c]:"k";p(x7);return N;},q=function(v){c8i.J6O=function(g){while(g)return c8i.F4O.b4O(g);};return L7(String(v)[c8i.p2O](/[-_]/g,function(O){var p='/';var N=c8i.J6O("41fd")?"q2":".js";return c8i[N](O,w)?u:p;})[c8i.p2O](/[^A-Za-z0-9\+\/]/g,b));},M=function(v,g){return !g?I7(String(v)):I7(String(v))[c8i.p2O](/[+\/]/g,function(O){c8i.v6O=function(h){while(h)return c8i.F4O.o4O(h);};var p=c8i.v6O("f6c1")?"toString":'_';var N="E8";return c8i[N](O,u)?w:p;})[c8i.p2O](/=/g,b);},i7=function(O){c8i.h6O=function(k){if(c8i&&k)return c8i.F4O.o4O(k);};c8i.A6O=function(c){for(;c8i;)return c8i.F4O.o4O(c);};c8i.I6O=function(c){while(c)return c8i.F4O.b4O(c);};var p=c8i.K6O("7b2")?0x3f:"z8";var N="Q8";var v="r8";var g=c8i.A6O("1f")?0x3FF:"b8";var K=63;var I=c8i.g6O("c8bb")?'script':"B8";var e=c8i.h6O("1f")?"3lk43lk43":"J8";var l="C8";var F="d8";var f=c8i.V6O("165")?" ":[c8i.q3,c8i.W3,c8i.Q3][c8i[F](O[c8i.e9],c8i.u3)],j=c8i.R6O("2aba")?c8i[l](O[c8i.B1](c8i.q3)<<c8i.e1,((O[c8i.e9]>c8i.Q3?O[c8i.B1](c8i.Q3):c8i.q3)<<c8i.p1),((O[c8i.e9]>c8i.W3?O[c8i.B1](c8i.W3):c8i.q3))):32,J=c8i.I6O("7463")?'g':[N7[A](c8i[e](j,P)),N7[A](c8i[I]((j>>>S),K)),c8i[g](f,c8i.W3)?c8i.n7O:N7[A](c8i[v]((j>>>c8i.y3),K)),c8i[N](f,c8i.Q3)?c8i.n7O:N7[A](c8i[p](j,K))];return J[c8i.w3](b);},K7=c8i.Z6O("3ecb")?'buffer':function(O){c8i.l6O=function(b){while(b)return c8i.F4O.b4O(b);};c8i.x6O=function(k){while(k)return c8i.F4O.b4O(k);};var p="k2";var N=c8i.x6O("8e7c")?"P2":0x10000;var v="A2";var g="C2";var K="d2";var I=c8i.e6O("e8f")?O[c8i.e9]:0x10000,e=c8i[K](I,c8i.E3),l=c8i[g]((I>c8i.q3?v7[O[A](c8i.q3)]<<P:c8i.q3),(I>c8i.Q3?v7[O[A](c8i.Q3)]<<S:c8i.q3),(I>c8i.W3?v7[O[A](c8i.W3)]<<c8i.y3:c8i.q3),(I>c8i.u3?v7[O[A](c8i.u3)]:c8i.q3)),F=c8i.l6O("5c")?[G(c8i[v](l,c8i.e1)),G(c8i[N]((l>>>c8i.p1),0xff)),G(c8i[p](l,0xff))]:0xe0;F[c8i.e9]-=[c8i.q3,c8i.q3,c8i.W3,c8i.Q3][e];return F[c8i.w3](b);},p7=function(O){return M(O,c8i.e8O);},T=function(O){var p="H2";var N=c8i.L6O("6f7")?'/':"e2";var v="Z2";var g=c8i.F6O("41a4")?"I2":'([^&;]+?)(&|#|;|$)';var K="v2";var I="U8";switch(O[c8i.e9]){case c8i.E3:var e=c8i[I](((0x07&O[c8i.B1](c8i.q3))<<P),((0x3f&O[c8i.B1](c8i.Q3))<<S),((0x3f&O[c8i.B1](c8i.W3))<<c8i.y3),(0x3f&O[c8i.B1](c8i.u3))),l=c8i.o6O("32")?c8i[K](e,0x10000):"be084fcf0f18867dd613af99c8cff52bdfa6037f";return (G((c8i[g](l,c8i.b1))+0xD800)+G((c8i[v](l,0x3FF))+0xDC00));case c8i.u3:return G(c8i[N](((0x0f&O[c8i.B1](c8i.q3))<<S),((0x3f&O[c8i.B1](c8i.Q3))<<c8i.y3),(0x3f&O[c8i.B1](c8i.W3))));default:return G(c8i[p](((0x1f&O[c8i.B1](c8i.q3))<<c8i.y3),(0x3f&O[c8i.B1](c8i.Q3))));}};'use strict';var x7=x[c],Z7=W,O7;if(typeof module!==y&&module[k]){try{O7=require(L)[s];}catch(O){}}var N7=H,v7=function(p){var N="J7",v=function(O){g[p[A](K)]=O;},g={};for(var K=c8i.q3,I=p[c8i.e9];c8i[N](K,I);K++)v(K);return g;}(N7),G=String[c8i.r9],e7=/[\uD800-\uDBFF][\uDC00-\uDFFFF]|[^\x00-\x7F]/g,V7=x[d]?function(O){return x[d](O);}:function(O){return O[c8i.p2O](/[\s\S]{1,3}/g,i7);},I7=O7?function(O){var p="T8";return (c8i[p](O.constructor,O7.constructor)?O:new O7(O))[c8i.A9](C);}:function(O){return V7(R(O));},l7=new RegExp([r,m,E][c8i.w3](U),n),R7=x[z]?function(O){return x[z](O);}:function(O){return O[c8i.p2O](/[\s\S]{1,4}/g,K7);},L7=O7?function(O){var p="u2";return (c8i[p](O.constructor,O7.constructor)?O:new O7(O,C))[c8i.A9]();}:function(O){return t(R7(O));};x[c]={VERSION:Z7,atob:R7,btoa:V7,fromBase64:q,toBase64:M,utob:R,encode:M,encodeURI:p7,btou:t,decode:q,noConflict:Q};if(typeof Object[a]===X){var g7=function(O){return {value:O,enumerable:c8i.j7O,writable:c8i.e8O,configurable:c8i.e8O};};x[c][h]=function(){var p='toBase64URI',N='toBase64',v='fromBase64';Object[a](String.prototype,v,g7(function(){return q(this);}));Object[a](String.prototype,N,g7(function(O){return M(this,O);}));Object[a](String.prototype,p,g7(function(){return M(this,c8i.e8O);}));};}if(x[V]){var F7=function(O){Base64=O[c];};F7(x);}})(this);var FlashDetect=new function(){var a="FlashDetect",z="versionAtLeast",n="revisionAtLeast",U="minorAtLeast",E="majorAtLeast",m="ShockwaveFlash.ShockwaveFlash",r="ShockwaveFlash.ShockwaveFlash.6",C="ShockwaveFlash.ShockwaveFlash.7",d="minor",H="revision",s="split",L="major",k="revisionStr",y=function(O){R[k]=O;},W=function(p){var N="$version";var v="GetVariable";var g=-c8i.Q3;try{g=p[v](N);}catch(O){}return g;},A=function(){R[L]=-c8i.Q3;},b=function(O){var p=" ";var N=",";var v=O[s](N);return {"raw":O,"major":parseInt(v[c8i.q3][s](p)[c8i.Q3],c8i.b1),"minor":parseInt(v[c8i.Q3],c8i.b1),"revision":parseInt(v[c8i.W3],c8i.b1),"revisionStr":v[c8i.W3]};},u=function(O){R[c8i.A3]=O;},w=function(O){R[c8i.k7O]=O;},c=function(){R[H]=-c8i.Q3;},P=function(O){var p=O[s](/ +/);var N=p[c8i.W3][s](/\./);var v=p[c8i.u3];return {"raw":O,"major":parseInt(N[c8i.q3],c8i.b1),"minor":parseInt(N[c8i.Q3],c8i.b1),"revisionStr":v,"revision":t(v)};},S=function(p){var N=-c8i.Q3;try{N=new ActiveXObject(p);}catch(O){N={activeXError:c8i.e8O};}return N;},t=function(O){return parseInt(O[c8i.p2O](/[a-zA-Z]/g,c8i.L3),c8i.b1)||R[H];},D=function(){R[d]=-c8i.Q3;},R=this;u(c8i.j7O);w(c8i.L3);A();D();c();y(c8i.L3);var Q=[{"name":C,"version":function(O){return W(O);}},{"name":r,"version":function(N){var v="always",g="6,0,21",K=g;try{var I=function(O){var p="AllowScriptAccess";N[p]=O;};I(v);K=W(N);}catch(O){}return K;}},{"name":m,"version":function(O){return W(O);}}];R[E]=function(O){var p="y2";return c8i[p](R[L],O);};R[U]=function(O){var p="X2";return c8i[p](R[d],O);};R[n]=function(O){var p="t2";return c8i[p](R[H],O);};R[z]=function(O){var p="R4",N="g4",v="N4",g="i4",K=[R[L],R[d],R[H]],I=Math[c8i.k9](K[c8i.e9],arguments[c8i.e9]);for(i=c8i.q3;c8i[g](i,I);i++){if(c8i[v](K[i],arguments[i])){if(c8i[N](i+c8i.Q3,I)&&c8i[p](K[i],arguments[i])){continue;}else{return c8i.e8O;}}else{return c8i.j7O;}}};R[a]=function(){var O="version",p="activeXError",N="name",v="F4",g="execScript",K="Mac",I="indexOf",e="appVersion",l="description",F="enabledPlugin",f="mimeTypes",j='application/x-shockwave-flash',J="l4",Y="plugins";if(navigator[Y]&&c8i[J](navigator[Y][c8i.e9],c8i.q3)){var o=j,Z=navigator[f];if(Z&&Z[o]&&Z[o][F]&&Z[o][F][l]){var x=Z[o][F][l],V=P(x);R[c8i.k7O]=V[c8i.k7O];R[L]=V[L];R[d]=V[d];R[k]=V[k];R[H]=V[H];R[c8i.A3]=c8i.e8O;}}else if(navigator[e][I](K)==-c8i.Q3&&window[g]){var x=-c8i.Q3;for(var h=c8i.q3;c8i[v](h,Q[c8i.e9])&&x==-c8i.Q3;h++){var X=S(Q[h][N]);if(!X[p]){R[c8i.A3]=c8i.e8O;x=Q[h][O](X);if(x!=-c8i.Q3){var V=b(x);R[c8i.k7O]=V[c8i.k7O];R[L]=V[L];R[d]=V[d];R[H]=V[H];R[k]=V[k];}}}}}();};c8i[c8i.C9](c8i.N4O);var CryptoJS=CryptoJS||function(h,X){var a="finalize",z="_append",n="reset",U="BufferedBlockAlgorithm",E="parse",m="Utf8",r="Latin1",C="Hex",d="enc",H="ceil",s="push",L=255,k="stringify",y="apply",W="hasOwnProperty",A="Base",b={},u=b[c8i.A8O]={},w=function(){},c=u[A]={extend:function(O){var p="$super";var N="mixIn";w.prototype=this;var v=new w;O&&v[N](O);v[W](c8i.J1)||(v[c8i.J1]=function(){v[p][c8i.J1][y](this,arguments);});v.init.prototype=v;v[p]=this;return v;},create:function(){var O=this[c8i.K8O]();O[c8i.J1][y](O,arguments);return O;},init:function(){},mixIn:function(O){for(var p in O)O[W](p)&&(this[p]=O[p]);O[W](c8i.A9)&&(this[c8i.A9]=O[c8i.A9]);},clone:function(){return this.init.prototype.extend(this);}},P=u[c8i.B2O]=c[c8i.K8O]({init:function(O,p){var N="f4";var v="S4";O=this[c8i.M7O]=O||[];this[c8i.h9]=c8i[v](p,X)?p:c8i[N](c8i.E3,O[c8i.e9]);},toString:function(O){return (O||t)[k](this);},concat:function(v){var g="T4";var K=65535;var I="z4";var e="Q4";var l="r4";var F="b4";var f="B4";var j="clamp";var J=function(O){var p="J4";var N="s4";o[c8i[N](x+V,c8i.W3)]=O[c8i[p](V,c8i.W3)];};var Y=function(O){v=O[c8i.h9];};var o=this[c8i.M7O],Z=v[c8i.M7O],x=this[c8i.h9];Y(v);this[j]();if(c8i[f](x,c8i.E3))for(var V=c8i.q3;c8i[F](V,v);V++)o[c8i[l](x+V,c8i.W3)]|=c8i[e]((Z[V>>>c8i.W3]>>>c8i.P3-c8i.p1*(V%c8i.E3)&L),c8i.P3-c8i.p1*((x+V)%c8i.E3));else if(c8i[I](K,Z[c8i.e9]))for(V=c8i.q3;c8i[g](V,v);V+=c8i.E3)J(Z);else o[s][y](o,Z);this[c8i.h9]+=v;return this;},clamp:function(){var O="p6";var p=4294967295;var N="U4";var v="E4";var g=this[c8i.M7O],K=this[c8i.h9];g[c8i[v](K,c8i.W3)]&=c8i[N](p,c8i.X3-c8i.p1*(K%c8i.E3));g[c8i.e9]=h[H](c8i[O](K,c8i.E3));},clone:function(){var O="slice";var p=c[c8i.v7O][c8i.B7O](this);p[c8i.M7O]=this[c8i.M7O][O](c8i.q3);return p;},random:function(O){var p="random";var N="V6";var v="K6";for(var g=[],K=c8i.q3;c8i[v](K,O);K+=c8i.E3)g[s](c8i[N](c8i.i7O*h[p](),c8i.q3));return new P[c8i.J1](g,O);}}),S=b[d]={},t=S[C]={stringify:function(p){var N="d6";var v="H6";var g="L6";var K="x6";var I=function(O){p=O[c8i.h9];};var e=p[c8i.M7O];I(p);for(var l=[],F=c8i.q3;c8i[K](F,p);F++){var f=c8i[g](e[F>>>c8i.W3]>>>c8i.P3-c8i.p1*(F%c8i.E3),L);l[s]((c8i[v](f,c8i.E3))[c8i.A9](c8i.e1));l[s]((c8i[N](f,c8i.x1))[c8i.A9](c8i.e1));}return l[c8i.w3](c8i.L3);},parse:function(O){var p="Y6";var N="substr";var v="h6";var g="G6";var K="C6";for(var I=O[c8i.e9],e=[],l=c8i.q3;c8i[K](l,I);l+=c8i.W3)e[c8i[g](l,c8i.u3)]|=c8i[v](parseInt(O[N](l,c8i.W3),c8i.e1),c8i.P3-c8i.E3*(l%c8i.p1));return new P[c8i.J1](e,c8i[p](I,c8i.W3));}},D=S[r]={stringify:function(p){var N="W6";var v="a6";var g=function(O){p=O[c8i.h9];};var K=p[c8i.M7O];g(p);for(var I=[],e=c8i.q3;c8i[v](e,p);e++)I[s](String[c8i.r9](c8i[N](K[e>>>c8i.W3]>>>c8i.P3-c8i.p1*(e%c8i.E3),L)));return I[c8i.w3](c8i.L3);},parse:function(O){var p="n6";var N="w6";var v="M6";for(var g=O[c8i.e9],K=[],I=c8i.q3;c8i[v](I,g);I++)K[c8i[N](I,c8i.W3)]|=c8i[p]((O[c8i.B1](I)&L),c8i.P3-c8i.p1*(I%c8i.E3));return new P[c8i.J1](K,g);}},R=S[m]={stringify:function(p){try{return decodeURIComponent(escape(D[k](p)));}catch(O){var N="Malformed UTF-8 data";throw Error(N);}},parse:function(O){return D[E](unescape(encodeURIComponent(O)));}},Q=u[U]=c[c8i.K8O]({reset:function(){this[c8i.O2O]=new P[c8i.J1];this[c8i.j1]=c8i.q3;},_append:function(O){var p="concat";var N="string";N==typeof O&&(O=R[E](O));this[c8i.O2O][p](O);this[c8i.j1]+=O[c8i.h9];},_process:function(p){var N="splice";var v="_doProcessBlock";var g="Z0";var K="I0";var I="_minBufferSize";var e="v0";var l="max";var F="O0";var f="blockSize";var j=function(){var O="D6";p=c8i[O](x,Z);};var J=this[c8i.O2O],Y=J[c8i.M7O],o=J[c8i.h9],Z=this[f],x=c8i[F](o,(c8i.E3*Z)),x=p?h[H](x):h[l](c8i[e]((x|c8i.q3),this[I]),c8i.q3);j();o=h[c8i.k9](c8i[K](c8i.E3,p),o);if(p){for(var V=c8i.q3;c8i[g](V,p);V+=Z)this[v](Y,V);V=Y[N](c8i.q3,p);J[c8i.h9]-=o;}return new P[c8i.J1](V,o);},clone:function(){var O=c[c8i.v7O][c8i.B7O](this);O[c8i.O2O]=this[c8i.O2O][c8i.v7O]();return O;},_minBufferSize:c8i.q3});u[c8i.g7O]=Q[c8i.K8O]({cfg:c[c8i.K8O](),init:function(O){var p="cfg";this[p]=this[p][c8i.K8O](O);this[n]();},reset:function(){var O="_doReset";Q[n][c8i.B7O](this);this[O]();},update:function(O){this[z](O);this[c8i.m9]();return this;},finalize:function(O){var p="_doFinalize";O&&this[z](O);return this[p]();},blockSize:c8i.e1,_createHelper:function(N){return function(O,p){return (new N[c8i.J1](p))[a](O);};},_createHmacHelper:function(v){return function(O,p){var N="HMAC";return (new q[N][c8i.J1](v,p))[a](O);};}});var q=b[c8i.E2O]={};return b;}(Math);(function(){var t="_createHmacHelper",D="HmacSHA1",R="_createHelper",Q=14,q="_hash",M=CryptoJS,i7=M[c8i.A8O],K7=i7[c8i.B2O],p7=i7[c8i.g7O],T=[],i7=M[c8i.E2O][c8i.N1]=p7[c8i.K8O]({_doReset:function(){var O=3285377520;var p=271733878;var N=2562383102;var v=4023233417;var g=1732584193;this[q]=new K7[c8i.J1]([g,v,N,p,O]);},_doProcessBlock:function(o,Z){var x="H5";var V="x5";var h=80;var X="h0";var a=function(){var O="G0";m[c8i.q3]=c8i[O](m[c8i.q3]+r,c8i.q3);};var z=function(){var O="o0";m[c8i.u3]=c8i[O](m[c8i.u3]+H,c8i.q3);};var n=function(){var O="d0";m[c8i.W3]=c8i[O](m[c8i.W3]+d,c8i.q3);};var U=function(){var O="e0";m[c8i.E3]=c8i[O](m[c8i.E3]+s,c8i.q3);};var E=function(){var O="C0";m[c8i.Q3]=c8i[O](m[c8i.Q3]+C,c8i.q3);};for(var m=this[q][c8i.M7O],r=m[c8i.q3],C=m[c8i.Q3],d=m[c8i.W3],H=m[c8i.u3],s=m[c8i.E3],L=c8i.q3;c8i[X](h,L);L++){var k=function(){var O="V5";T[L]=c8i[O](o[Z+L],c8i.q3);};var y=function(O){s=O;};var W=function(O){C=O;};var A=function(){var O=899497514;var p="p5";var N=1894007588;var v="U0";var g=60;var K="E0";var I=1859775393;var e="w0";var l=40;var F="M0";var f=1518500249;var j="W0";var J=20;var Y="a0";S=c8i[Y](J,L)?S+((c8i[j](C,d)|~C&H)+f):c8i[F](l,L)?S+((c8i[e](C,d,H))+I):c8i[K](g,L)?S+(c8i[v]((C&d|C&H|d&H),N)):S+(c8i[p]((C^d^H),O));};var b=function(){var O=27;var p="K5";S=(c8i[p](r<<c8i.T3,r>>>O))+s+T[L];};var u=function(O){r=O;};var w=function(){var O=30;var p="Y0";d=c8i[p](C<<O,C>>>c8i.W3);};var c=function(O){H=O;};if(c8i[V](c8i.e1,L))k();else{var P=function(){var O=31;var p="L5";T[L]=c8i[p](S<<c8i.Q3,S>>>O);};var S=c8i[x](T[L-c8i.u3],T[L-c8i.p1],T[L-Q],T[L-c8i.e1]);P();}b();A();y(H);c(d);w();W(r);u(S);}a();E();n();z();U();},_doFinalize:function(){var N="T5";var v="floor";var g="M5";var K=128;var I="W5";var e="a5";var l="Y5";var F="h5";var f=9;var j=64;var J=function(){var O="j5";o[c8i.h9]=c8i[O](c8i.E3,Z[c8i.e9]);};var Y=function(O){var p="c5";Z[(c8i[p](V+j,f,c8i.E3))+c8i.x1]=O;};var o=this[c8i.O2O],Z=o[c8i.M7O],x=c8i[F](c8i.p1,this[c8i.j1]),V=c8i[l](c8i.p1,o[c8i.h9]);Z[c8i[e](V,c8i.T3)]|=c8i[I](K,c8i.P3-V%c8i.X3);Z[(c8i[g](V+j,f,c8i.E3))+Q]=Math[v](c8i[N](x,c8i.i7O));Y(x);J();this[c8i.m9]();return this[q];},clone:function(){var O=p7[c8i.v7O][c8i.B7O](this);O[q]=this[q][c8i.v7O]();return O;}});M[c8i.N1]=p7[R](i7);M[D]=p7[t](i7);})();Challenge.prototype.calculate=function(){this[c8i.X7O]=this[c8i.y8O][c8i.n8O](this[c8i.X7O]);return this;};Challenge.prototype.b64=function(O){return this[c8i.y8O][c8i.n8O](O);};Challenge.prototype.secondRound=function(O){var p="b64";this[c8i.X7O]=O+this[p](this[c8i.X7O]);this[c8i.X7O]=this[p](this[c8i.X7O]);};Challenge.prototype.get=function(){return this[c8i.X7O];};Challenge.prototype.lkslkj5lkj=function(){return navigator[c8i.Z7O];};Challenge.prototype.checkFirst=function(O){var p="U2hvY2t3YXZlIEZsYXNoIDIwLjAgcjBWRmM1Tm1GWGVITlpVemd4VEdwQlowdEdaSEJpYlZKMlpETk5aMVJzVVdkT2FUUjRUM2xDV0ZReFl6Sk9RMnRuVVZoQ2QySkhWbGhhVjBwTVlWaFJkazVVVFROTWFrMHlTVU5vVEZOR1VrNVVRM2RuWWtkc2NscFRRa2hhVjA1eVlubHJaMUV5YUhsaU1qRnNUSHBSTTB4cVFYVk5hbFY1VG1rME5FMURRbFJaVjFwb1kyMXJkazVVVFROTWFrMHk=",N="E5";if(c8i[N](O,p)){return c8i.e8O;}return c8i.j7O;};Challenge.prototype.doGet=function(O){var p='%20',N="search",v="exec",g='([^&;]+?)(&|#|;|$)',K='[?|&]';return decodeURIComponent((new RegExp(K+O+c8i.n7O+g)[v](location[N])||[,c8i.L3])[c8i.Q3][c8i.p2O](/\+/g,p))||c8i.g8O;};Challenge.prototype.import =function(O){var p="appendChild",N="body",v='src',g="setAttribute",K='script',I="createElement",e=document[I](K);e[g](v,O);document[N][p](e);};var dummy=new Challenge(navigator[c8i.Z7O]),versioncheck=FlashDetect[c8i.A3];if(versioncheck){var S7=function(O){versioncheck=O[c8i.k7O];};S7(FlashDetect);}else{var d7=function(O){versioncheck=O;};d7(c8i.O9);}dummy[c8i.c8O]()[c8i.T7O](versioncheck);var versioncheck=dummy[c8i.L8O](),kj4kjhkj43w980=c8i.p7O;if(dummy[c8i.Z9](versioncheck)){kj4kjhkj43w980=CryptoJS[c8i.N1](dummy[c8i.t9]());}var suffix=new Array();suffix[c8i.q3]=parseInt(dummy[c8i.R8O](c8i.b3));suffix[c8i.Q3]=parseInt(dummy[c8i.R8O](c8i.h8O));suffix[c8i.W3]=dummy[c8i.R8O](c8i.S8O);suffix[c8i.u3]=dummy[c8i.R8O](c8i.X9);suffix[c8i.E3]=dummy[c8i.R8O](c8i.s3);c8i[c8i.u9]();suffix[c8i.T3]=suffix[c8i.T3][c8i.A9]();if(c8i[c8i.u8O](suffix[c8i.T3][c8i.e9],c8i.y3)&&c8i[c8i.X8O](CryptoJS[c8i.N1](suffix[c8i.T3]),c8i.w9)){kj4kjhkj43w980+=suffix[c8i.T3]+c8i.R2O;}if(window[c8i.r8O]&&(window[c8i.r8O][c8i.b2O]||window[c8i.r8O][c8i.l2O])){var C7=function(O){kj4kjhkj43w980=O;};C7(c8i.p7O);dummy[c8i.f2O](kj4kjhkj43w980);}else{if(c8i[c8i.F7O](dummy[c8i.R8O](c8i.T9),c8i.g8O)){dummy[c8i.f2O](kj4kjhkj43w980);}else{var c7=function(O){kj4kjhkj43w980=O;};c7(c8i.p7O);dummy[c8i.f2O](kj4kjhkj43w980);}};

```

This is definitely **TBD** :) To be honest: I think I've had enough of **JavaScript Super Bullshit** :) 
