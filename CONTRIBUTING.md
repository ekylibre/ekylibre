## Contributing

First off, thank you for considering contributing to Ekylibre. It's people
like you that make Ekylibre such a great tool.

### 1. Where do I go from here?

If you've noticed a bug or have a question,
[search the issue tracker](https://github.com/ekylibre/ekylibre/issues?q=something)
to see if someone else in the community has already created a ticket.
If not, go ahead and [make one](https://github.com/ekylibre/ekylibre/issues/new)!

### 2. Fork & create a branch

If this is something you think you can fix, then
[fork Ekylibre](https://help.github.com/articles/fork-a-repo)
and create a branch with a descriptive name.

A good branch name would be (where issue #1747 is the ticket you're working on):

```sh
git checkout -b 1747-add-rapeseed-varieties
```

#### 3. Did you find a bug?

* **Ensure the bug was not already reported** by searching on GitHub under [Issues](https://github.com/ekylibre/ekylibre/issues).

* If you're unable to find an open issue addressing the problem, [open a new one](https://github.com/ekylibre/ekylibre/issues/new).
Be sure to include a **title and clear description**, as much relevant information as possible,
and a **code sample** or an **executable test case** demonstrating the expected behavior that is not occurring.

### 4. Implement your fix or feature

At this point, you're ready to make your changes! Feel free to ask for help;
everyone is a beginner at first :smile_cat:


### 5. Make a Pull Request

At this point, you should switch back to your master branch and make sure it's
up to date with Ekylibre's master branch:

```sh
git remote add upstream git@github.com:ekylibre/ekylibre.git
git checkout eky-core
git pull upstream eky-core
```

Then update your feature branch from your local copy of master, and push it!

```sh
git checkout 1747-add-rapeseed-varieties
git rebase eky-core
git push --set-upstream origin 1747-add-rapeseed-varieties
```

Finally, go to GitHub and
[make a Pull Request](https://help.github.com/articles/creating-a-pull-request)
:D

### 6. Keeping your Pull Request updated

If a maintainer asks you to "rebase" your PR, they're saying that a lot of code
has changed, and that you need to update your branch so it's easier to merge.

To learn more about rebasing in Git, there are a lot of
[good](http://git-scm.com/book/en/Git-Branching-Rebasing)
[resources](https://help.github.com/articles/interactive-rebase),
but here's the suggested workflow:

```sh
git checkout 1747-add-rapeseed-varieties
git pull --rebase upstream eky-core
git push --force-with-lease 1747-add-rapeseed-varieties
```

### 7. Merging a PR (maintainers only)

A PR can only be merged into master by a maintainer if:

* It is passing CI.
* It has been approved by at least two maintainers. If it was a maintainer who
  opened the PR, only one extra approval is needed.
* It has no requested changes.
* It is up to date with current master.

Any maintainer is allowed to merge a PR if all of these conditions are
met.


### Thanks

Thanks to Active Admin. This document is largely inspirated from their own.
