# When to Mock

Mock at **system boundaries** only:

- External APIs (payment, email, etc.)
- Databases (sometimes — prefer a test database)
- Time and randomness
- The file system (sometimes)

Do not mock:

- Your own classes or modules
- Internal collaborators
- Anything you control

If a mock does not represent the real boundary, the test proves nothing. The test passes against a fiction.

## Designing for mockability

At system boundaries, design interfaces that are easy to mock.

**1. Use dependency injection**

Pass external dependencies in rather than creating them internally:

```typescript
// Easy to mock
function processPayment(order, paymentClient) {
  return paymentClient.charge(order.total);
}

// Hard to mock
function processPayment(order) {
  const client = new StripeClient(process.env.STRIPE_KEY);
  return client.charge(order.total);
}
```

**2. Prefer SDK-style interfaces over generic fetchers**

Create specific functions for each external operation instead of one generic function with conditional logic:

```typescript
// GOOD: Each function is independently mockable
const api = {
  getUser: (id) => fetch(`/users/${id}`),
  getOrders: (userId) => fetch(`/users/${userId}/orders`),
  createOrder: (data) => fetch("/orders", { method: "POST", body: data }),
};

// BAD: Mocking requires conditional logic inside the mock
const api = {
  fetch: (endpoint, options) => fetch(endpoint, options),
};
```

The SDK approach means:

- Each mock returns one specific shape
- No conditional logic in test setup
- Easier to see which endpoints a test exercises
- Type safety per endpoint

**3. Inject the clock and the random source**

```typescript
// Easy to make deterministic
function createInvoice(data, clock = { now: () => new Date() }) {
  return { ...data, createdAt: clock.now() };
}
```

A boundary that is injected can be replaced with a fixed clock or a seeded generator. A boundary created inside the function cannot.

## What a mock must not become

- A mock of your own module: test the public interface with the real implementation.
- A call-count assertion: assert the observed behavior, not how many times an internal function ran.
- A stand-in that always returns a convenient value regardless of input: the mock should mirror the real contract, including errors and empty results.
- A way to skip the test database for integration tests that are supposed to prove the schema works.
