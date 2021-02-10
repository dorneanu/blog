+++
title = "HowTo: Keep your passwords safe using SQLite and SQLCipher"
author = "Victor"
date = "2011-07-28"
tags = ["security", "crypto", "sqlite", "howto", "sql"]
category = "blog"
+++

I was recently doing some hacks and realized that there must be a way to store gained information in a secure manner. I usually encrypt sensitive information (like passwords, accounts etc.) using GPG. But that's quite unhandy: You always need your private key and the encrypted data is stored unencrypted on the device (unless you're using full disk encryption which shouldn't be a problem since data is stored encrypted on the device). Like you probably also do, I have several account types: Mail, SSH, FTP, LDAP etc. Finding a good structure to store all that information could be a headache. Besides that you usually have several `organizations` offering specific services: Firm A offers Service 1 and Service 2; Firm B also offers Service 1 but on different port and so on...

Pondering about all this stuff, I came up with an idea which might be useful to some of you: Relational Database Management Systems (RDBMS). The concept should be able to:

*   store ALL information in ONE place
*   provide simple functionalities in order to ADD, DELETE, MODIFY data
*   encrypt ALL data

Well these are the requirements. What about real-life tools to satisfy them?

## SQLite


>"SQLite is a software library that implements a self-contained, serverless, zero-configuration, transactional SQL database engine. SQLite is the most widely deployed SQL database engine in the world. The source code for SQLite is in the public domain." (Source: <a class="http" href="http://www.sqlite.org">http://www.sqlite.org</a>) 

What does this mean?
*   We got relations! Enjoy the magic of simple SQL queries.
*   No configuration! You don't have to configure any server nor the SQL client. Just create the DB and you're done.
*   The data base is stored in ONE file.
*   You can have multiple data bases within each file.

Pretty much for a DB! The really cool thing about SQLite is the fact that there are no additional steps required in order to create and maintain the DB. I really like PostgreSQL/MySQL & Co. but the whole configuration process is driving me nuts. With SQLite you just create the file, put some schema to it and you're done. Last but not least: It's fast! Although the document is outdated you could have a look at the speed comparsion <a class="http" href="http://www.sqlite.org/speed.html">here</a>.

## Database schema

Now let's have a closer look at the interna of our DB. Let's start with the simplest table: the **organization** table.

~~~.sql
CREATE TABLE "organization" (
    "id" INTEGER PRIMARY KEY NOT NULL,
    "name" TEXT NOT NULL
);
~~~

That should do the job since you need only the organizations name and some primary key. Usually an organization offers serveral services. So we'll create the 2nd table: the **service** table.

~~~.sql
CREATE TABLE "service" (
    "id" INTEGER PRIMARY KEY NOT NULL,
    "host" TEXT NOT NULL,
    "port" INTEGER NOT NULL,
    "organization_id" INTEGER NOT NULL,

    CONSTRAINT fk_service_organization_id FOREIGN KEY (organization_id) REFERENCES organization(id)
);
~~~

Assuming we have `Firm A` in our organization table, then its services will be stored in this way:

~~~.shell
sqlite> SELECT * FROM organization;
id          name
----------  ----------
1           Firm A

sqlite> SELECT * FROM service;
id          host         port        organization_id
----------  -----------  ----------  ---------------
1           smtp.a.com   25          1
~~~

I think you got the point. You'll need a PK (primary key) , a host (actually this should be called `url`), a port number and the organization ID offering the service.

By now the schema was quite simple. We got the organization and its services. The **account** will interfere with both of them. First let's have a look the table:
</p>

~~~.sql
CREATE TABLE "account" (
        "id" INTEGER PRIMARY KEY NOT NULL,
        "created" TEXT NOT NULL,
        "expires" TEXT NOT NULL,
        "user" TEXT NOT NULL,
        "passwd" TEXT,
        "service_id" INTEGER NOT NULL,

        CONSTRAINT fk_account_service_id FOREIGN KEY (service_id) REFERENCES service(id)
);
~~~

I think the attributes are self-explanatory. Here are some sample entries:

~~~.shell
sqlite> SELECT * FROM accounts;
id          created     expires     user                    passwd      host         port
----------  ----------  ----------  ----------------------  ----------  -----------  ----------
1           2011-07-23  2012-07-26  victor.dorneanu@blab    XXXXXX      smtp.kjs.de  25
2           2011-07-23  2012-07-26  victor.dorneanu@bla2    XXXXXX      pop3.kjs.de  995
3           2011-07-23  2012-07-26  victor@gmail            XXXXXX      smtp.gmail.  25
~~~

## Entity-Relationship-Modell

This is for the ER-Modell freaks among you...

![ER model](/posts/img/2011/255/er-modell.png)

Graphviz code:

~~~
graph ER {
    node [shape=box, style=filled, color=yellow]; organization; service; account;
    node [shape=ellipse, style=filled, color=green]; acc_id; created; expires; user; passwd; org_id; org_name; serv_id; host;
    port;
    node [shape=diamond,style=filled,color=lightgrey]; {node [label="has"] has0;
    has1;}

    organization -- org_id;
    organization -- org_name;

    account -- acc_id;
    account -- created;
    account -- expires;
    account -- user;
    account -- passwd;

    service -- serv_id;
    service -- host;
    service -- port;

    organization -- "has0" [label="M",len=1.00];
    "has0" -- service [label="N",len=1.00];

    service -- "has1" [label="1",len=1.00];
    "has1" -- account [label="N",len=1.00];

    label = "

ER Modell (dornea.nu)";
    fontsize=9;
}
~~~


## Security

Ok. So we got our DB, our tables and inserted some dummy data. What about security? What if our SQLite file gets in the wrong hands? <a class="http" href="http://sqlcipher.net/">SQLCipher</a> could help us to minimize the potential impact. What is it?


>"SQLCipher is an SQLite xtension that provides transparent 256-bit AES encryption of database files. Pages are encrypted before being written to disk and are decrypted when read back. Due to the small footprint and great performance it’s ideal for protecting embedded application databases and is well suited for mobile development."" (Source: <a class="http" href="http://sqlcipher.net/">http://sqlcipher.net/</a>) 

Advantages:

*   EVERYTHING is encrypted
*   you have a small percentage of overhead (for encryption routines): 5-15%
*   uses OpenSSL crypto library
*   good security (CBC mode, key derivation)

In order to use SQLCipher you'll have to build the SQLite package with the enhanced features. Just follow the instructions on <a class="http" href="http://sqlcipher.net/introduction/">http://sqlcipher.net/introduction/</a> and use following command to configure and build the package:


~~~.shell
./configure --prefix=/usr/local --enable-tempstore=yes CFLAGS="-DSQLITE_HAS_CODEC" LDFLAGS="-lcrypto"
make
make install
~~~

Then you should have a working binary in /usr/local/bin. I suggest you create a new encrypted DB rather than encrypt an existing one. There are several <a class="http" href="http://sqlcipher.net/sqlcipher-api/">hints</a> how to do this, but I recommend you starting with a new fresh DB. Let's get started:

~~~.shell
$ /usr/local/bin/sqlite3 new_db.db
SQLite version 3.7.2
Enter ".help" for instructions
Enter SQL statements terminated with a ";"
sqlite> PRAGMA key = 'crackme';
sqlite> PRAGMA cipher = 'aes-256-cfb';
sqlite> PRAGMA kdf_iter = '1000';
sqlite>
~~~

Now you're ready to create your DB schema. I'd create some SQL file, set the DB key and afterwards create the table. Create some new file (e.g. dump.sql) and paste these line to it:

~~~.shell
PRAGMA key = 'crackme';
PRAGMA cipher = 'aes-256-cfb';
PRAGMA kdf_iter = '1000';
BEGIN TRANSACTION;
-- CREATE Tables
CREATE TABLE "organization" (
    "id" INTEGER PRIMARY KEY NOT NULL,
    "name" TEXT NOT NULL
);

CREATE TABLE "service" (
    "id" INTEGER PRIMARY KEY NOT NULL,
    "host" TEXT NOT NULL,
    "port" INTEGER NOT NULL,
    "organization_id" INTEGER NOT NULL,

    CONSTRAINT fk_service_organization_id FOREIGN KEY (organization_id) REFERENCES organization(id)
);

CREATE TABLE "account" (
        "id" INTEGER PRIMARY KEY NOT NULL,
        "created" TEXT NOT NULL,
        "expires" TEXT NOT NULL,
        "user" TEXT NOT NULL,
        "passwd" TEXT,
        "service_id" INTEGER NOT NULL,

        CONSTRAINT fk_account_service_id FOREIGN KEY (service_id) REFERENCES service(id)
);

END TRANSACTION;
~~~

Then create your encrypted DB using:

~~~.shell
$ /usr/local/bin/sqlite3 -init dump.sql encrypted.db
SQLite version 3.7.2
Enter ".help" for instructions
Enter SQL statements terminated with a ";"
sqlite> .tables
account       organization  service
sqlite>
~~~

Voila! Is the file `encrypted.db` really encrypted? Let's have a look:

~~~.shell
$ file encrypted.db
encrypted.db: data
$ hexdump -C encrypted.db
00000000  e4 2a cd 22 4f d4 30 a6  b7 95 9c 28 19 f5 4a 45  |.*."O.0....(..JE|
00000010  c9 b6 c4 28 49 0b 3b c3  91 ef 06 95 e7 6a aa 03  |...(I.;......j..|
00000020  ff b7 ef 2f cd 48 c9 b3  01 36 24 4b dd 4c 95 ef  |.../.H...6$K.L..|
00000030  93 df be 94 ff 8a 0e 04  c4 fc b0 bf 67 97 fc 43  |............g..C|
00000040  38 2b b3 6e e2 88 2e 26  e7 ef 19 e3 e5 b8 0f 04  |8+.n...&........|
00000050  50 44 5a d9 83 1d ac 33  d9 21 cd d1 40 c6 d8 3d  |PDZ....3.!..@..=|
00000060  ab 11 5d 77 6d 94 08 59  64 5f ac e6 99 20 05 03  |..]wm..Yd_... ..|
00000070  da 08 8a b7 a3 cf d4 22  44 c2 de 4c 00 48 51 4d  |......."D..L.HQM|
00000080  74 0b 3b f6 5d f9 07 07  1b 77 a0 8b 9e 5e bd bb  |t.;.]....w...^..|
00000090  d4 ca 25 75 f2 f7 56 48  ea 03 02 c5 da 50 41 f6  |..%u..VH.....PA.|
000000a0  91 01 d1 3d cb 34 12 5c  eb 49 05 da 4f 13 65 e7  |...=.4..I..O.e.|
000000b0  1c ae 60 13 e1 0d ef 11  33 bc 8f 55 a5 e3 9c 56  |..`.....3..U...V|
000000c0  d5 78 16 7f 20 ee 54 c0  4b a9 7c 70 41 56 8c e3  |.x.. .T.K.|pAV..|
000000d0  e3 d1 81 f8 fc aa 31 ac  c1 e0 5c 92 59 0b 26 e9  |......1....Y.&.|
000000e0  89 68 96 3c d4 87 d2 ef  d7 8a ee 9a 29 78 c4 12  |.h.<........)x..|
000000f0  88 28 fb db 51 8b 66 fc  96 2e d9 3c d4 90 ea d5  |.(..Q.f....<....|
00000100  d9 49 04 da dc 61 f0 54  0e 3f c9 e2 a9 a4 7b 8c  |.I...a.T.?....{.|
00000110  67 5d 0f 15 bb 7e 30 b8  5b 6b 0a 78 ee 81 f2 b0  |g]...~0.[k.x....|
00000120  fd 60 cf d0 79 92 60 06  6f d7 b6 15 aa 39 eb 6e  |.`..y.`.o....9.n|
00000130  7c d6 38 38 44 47 4f c1  54 d4 6c 51 53 a3 6e 99  ||.88DGO.T.lQS.n.|
00000140  65 13 32 88 71 a3 c3 67  dd b9 7a 4d 33 7d 0a 47  |e.2.q..g..zM3}.G|
00000150  2b ca b0 ff b7 dd d6 9b  0b 4f 8f 5f 31 b3 85 92  |+........O._1...|
00000160  8e cc 63 5a 91 06 ce 94  cf ba 7d 52 2d 4e 22 d5  |..cZ......}R-N".|
00000170  43 37 95 27 2a a6 a1 89  65 2c fc c4 e6 47 6f 0c  |C7.'*...e,...Go.|
00000180  28 fb ed ad 16 fb 7c 2a  50 bc e2 b1 b7 22 39 c0  |(.....|*P...."9.|
00000190  7f 23 68 80 9e c9 1d 44  eb bf f0 01 49 ed 71 6b  |.#h....D....I.qk|
000001a0  af 4b 35 e4 52 de 14 75  e2 30 ae 7b 39 34 bc 72  |.K5.R..u.0.{94.r|
000001b0  c4 2b 20 1c fa 58 d1 5c  4e 4c de 50 ac 67 24 be  |.+ ..X.NL.P.g$.|
000001c0  e2 d0 ed 98 ae 60 67 24  c2 b2 c2 46 1b ab 96 bb  |.....`g$...F....|
000001d0  4e 2e 67 63 cb ca bc c6  ea 48 db b2 ed 7d 34 5a  |N.gc.....H...}4Z|
000001e0  0b 7d 5a 6a 38 8c 59 21  01 e2 7c 7c 42 80 05 36  |.}Zj8.Y!..||B..6|
000001f0  d5 b9 b8 02 31 f1 cf 80  75 7a a3 5f 38 b6 c7 07  |....1...uz._8...|
00000200  bd 2a 29 61 80 b2 19 05  2c 07 2c b6 35 ef 26 32  |.*)a....,.,.5.&2|
00000210  18 61 27 4c 27 38 d1 a1  07 ca 1a 23 d4 97 8f d1  |.a'L'8.....#....|
00000220  88 db 87 07 88 97 cf 64  88 f6 53 a5 e6 05 62 02  |.......d..S...b.|
00000230  0f c3 04 c5 0b de 66 45  dd 1e 62 bf 7d ff 8a 03  |......fE..b.}...|
00000240  23 41 b3 6a d1 2d 60 e7  3f 34 03 9f 8c a0 3c 37  |#A.j.-`.?4....<7|
00000250  5c bc 78 c9 06 f1 e4 2c  f2 38 e6 cb a1 18 1a 5a  |.x....,.8.....Z|
00000260  bc 4d 2d 4f 9e 40 de f2  73 d2 25 c7 1f dd d4 00  |.M-O.@..s.%.....|
00000270  3c 0e 9c 66 09 56 37 bf  08 12 e8 f0 d0 fa 67 a2  |<..f.V7.......g.|
00000280  f8 12 9a 46 ae 8e e4 4c  31 db 74 8a d9 ed 36 97  |...F...L1.t...6.|
00000290  62 25 6c 28 22 5e 08 80  40 07 83 47 e0 62 dc cd  |b%l("^..@..G.b..|
000002a0  ce f8 4b 48 48 19 c9 cd  ba 2c 11 9b 0b 0c 90 ea  |..KHH....,......|
000002b0  fe 17 9e 30 02 33 46 c0  49 7d c1 e4 f0 5b de e4  |...0.3F.I}...[..|
000002c0  08 52 66 b4 be 7b e7 58  54 52 11 0c 76 6e 75 99  |.Rf..{.XTR..vnu.|
000002d0  26 84 b1 42 b4 a5 6e a5  eb dd 17 d7 86 07 a0 b9  |&..B..n.........|
000002e0  17 d8 86 70 3f 9a d0 4f  3b b7 00 9f fb dd bc 94  |...p?..O;.......|
000002f0  aa f5 08 94 a8 98 22 2b  88 84 14 76 d9 d9 bd 35  |......"+...v...5|
00000300  f1 19 66 0f 25 31 7d 57  43 7b 66 c5 79 b5 4a 94  |..f.%1}WC{f.y.J.|
00000310  7b 5a 66 63 3a 7f e5 d4  e6 6b c7 f1 bf 7c 46 76  |{Zfc:....k...|Fv|
00000320  94 d7 4a d6 60 b3 5b f2  fb 74 3d ec 3c dc 8e 08  |..J.`.[..t=.<...|
00000330  e9 b0 1f 42 a4 90 6f 40  5d 48 f1 9d 28 c2 66 28  |...B..o@]H..(.f(|
00000340  51 a6 67 e2 c8 b8 f9 46  3f 42 e8 67 91 8a 25 e6  |Q.g....F?B.g..%.|
00000350  e6 4c 35 a7 9c d1 2d 4f  8e 6a 24 ba b0 ca a3 22  |.L5...-O.j$...."|
00000360  8e 75 b1 b4 f3 58 ce c9  9e 59 39 10 04 be 37 f8  |.u...X...Y9...7.|
00000370  ca d4 1e 88 54 cd f8 92  9a 54 7a 70 94 8b b0 11  |....T....Tzp....|
00000380  ee e8 ae 4a 59 3b bc 32  e5 8e aa 16 0f a0 81 e6  |...JY;.2........|
00000390  54 15 bc 9a 58 1b 4d a0  2e d5 f0 7e 0f 60 6e b0  |T...X.M....~.`n.|
000003a0  29 48 f4 4a 5c 1a d5 92  d3 1a 9d 9d d2 d9 8e 77  |)H.J..........w|
000003b0  b5 63 0d 59 c7 8d d7 f5  f6 42 7c 45 cb dd 05 05  |.c.Y.....B|E....|
...
~~~

As you can see, there is a lot of ... garbage inside the file! No SQL commands, nothing!

## End

I hope you've enjoyed this one as much as I did. Don't hesitate to write comments and keep it clean.
