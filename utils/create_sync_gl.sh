#!/bin/bash

echo "Dont run this script directly! Execute the Steps manually!"
exit

# Run this where you can reach the gitlab repo
git clone https://gitlab.internal/group/repo.git
cd repo

git remote add github https://github.com/yourusername/repo.git

# To sync changes from GitHub to GitLab
git fetch github
git merge github/main
git push origin main

# To sync changes from GitLab to GitHub
# Important!!! Test this first!
# git fetch origin
# git merge origin/main
# git push github main