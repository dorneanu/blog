+++
title = "HowTo: Get SETOF from Array in PostgreSQL"
date = "2009-03-30"
tags = ["coding", "howto", "sql", "admin", "postgresql"]
category = "blog"
+++

The use of so called "procedural languages" in PostgreSQL allows the user to write user-defined functions in other languages than SQL or C. Since every query is sent to the server, the database server has to know how to interpret and handle function statements. As the PostgreSQL documentation describes, the function handler itself is a C language function compiled into a shared object and loaded on demand. All you have to do is to install the *language* into your database. Besides that you'll have to install the pre-compiled shared objects on your system. On my system (Debian 5.0) I had to install the `postgresql-plperl` package. Afterwars I connected to the database and typed:

~~~.sql
CREATE FUNCTION plpgsql_call_handler ()
   RETURNS OPAQUE
   AS '/usr/lib/postgresql/8.3/lib/plpgsql.so'
LANGUAGE 'C';
~~~

Of course you'll have to look up for the right file path in order to work. Finally I was able to use the language `plpgsql` in my functions. If you need help installing languages just check out the PostgreSQL [documentation][1] (it helped me too).

## Polymorphic types

When speaking of polymorphism in PostgreSQL, we actually refer to the polymorphic functions. So what&#8217;s the difference between a polymorphic type and a polymorphic function? They're related to each other. In fact every function declared to use polymorphic types is called as a polymorphic function. These types (pseudo-types) are `anyelement` and `anyarray`. So when arguments of these types are passed to a function, it can handle with different data types. Imagine a function called `equal` that compares two arguments and returns a boolean:

~~~.sql
CREATE or REPLACE FUNCTION equal (anyelement,anyelement)
  RETURNS boolean AS
  $$
      ...
      IF $1 == $2 THEN
          return TRUE;
      ELSE
          return FALSE;
      END IF;
  $$
LANGUAGE 'sql';
~~~

`equal` will take 2 input values of the SAME data type. Otherwise how could you e.g. compare a string to an integer? Read [more][2].

## Getting started

I'll use following employees table:

~~~.sql
create table t_employee
(
        ID integer NOT NULL,
        name text,
        salary real, 
        start_date date,
        city text,
        CONSTRAINT primkey_ID PRIMARY KEY (ID)

) WITH (OIDS=FALSE);
~~~

Then we insert some new data into the table:

~~~.sql
INSERT INTO t_employee(ID,name,salary,start_date,city) 
   VALUES (1,'Peter','2100','2003-06-19','Stuttgart');
INSERT INTO t_employee(ID,name,salary,start_date,city) 
   VALUES (2,'Peter','2100','2003-06-19','Stuttgart');
INSERT INTO t_employee(ID,name,salary,start_date,city) 
   VALUES (3,'Marc','1560','2001-02-25','Mannheim');
INSERT INTO t_employee(ID,name,salary,start_date,city) 
   VALUES (4,'Stefan','1100','2008-03-14','Hamburg');
INSERT INTO t_employee(ID,name,salary,start_date,city) 
   VALUES (5,'Gerd','900','2004-06-24','Hannover');
~~~

`t_employee` will now contain:

~~~.sql
select * from t_employee;

 id |  name  | salary | start_date |   city    
----+--------+--------+------------+-----------
  1 | John   |   1100 | 2002-05-01 | Berlin
  2 | Peter  |   2100 | 2003-06-19 | Stuttgart
  3 | Marc   |   1560 | 2001-02-25 | Mannheim
  4 | Stefan |   1100 | 2008-03-14 | Hamburg
  5 | Gerd   |    900 | 2004-06-24 | Hannover
(5 rows)
~~~

In the next step we'll try to write a function which returns a SETOF containing our data.

## SETOF vs. Array

Now we need a function which returns our data as a SETOF. In my function I can declare `l_row` of type `t_employee`(see below). In this variable data is structured as in the table `t_employee`. So far, no big deal. Just let us have a look at the function:

~~~.sql
CREATE or REPLACE FUNCTION get_employee()
   RETURNS SETOF t_employees AS
$BODY$

DECLARE
   l_row t_employee;

BEGIN

   -- Loop through rows
   FOR l_row IN
      SELECT * FROM t_employee
   LOOP
      -- Return data
      RETURN NEXT l_row;
   END LOOP;
END;
$BODY$
   LANGUAGE 'plpgsql';
~~~

Okay. But as you might have noticed, the purpose of this howto ist to show you how to get a SETOF from an array. Therefor we need some array. We'll modify `get_employees` in this way:

~~~.sql
CREATE or REPLACE FUNCTION get_employee()
   RETURNS SETOF t_employee AS
$BODY$

DECLARE
   l_row t_employee;
   l_array t_employee[];

BEGIN

   -- Loop throught rows
   FOR l_row IN
      SELECT * FROM t_employee
   LOOP
      -- Put all data into array
      SELECT array_append(l_array,l_row) INTO l_array;
   END LOOP;
   ...
END;
$BODY$
   LANGUAGE 'plpgsql';
~~~

IN the next step we'll have to extract SETOF data from the array. Since you can't do that with built-in Postgres functions, we'll need some auxiliary function:

~~~.sql
/*
   Polymorphic function 'unnest': ANYARRAY -&gt; SETOF
   Return SETOF from ANYARRAY
*/

CREATE or REPLACE FUNCTION unnest(ANYARRAY)
RETURNS SETOF ANYELEMENT
LANGUAGE SQL AS

$$
   SELECT $1[i] FROM generate_series(array_lower($1,1),array_upper($1,1)) i;
$$;
~~~

I hope you have noticed the `anyarray` which is given as a parameter to the function. So you can use `unnest` for every type of array. That's the great point when using polymorphic functions: You have some kind of generic function and you can use it for all arrays. Well having this function implemented, we can now modify `get_employees`:

~~~.sql
CREATE or REPLACE FUNCTION get_employee()
   RETURNS SETOF t_employee AS
$BODY$

DECLARE
   l_row t_employee;
   l_array t_employee[];

BEGIN

   -- Loop throught rows
   FOR l_row IN
      SELECT * FROM t_employee
   LOOP
      -- Put all data into array
      SELECT array_append(l_array,l_row) INTO l_array;
   END LOOP;

   -- ARRAY -&gt; SETOF
   FOR l_row IN
      SELECT * FROM unnest(l_array)
   LOOP
      return next l_row;
   END LOOP; 
END;
$BODY$
   LANGUAGE 'plpgsql';
~~~

 [1]: http://www.postgresql.org/docs/8.3/static/plpgsql.html
 [2]: http://www.postgresql.org/docs/current/static/extend-type-system.html
