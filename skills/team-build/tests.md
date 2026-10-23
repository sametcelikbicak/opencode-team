# Good and Bad Tests

## Good tests

**Integration-style**: test through real interfaces, not mocks of internal parts.

```typescript
// GOOD: Tests observable behavior
test("user can checkout with valid cart", async () => {
  const cart = createCart();
  cart.add(product);
  const result = await checkout(cart, paymentMethod);
  expect(result.status).toBe("confirmed");
});
```

Characteristics:

- Tests behavior users/callers care about
- Uses the public API only
- Survives internal refactors
- Describes WHAT, not HOW
- One logical assertion per test

## Bad tests

**Implementation-detail tests**: coupled to internal structure.

```typescript
// BAD: Tests implementation details
test("checkout calls paymentService.process", async () => {
  const mockPayment = jest.mock(paymentService);
  await checkout(cart, payment);
  expect(mockPayment.process).toHaveBeenCalledWith(cart.total);
});
```

Red flags:

- Mocking internal collaborators
- Testing private methods
- Asserting on call counts or order
- The test breaks when refactoring without a behavior change
- The test name describes HOW, not WHAT
- Verifying through external means instead of the interface

```typescript
// BAD: Bypasses the interface to verify
test("createUser saves to database", async () => {
  await createUser({ name: "Alice" });
  const row = await db.query("SELECT * FROM users WHERE name = ?", ["Alice"]);
  expect(row).toBeDefined();
});

// GOOD: Verifies through the interface
test("createUser makes user retrievable", async () => {
  const user = await createUser({ name: "Alice" });
  const retrieved = await getUser(user.id);
  expect(retrieved.name).toBe("Alice");
});
```

**Tautological tests**: the expected value restates the implementation, so the test passes by construction.

```typescript
// BAD: Expected value is recomputed the way the code computes it
test("calculateTotal sums line items", () => {
  const items = [{ price: 10 }, { price: 5 }];
  const expected = items.reduce((sum, i) => sum + i.price, 0);
  expect(calculateTotal(items)).toBe(expected);
});

// GOOD: Expected value is an independent, known literal
test("calculateTotal sums line items", () => {
  expect(calculateTotal([{ price: 10 }, { price: 5 }])).toBe(15);
});
```

**Order-dependent tests**: the test only passes when another test ran first.

```typescript
// BAD: Relies on state left by another test
test("lists users", async () => {
  expect(await listUsers()).toHaveLength(2);
});

// GOOD: Creates the state it asserts on
test("lists the users created for this test", async () => {
  await createUser({ name: "Alice" });
  await createUser({ name: "Bob" });
  expect(await listUsers()).toHaveLength(2);
});
```

## Deterministic tests

A test that reads the real clock, the real network or unseeded randomness will fail eventually.

```typescript
// BAD: The assertion depends on when the test runs
test("marks an invoice overdue", () => {
  const invoice = createInvoice({ dueAt: "2026-01-01" });
  expect(invoice.isOverdue()).toBe(true);
});

// GOOD: The clock is fixed by the test
test("marks an invoice overdue after its due date", () => {
  vi.setSystemTime(new Date("2026-02-01T00:00:00Z"));
  const invoice = createInvoice({ dueAt: "2026-01-01" });
  expect(invoice.isOverdue()).toBe(true);
});
```

Rules:

- Fix time with a fake clock or inject a clock.
- Seed randomness or inject the random source.
- Never call a real external API from a unit test; mock the boundary instead (see [mocking.md](mocking.md)).
- Each test creates its own data and does not rely on another test's leftovers.

## Naming

The test name says what capability exists, in the project's vocabulary:

- Good: `returns_empty_state_when_no_invoices`
- Bad: `test_invoice_list_2`
- Bad: `calls_repository_once`
