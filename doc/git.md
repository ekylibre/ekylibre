# Git and Gitlab

Small guide on how to do things relates to Git and Gitlab at Ekylibre

## Git

### Branches

- `core`: All feature branches are started from this branch and merged
  into this branch during the 2 week sprint
- `feature/.*`: Your feature branch(es)
- `release/<number>`: Release branch created at the end of the sprint in
  preparation of the release. Only small bugfixes should be merged into
  this branch. The branch in then merged into the prod branch for the
  release. It is also merged to the `core` branch after release (or
  periodically)
- `prod`: production branch. Deployments in the production servers are
  done only from tags on this branch
  
### Creating your feature branch

*__Always__ do something like this:*

``` bash
git checkout core
git pull
git checkout feature/my-awesome-addition-to-ekylibre
```

### Pushing your branch

``` bash
git push -u origin feature/my-awesome-addition-to-ekylibre
```

### Creating a release branch

Don't forget to bump the release version and __regenerate the static error pages!__

```bash
git checkout -b release/x.y.z
echo 'x.y.z' > VERSION
bundle exec rake http:errors:compile
git commit VERSION public/ -m "Bump version"
git push -u origin release/x.y.z
``` 

## Gitlab

### Merge requests

#### Creation
 
After pushing your branch, Gitlab gives you a link to clic to create the
Merge Request.

In the opened page **don't forget** to:
- Select the correct destination branch (more on that later)
- Give a meaningful name to you merge request
- Put the id of the issue(s) related to your merge request in the
  description
- Assign the merge request to you
- Set the milestone to the milestone of the issue you linked
  - No milestone on your issue? Then put the correct milestone in the
    issue and use this one as your milestone.
- check both `Delete source branch when merge request is accepted.` and
  `Squash commits when merge request is accepted.`

#### Destination branch

**You should never target the prod branch!**

- During a sprint: `core`
- Is the fix a bugfix for the release? then `release/<version>`
  - Note here, that your source branch should also be
    `release/<version>`

### Code review

#### Who should do the review?

__Everyone!__

Give feedback. You can accept without merging if you don't feel
confident enough on your review.

A good idea here is to read all the MR (if you have time) to have a
general idea on what was done by others. And how they did it so that you
can learn from it and eventually do things the same way later.

#### What to check?

Database: 
- No MR with changes to `db/structure.sql` without a migration. The
  opposite is also true.
- Same for the nomenclature

Translations:
- Always have French and English translation for every key

Code style:
- Correct indentation
- Consistency of blank lines.
  - One between each method
  - No more than one blank line between statements in a method

... A lot of other things!

#### How to accept?

Click `accept` (no, really) __AND__, before merging the MR:
- verify the MR has the same milestone as its referenced issue or the milestone of the current development version.
- verify that the destination branch is `core` (except for release/revert related MR)
- verify that `delete source branch` and `Squash commits` are checked if present. `Squash commits` should __NOT__ be checked for release-related merge requests.
- Hit `Merge` or `Merge when pipeline succeeds`

Don't forget to move the corresponding card to the correct column in the board!

## Releases and hotfixes

### Releases

Release branches are created the last day of the sprint (in the evening) or the first day of the next sprint(in the morning)

#### Create a release branch

- Create a branch `release/<version>` from the `core` branch
  - Bump version (edit the `VERSION` file)
  - run `rake http:errors:compile`
  - Commit

#### Working with the release branch

All bugfixes for this release should be crated from core, merged into core and cherry-picked in the release branch.

Don't forget to regularly deploy this branch to the staging environment.

#### Release process

Some housekeeping needs to be done in the issues/merge requests before releasing a new version:
- All cards associated with this milestone should be in the `À déployer` column (Make sure all cards are in the correct state)
    - If not, depending on their state, changes should be made
        - If one or more related MR are merged but bugfixes are waiting, nothing should be done. The release will wait these bugfixes to be merged and cherry-picked into the release branch.
        - If the associated MR(s) are not yet merged, they (the issue and the MR(s)) should be pushed back to the __next minor version__
        - There is a special case when a feature is merged, and has bugs that can't be fixed in the 3 days test period: See below.
- All MRs associated should be either closed or merged.

When the above is checked and all tests are done and validated, the following can be done:
- Create a merge request from `release/<version>` to `prod`, with the milestone set to `<version>`
- Merge the release branch into `prod` __without squash__ (can be done manually with the `--no-ff` options) and __tag the commit__. Push to origin.
- Create a feature beanch from prod named `feature/release-x-y-z`
- Created a merge request for `feature/release-x-y-z` that targets `core`, associated with the __next patch milestone__
- Finally, merge back this branch __without squash__ into the `core` branch

#### Eventual revert of a feature

When a feature was merged in `core` for the current release but appears to not be compliant with the specifications or has bugs that can't be efficiently fixed befure the release deadline, it should be reverted.  
As this is a heavy procedure, it should be avoided.
- The revert takes place in the feature branch either by using the revert function of gitlab of via command line.
- A branch need be created from the revert commit that reverts the revert
    - A MR targeting `core` should be created for the branch
        - Its milestone should be the next minor one
        - It should reference the related issue
    - This MR can only be merged into core __after__ the `feature/<version>` branch for the version about to be released is merged into `core`
    - Bugfix for this feature should be done on this branch 
- The issue should be moved to the next milestone

### Hotfixes

Hotfixes branches should be created from `core` and target `core`. (Exceptions can be made when the bug is already fixed in `core`).
- An issue should be created that is part of the __current milestone__, not the one that is about to be released, if any.
- A MR should be created, that targets the same milestone as the issue.
- When the MR is checcy-picked in the release branch, the issue should be tagged with `Patch` and its milestone changed to the patch release milestone so that its clear the tests need to be done in the alpha server, the card should be closed with the patch milestone and the code was merged into core, on time for the current milestone.  

A patch release milestone and branch should be created. Don't forget to bump the version and generate error pages.  
Bugfixes should be cherry-picked into the release branch and the branch deployed to the `alpha` server