---
title: "Djangocon Europe 2018 - Talk picks"
date: 2018-05-27
draft: true 
---

Djangocon was arranged last week in Europe. All the talk recording were released
in their [YouTube channel](https://www.youtube.com/user/djangoconeurope/videos).
Having done projects recently with Django, I was curious to dive in and check out
some of the recent developments and applications of Django and what kind of 
other technologies have been built around it.

### Keynote

### GraphQL in Python and Django

[https://www.youtube.com/watch?v=ix_DSdxgoK0](Link to the talk)

Having some earlier experience with Flask and GraphQL, I was curious to see how
`graphene` (GraphQL module for Python) can be integrated together with Django. 

When it comes to GraphQL, common misunderstanding is that GraphQL is not an API but 
it is a query language to expose and mutate data via an API endpoint.
I liked how it was addressed in the speak how GraphQL fares to RESTful design:
> REST is not a standard but rather a design concept for telling that our data is a collection of resources that can be accessed and manipulated using RESTful endpoints.

It is a very practical way to access data on per-need basis
instead of querying individual resources on various API endpoints. This makes it quite powerful in 
situations where you are designing backend software for clients that
you are not in control of or need data more flexibly, like client-to-service 
communication and not service-to-service communication e.g. between internal 
services, where more tighter coupling can be needed or designed (REST/RPC).

In the talk, `graphene-django` package was introduced and basic development was shown
that was helpful in understanding how it can be integrated to your Django
applications. Some of the strengths and weaknesses of current version of `graphene-django` were also
discussed. 

Django REST framework integration was presented and demos were also shown on how 
existing Django models can be utilized for Graphene's `ObjectTypes`, including 
basic `resolve()` and `mutate()` handlers for GraphQL operations. The talk also goes through topics such 
as authentication using e.g. Django sessions, headers, token parameters 
(e.g. in the query or mutation object). However, there was no
built-in features for permissions yet, and no decoration-based access controls, which 
mean that granular access control would need to be handled manually e.g. in the Graphene objects' resolvers and mutators
or higher in the abstraction level in your application depending on your use cases.

There was also interesting discussion around some strategies to improve the quality and availability
of your service in case of large, repetitive, or deep queries. This included ways such as timeouts, 
nesting limits, query cost counting, and static queries.

### Protecting Personal Data with Django

[Link to the talk](https://www.youtube.com/watch?v=b6KEoNVKFxM)

Ah, GDPR. The European Union legistalion that regulates the processing of personal data.

This talk discusses the new regulation and its effects on software industry in a humorous
and informational way. As the talk mentions, there was another similar directive in 1995, 
but the scope and enforcement of this has changed dramatically after the introduction of
GDPR (loved the meteorite reference). 

Very good and informational talk to watch to understand the biggest changes affecting the software 
industry: terminology, what is personal data, how it applies to company developers and freelancers,
user rights and tasks that belong to the responsibility of software design, and anonymization and 
pseudonymization of data and external static file access using proxies.

Considering Django, the presenter also mentions some tips on how Django can help in 
the data storage using Djangos `views` and field handlers. 

### Creating Solid APIs

[Link to the talk](https://www.youtube.com/watch?v=1pgQXzoUcgk)

When designing APIs and their documentation, how often are humans being thought of 
who are the first ones that interact with your API after all? 

The talk focuses on general API design: How to make API design human-driven (albeit 
the beginning was quite much documentation-driven), and then extending that 
to technical details for service development and what things to consider when 
it comes to common standards and topics on simplicity vs complexity. 

Even if most of the topics in the talk were familiar already,
I find it fun and good to always to go back to basic principles and revise current knowledge as well.

### Banking with Django - how not lose your customer data

[Link to the talk](https://www.youtube.com/watch?v=PEo7I8N8zlU)

This presentation was from a Finnish payment service company called Holvi.
They provide services for individuals (entrepreneurs) and companies for ecommerencing, billing,
and money transfers - business accounts.

Holvi uses Django extensively as their main backend, which makes this talk
extremely interesting from many points of view: banking and money transfers require
high availability, robustness, scalability, and reliability. Reasons why
Django was picked as one of their main backends was the supportive community and large ecosystem,
and Django was highlighted being proven software with a successful track record and 
reliable long-term support.

In the talk, separation between core and customer facing services, reliability
and service sanity checks, and service segregation is
also discussed. Different models and techniques on asynchronous tasks are introduced with "Inbox & Outbox" model
using Django, where senders and receiver ends utilize Celery for asynchronous operations,
and how to guarantee idempotency and service-to-service reconciliation of data contents.

If you want to get a brief surface on how Django can be utilized in backing setups
on smaller startup scale to enterprise level, check out this talk.

### Building real time applications with Django

### Taking channels async

### Making smarter queries with advanced ORM resources

[Link to the talk](https://www.youtube.com/watch?v=eUM3b2q27pI)

In this video, the advantages and disadvantages of advanced ORM resources of Django are explored.
They are compared to the more usual ones in terms of performance and readability, and how 
more advanced ORM resources can be utilized to process data in more performing manner.

Talk discusses, how SQL can help writing complex (move processing more to the database etc.)
that are hard to implement in django, and how they can be fit together using these more advanced ORM resources.
These include `prefetch_related`, `select_related`, `only`, `defer`, `values`, `values_list`, and database
caching. Also the use of `assertNumQueries` with unit tests is discussed and how it can help you debugging on how expensive 
your database queries can be on your database in terms of the number of commands executed by your ORM. This
might provide visibility and insight on improving your ORM queries to minimize the amount of executed consecutive commands,
and it wraps it well together with prefetch queries in retrieving relataed objects by context and subqueries.
