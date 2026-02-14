# GitHub Repository Setup Guide

Your DevScope project has been initialized as a local Git repository. Follow these steps to push it to GitHub:

## Step 1: Create the Repository on GitHub

1. Go to https://github.com/new
2. Fill in:
   - **Repository name**: `devscope`
   - **Description**: System Activity and Productivity Analyzer
   - **Public or Private**: Choose your preference
   - **Initialize with**: Leave unchecked (we already have files)
3. Click "Create repository"

## Step 2: Add Remote and Push

After creating the repository on GitHub, run these commands from your project directory:

```bash
cd /home/dev/Downloads/devscope-linux

# Add the remote (replace USERNAME with your GitHub username)
git remote add origin https://github.com/USERNAME/devscope.git

# Rename master to main (optional but recommended)
git branch -M main

# Push your code
git push -u origin main
```

When prompted for credentials, use:
- **Username**: Your GitHub username
- **Password**: Your Personal Access Token (not your GitHub password)

## Step 3: Generate a Personal Access Token (if needed)

If you need a token for authentication:

1. Go to https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Give it a name: `devscope-push`
4. Select scopes:
   - ✓ `repo` (Full control of private repositories)
5. Click "Generate token"
6. Copy the token (you won't see it again!)
7. Use it as your password when pushing

## Current Status

✅ Local repository initialized at: `/home/dev/Downloads/devscope-linux`
✅ All files committed to local Git
⏳ Waiting for you to create the GitHub repository and push

## Quick Reference

```bash
# Check git status
git status

# View commit history
git log --oneline

# Add remote after creating GitHub repo
git remote add origin https://github.com/USERNAME/devscope.git

# Push to GitHub
git push -u origin main
```

Once you complete these steps, your DevScope project will be live on GitHub!
