# Git Workflow Guide for Snowflake Intelligence Custom Tools

## 🔄 Standard Development Workflow

### 1. After PR is Merged to Main

**Always sync dev branch immediately:**

```bash
# Switch to dev branch
git checkout dev

# Pull latest changes from main
git pull origin main

# Push updated dev to remote
git push origin dev
```

### 2. Making New Changes

```bash
# Ensure you're on dev and it's up to date
git checkout dev
git pull origin main

# Make your changes
# ... edit files ...

# Commit changes
git add -A
git commit -m "feat: your new feature"

# Push to dev
git push origin dev

# Create PR
gh pr create --title "your feature" --body "description" --base main --head dev
```

## 🚨 What Happens if You Don't Sync?

### Problem: Divergent Branches
```
main:  A---B---C---D (PR merged)
dev:   A---B---C---E---F (new work on old base)
```

### Issues:
- Next PR will include old changes again
- Potential merge conflicts
- Confusing commit history
- Harder code reviews

### Solution: Always Sync
```
main:  A---B---C---D
dev:   A---B---C---D---E---F (clean new work)
```

## 🎯 Best Practices

### ✅ DO:
- Sync dev immediately after PR merge
- Always start new work from latest main
- Use descriptive commit messages
- Keep PRs focused and small
- Test changes before pushing

### ❌ DON'T:
- Work on dev without syncing first
- Mix multiple features in one PR
- Force push to shared branches
- Skip testing before pushing

## 🤖 Automation Ideas

### Quick Sync Script
Create an alias for quick syncing:

```bash
# Add to your ~/.zshrc or ~/.bashrc
alias sync-dev="git checkout dev && git pull origin main && git push origin dev"
```

Then just run: `sync-dev`

### GitHub Actions (Future)
Consider setting up automated branch syncing with GitHub Actions.

## 🚀 Emergency: What if Dev Gets Messy?

If you ever get confused or branches get messy:

```bash
# Reset dev to match main exactly
git checkout dev
git reset --hard origin/main
git push --force-with-lease origin dev
```

**⚠️ Warning**: Only do this if you're sure no important changes will be lost!

## 📋 Quick Reference

1. **PR Merged** → Sync dev immediately
2. **New Feature** → Start from synced dev
3. **Push Changes** → Create PR from dev to main
4. **PR Merged** → Sync dev again
5. **Repeat** → Clean, linear workflow

This workflow ensures clean commit history and easier collaboration!
