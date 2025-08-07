#!/bin/bash
# Step 1: Fetch latest changes from GitHub
git fetch github

# Step 2: Merge them into your local main branch
git merge github/main

# Step 3: Push the merged changes to GitLab
git push origin main
