<!-- TITLE: Jenkins Development Container -->

I am not a Jenkins plugin developer, but I recently found myself requiring a Jenkins plugin development environment. After upgrading Jenkins, one of our plugins stopped working properly.

## Back Story

I don't know specifically when, but at some point Jenkins changed the behavior of `JenkinsLocationConfiguration()` (somewhere between versions 2.121.2 and 2.150.1).

A groovy script like the following used to display your Jenkins URL:

    JenkinsLocationConfiguration config = new JenkinsLocationConfiguration()
    url = config.getUrl()
    println(url)

It changed at some point to:

    JenkinsLocationConfiguration config = new JenkinsLocationConfiguration().get()
    url = config.getUrl()
    println(url)

(Notice the `.get()`?)

Seems like a harmless enough change, but it was causing the [Stash Pull Request Builder Plugin](https://wiki.jenkins-ci.org/display/JENKINS/Stash+pullrequest+builder+plugin) to spam our BitBucket pull requests with "PLEASE SET JENKINS ROOT URL FROM GLOBAL CONFIGURATION". Keep in mind this wasn't causing any unintended side effects, it was just distracting (and ugly to look at).

I was tasked with making it go away.

## Jenkins Development Environment

I didn't want to take the time to set up my laptop as a Jenkins plugin workspace (especially without knowing the first thing about it) – so I decided to take another route.

We're going to create a Jenkins development container based off of the [LTS Jenkins image](https://hub.docker.com/r/jenkins/jenkins) from Docker Hub.

For the rest of this post, I'll be actually walking through fixing that particular issue on that particular plugin.

### Create the Dockerfile

First thing first, let's create a directory to house our work. We'll call it `jenkins-dev`:

    mkdir jenkins-dev
    cd jenkins-dev
    touch Dockerfile

Now open up `Dockerfile` with your favorite editor and we'll start by specifying the base image we plan on using. (I suggest taking a brief look at the [original Dockerfile](https://github.com/jenkinsci/docker/blob/master/Dockerfile) in order to get an understanding of what it's doing and what we need to do).

    FROM jenkins/jenkins:lts

Jenkins plugins use maven, so now we'll switch to the root user so that we can install our (only) [dependency](https://maven.apache.org/what-is-maven.html).

    USER root

    RUN apt-get update && \
        apt-get install -y maven

If you're new to Docker or writing Dockerfiles, keep in mind that the backslash on the first RUN line is important, that tells Docker that the following line is part of that directive (and to keep them [in the same layer](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#minimize-the-number-of-layers)).

Finally, we'll change back to the jenkins user.

    USER jenkins

You should have a pretty small file.

    FROM jenkins/jenkins:lts
    USER root RUN apt-get update && \
         apt-get install -y maven
    USER jenkins

### Build and run the image

From that same directory, start the build. We're going to name and tag our image `jenkins/dev:lts`.

    docker build -t jenkins/dev:lts .

Once it has completed, verify that build was successful.

    $ docker images
    REPOSITORY   TAG   IMAGE ID       CREATED         SIZE 
    jenkins/dev  lts   29559a9e7f04   2 seconds ago   756MB

Perfect! That was easy. Now let's start it up so we can start compiling. We're going to give it an easy to remember name: `jenkins-dev`.

    docker run -p 8080:8080 -p 50000:50000 -v jenkins_home:/var/jenkins_home --name jenkins-dev jenkins/dev:lts

At this point, you should be able to fire up your browser and point it to [http://localhost:8080/](http://localhost:8080/). It should be asking you for credentials. For our purposes this is as far as we go in the browser. We'll be using the command line the rest of the way.

### Compile the plugin

You should already have your (fixed) plugin code in a repository that you control. We're going to simply use the Pull Request on the original plugin repo for this example.

We could do it two ways, either clone locally and then copy to the container – or we can execute a shell prompt and do everything on the container (If you reviewed the Jenkins Dockerfile, you know that it already has git installed). Of course we're going to do the second.

Let's execute a shell prompt.

    docker exec -it jenkins-dev /bin/bash

You should see your terminal prompt change. Something like:

    $ docker exec -it jenkins-dev bash
    jenkins@1eaaa7a9c5be:/$

We're in!

(If you were curious about logging in to Jenkins in your browser, the contents of the `/var/jenkins_home/secrets/initialAdminPassword` file might be of some interest.)

Okay, now let's get to our home directory and clone the repository and check out that particular pull request.

    cd ~
    git clone https://github.com/nemccarthy/stash-pullrequest-builder-plugin.git
    cd stash-pullrequest-builder-plugin
    git fetch origin pull/159/head:fix-root-url
    git checkout fix-root-url

Now that we have grabbed the pull request code, created a local branch for it, and then checked that code out – it's time to compile. Since Jenkins plugins use Maven, that is as simple as the following command.

    mvn clean install -DskipTests=true

Note: We're skipping tests here for brevity.

Once the build has completed, verify that your plugin file was created.

    jenkins@1eaaa7a9c5be:~/stash-pullrequest-builder-plugin$ ls target/*.hpi
    target/stash-pullrequest-builder.hpi

Now we need to get the hpi file from the container to our computer so that we can upload it to Jenkins.

### Install the plugin

Okay, now you can either `exit` out of your shell prompt on the container or open a new terminal.

Now let's copy.

    docker cp jenkins-dev:/var/jenkins_home/stash-pullrequest-builder-plugin/target/stash-pullrequest-builder.hpi .

Open up Jenkins (the one where you need your updated plugin), navigate to "Manage Jenkins", then "Manage Plugins". Now click on the "Advanced" tab (https://your.jenkins.url/pluginManager/advanced) and scroll down until you get to the "Upload Plugin" section. Click on "Choose File", select your plugin (stash-pullrequest-builder.hpi), and then click the "Upload" button.

Finally, check the "Restart Jenkins when installation is complete and no jobs are running" check box so that Jenkins loads your updated plugin.

### Build your job

At this point, any time you update a Pull Request on a repo connected to a Jenkins job (that uses this plugin), you should no longer be unwelcomly greeted with the "PLEASE SET JENKINS ROOT URL FROM GLOBAL CONFIGURATION" spam.

### Clean it up

It is now safe to stop the container and optionally delete the image.

    docker kill jenkins-dev
    docker rmi jenkins/dev:lts

## Post Mortem

Containers are neat.
