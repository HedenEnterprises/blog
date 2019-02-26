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
    * **none yet**


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


## Plugin references

### builder


#### pre-files

This is executed before the list of files for processing is enumerated.

##### arguments

None.

##### returns

None.


#### pre-markdown

This is executed before a files markdown source is concatenated with the
temporary header/footer and copied to another temporary file.

##### arguments

* `$source` - The location of the source file. **Not a full path**
* `${header}.tmp` - The location of the temporary header file with completed
    variables. **Not a full path**
* `${footer}.tmp` - The location of the temporary footer file with completed
    variables. **Not a full path**

##### returns

Could update the `${source}.tmp`, `${header}.tmp`, and `${footer}.tmp` files
before they are used during the markdown process.

####

##### arguments

##### returns


####

##### arguments

##### returns


####

##### arguments

##### returns


####

##### arguments

##### returns


####

##### arguments

##### returns


####

##### arguments

##### returns


####

##### arguments

##### returns


####

##### arguments

##### returns


####

##### arguments

##### returns


####

##### arguments

##### returns


####

##### arguments

##### returns


####

##### arguments

##### returns


####

##### arguments

##### returns

