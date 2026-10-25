# 0003. Due dates are calendar dates in a configured local time zone

- Status: Proposed
- Date: 2026-10-25
- Issues: #2, #4

## Context

#2/AC1 sets the due date "14 days from today in local time" and #4/AC2 says a loan due today in local time is not
overdue. "Today" depends on the time zone, and the server may run in UTC.

## Decision

Lending stores `due_date` as a SQL `date`, computed as today's date in the office time zone plus 14 days. The time zone
comes from configuration (`SHELF_TIME_ZONE`, an IANA name), not the host's clock settings. A loan is overdue when its
`due_date` is before today in that zone; days overdue is the whole-day difference. Lending takes a clock as a
dependency so integration tests can fix "today".

## Alternatives considered

- **Store a UTC timestamp for the due moment.** Comparing it to "now" makes a loan overdue partway through its due day
  in some time zones, breaking #4/AC2.
- **Use the host's local time zone.** Silently changes behaviour when the container runs in UTC.
- **Per-librarian time zones.** No requirement asks for it.
