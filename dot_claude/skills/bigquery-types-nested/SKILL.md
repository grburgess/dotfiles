---
name: bigquery-types-nested
description: BigQuery data types and nested/repeated data — all GoogleSQL types (INT64, FLOAT64, NUMERIC/BIGNUMERIC, STRING, BOOL, DATE/DATETIME/TIMESTAMP, BYTES, ARRAY, STRUCT, JSON, GEOGRAPHY, INTERVAL, RANGE), type casting (CAST, SAFE_CAST, implicit coercion rules), TIMESTAMP vs DATETIME distinction, and nested/repeated field patterns (STRUCT, ARRAY<STRUCT>, UNNEST, CROSS JOIN UNNEST, ARRAY_AGG(STRUCT(...))). Apply when working with data types, type errors, casting, NULL handling, or querying nested/repeated columns.
---

# BigQuery Data Types and Nested/Repeated Data

---

## Type Reference

| Type | Notes |
|---|---|
| `INT64` | Only integer size in BigQuery — no INT32, SMALLINT, TINYINT |
| `FLOAT64` | Approximate; supports `+inf`, `-inf`, `NaN` |
| `NUMERIC` | Exact decimal: 29 significant digits, 9 decimal places |
| `BIGNUMERIC` | Exact decimal: 76+ significant digits, 38 decimal places |
| `BOOL` | TRUE / FALSE / NULL |
| `STRING` | Unicode text |
| `BYTES` | Binary data — strict separation from STRING |
| `DATE` | `YYYY-MM-DD` — no time component |
| `TIME` | `HH:MM:SS[.fraction]` — no date, no timezone |
| `DATETIME` | `YYYY-MM-DD HH:MM:SS[.fraction]` — no timezone |
| `TIMESTAMP` | UTC instant; always timezone-aware |
| `INTERVAL` | Duration: years, months, days, hours, minutes, seconds |
| `ARRAY<T>` | Ordered list of same-type values |
| `STRUCT<...>` | Named, ordered fields of mixed types |
| `JSON` | Native JSON type (distinct from STRING containing JSON) |
| `GEOGRAPHY` | WGS84 geospatial point set |
| `RANGE<T>` | Contiguous range of DATE, DATETIME, or TIMESTAMP |

---

## TIMESTAMP vs DATETIME

| | TIMESTAMP | DATETIME |
|---|---|---|
| Timezone | Stored as UTC, displays with timezone | No timezone — "civil time" |
| Use for | Absolute events (log entries, API calls) | Local time (schedules, business dates) |
| Conversion | `TIMESTAMP(datetime_val, 'America/New_York')` | `DATETIME(timestamp_val, 'America/New_York')` |

```sql
-- TIMESTAMP: absolute moment in time
SELECT CURRENT_TIMESTAMP()                              -- e.g. 2024-03-01 15:30:00 UTC

-- DATETIME: wall-clock time without timezone
SELECT CURRENT_DATETIME('America/New_York')             -- e.g. 2024-03-01 10:30:00

-- Convert between them
SELECT DATETIME(TIMESTAMP '2024-03-01 15:30:00 UTC', 'America/New_York')
-- → 2024-03-01T10:30:00

SELECT TIMESTAMP(DATETIME '2024-03-01 10:30:00', 'America/New_York')
-- → 2024-03-01 15:30:00 UTC

-- Extract date from timestamp (always specify timezone)
SELECT DATE(ts, 'America/New_York') FROM events
```

---

## NUMERIC / BIGNUMERIC

Use for monetary values and anything requiring exact decimal arithmetic.

```sql
SELECT NUMERIC '1234.56'
SELECT BIGNUMERIC '9999999999999999999999999999999.99999999'

-- Explicit cast from FLOAT64
CAST(3.14159 AS NUMERIC)
CAST(price AS BIGNUMERIC)
```

`FLOAT64` cannot safely represent most decimals — `0.1 + 0.2 ≠ 0.3` in FLOAT64 arithmetic.

---

## FLOAT64 Specials

```sql
IS_INF(val)      -- TRUE for +inf or -inf (never use = for these)
IS_NAN(val)      -- TRUE for NaN (NaN ≠ NaN — equality always returns FALSE)
IEEE_DIVIDE(x, y) -- returns ±inf or NaN instead of error on divide by zero
```

---

## Type Casting

### Explicit Cast
```sql
CAST(expr AS type)         -- raises error on failure
SAFE_CAST(expr AS type)    -- returns NULL on failure (prefer for user/external data)
```

```sql
CAST('2024-01-15' AS DATE)
CAST(price AS NUMERIC)
CAST(flag AS BOOL)
SAFE_CAST(user_input AS INT64)     -- NULL if input is not a valid integer
```

### Implicit Coercion (automatic widening)
```sql
INT64 → NUMERIC → BIGNUMERIC → FLOAT64
INT64 → FLOAT64
DATE → DATETIME → TIMESTAMP  (not implicit — requires explicit cast)
```

- String ↔ numeric: **always requires explicit `CAST`** — `'5' + 1` is an error
- TIMESTAMP → DATE: requires `DATE(ts)` or `CAST(ts AS DATE)`
- BYTES ≠ STRING: no implicit conversion in either direction

### Date/Time Parsing Functions
```sql
PARSE_DATE('%Y/%m/%d', '2024/03/01')          -- → DATE
PARSE_DATETIME('%Y-%m-%d %H:%M:%S', '...')    -- → DATETIME
PARSE_TIMESTAMP('%Y-%m-%dT%H:%M:%E*SZ', '...') -- → TIMESTAMP
PARSE_NUMERIC('1,234.56')                     -- → NUMERIC
```

---

## ARRAY Type

Arrays are ordered lists of values of a single type.

```sql
-- Literal arrays
[1, 2, 3]
['a', 'b', 'c']
ARRAY<INT64>[1, 2, 3]

-- Empty array
ARRAY<STRING>[]
[]   -- needs type context
```

**Element access** — always use `OFFSET` or `ORDINAL`, never bare `[n]`:
```sql
arr[OFFSET(0)]          -- 0-indexed; error if out of bounds
arr[ORDINAL(1)]         -- 1-indexed; error if out of bounds
arr[SAFE_OFFSET(0)]     -- returns NULL if index out of range
arr[SAFE_ORDINAL(1)]    -- returns NULL if index out of range
```

**Constraints:**
- Cannot contain `NULL` elements directly — `ARRAY_AGG` with nulls wraps them; `IGNORE NULLS` to exclude
- Cannot nest arrays: `ARRAY<ARRAY<INT64>>` is illegal — use `ARRAY<STRUCT<...>>` or `UNNEST`
- Maximum 15 levels of nested RECORDs

---

## STRUCT Type

Named, ordered field container with mixed types.

```sql
-- Struct literal
STRUCT(1 AS id, 'Alice' AS name, 30 AS age)
STRUCT<id INT64, name STRING, age INT64>(1, 'Alice', 30)

-- Accessing fields
my_struct.field_name
record_col.nested_field

-- Anonymous fields (positional access not supported — always name them)
STRUCT(1, 'hello')     -- valid but fields accessed as _field_1, _field_2
```

STRUCT columns are called `RECORD` type in schema JSON / bq CLI.

---

## Nested and Repeated Fields

BigQuery represents nested data as `RECORD` (STRUCT) and repeated data as `REPEATED` (ARRAY).

### Schema Example

```json
[
  {"name": "user_id", "type": "STRING"},
  {
    "name": "addresses",
    "type": "RECORD",
    "mode": "REPEATED",
    "fields": [
      {"name": "city",    "type": "STRING"},
      {"name": "country", "type": "STRING"},
      {"name": "zip",     "type": "STRING"}
    ]
  }
]
```

SQL type: `addresses ARRAY<STRUCT<city STRING, country STRING, zip STRING>>`

### Querying Nested/Repeated Fields

**Access a struct field (dot notation):**
```sql
SELECT user_id, profile.age, profile.email
FROM users
```

**Access first array element:**
```sql
SELECT user_id, addresses[SAFE_OFFSET(0)].city AS first_city
FROM users
```

**Flatten all array elements (UNNEST + CROSS JOIN):**
```sql
SELECT u.user_id, a.city, a.country
FROM users AS u
CROSS JOIN UNNEST(u.addresses) AS a
```

This produces one row per array element per user. Users with empty `addresses` arrays are excluded (CROSS JOIN semantics). Use `LEFT JOIN UNNEST(...)` to keep them:
```sql
SELECT u.user_id, a.city
FROM users AS u
LEFT JOIN UNNEST(u.addresses) AS a
```

**Filter on nested field:**
```sql
SELECT u.user_id
FROM users AS u
CROSS JOIN UNNEST(u.addresses) AS a
WHERE a.country = 'US'
```

**With element position:**
```sql
SELECT u.user_id, a.city, pos
FROM users AS u
CROSS JOIN UNNEST(u.addresses) AS a WITH OFFSET AS pos
ORDER BY u.user_id, pos
```

### Building Nested Structures

```sql
-- ARRAY_AGG to re-pack rows into arrays
SELECT
  user_id,
  ARRAY_AGG(STRUCT(event_type, ts, page_id) ORDER BY ts) AS events
FROM raw_events
GROUP BY user_id
```

### Multi-Level Nesting

```sql
-- Table: orders with nested items, each item has nested options
SELECT
  o.order_id,
  item.name,
  opt.color
FROM orders AS o
CROSS JOIN UNNEST(o.items) AS item
CROSS JOIN UNNEST(item.options) AS opt
WHERE opt.color = 'red'
```

Each `CROSS JOIN UNNEST` flattens one level.

---

## NULL Semantics

```sql
-- NULL comparisons always use IS NULL / IS NOT NULL
col IS NULL
col IS NOT NULL

-- COALESCE: first non-NULL value
COALESCE(col1, col2, 'default')

-- IFNULL: two-argument shorthand
IFNULL(col, 'fallback')

-- NULLIF: return NULL when two values are equal
NULLIF(col, 0)    -- returns NULL if col = 0

-- Conditional
IF(condition, true_val, false_val)
IFF(condition, true_val, false_val)   -- alias
```

**NULL in aggregates**: most aggregate functions ignore NULLs. `COUNT(*)` is the only exception — it counts all rows including those with NULL values in all columns.

**NULL in arrays**: `ARRAY_AGG` includes NULLs by default; use `ARRAY_AGG(col IGNORE NULLS)` to exclude them. Arrays cannot be created with NULL elements via literals.

---

## Common Mistakes

- **`col[0]`**: BigQuery does not support bare integer subscripts — use `col[OFFSET(0)]` or `col[SAFE_OFFSET(0)]`
- **TIMESTAMP vs DATETIME in partition keys**: partition filter expressions must match the column type exactly
- **STRING + INT64**: no implicit coercion — `CAST('5' AS INT64) + 1` is required
- **`FLOAT64` for money**: use `NUMERIC` — FLOAT64 arithmetic is imprecise
- **STRUCT/ARRAY with UNION**: `UNION`, `INTERSECT`, `EXCEPT DISTINCT`, and `SELECT DISTINCT` do not work with ARRAY or STRUCT columns
- **`IS_NAN` vs `= NaN`**: NaN is never equal to anything including itself — `val = IEEE_VALUE(NaN)` always returns FALSE
- **CROSS JOIN UNNEST excluding empty arrays**: if users with zero addresses must appear in results, use `LEFT JOIN UNNEST(...)`
- **Nested struct depth**: maximum 15 levels — plan schema accordingly
