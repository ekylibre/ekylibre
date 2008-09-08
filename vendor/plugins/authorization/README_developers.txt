
INSTRUCTIONS FOR DEVELOPERS:

Authorization and Git

All source code for the plugin is managed in a Git master repository. Currently this repository is hosted on GitHub, which is a great site that makes working with, and sharing, Git managed code so much better.

You can browse the master Git repo here:

http://github.com/DocSavage/rails-authorization-plugin/tree/master

Authorization @ GitHub

If you want to learn more about how you can use GitHub to create your own fork of the Authorization repository and use that as the base for your enhancements this excellent article provides a great start:

http://railsontherun.com/2008/3/3/how-to-use-github-and-submit-a-patch

Authorization and SVN

We currently maintain a mirror of the Git master repo in an SVN repository on GoogleCode. We push commits from Git to SVN using the 'git svn dcommit' command. Code is never pulled from SVN to Git. The primary reason we maintain this mirror is because it allows us to use the standard rails './script/plugin install URL' tools to allow for easy end user installation of the plugin. When the newest version of Rails allows us to provide the same functionality by installing directly from a Git repo this SVN mirror may be discontinued.

You can browse the source code and get instructions for getting a copy of the repo in SVN form from:

http://code.google.com/p/rails-authorization-plugin/source/checkout

Testing

We request that all patches be fully tested prior to submission and we would like all code changes to be accompanied wherever possible by valid passing tests. You can test the application by downloading our most recent test repository from Git and running the tests as instructed in the README. Please submit a separate patch against the test repo to accompany any plugin change patches.

http://github.com/grempe/rails-authorization-plugin-test/tree/master

Instructions for using the test app are available:

http://github.com/grempe/rails-authorization-plugin-test/tree/master/README

We also welcome any patches that would integrate a plugin testing framework (RSpec) into the plugin itself so we could use the test app only for demo purposes and be able to run the suite of tests directly in the plugin code base.

Submitting Patches

The recommended way to submit patches is to initiate a pull request from a Git fork @ GitHub.

However, we will also accept patches submitted on the Authorization Google Group, or by email.


PUSHING CHANGES TO GOOGLE CODE SVN:
- - - - - - - - - - - - - - - - - -
Pushing a read-only copy of the git repo master branch to the google code SVN repo.
--

Based on an article found at :
http://blog.nanorails.com/articles/2008/1/31/git-to-svn-read-only

Setup:

Clone a local copy of the git repo from GitHub:

'git clone git@github.com:DocSavage/rails-authorization-plugin.git'

cd rails-authorization-plugin

edit .git/config and add the following to the end:

--
[svn-remote "googlecode"]
  url = https://rails-authorization-plugin.googlecode.com/svn/trunk
  fetch = :refs/remotes/googlecode
--

run : 'git svn fetch'

run : 'git checkout -b local-svn googlecode'

run : 'git svn rebase'

run : 'git merge master'

run : 'git svn dcommit'


Now in the future as new changes are commit to master, do this to publish to GoogleCode:

$ git checkout local-svn
$ git merge master
$ git svn dcommit

And thats it!
