---
title: "How to get started with Nix"
author: Alessandro Marrella
date: 2020-05-13
tags: [nix]
description: Useful links and resources
---

I started learning Nix a few months ago, when it was introduced to the company I work for by some brilliant coworkers. I'm still learning and exploring this space, but I thought I'd share a few tips and resources that helped me start this journey to help newbies like me start working with this awesome tool.


## What is Nix
From [nixos.org](https://nixos.org):

> Nix is a powerful package manager for Linux and other Unix systems that makes package management reliable and reproducible. It provides atomic upgrades and rollbacks, side-by-side installation of multiple versions of a package, multi-user package management and easy setup of build environments. 

So yeah, this post talks about a package manager. Usually this is something not very exciting. I can feel readers just thinking "aren't you just happy with Brew?". The truth is that Nix solved so many problems well that it's very hard for me not to get excited about it! 


Let's break down the features listed in the description above:
- *package management*: well if this wasn't a feature we wouldn't really talk about a package manager
- *makes package management reliable and reproducible*: here stuff starts to get interesting. With Nix stuff works on _everyone_'s machine, not just yours. This is because of how packages are built. Nix will pull all the necessary dependencies for you and packages are usually guaranteed to not need anything else (it makes no assumptions on what you already have installed). 
- *atomic upgrades and rollbacks*: for real, it's like having transactions but for installations. Because of how Nix works (more about it later), multiple versions of the same package can coexist in the system (!) so upgrading will just mean referencing the new version, rolling back referencing the old one. And for everything else, there is garbage collection :) 
- *side by side installation of multiple version of a package*: i spoilered this in the point above. But this works _really_ well. You no longer have to decide which version of `npm` you need in your system and you can even start ephemeral shells with specific versions of stuff.
- *multi user package management*: usually package managers install stuff in user space. Nix normally install stuff so that it's available to multiple users in the system.
- *easy setup of build environments*: it's relatively easy to set up isolated build environments with the packages and versions you need. I say relatively because you'd still have to learn Nix, and the learning curve is steep. But once you learn it, it empowers you to do this. It's much harder to achieve this with "easier" package managers (so much that people starting creating docker images with their build environments, ugh).


I hope this list convinced you that learning Nix is worth it :) There are many more exciting features (like distributed binary caches, or the possibility to create small docker images and AMIs with the same language and only pull the runtime closures required), but now let's proceed with the learning stuff.

## How to learn Nix

### Learn how to install Nix
If you are on Linux or on a Mac Os X version *10.14 or earlier (NO CATALINA)* , no problem, just follow the instructions here: https://nixos.org/nix/manual/#sect-multi-user-installation


I am linking to the multi user installation instructions because it seems to be the most frequently adopted in the community, so it might be easier to get help. 


If you are on Mac Os X *10.15 or above (CATALINA or later)*:
- Install nix via: `curl -fsSL https://nixos.org/nix/install | sh /dev/stdin --daemon  --darwin-use-unencrypted-nix-store-volume` 
- Close and reopen the terminal to make sure the right environment is loaded.

### Learn to use Nix as a your package manager replacement

This video will explain briefly how to use nix as a "normal" package manager:
[Nix as a Homebrew Replacement](https://www.youtube.com/watch?v=NYyImy-lqaA)


I will refer to many other videos from the [Nixology](https://www.youtube.com/playlist?list=PLRGI9KQ3_HP_OFRG6R-p4iFgMSK1t5BHs) playlist created by Burke Libbey throughout this article. If you want to skip ahead and watch all of them they are a great resource!


Note: to search packages, the video mentions this link: https://nixos.org/nixos/packages.html?channel=nixpkgs-unstable


### Learn how to use and create nix-shells

Nix shells are a very powerful tool to create isolated development environments. I started creating them for many of the projects I am working on (some projects even have more than one shell) and they truly are a blessing. No more fiddling with different versions of software required in different projects. 


You can start a nix-shell in any project that contains a `default.nix` or `shell.nix` file (for example [this blog](https://github.com/amarrella/blog)) and you will be dropped into a shell which contains the dependencies you need to work. To learn how to create these files, check out the [Learn how to write a derivation in Nix](#learn-how-to-write-a-derivation-in-nix) section.


You can also start random nix shells without those files, just by specifying the packages you need.
For example `nix-shell -p nodejs-12_x` will start a shell with node 12 installed, without polluting your global PATH.


You can also reference remote paths to start your shell. For example `nix-shell https://github.com/amarrella/blog/archive/master.tar.gz` will start the nix-shell used to build this blog.


#### Automatic nix-shells with direnv
[direnv](https://direnv.net/) is a software that lets you load and unload enviroment variables when entering and exiting a directory. In combination with a nix shell, this will allow you to get an isolated environment as soon as you `cd` into the directory. Install [direnv](https://direnv.net/docs/installation.html) and [nix-direnv](https://github.com/nix-community/nix-direnv). 


To use it, create a `.envrc` file in the directory together with the nix shell and add the following line:
```
use nix
```


That's it. To enable direnv in the directory, run `direnv allow` and now every time you cd into that directory the environment is loaded.

### Learn the Nix language

Nix has its own purely functional and (unfortunately) dynamically typed programming language. It's a quite simple language, designed specifically for the Nix package manager. You can take a tour of the language (you can read up to slide 23, the later slides are way more advanced and not really required): https://nixcloud.io/tour/

### Learn how to write a derivation in Nix
From [nix manual](https://nixos.org/nix/manual/):
> Packages are built from Nix expressions, which is a simple functional language. A Nix expression describes everything that goes into a package build action (a “derivation”): other packages, sources, the build script, environment variables for the build script, etc. Nix tries very hard to ensure that Nix expressions are deterministic: building a Nix expression twice should yield the same result.


I suggest first watching these 3 videos from [Nixology](https://www.youtube.com/playlist?list=PLRGI9KQ3_HP_OFRG6R-p4iFgMSK1t5BHs) to get an idea on what you can do with derivations:
- [Packaging a Gem as a Nix derivation](https://www.youtube.com/watch?v=61RCi_5IgEY)
- [Using nix to prettify `ls` output on macOS ](https://www.youtube.com/watch?v=1nU_hR2kod4)
- [Fetching stuff from the internet using Nix derivations](https://www.youtube.com/watch?v=XMauFegrtB4)


Then when you have a general idea and you need to dig deeper [Nix pills](https://nixos.org/nixos/nix-pills/index.html) provides a good overview on how to build nix derivations.


For a complete reference, you can check out the [nix manual](https://nixos.org/nix/manual/), which contains very useful sections such as the one dedicated to [Nixpkgs library functions](https://nixos.org/nixpkgs/manual/#sec-functions-library). 

#### Learn how to create derivations to package your code
There are several libraries that help you package your code depending on the programming language you are using. The [nixpkgs manual](https://nixos.org/nixpkgs/manual/#chap-language-support) links some of them but sometimes checking out what is in the community leads to easier solutions. For example for Haskell, I'd use [haskell.nix](https://github.com/input-output-hk/haskell.nix).

##### Learn to create docker images with Nix
Nix is also an excellent way of creating small and reproducible docker images. The [dockerTools](https://nixos.org/nixpkgs/manual/#sec-pkgs-dockerTools) documentation provides some reference and examples.

### Learn how to set up your computer or servers with Nix
You can use Nix to manage your home directory and all your user's environment via [home-manager](https://github.com/rycee/home-manager). It is really refreshing having a home directory and user environment managed in a declarative way, with easy updates to new versions and the possibility of rolling back at any point.


You can check out these videos from [Nixology](https://www.youtube.com/playlist?list=PLRGI9KQ3_HP_OFRG6R-p4iFgMSK1t5BHs) to learn more:
- [Installing home-manager](https://www.youtube.com/watch?v=Ubhc94lrfTo)
- [Getting started with home-manager](https://www.youtube.com/watch?v=OgUvDXxHlLs)
- [From nix-env to home-manager](https://www.youtube.com/watch?v=PmD8Qe8z2sY)
- [home-manager: reading the source](https://www.youtube.com/watch?v=CID_ZbwObJ8)


The [home-manager manual](https://rycee.gitlab.io/home-manager/) is also a great resource. Make sure you check out the [configuration options](https://rycee.gitlab.io/home-manager/options.html) appendix as well to see everything you can configure with home-manager.


You can also use the power of Nix to manage everything that is installed on your machine by [using NixOs as a linux distribution](https://nixos.org/nixos/) or installing [nix-darwin](https://github.com/LnL7/nix-darwin) on your macOs. Both follow the same principle: you configure your machine using a configuration file and you apply changes atomically with `nixos-rebuild` or `darwin-rebuild`. Also here you have the possibility to roll back changes at any point. Here you can check the [nixos manual](https://nixos.org/nixos/manual/) and [nix-darwin manual](https://lnl7.github.io/nix-darwin/manual/index.html).


If you are curious about my configuration, it's published on [Github](https://github.com/amarrella/nix-config).

## Getting help from the community
Check out the [nix community](https://nixos.org/community.html) page for many official links. I personally lurk on the [discourse forum](https://discourse.nixos.org/), on the #nix channel in the functional programming slack ([invite here](https://fpchat-invite.herokuapp.com/)) follow Github issues on the [nix](https://github.com/nixos/nix) and [nixpkgs](https://github.com/nixos/nixpkgs) repositories.

