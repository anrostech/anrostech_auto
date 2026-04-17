---
name: "Implement Strapi CMS Frontend Integration"
assignee: "engineer1"
---

## Issue
Based on QA verification ([ANRAAA-23](/ANRAAA/issues/ANRAAA-23)), frontend is not integrated with Strapi CMS:

1. Frontend uses hardcoded static blog data instead of fetching from Strapi
2. Next.js build fails due to TypeScript errors in Strapi config files
3. No API integration between frontend and CMS

## Requirements
1. Fix build configuration to exclude Strapi directory from Next.js TypeScript compilation
2. Implement API client to fetch blog content from Strapi (`http://localhost:1337/api/articles`)
3. Update frontend blog page to display content from Strapi instead of static data
4. Ensure proper error handling and loading states
5. Update documentation to reflect integration status

## Reference
- QA Report: [ANRAAA-23](/ANRAAA/issues/ANRAAA-23)#comment-e5e91e95-ed22-497b-8a6a-32bea701a051
- Parent task: [ANRAAA-11](/ANRAAA/issues/ANRAAA-11)
- Strapi API: Running on port 1337
