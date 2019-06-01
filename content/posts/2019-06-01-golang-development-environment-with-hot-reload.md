---
title: "Go Development Environment with Docker and Hot Reloading Using Realize"
date: 2019-06-01
draft: true
---

## Introduction

Hot reloading with task runners is extremely useful in software development.
While having a local development environment running on the background, testing it, 
continuously doing code, each of the file written (saved) to the disk can trigger a task
in a task runner software. These tasks can be configured to rebuild your software and
restart it, run unit tests, and much more. Some examples of these software include 
Grunt for JavaScript, Django in Python has this natively built in in the test
server that ships with the package. For Golang, there is an utility tool called `realize`.

In all their simplicity, these kind of task runners can make life as a developer just a bit more easier as
manual chores and CLI work can be automated.

In this blog post, we will go through setting up a containerized Golang development
environment using Docker and Realize. At the end, we will have an environment that needs
only `docker-compose up` to get everything up and running, where each saved `.go` file will trigger
a rebuild, unit tests, installs and restart of our glorious RESTful Hello World! service.

## Implementation

First off, let's create a development environment and a `Dockerfile` in which we will
test our code in.

`Dockerfile` 
```
```

`.realize.yaml`
```
```

`docker-compose.yml`
```
```

## Conclusions

## References

