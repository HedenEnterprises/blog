# Heden Enterprises Blog Builder

> Simple project for converting markdown posts to published static html pages.


## What?

The blog builder project allows me to focus more on creating good content than
worrying about formatting or writing html for static pages.

Pull requests are welcome.


## Why?

Because I like markdown files. They are easy to read in command line editors
and desktop editors, even when they are being viewed in the repository online.

Yes, I know there are things out there already that do this. They didn't suit
my fancy - also I like building things. So I built this thing.


## How?

The steps are pretty simple, actually...

1. I create a blog post by adding a markdown file to the `posts/` directory.
1. I commit my changes.
1. Travis CI launches a build - this build installs a few dependencies and then
   scans the `posts/` directory for changes - if there have been no changes,
   then nothing happens.
1. Otherwise, all of the markdown files in the `posts/` directory are processed
   into html files (and beautified). The files in the `template/` directory
   are also applied to the processed files.
1. The processed files are placed in the `published/` directory.
1. Travis CI then commits these changes and pushes back to the repository with
   a special commit message. *(That way when Travis picks that commit up, it
   knows to ignore it)*
1. A scheduled job on the blog server polls the repository regularly to see if
   any commits have happened recently with the special Travis CI commit message.
   If it polls and finds one, it fetches the repository contents and publishes
   the updated static pages.


## When?

Tuesday.


## Who?

Everyone. You're invited to fork or contribute. I'd like to see it being used
by others at some point. I know there are other things out there that do a
heck of a lot more than this - but that is kind of the point of keeping this so
simple.


## Anything else?

If you're developing or writing blog posts with this software - you should
install the git hook. It is a pre-commit hook that checks that all of the
markdown files for template variable compliance.

```
bash ./builder/install-git-hook.sh
```
