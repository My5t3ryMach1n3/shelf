# 0002. Catalog and Lending behind one HTTP component

- Status: Proposed
- Date: 2026-10-25
- Issues: #1, #2, #3, #4, #5

## Context

The five stories split into two concerns: what books exist (#1 add, #5 search) and who has them (#2 borrow, #3 return,
#4 overdue). All five arrive over the same HTTP API.

## Decision

One container, `Shelf API`, with three components:

- `HTTP API` (`src/shelf-api/http`): server start-up, routing, input validation, mapping outcomes to status codes.
- `Catalog` (`src/shelf-api/catalog`): books and title search. Owns the `books` table and its migrations.
- `Lending` (`src/shelf-api/lending`): loans, due dates, overdue. Owns the `loans` table and its migrations.

Each domain component holds its own SQL; there is no shared repository component. A book's availability is derived
from whether it has an open loan, not stored as a status column, so borrow and return touch only `loans` and cannot
drift from the books table. Catalog's search therefore reads `loans` to report availability (#5/AC1). Lending relies on
the foreign key to `books` to reject a borrow of an unknown ISBN, rather than calling Catalog.

The ISBN is the book's identifier in the API, since #1/AC2 makes it unique on the shelf.

## Alternatives considered

- **One component per story.** Five near-identical components with duplicated data access; harder to describe each
  in one sentence than two by concern.
- **A shared repository component.** Adds a hop to every dynamic view and a component whose only job is SQL; the two
  domains have little data in common.
- **A `books.status` column updated by Lending.** Makes Lending write to Catalog's table and needs both rows updated
  in one transaction to stay consistent.
- **Separate services for catalog and lending.** No requirement justifies two deployables for an office tool.
