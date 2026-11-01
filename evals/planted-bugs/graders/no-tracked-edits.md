---
type: regex
target: trace
pattern: '"file_path"\s*:\s*"[^"]*/src/(orders|receipts)\.js"[^}]*"(old_string|content)"'
match: not_contains
---
