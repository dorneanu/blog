+++
title = "AWS Summit in Berlin 2016"
date = "2016-04-12"
tags = ["events", "aws", "amazon", "berlin"]
category = "blog"
+++

![AWS Summit 2016 in Berlin](/posts/img/2016/670b3b02c8945633d069ba2ecd353870.jpg)

For the first time I've attended the [AWS Summit in Berlin](https://aws.amazon.com/de/campaigns/summit2016/) which against my expectations was very interesting. Not having much in common with 
AWS (at least not yet), from a [security](http://blog.dornea.nu/tag/security/) perspective the cloud still remains a very neglected threat to companies. As we all know there is some "rain"
coming down from the cloud  from time to time. And by "rain" I mean sensitive data which gets exposed due to misconfigured APIs, weak credentials or 
**insecure** applications.

![AWS Summit 2016 Berlin](/posts/img/2016/de3a6b18a864216637b801f9c11bd138.jpg)

![AWS Summit 2016 Berlin](/posts/img/2016/80864ceb309319c31cad519e8e52f8e0.jpg)

## Cloud trends 

In this years keynote [Dr. Werner ...](https://twitter.com/werner) pointed out **why** everybody is moving into the cloud and **how** they do it. But most important 
he talked about **trends** the digital world is facing at nowadays. Among these I'd like to list some.

### Data explosion
* the amount of data every company is generating or collecting is **huge**
* everybody wants to **analyze** data and get some valuable information related to their business
* data type depends on business case, so you might want to store media files differently as you would do with customer data for example
* the need for a DB as a service inside the cloud is increasing 
* Amazon has [AWS Aurora](https://aws.amazon.com/rds/aurora/details/) which is a MySQL based DB optimized for performance and high scalability

### Data warehouse everywhere
* people **need** to analyze data in **real-time** 
* smart automatic data analysis helps you understand your data
* [AWS Redshift](http://docs.aws.amazon.com/redshift/latest/mgmt/welcome.html) is **the** data warehouse you may want to use

### Analytics
* based on the available data people want to do data analysis with real-time input
* people also want to make predictions how their business might evolve based on data generated in the past

### Different ways to compute things
* depending where you want and how you want to serve your application, people choose different ways to **run** their application
* you might choose between:
    + virtual machines 
    + containers (yes, docker again)
    + functions ([AWS Lambda](https://aws.amazon.com/lambda/details/) which IMHO is very powerful)

### Deep security everwhere
* when Werner talked about security he tried to separate layers security can be applied to
* in general there is this thing "move fast vs stay secure"
* AWS does have some security:
    + network separation
    + default data encryption 
    + compliance rules that can be applied to ressources

### Everything is mobile
* mobile clients dominate the market
* there is a need for developers to test their apps against as many devices as possible
* using [AWS Device Farm](https://aws.amazon.com/device-farm/) the developers can choose from a variety of devices to test the app against
* [AWS Mobile Hub](https://aws.amazon.com/mobile/) helps you automate to app development process in the cloud

### Everything is connected
* yes, [IoT](https://en.wikipedia.org/wiki/Internet_of_Things) is indeed a threat
* there are a lot of [Industry 4.0](https://en.wikipedia.org/wiki/Industry_4.0) companies using the cluod to aggregate data from *sensors* and control the *actors*

### Hybrid
* "make the best of both worlds"


## Security

As previously mentioned, the main goal was to identify main security threats in the cloud architecture. [Dave Walker](https://www.linkedin.com/in/dave-walker-5b4194) had an excellent talk about [Securing serverless architectures](http://aws-de-media.s3.amazonaws.com/images/AWS_Summit_Berlin_2016/sessions/pushing_the_boundaries_1350_securing_serverless_architectures.pdf). Driven by "*bad things could happen, when people get creative*" operational security is being taken seriously inside AWS. A few attack vectors were shown and the corresponding countermeasures. In general he distinguished between different layers:

* application layer
    + several security were taken to secure applications in general:
        - use TLS 1.2
        - own implementation of TLS/SSL: [s2n](https://github.com/awslabs/s2n)
        - use of [Sigv4](http://docs.aws.amazon.com/general/latest/gr/signature-version-4.html) for authenticating AWS requests
* API
    + this also includes the [AWS API Gateway](https://aws.amazon.com/api-gateway/)
* in-band attacks
    + **DoS**ing the AWS components
* cross-account access
    + read more in [Cross-Account Access in the AWS Management Console](https://aws.amazon.com/blogs/aws/new-cross-account-access-in-the-aws-management-console/)
    + more details at the [AWS Security Roadshow](https://aws.amazon.com/events/security-week-2016/) this year but I couldn't find any materials on that
* lambda functions
    + functions applied to user-supplied input
    + read more in [AWS Lambda - Security and Control](https://aws.amazon.com/lambda/faqs/#security)

## Use cases

Among some (Siemens, Air Berlin, ProSiebenSat1, Dubsmash) companies already using AWS, I've really enjoyed **Air Berlin** talk where **Michael Ruplitsch** talked about their process moving stuff into the cloud:

* motivation
    + competition
    + cost efficiency
    + new distribution channels
        - personalized flight search
        - digital transformation


* lessons learned
    + do not understimate the "cloud migration"
    + educate and train involved parties
    + plan or confirm concept with AWS approved partner
    + take care of governence, change and release management
    + cross monitoring

### Berliner Philarmoniker

![AWS Use Cases](/posts/img/2016/6a1f993a91fc78d7ce549d1088099ddc.jpg)

### BitDefener

![AWS Use Cases](/posts/img/2016/8b55bd58d7fc270537f738ed335f9d79.jpg)

### SoundCloud

![AWS Use Cases](/posts/img/2016/8d8d673196bc5b15765f94e8799432b8.jpg)

## Microservices

Since AWS seems to love **microservices** , [Microservices on AWS](http://aws-de-media.s3.amazonaws.com/images/AWS_Summit_Berlin_2016/sessions/pushing_the_boundaries_1300_microservices_on_aws.pdf) was a really nice introduction. Implementing your own microservice and bringing it to the cloud, was then presented by [Julien Simon](https://twitter.com/julsimon) in [Clustering Docker on AWS with Amazon ECR & ECS](http://www.slideshare.net/JulienSIMON5/amazon-ecs-january-2016).  

