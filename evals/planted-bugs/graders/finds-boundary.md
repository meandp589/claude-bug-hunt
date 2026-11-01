---
type: llm
weight: 2
---

PASS if the final response reports that bulkDiscountCents uses `>` where the promise "100.00 or more" needs `>=`, so an order of exactly 10000 cents gets no discount.
FAIL if this boundary bug is missing from the findings.
