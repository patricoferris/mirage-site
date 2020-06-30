---
authors:
  - Patrick Ferris
title: MirageOS and Netlify CMS
updated: June 25, 2020 6:28 PM
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

![The Github + OAuth + Netlify CMS Workflow](images/oauth.png)

Instead of a separate server for authentication I used my own website. Most of the code is contained in the [oauth.ml](https://github.com/patricoferris/mirage-site/blob/master/src/oauth.ml) file. The image above gives a good overview of the basic mechanics of OAuth with Github and Netlify CMS. Initially you must register a new application on Github for your website to get the `client_id` and the `client_secret`. It is also important to set the "Authorization Callback URL" this will perform step (3) in the diagram e.g. `https://patricoferris.com/callback`.

For the initial authentication, Netlify CMS will hit the `/auth` endpoint and for Github we simply redirect to Github to get our temporary token. 

```ocaml
let auth_url client_id = 
  "https://github.com/login/oauth/authorize?client_id=" ^ client_id ^ "&scope=repo,user"
(* ... *)
S.respond_redirect (Uri.of_string (auth_url client_id)) ()
```

With the `client_id`, Github knows to send the token to the callback endpoint we registered earlier. We extract that from the URI. 

```ocaml
let extract_code query = 
    let questions = split '?' query in 
    let equals = List.flatten (List.map (split '=') questions) in 
    let apersand = List.flatten (List.map (split '&') equals) in 
    let rec get_code = function 
      | [] -> failwith "Error: couldn't find code query parameter"
      | "code" :: value :: _ -> value 
      | _ :: ls -> get_code ls 
    in 
      get_code apersand
```

## OCaml Cohttp

For step (3) we build a small JSON object containing the `code` (token), `client_id` and `client_secret`. This is then sent as an HTTP POST to the Github OAuth endpoint `"https://github.com/login/oauth/access_token"`. 

To send HTTP requests, we will use the [cohttp](https://github.com/mirage/ocaml-cohttp) library which builds HTTP daemons. In particular, we need the Mirage HTTP Client module to make requests to some Github endpoints. 

```ocaml
module C = Cohttp_mirage.Client
(* ... *)
let ctx = C.ctx resolver conduit in 
  C.post ~ctx ~headers ~body (Uri.of_string token_url) 
```

This is pretty much standard for an HTTP client. HTTP requests need some [headers and a body](https://tools.ietf.org/html/rfc2616#section-4.2). The `~ctx` parameter is Mirage specific and I think worth explaining. 

Machines are connected together on the internet by a series of protocols. The most widely used and taught is the [OSI model](https://en.wikipedia.org/wiki/OSI_model). 

Remember, Mirage Unikernels are completely bare-bones. Nothing can be assumed to already exist. Whilst confusing at the beginning, it makes you appreciative of the number of assumptions you make when programming in other environments. 

In the last step, making the access token available to the Netlify CMS code, I've followed the approach laid out [here](https://github.com/vencax/netlify-cms-github-oauth-provider/blob/master/index.js#L74). It involves using the `Window.postMessage` [API](https://developer.mozilla.org/en-US/docs/Web/API/Window/postMessage) to pass the access token back to the original window. This is a bit ugly in the code and involves responding with a `<script>` which handles this. 

## Netlify CMS Configuration

The last things to add our the necessary [configuration](https://www.netlifycms.org/docs/add-to-your-site/) files which explain the blogpost layout (metadata, image folder etc.) and the JavaScript and HTML files to load the initial [admin page](https://patricoferris.com/admin/) and then the React-based editing environment. These can be found [here](https://github.com/patricoferris/mirage-site/tree/master/static/admin).

## Github Actions 

With the Netlify CMS backend, blogposts are much easier to write and edit. The metadata is also automatically handled. For non-technical users it also removes the need for understanding git and Github! The final touch is to add a [Github Action](https://github.com/features/actions) to hit the synchronisation endpoint whenever new content is pushed to the repository. This is found [here](https://github.com/patricoferris/mirage-site/tree/master/.github/workflows).

🦆🦆

