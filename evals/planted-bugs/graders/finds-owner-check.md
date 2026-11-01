---
type: llm
weight: 2
---

PASS if the final response reports that getReceipt returns any order's receipt to any signed-in user because it never compares the order's ownerId with the user (unlike getOrder), and rates it at least High.
FAIL if this missing owner check is not reported, or is rated Medium or lower.
