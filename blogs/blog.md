---
author: Patrick Ferris 
title: A Mirage Blog
date: 2020-01-22
tags:
  - mirage
  - unikernel
---

MirageOS is a library Operating System designed for building specific, well-performing unikernels to run a myriad of applications. This post will cover how this site was setup inspired primarily from the [Mirage](https://mirage.io) website. 

# Overall Architecture 

This isn't the post to explain about unikernels or MirageOS. 

A simple static website that has a blog feed has the following requirements: 

 - Blog post content: this will be managed through markdown files (a standard approach) 
 - Generating blog posts from this content and managing a feed of these posts
 - A simple home and about page 
 - Serving all of this content over `http` or `https` 

It's very minimal, but as this is a fairly "niche" approach to building such sites, there are lots of things to learn and documentation (or other tutorials) can be scarce. We'll be using to libraries to manage the types in our website: `COW` (Caml on the Web) and `Cowabloga`. 
