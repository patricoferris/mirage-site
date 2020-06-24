---
authors:
  - Patrick Ferris
title: Mirage and Netlify CMS
updated: 2020-06-24
tags:
  - mirage
  - netlify
  - web-dev
---
This post builds on the [Unikernel Site](/blogs/unikernel-site) post where we created a simple git-based Mirage Unikernel blog. Now we'll modernise that stack by adding a content management system (CMS). 

The tool of choice is the open-source CMS from [Netlify](https://www.netlifycms.org/). Netlify are a hosting company with a great suite of tools for managing modern [JAMStack](https://www.netlify.com/jamstack/) web applications. The CMS has great integration support with Netlify (a few clicks) but is not tied to that one service as we'll see. It is a CMS for git-based data stores.

## OAuth and Github 
[OAuth](https://tools.ietf.org/html/rfc6749) is an open standard for authentication on the internet. The basic idea is granting users access to information on other website without having to share passwords. The blog content of this website is held on Github and the Netlify CMS wants to ability to read and write that content. We use OAuth to authenticate on Github. 

The Netlify CMS expects this to be handled by a server with specific endpoints to do certain jobs. I based the Mirage solution on [this great blog post](https://tylergaw.com/articles/netlify-cms-custom-oath-provider/).