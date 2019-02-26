# The Publisher

To install, `cd` to this directory and run:

```
sudo bash ./install-publisher.sh
```

***Note:*** this assumes that you are running on a Debian-based system, and have
some specific directories on your system. This could change sometime, but I'm
actually *very* lazy. Accepting pull requests, however.


## Manual Installation

Currently, this is only known to install on Ubuntu 16.04. I'm sure it would work
on other Debian flavors out of the box - but you never know until you know, you
know?

Several files are of interest:

1. `publisher.sh`
1. `config`
1. `blog.cron.d`
1. `blog.apache.conf`

I suggest creating a `/var/www/html/publisher` directory to house at least
`publisher.sh` and `config`.

The contents of `blog.cron.d` could simply be copied to `/etc/crontab`. You can
edit the execution portion of the cron job with 3 arguments. They are, in order:

1. The location of the config file
1. The location of a "last check" timestamp file (when was the repo polled
   last?)
1. The location of a "bad fetch" file. This is a temp file containing
   information in case of a bad `git fetch`.

You can also just leave arguments out and let The Publisher figure them out.

The apache configuration likewise needs to either be copied to the global
apache configuration or put in one of the `*.conf` directories.

You can just copy it to your main apache configuration (we'll use
`/etc/apache2/apache.conf` as an example, but it could be
`/etc/httpd/httpd.conf` just as easily):

```
cat blog.apache.conf >> /etc/apache2/apache.conf
```

***Note:*** Obvious, but make sure the user specified in the cron job has
appropriate ownership to all the directories touched (the `target` in the
`config` file, and the `clone_target` directory as well).



## Why are directories hardcoded?

Because I don't care, really. This was built for me. It's trivial enough to
make this whole thing (not just publisher) system agnostic, but again:
_*I*_ _*just*_ _***don't_ _care***_.


## Todo

- [ ] Make it work on more linices (linuxes?)
- [ ] Add logrotate for bloglog
- [ ] Interactive install?
