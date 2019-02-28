# The Builder

This is what builds the published commits which *The Publisher* picks up and
..well.. publishes.

This really isn't for end-user consumption - it is ran by Travis and then
executes its own builds for publishing raw markdown commited to `posts/`.


## Options

* `SKIPGIT` - Set to `YES` to skip any significant `git` commands. Useful for
    simulations.
* `TRAVIS_COMMIT_MESSAGE` - The script requires a commit message in order to
    run. If you're simulating a build, you must set this variable to something.
* `token` - The script is set to use a [Travis CI](https://travis-ci.org)
    encrypted environment variable named `token`. You can override that value.
    Necessary for publishing back to the remote repository.

Example:

```
SKIPGIT=YES TRAVIS_COMMIT_MESSAGE="This is a message" ./builder/builder.sh
```
