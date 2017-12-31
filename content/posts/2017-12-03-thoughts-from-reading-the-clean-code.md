---
title: "Thoughts from reading: The Clean Code"
date: 2017-12-31
draft: true
---

The Clean Code is a book written by Robert Martin. It goes through sets of principles, patterns, examples, case studies, and discussion on what is clean code and how to write it. I got a recommendation from a colleage about the author so I decided to dive in to his book series. At the moment it consists of Clean Code, Clean Coder, and Clean Architecture. Right now I've read the first two, of which Clean Code already twice.

The book presented plenty of thoughts that I personally would like to learn to apply in my daily work, and I thought about going through couple of core thoughts that it left behind. I'm not going to focus on all the concepts presented in the book, but to take a quick look of all the principles presented.

In this blog post, we will go through some of my core thoughts on generic concepts, naming, layout, and how to comment code. After that, we'll scratch a bit of the surface on code abstraction, objects, and testing as well. We'll finish the analysis of the book on a small "code of conduct" that tried to encompass the principles of the book from the human-factor point of view of engineering community.

## Core thoughts

### Clean code?

Martin has collected some of quotes from reputable software developers on what is clean code. Here are my thoughts as a collection of them all:

> Clean code is what expresses the intention of the programmer consistently and in a well-structured manner. It tells the reader how the software is indended to work in an understandable and concise way. Abstraction levels, naming of entities, tests, and arrangement of the codebase are done in a way which allows the reader to go through the code in a way like reading a book or "a story of the software". The code tells you what to expect, does not duplicate, and is expressive. Even if there are ways to make it better, it can be seen that it was written by someone who cares about the software as a craftmanship.

One point still to remember is that code may not be clean straight away. It is crafted by iteration, repetition, and learning how to show your intention in a form of code. It's a constant progress throughout the life of a project.

### General concepts

So what can software development be considered to be? Martin has taken a stance it being a handicraft - an artisanship - that should express both the intention of the programmer and the structure of the application in a consistent and precise manner. Engineers are part of the designing as well when it comes to understanding the intricate details of the system and what is it meant to solve and how.

When it comes to the expression of the code and development via interations, Martin presents **Boy scout principle**, which basically means:

> Always leave the campground cleaner than you found it.

Regardless of the state of the project, key thing is that also when continuing the development of the software, also the code itself should be kept understandable and expressible. Leaving the codebase even a bit more better state after you finished will help you in the next day and others as well.

Next we will go though couple of simple principles on naming, code layout, and how to comment it based on Martin's principles. Even if these are considered, it should be noted however that common conventions are also necessary within teams and projects themselves. Every team or contributor to an open source project should follow a balance between the industry standards, recommendations, and how the existing codebase is implemented. It keeps the code consistent when common conventions are followed.

#### Naming can be hard

Ever encountered pieces of code where variables don't seem to tell what they are supposed to do? Naming things in a meaningful way can be difficult at times. Some general rules of thumb are: 

* Consider names of variables, objects, and function as their purpose is.
 * What is it meant to do?
 * What is it actually doing? Does the name tell the intention?
* Avoid side-effects with naming and consider the abstraction level where entities are named at.

There are some exceptions though: iterating through an index in loops does not have any sense to have longer ```index``` variable instead of ```i```; So when it comes to short encapsulations or iterations, some common short variable names are still a valid option. 

#### Layout and readability

This continues the topic of naming by focusing on the layout of the code. What I have learned from my previous occupations as well, is how all definitions should be defined close to where they are used. This is so called vertical alignment. Keeping local variables close and in a small scope to each other between definition and use cases keep the code readable and also maintainable if ever it needs to be refactored. Function definitions within an object should follow each other based on definitions to allow reading "deeper" into the object's internals without the need to scroll around the source file.

Source files can also begin to suffer from clutter, which can result in unnecessary scrolling around the codebase. When variables and functions that are declared are not used (Golang is great and picky in this one), and comments that add no information, it can start to affect the readability as well. To keep it clean, keep it simple.

#### Comments

There are lots of discussions when documenting code is useful and when is it not. Code can be considered as documentation when it's clear, expressive and shows the intention of it. Documentation is something that will need to be maintained throughout the lifecycle of the code to also avoid obsolete comments that don't describe the correct behavior anymore.

* Avoid redundant commenting. Does the code already tells clearly the same that the comment would do?
* If you use a VCS, it's not useful to replicate the history by adding change histories to code.
* Do not include commented out code. It will rot.
* If the function signature tells what it will do, do you need to comment it as well?

Some languages like Go also have principles that if a Go package has an exportable entity (denoted with name starting with a capital), it needs to be commented. This is a clever take on commenting on package internals.

### Logic, objects and abstraction levels

#### Objects

When it comes to implementing objects, there is a concept called **Principle of least astonishment**. It means that a function or an object should implement the behaviors that the other user can expect it to behave. This is also quite well related to the naming discussed earlier, as naming is also one aspect when it comes to expressing the intention of an entity and keeping the behavior consistent.

Martin argues, that duplication is also one sign of missed opportunity of abstraction in code. If you need to repeat yourself, are you expressing your intention in a well-structured manner? Multiple and long switch/case and if/else chains that require continous modification as more features are added could be replaced with concepts of [polymorphism](https://en.wikipedia.org/wiki/Polymorphism_(computer_science)) and templates. For instance, Martin mentions a "one switch rule":

> There may be no more than one switch statement for a given type of selection. The cases in that switch statement must create polymorphic objects that take the place of other such switch statements in the rest of the system.

To separate higher level concepts for lower level details, proper abstraction levels are needed. Simply put, the base class of an object should know nothing about the internal structures of the lower level objects that belong to the domain of lower level objects. This is also related to the law of demeter explained next. The same principles also apply for the codebase itself from source files to directory separation.

#### Law of Demeter: abstraction levels in objects vs data structures

[Law of Demeter, principle of least knowledge](https://en.wikipedia.org/wiki/Law_of_Demeter), was a relatively new concept for me even though after reading about it, I realized that I have encountered the similar principles before while having discussions about abstraction levels of projects with other engineers. In short, it is a guideline for objects to not expose their internal structure through accessors but to expose behavior. The job of exposing data is left to data structures and data transfer objects. [In this paper](https://www2.ccs.neu.edu/research/demeter/demeter-method/LawOfDemeter/paper-boy/demeter.pdf), LoD is defined so that

> * A method of an object should invoke only the methods of the following kinds of objects: 
>  1. itself 
>  1. its parameters 
>  1. any objects it creates/instantiates 
>  1. its direct component objects 

This wraps these three different object types so that objects in general should expose behavior and hide internal structure. Data structures in opposite, should expose data but have no meaningful functions and behavior. Data Transfer Objects is a form of a data structure that expose data through methods e.g. when communicating with databases, parsing messages from sockets etc.

### Testing

During my pet projects and time in work life, I have also made mistakes when it comes to creating tests for software to validate the functionalities of it. Even if the impact of testing code is quite obvious, it can be overlooked or even implemented wrong when focusing on wrong things. The book explains that:

* Tests are not only a crucial part of the development process itself, but also for maintenance.
* Tests should be fast. Slow tests hinder the development process.
* As the code itself, tests should also be expressive and show the intention of the test and functionality of an object in a clear manner.
* Testing is already an implementation to express how the software should work

To summarize the impact of this, tests should not be considered only as a mandatory part of validation and verification of a software. It is also to improve maintainability and for the developer to express what the intention of the application should be. It will also improve readability of the code.

## Conclusion

In overall, the Clean Code was a thought-provoking book for me. It also made me realize some of the root causes of my mistakes in the past when it comes to software development. The code examples in the book are written in Java, but huge amount of the principles and patterns that were presented apply to the field of software development also in general.

At work, the book made me understand more of the fundamental practices and considerations that a software project needs. In this blog post, only a small fraction of the principles shown in the book were presented. It's a highly recommended read for anyone for software engineering field who cares about the craft, and goes more deeply into how to design and implement software. It bundles all those multiple software engineering fundamentals from online courses, articles, and university classes together into consistent guidelines on how to write concise and clean code.

### Software Artisan Code of Conduct 

After reading the book and encountering some interesting Twitter message threads on the developer communities, I thought about making a draft of kind of code of conduct for software developers. It is a list of topics to improve ourselves as professionals and bringing engineering communities together as well.

Maybe this can be updated someday, but here are couple of points where to start from:

* Improvement through iteration - No project is the shiniest form in it's first iterations. 
* Openness for learning and aim to improve my crafts to my best attempt.
* Making mistakes belongs to the steps in learning.
* Mentoring and supporting others is part of engineering to foster growth of myself and others.
* Keep an open mindset towards new topics and counterarguments.
* Engineering knowledge flows both ways from new engineers to experienced and back.
* Respect fellow engineers - aim to discuss openly and with curiosity.
* Take responsibility of own crafts.