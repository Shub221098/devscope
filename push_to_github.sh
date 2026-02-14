#!/bin/bash

# Quick script to push DevScope to GitHub
# Usage: ./push_to_github.sh <github-username>

if [ -z "$1" ]; then
    echo "Usage: ./push_to_github.sh <github-username>"
    echo "Example: ./push_to_github.sh octocat"
    exit 1
fi

USERNAME="$1"
REPO="devscope"

echo "🚀 Pushing DevScope to GitHub..."
echo "Repository: https://github.com/$USERNAME/$REPO"
echo ""
echo "Steps:"
echo "1. Make sure you've created the repository at https://github.com/new"
echo "2. Enter your Personal Access Token when prompted for password"
echo ""

# Add remote
git remote remove origin 2>/dev/null
git remote add origin "https://github.com/$USERNAME/$REPO.git"

# Rename to main if on master
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" = "master" ]; then
    echo "📝 Renaming branch from master to main..."
    git branch -M main
fi

# Push
echo "📤 Pushing to GitHub..."
git push -u origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Success! Your repository is now at:"
    echo "   https://github.com/$USERNAME/$REPO"
else
    echo ""
    echo "❌ Push failed. Make sure:"
    echo "   1. The repository exists at https://github.com/$USERNAME/$REPO"
    echo "   2. You have a valid Personal Access Token from https://github.com/settings/tokens"
    exit 1
fi
