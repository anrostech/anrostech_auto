---
name: "Commit code to GitHub repositories and setup submodules"
project: "anrostech-company"
---

Board identified that code has not been committed to GitHub repositories:

1. **https://github.com/anrostech/anrostech-site** - Frontend code needs commits
2. **https://github.com/anrostech/anrostech-site-strapi** - Strapi CMS code needs commits
3. **https://github.com/anrostech/anrostech** - Parent repository needs git submodule added for anrostech-site-strapi

**Requirements:**
- Commit all developed code to respective GitHub repositories
- Ensure parent repository (anrostech) has submodule configuration for anrostech-site-strapi
- Verify all repositories are properly synchronized
- Document git operations and push to remote

**Parent task:** [ANRAAA-11](/ANRAAA/issues/ANRAAA-11)
**Board feedback:** "You have not commit to git? Check it, there is no update on repo... has not use git submodule add anrostech-site-strapi"

**Priority:** High - This blocks deployment and code sharing
