---
name: disciplined-coding-workflow
description: >-
  Disciplined engineering workflow to prevent overcomplication, ensure surgical
  changes, surface assumptions upfront, and execute goal-driven verification.
---
# Workflow: Disciplined Coding Guidelines (`disciplined-coding-workflow`)

Use this skill when planning, implementing, refactoring, or reviewing code to maintain clean, minimal, and disciplined engineering standards while avoiding common AI agent pitfalls.

---

## 1. Think Before Coding
**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before writing code:
- **State assumptions explicitly**: If requirements or acceptance criteria are uncertain, clarify upfront rather than guessing silently.
- **Surface alternatives**: If multiple valid implementations exist, present options and tradeoffs clearly.
- **Push back on unnecessary complexity**: If a simpler approach satisfies the user request, propose it.
- **Stop when unclear**: Identify exactly what is confusing and resolve ambiguities first.

---

## 2. Simplicity First
**Minimum code that solves the problem. Nothing speculative.**

During implementation:
- Implement strictly what is requested; avoid adding unasked features or speculative flexibility.
- Do not introduce abstractions or design patterns for single-use logic.
- Avoid unnecessary configurability or defensive error handling for impossible scenarios.
- If an implementation can be cleanly done in 50 lines instead of 200, refactor it down.
- **Evaluation Heuristic**: Ask yourself: *"Would a senior engineer say this is overcomplicated?"* If yes, simplify immediately.

---

## 3. Surgical Changes
**Touch only what you must. Clean up only your own mess.**

When modifying existing code:
- Do not "improve" adjacent formatting, comments, or styling unless explicitly requested.
- Do not refactor functioning code that is not broken or directly part of the task scope.
- Conform strictly to the existing codebase conventions and architectural style.
- If unrelated dead code is discovered, mention it in the summary rather than deleting it unilaterally.

When changes leave orphan artifacts:
- Clean up unused imports, variables, helpers, or props created by your changes.
- Do not prune pre-existing dead code outside the task scope unless asked.
- **Evaluation Heuristic**: Every modified line must trace directly back to the active user request.

---

## 4. Goal-Driven Execution
**Define success criteria. Loop until verified.**

Transform tasks into verifiable checkpoints:
- *"Add validation"* → *"Write tests or checks for invalid inputs, then verify valid/invalid boundaries pass"*
- *"Fix bug"* → *"Reproduce the failing behavior, implement the surgical fix, then verify it passes"*
- *"Refactor component"* → *"Ensure existing behavior and visual layout match before and after"*

For multi-step work, structure a concise execution loop:
```text
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

---

## 5. Verification Checklist

Before reporting completion:
- [ ] Requirements and assumptions clarified before touching code.
- [ ] Implemented minimal, simple solution without premature abstractions.
- [ ] Diffs are surgical; only files and lines relevant to the task were modified.
- [ ] Cleaned up orphaned imports/variables introduced during this change.
- [ ] Verified build, lint, and runtime flow (`npm run lint`, `npm run build`).
