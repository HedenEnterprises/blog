# Executor

> The executor. Executioner. Judge and jury. Etc.

This lil buddy is responsible for handling plugins.


## What are plugins, hedenface?

Glad you asked.

Plugins are little itty bitty pieces of code that are executed at certain
points when *other code* is executing.

Sometimes, relevant data is passed to the little itty bitty pieces of code
(hereinafter referred to as "plugins"). You can usually find all of the
important information about what kind of data is passed to what kind of plugin
or what kind of data the plugin needs to return in a reference document.

This is that reference document.


## The plugin types

In order to give an example on the directory structure, the types must be
briefly described.

A plugin is specified by app and type. The app is literally one of the strings
`builder` or `publisher`. This is the first argument that the executor receives.

The type is specific to the app. The list below defines the types. More detail
is provided in sections below.

* `builder`
    * `pre-files`
    * `post-files`
    * `pre-markdown`
    * `post-markdown`
    * `pre-tidy`
    * `post-tidy`
    * `pre-git-commit`
    * `pre-git-push`
* `publisher`
    * `post-config-load`
    * `pre-last-check`
    * `post-last-check`
    * `pre-rsync`
    * `post-rsync`


## The plugin directory structure

The executor is ran at a few specific points during either the builder or the
publisher process.

If you'd like to use a plugin, you need a `plugin/` directory. A few example
plugins are included in the repository for you to look at and edit to your
liking.

Ultimately, the way the executor looks for a plugin is based on a string
containing both the app and the type (look at the previous section).

Given that information, the executor looks in the following order:

1. `plugins/app-type/*.plugin`
1. `plugins/app/type/*.plugin`
1. `plugins/app-type*.plugin`

So let's say we want to run a plugin prior to the processing of files during
the builder process.

The executor would look for files that match the following glob:

1. `plugins/builder-pre-files/*.plugin`
1. `plugins/builder/pre-files/*.plugin`
1. `plugins/builder-pre-files*.plugin`

And execute them as found in that order (according to how `ls` lists the files).

This gives you options on organizing your plugins.

Which is silly.


## Important things to keep in mind

1. The only things that are guaranteed to be staged in git are the `./posts.md5`
    file and all contents of the `./published/` directory. If you are adding
    files to the `./posts/` directory, you need to add those manually to the
    git staging area.
1. There are a ***lot*** of different ways to accomplish the same thing. Pick
    whichever one you want. Just make sure you aren't screwing up the flow.


## Plugin return codes

There are only two reserved return codes. `0` is considered to be successful
plugin execution, `9` is considered a **catastrophic failure** which results in
publisher termination, and all other return codes are considered *warnings*.


## Plugin references


### publisher


#### post-config-load

This is loaded after the `config` file is sourced and after the variables set
in it are normalized a bit.

##### arguments

* `$repo_url` - The remote URL of the repository to clone.
* `$clone_target` - The directory that will store the full repository once it
    is cloned or pulled. **This is a full path**
* `$target` - The directory which will store the published data. **This is a
    full path**

##### alterations

None.




### pre-last-check

This happens directly after the `$frequency` variable is sanitized, and directly
before the publisher checks if the last-check file exists.

##### arguments

* `$frequency` - The amount of time in minutes to poll the repo to check for
    changes.
* `$last_check_file` - The location of the file that contains the timestamp
    of the last time the repository was polled. **Not a full path**, **This file
    is not guaranteed to exist**

##### alterations

Altering the contents of the file containing the last check timestamp could
cause either the repo to be polled earlier or later than anticipated.




### post-last-check

This is executed directly after the last check file is updated with the current
timestamp.

##### arguments

* `$current_timestamp` - The timestamp of right now.

##### alterations

None.




### pre-rsync

This happens directly before the target directory is synced with the cloned
repository's `published/` directory.

##### arguments

* `$target` - The location where the published files will end up. **This is a
    full path**

##### alterations

Any alterations to the contents of the `published/` directory will end up in the
`$target` directory, and any additional files placed in the `$target` directory
will be destroyed after the rsync is complete.




### post-rsync

This is executed after rsyncing occurs. It is effectively the last execution of
the publisher.

##### arguments

None.

##### alterations

None. *(Unless you're clever)*




### builder


#### pre-files

This is executed directly after the list of files for processing is enumerated.

##### arguments

* `$files` - The list of enumerated files.

##### alterations

The builder will look for a file `./file.list`. If there exists such a file, it
will overwrite the value of the `$files` variable with the contents of that
file.

Also, hopefully obviously, altering any of the files in the list has the
potential to alter any of the final/published files. 




#### pre-markdown

This is executed before a files markdown source is concatenated with the
temporary header/footer and copied to another temporary file.

##### arguments

* `$source` - The location of the source file. **Not a full path**
* `${header}.tmp` - The location of the temporary header file with completed
    variables. **Not a full path**
* `${footer}.tmp` - The location of the temporary footer file with completed
    variables. **Not a full path**

##### alterations

Could update the `${source}.tmp`, `${header}.tmp`, and `${footer}.tmp` files
before they are used during the markdown process.

The header temp file is cat'd into an interim temp file, followed by the output
of `markdown ${source}.stripped`, followed by the footer temp file. Note that
the file that is `markdown`ed is the `${source}.stripped` - you must append
the extension yourself.




#### post-markdown

This is executed directly after the the header, `markdown`ed source, and footer
are all concatenated into the source interim temp file.

##### arguments

* `$source` - The location of the source file. **Not a full path**
* `${source}.tmp` - The location of the interim temp source file. The file at
    this location contains the contents of the header, source converted to html,
    and footer all concatenated together. **Not a full path**

##### alterations

Could update the `${source}.tmp` file. This is the file that `tidy` processes to
produce cleanly formatted html.




#### pre-tidy

This is executed directly before the html in the source interim temp file is
prettified and passed to the target temporary file.

 "${opts_tidy}" "${source}" "${source}.tmp" "${target}.tmp"

##### arguments

* `$opts_tidy` - The default (builder-defined) options that will be passed to
    the `tidy` command.
* `$source` - The location of the source file. **Not a full path**
* `${source}.tmp` - The location of the interim temp source file. The file at
    this location contains the contents of the header, source converted to html,
    and footer all concatenated together. **Not a full path**

##### alterations

Obviously editing the `${source}.tmp` file will alter the output of the `tidy`
command, but also, right before tidy is executed and directly after this
plugin is executed - the builder looks for a file `./tidy.opts`. The contents
of this file are passed as the options to `tidy`. As an example, if the contents
of the file `./tidy.opts` are `-indent --indent-spaces 8 -wrap 40`, that will
overwrite the builder `tidy` defaults of
`-indent --indent-spaces 4 -wrap -1 --doctype omit`, and could drastically alter
the output of the final prettified file.




#### post-tidy

This is executed directly after the `tidy` command has been written.

##### arguments

* `${target}.tmp` - The location of the temporary target file that ultimately
    has the doctype prepended to it before creating the final `$target`. **Not a
    full path**

##### alterations

Altering the file at the `${target}.tmp` location will be a direct alteration
of the final file that is published to the `published/` directory.




#### pre-plain

This is executed before a non-markdown file is copied verbatim from the `posts/`
directory to the `published/` directory.

##### arguments

* `$source` - The location of the source file to be copied. **Not a full path**

##### alterations

Any editing to the source file will be reflected in the published file.




#### post-plain

This is executed directly after a file is copied from the `posts/` directory to
the `published/` directory.

##### arguments

* `$target` - The location of the target file which will be published. **Not a
    full path**

##### alterations

Any alteration to the `$target` file will be reflected in the published file.




#### post-files

This is executed after the list of enumerated files has been processed. After
these plugins are called, the `./posts.md5` file is recreated.

##### arguments

None.

##### alterations

Any files that are in the `published/` directory will be staged for committing.




#### pre-git-commit

This is executed directly before the builder commits the changes to the git
repository locally.

***This is executed even if `SKIPGIT` is set to "YES"***.

##### arguments

* `$TRAVIS_COMMIT` - The full commit hash of the commit that triggered the
    builder execution.
* `$TRAVIS_COMMIT_MESSAGE` - The commit message of the commit that triggered the
    builder execution.

##### alterations

Hopefully obviously, if you alter the git staging area, that will be reflected
in the commit.

Keep in mind that this is executed **after** the `./posts.md5` file and the
`./published/` directory are staged.




#### pre-git-push

This is executed directly before the builder pushes the changes to the remote
origin (GitHub).

***This is executed even if `SKIPGIT` is set to "YES"***.

##### arguments

None.

##### alterations

If there is any additional commits you'd like to do prior to the push, this
is the time for that.
