+++
title = "Birthday paradox/problem"
author = "Victor"
date = "2010-05-07"
tags = ["coding", "python"]
category = "blog"
+++

In probability theory, the birthday problem, or birthday paradox pertains to the probability that in a set of randomly chosen people some pair of them will have the same birthday. In a group of at least 23 randomly chosen people, there is more than 50% probability that some pair of them will have the same birthday. Such a result is counter-intuitive to many.

For 57 or more people, the probability is more than 99%, and it reaches 100% when, ignoring leap-years, the number of people reaches 366 (by the pigeonhole principle). The mathematics behind this problem led to a well-known cryptographic attack called the birthday attack.` [Source: [wikipedia][1]]

Well I tried to show that using empirical methods: I randomly generated groups of `persons` and calculated the probability that 2 people will have the same birthday. Therefor I've been using Python due to its simplicity and clean coding style. Here is my code:

~~~.python
def birthday_paradox():
""" We calculate the probability that 2 persons will have the same
birthday.
"""
import random
random.seed()

# How many times should the experiment be conducted
c = 10000

def generate_bdays(t):
""" We generate t random birthdays between 1 and 365.
Generated birthdays will be returned as a list.
"""
l = []
for j in range(t):
b_day = random.randint(1,365)
l.append(b_day)

return l

def duplication(l):
""" Does the list contain any duplication ? """
d = {}

# First we create a dictionary:
# [Birthday] -> [Number of occurences]
#
# [Birthday] is in our dictionary key and
# [Number of occurences] the key value
for n in l:
d[n] = d.get(n, 0) + 1

# Check if any key/birthday is duplicated
for c in d.values():
if c > 1: return True

return False

def experiment(n,t):
""" We create _t_ random birthdays. We do that _n_ times.
Return value:

Number of duplications (if any) / n

"""
duplikate = 0
for i in range(n):
if duplication(generate_bdays(t)):
duplikate += 1

return duplikate / n

# Here we conduct our experiment
for i in range(50):
print("Number of persons:",i, " Probability: ",experiment(c,i))

if __name__ == "__main__":
birthday_paradox()
~~~

Simple run will show:

~~~.shell
$ python3.1 birthday_paradox.py
Number of persons: 0 Probability: 0.0
Number of persons: 1 Probability: 0.0
Number of persons: 2 Probability: 0.0023
Number of persons: 3 Probability: 0.0088
Number of persons: 4 Probability: 0.0172
Number of persons: 5 Probability: 0.0246
Number of persons: 6 Probability: 0.0417
Number of persons: 7 Probability: 0.0591
Number of persons: 8 Probability: 0.0709
Number of persons: 9 Probability: 0.0908
Number of persons: 10 Probability: 0.1152
Number of persons: 11 Probability: 0.1421
Number of persons: 12 Probability: 0.1745
Number of persons: 13 Probability: 0.2005
Number of persons: 14 Probability: 0.2318
Number of persons: 15 Probability: 0.2603
Number of persons: 16 Probability: 0.2759
Number of persons: 17 Probability: 0.3205
Number of persons: 18 Probability: 0.3499
Number of persons: 19 Probability: 0.3765
Number of persons: 20 Probability: 0.4118
Number of persons: 21 Probability: 0.4353
Number of persons: 22 Probability: 0.4745
Number of persons: 23 Probability: 0.5078
Number of persons: 24 Probability: 0.5311
Number of persons: 25 Probability: 0.5681
Number of persons: 26 Probability: 0.5978
Number of persons: 27 Probability: 0.6261
Number of persons: 28 Probability: 0.6486
...
~~~

As we, see we need** at least 23 persons** in order to have a **probability greather-equal 50%**.

 [1]: http://en.wikipedia.org/wiki/Birthday_problem
