+++
title = "On Java, OpenSSL, Crypto, Blowfish and stuff"
date = "2014-07-01"
category = "blog"
author = "Victor Dorneanu"
tags = ["java", "cryptography", "crypto", "openssl", "ssl", "tls", "coding", "python"]
+++

During some Android malware analysis I came along some Java routines which were meant to decrypt/encrypt some content. Nothing special about it. The key had to be extracted from a file and the encrypted file was in Base64. After unsuccessfully trying **openssl** in order to decrypt the file I decided to make some further investigations.

In this article I'll have a look how `Python`, `Java` and `openssl` (command line utility) implement [Blowfish](https://www.schneier.com/paper-blowfish-fse.html) in `CBC` mode. Furthermore I want to know if data encrypted with Python can be later on decrypted with Java and viceversa. Following compatibility dependencies might be interesting:

1. Python <-> Java
1. Java <-> openssl
1. Python <-> openssl


## Java

Let's take a look at some routines in `Java`. You can also view/download the following code on this [GitHub Gist](https://gist.github.com/dorneanu/b8e53b034d89f6be383c).

~~~ java
/*
 * Based on https://raw.githubusercontent.com/usefulfor/usefulfor/master/security/JBoss.java
 *
 * JBoss.java - Blowfish encryption/decryption tool with JBoss default password
 *    Daniel Martin Gomez <daniel@ngssoftware.com> - 03/Sep/2009
 *
 * This file may be used under the terms of the GNU General Public License
 * version 2.0 as published by the Free Software Foundation:
 *   http://www.gnu.org/licenses/gpl-2.0.html
 */
import javax.crypto.*;
import javax.crypto.spec.SecretKeySpec;

import java.math.BigInteger;
import javax.xml.bind.DatatypeConverter;

public class JBlowfish
{
    final protected static char[] hexArray = "0123456789ABCDEF".toCharArray();

    // Converts byte array to hex string
    // From: http://stackoverflow.com/questions/9655181/convert-from-byte-array-to-hex-string-in-java
    public static String bytesToHex(byte[] bytes) {
        char[] hexChars = new char[bytes.length * 2];
        for ( int j = 0; j < bytes.length; j++ ) {
            int v = bytes[j] & 0xFF;
            hexChars[j * 2] = hexArray[v >>> 4];
            hexChars[j * 2 + 1] = hexArray[v & 0x0F];
        }
        return new String(hexChars);
    }

    public static void main(String[] args) throws Exception
    {

        if ( ( args.length != 2 ) || !( args[0].equals("-e") | args[0].equals("-d") ) )
        {
            System.out.println( "Usage:\n\tjava JBlowfish <-e|-d> <encrypted_password>" );
            return;
        }

        String mode = args[0];

        // Configuration
        byte[] key  = "secret".getBytes();
        String IV   = "12345678";


        System.out.println("-- Settings -----------");
        System.out.println("KEY:\t " + bytesToHex(key));
        System.out.println("IV:\t " + bytesToHex(IV.getBytes()));

        // Create new Blowfish cipher
        SecretKeySpec keySpec = new SecretKeySpec(key, "Blowfish");
        Cipher cipher = Cipher.getInstance("Blowfish/CBC/PKCS5Padding");
        String out = null;

        if ( mode.equals("-e") )
        {
            String secret = args[1];
            cipher.init(Cipher.ENCRYPT_MODE, keySpec, new javax.crypto.spec.IvParameterSpec(IV.getBytes()));
            byte[] encoding = cipher.doFinal(secret.getBytes());

            System.out.println("-- Encrypted -----------");
            System.out.println("Base64:\t " + DatatypeConverter.printBase64Binary(encoding));
            System.out.println("HEX:\t " + bytesToHex(encoding));
        }
        else
        {
            // Decode Base64
            byte[] ciphertext = DatatypeConverter.parseBase64Binary(args[1]);

            // Decrypt
            cipher.init(Cipher.DECRYPT_MODE, keySpec, new javax.crypto.spec.IvParameterSpec(IV.getBytes()));
            byte[] message = cipher.doFinal(ciphertext);

            System.out.println("-- Decrypted -----------");
            System.out.println("HEX:\t " + bytesToHex(message));
            System.out.println("PLAIN:\t " + new String(message));

        }
    }
}
~~~

The programm will encrypt messages using *Blowfish* in *CBC* mode. There are 2 modi available:

* `-e <message>`: will encrypt the message < message >
* `-d <Base64>`: will decrypt the specified Base64 string < Base64 >

The encryption `key` and the `IV` (initialization vector) are static. Let's see an example:

~~~ shell
# javac JBlowfish.java
# java -cp . JBlowfish -e secretmessage
-- Settings -----------
KEY:     736563726574
IV:      3132333435363738
-- Encrypted -----------
Base64:  2CEndW0AA2xpsYz3XrXnrA==
HEX:     D82127756D00036C69B18CF75EB5E7AC
~~~

We just *encrypted* the message *"secretmessage*" with *Blowfish/CBC*. In the *settings* section you'll see the `KEY` and the `IV` in their *hex* representation. Afterwards the programm will show the `Base64` and the `hex` representation of **encrypted** message. *Decryption* works quite straightforward:

~~~ shell
# java -cp . JBlowfish -d 2CEndW0AA2xpsYz3XrXnrA==
-- Settings -----------
KEY:     736563726574
IV:      3132333435363738
-- Decrypted -----------
HEX:     7365637265746D657373616765
PLAIN:   secretmessage
~~~

Our little Java application does its job pretty fine. Ok, now let's have a look at `openssl`.

## OpenSSL <-> Java

Using `openssl` I'll encrypt/decrypt the previous secret message with the same cipher:

~~~ shell
# echo "secretmessage" | openssl bf-cbc -nosalt -a -pass pass:victor -iv 3132333435363738 -p
key=FFC150A160D37E92012C196B6AF4160D
iv =3132333435363738
+NtBjHQzii7i//apIvfHkw==
~~~

A few explanations:

* `bf-cbc`: this is Blowfish with CBC
* `nosalt`: Use no salt (which in general is very bad!)
* `-a`: This means that if encryption is taking place the data is base64 encoded after encryption. If decryption is set then the input data is base64 decoded before being decrypted.
* `-pass`: Specify the passphrase to encrypt the message with. This is actually **not** the encryption key openssl will use. The encryption key will be derived from the passphrase.
* `-iv`: Specify IV in hex representation. In the Java code I've used `IV="12345678` and `hex(IV)=3132333435363738`

As you can see the output of *openssl* looks quite different. Following observations:


| Tool          | KEY                              | IV               | Encrypted message (Base64) |
| ------------- | -------------                    | ---------------  | ------------------------   |
| *Java*        | 736563726574                     | 3132333435363738 | 2CEndW0AA2xpsYz3XrXnrA==   |
| *openssl*     | FFC150A160D37E92012C196B6AF4160D | 3132333435363738 | +NtBjHQzii7i//apIvfHkw==   |


Besides the IV everything looks different :(


## Python <-> Java

Let's also have a look at *Python*:

~~~ python
In [67]:    from Crypto.Cipher import Blowfish
            from Crypto import Random
            from struct import pack
            from binascii import hexlify, unhexlify


            IV = "12345678"
            KEY = "secret"

            # We'll use the Base64 string from JBlowfish output
            ciphertext = "2CEndW0AA2xpsYz3XrXnrA==".decode("base64")

            cipher = Blowfish.new(KEY, Blowfish.MODE_CBC, IV)
            message = cipher.decrypt(ciphertext)
            print("KEY: " + KEY.encode("hex"))
            print("IV: " + IV.encode("hex"))
            print("Message: " + message)

Out:        KEY: 736563726574
            IV: 3132333435363738
            Message: secretmessage
~~~

Well that looks good. This is what we got:


| Tool          | KEY             | IV               |
| ------------- | :-------------: | ---------------: |
| *Java*        | 736563726574    | 3132333435363738 |
| *python*      | 736563726574    | 3132333435363738 |


## Python <-> openssl

This time let's encrypt some message using Python:

~~~ python
In [71]:    from Crypto.Cipher import Blowfish
            from Crypto import Random
            from struct import pack
            from binascii import hexlify, unhexlify


            IV = "12345678"
            KEY = "secret"
            message = "12345678"


            cipher = Blowfish.new(KEY, Blowfish.MODE_CBC, IV)
            ciphertext = cipher.encrypt(message)
            print("HEX: " + ciphertext.encode("hex"))
            print("Base64: " + ciphertext.encode("base64"))

Out:        HEX: 010a0d9149750a32
            Base64: AQoNkUl1CjI=
~~~

Now decrypt that ciphertext using openssl:

~~~ shell
# echo "AQoNkUl1CjI=" | openssl bf-cbc -d -a -nosalt -pass pass:secret -iv 3132333435363738  -p
key=5EBE2294ECD0E0F08EAB7690D2A6EE69
iv =3132333435363738
bad decrypt
140568446580392:error:06065064:digital envelope routines:EVP_DecryptFinal_ex:bad decrypt:evp_enc.c:539:
~~~

Again the encryption key doesn't match the one we used in the Python code. Thus the Bas64 string can't be decoded by openssl.


## Conclusion

Obviously I'm not the [only one](http://stackoverflow.com/questions/8468799/decrypting-openssl-blowfish-with-java) facing this problem.

> [Not-Yet-Commons-SSL](http://juliusdavies.ca/commons-ssl/pbe.html) has an implementation of PBE ("password based encryption") that is 100% compatible with OpenSSL's command-line "enc" utility

That sounds promising but you should be warned:

> Warning:  All versions of not-yet-commons-ssl should be considered to be of "Alpha" quality! This code probably contains bugs. This code may have security issues.

as stated [here](http://juliusdavies.ca/commons-ssl/download.html).

If you still want some compatibility between `openssl` and your code, you should use the `key` and `IV` from openssl. Example:

~~~ shell
# echo "this-is-secret" | openssl bf-cbc -a -nosalt -pass pass:secret -iv 12345678 -p
key=5EBE2294ECD0E0F08EAB7690D2A6EE69
iv =1234567800000000
2whDyIn5hRdyXpRZbMZayw==
~~~

Now use those values in your code:

~~~ python
In [72]:    from Crypto.Cipher import Blowfish
            from Crypto import Random
            from struct import pack
            from binascii import hexlify, unhexlify


            KEY = unhexlify("5EBE2294ECD0E0F08EAB7690D2A6EE69")
            IV = unhexlify("1234567800000000")
            ciphertext = "2whDyIn5hRdyXpRZbMZayw==".decode("base64")


            cipher = Blowfish.new(KEY, Blowfish.MODE_CBC, IV)
            ciphertext = cipher.decrypt(ciphertext)

            print("Message: " + message)

Out:        Message: 12345678
~~~

Also have a look at [this](http://stackoverflow.com/questions/12227510/how-to-decrypt-unsalted-openssl-compatible-blowfish-cbc-pkcs5padding-password-in). That's all for today. Cya next time!
