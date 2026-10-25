# 0001. PostgreSQL for books and loans

- Status: Proposed
- Date: 2026-10-25
- Issues: #1, #2, #3, #4, #5

## Context

#1/AC2 rejects a duplicate ISBN and #2/AC2 rejects borrowing a book already on loan. Both rules must hold when two
librarians act at the same moment, so the store needs to enforce uniqueness itself. #5 needs a part-of-title search.

## Decision

The `Database` container is PostgreSQL. `books.isbn` is unique. `loans` has a partial unique index on `book_isbn`
where `returned_at IS NULL`, so a book can have at most one open loan. The Catalog and Lending components translate the
resulting unique-violation into the domain rejection. Title search uses `ILIKE '%text%'`.

## Alternatives considered

- **SQLite file next to the API.** Simpler to run, and supports the same constraints, but ties the data to the API
  container's filesystem and makes a second API instance impossible. Reasonable if the team prefers zero ops; the
  model would change only in the container's technology.
- **In-memory store.** Loses every loan on restart.
- **Check-then-insert in application code.** Races under concurrent requests; the constraint is the only reliable guard.
