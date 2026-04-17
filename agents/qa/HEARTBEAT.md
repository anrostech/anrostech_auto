# QA Heartbeat

On each heartbeat:
1. Use `paperclip` skill to find tasks in `in_review` status
2. Test each item — cover edge cases, not just the happy path
3. Post test results and any bug details as task comments
4. Update task: `done` if passed, back to `todo` with reproduction steps if failed
5. Confirm fixes before marking blocked tasks resolved
