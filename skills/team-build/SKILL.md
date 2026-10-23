---
name: team-build
description: The build and TDD playbook for this team. Red-green-refactor, test-first vertical slices, seams, test pyramid, mocking at boundaries, deterministic tests and definition of done.
---

# Build: Test-Driven Development

TDD is the **red → green → refactor** loop. This skill is the reference that makes that loop produce tests worth keeping: what a good test is, where tests go, what to mock, how to keep tests deterministic, and when the build is done.

Read [tests.md](tests.md) for examples and [mocking.md](mocking.md) for boundary guidelines.

Before the first test, read the ticket in `.team/03-backlog.md` and the contract in `.team/06-architecture.md`. The acceptance criteria and the API contract are the source of truth, not the implementation you are about to write. Use the project's domain vocabulary so test names match the product language.

## The loop

1. **Red** — write one failing test for one acceptance criterion. Run it and see it fail for the right reason.
2. **Green** — write only enough code to pass that test. Do not anticipate the next test or add speculative features.
3. **Refactor** — with the test still green, remove duplication in the production code and the test. Keep the public contract unchanged.

One seam, one test, one minimal implementation per cycle. If a refactor changes module boundaries, the API contract or the data model, stop: that is an architecture change for the `team-architecture` skill ([SKILL.md](../team-architecture/SKILL.md)) and belongs in the next cycle, not hidden inside a green step.

## What a good test is

Tests verify **behavior through public interfaces**, not implementation details. Code can change entirely; tests should not. A good test reads like a specification: "user can checkout with valid cart" tells you exactly what capability exists, and it survives refactors because it does not care about internal structure.

A test is the verification of an acceptance criterion, not proof that a line of code ran. Coverage percentage is not the goal; reliability is.

See [tests.md](tests.md) for good and bad examples.

## Seams: where tests go

A **seam** is the public boundary you test at: the interface where you observe behavior without reaching inside. Tests live at seams, never against internals.

Test only at pre-agreed seams. Before writing tests, write down the seams under test and confirm them with the user. No test is written at an unconfirmed seam. You cannot test everything, so agreeing the seams up front is how testing effort lands on critical paths and complex logic instead of every edge case.

Ask: "What is the public interface, and which seams should we test?" Give each proposed seam a one-line note on what it catches and what it misses.

When the shape of that interface is itself in question — how deep the module is, where the seam belongs, what it should expose — consult the `team-architecture` skill ([SKILL.md](../team-architecture/SKILL.md)). Its module boundaries and API contract define the seams; do not invent a second interface just for tests.

## The test pyramid

| Type | What it tests | Ratio | Speed |
|---|---|---|---|
| Unit | Business logic, edge cases | 70% | ms |
| Integration | DB, API, file system, external boundary adapters | 20% | s |
| e2e | The user journey | 10% | s–min |

Do not write e2e for everything. e2e is fragile and slow; use it only for the main journeys that bring in money.

## Anti-patterns

- **Implementation-coupled**: mocks internal collaborators, tests private methods, or verifies through a side channel (querying the database instead of using the interface). The tell: the test breaks when you refactor but behavior has not changed.
- **Tautological**: the assertion recomputes the expected value the way the code does (`expect(add(a, b)).toBe(a + b)`, a snapshot derived by hand the same way, a constant asserted equal to itself), so it passes by construction and can never disagree with the code. Expected values must come from an independent source of truth: a known-good literal, a worked example, the spec.
- **Horizontal slicing**: writing all tests first, then all implementation. Bulk tests verify _imagined_ behavior: you test the _shape_ of things rather than user-facing behavior, the tests go insensitive to real changes, and you commit to test structure before understanding the implementation. Work in **vertical slices** instead: one test → one implementation → repeat, each test a **tracer bullet** that responds to what the last cycle taught you.
- **Weakening the test**: deleting or loosening an assertion to make a test pass. See "Definition of done".

## Deterministic tests

A test that depends on the clock, the network, random data or execution order is a flaky test. Flaky tests train the team to ignore red.

- Fix time with the test framework's fake clock, or inject a clock. Never assert against `Date.now()`.
- Seed randomness, or inject the random source.
- Mock only the external boundary (see [mocking.md](mocking.md)); never reach the real network in a unit test.
- Each test creates its own state and cleans it up. Tests must pass in any order and in parallel where the runner allows.
- Do not hide a race condition by raising a timeout. Fix the cause or mark the test as an explicit known issue.

## Definition of done

The build is done only when all of these are true:

- Every acceptance criterion in the ticket has at least one test that maps to it.
- Each test was seen failing before the implementation that made it pass.
- The full suite passes, deterministically, in the project's configured command.
- No test was skipped, deleted, loosened or given a longer timeout to get green.
- Tests are versioned next to the code they verify.
- No known failing case is hidden. If something cannot be tested, say why in the build report.

## Handoff to QA

After implementation and tests are green, write `.team/07-build.md`:

- What was built, per ticket and per acceptance criterion.
- Tests added, with the criterion each one covers.
- Exact commands run and their exact output (or "not run").
- Known gaps, shortcuts and risks.

Then hand off to the **QA stage**: the `qa` agent ([agents/qa.md](../../agents/qa.md)) reads `.team/06-architecture.md` and `.team/07-build.md`, follows the `team-qa` skill ([SKILL.md](../team-qa/SKILL.md)), and independently verifies the acceptance criteria. Do not report the QA stage as passed from the build stage; only QA can do that.

> Adapted from the MIT-licensed test-driven development skill by Matt Pocock. See THIRD_PARTY_NOTICES.md.
