---
name: code-review
description: Automated code review for pull requests using specialized review patterns. Analyzes code for quality, security, performance, and best practices. Use when reviewing code changes, PRs, or doing code audits.
license: Apache-2.0
---

# Code Review

## Review Categories

### 1. Correctness Review

Check for:

- Logic errors
- Edge cases
- Off-by-one
- Input validation
- Concurrency issues
- Proper use of libraries/APIs

### 2. Performance Review

Check for:

- N+1 queries
- Missing database indexes
- Memory leaks
- Blocking operations in async code
- Missing caching opportunities
- Large bundle sizes

### 3. Code Quality Review

Check for:

- Code duplication (DRY violations)
- Functions doing too much (SRP violations)
- Deep nesting / complex conditionals
- Magic numbers/strings
- Poor naming
- Missing error handling
- Incomplete type coverage

## Review Checklist

- [ ] Error handling complete
- [ ] Types/interfaces defined
- [ ] No obvious performance issues
- [ ] Code is readable and documented
- [ ] Breaking changes documented
