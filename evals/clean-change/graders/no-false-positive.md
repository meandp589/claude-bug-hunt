---
type: llm
weight: 3
---

PASS if the response's verdict says the branch is ready (or safe) to merge, and it reports no Critical, High or Medium bug caused by this change. Low notes, "found on the way" items, or unverified items are allowed.
FAIL if it reports a Critical, High or Medium bug caused by this change, or says not to merge.
