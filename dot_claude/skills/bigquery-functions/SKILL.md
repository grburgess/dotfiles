---
name: bigquery-functions
description: BigQuery function reference for data engineers — aggregate functions (COUNT, SUM, ARRAY_AGG, STRING_AGG, APPROX_COUNT_DISTINCT, HAVING MAX/MIN modifier), window/analytic functions (OVER clause, PARTITION BY, ORDER BY, frame specs, named windows), numbering functions (ROW_NUMBER, RANK, DENSE_RANK, NTILE, PERCENT_RANK, CUME_DIST), array functions (ARRAY_AGG, ARRAY_LENGTH, ARRAY_CONCAT, GENERATE_ARRAY, UNNEST), and JSON functions (JSON_QUERY, JSON_VALUE, JSON_QUERY_ARRAY, JSON_VALUE_ARRAY, PARSE_JSON, TO_JSON, LAX_* functions). Apply when writing BigQuery SQL using any of these function categories.
---

# BigQuery Functions Reference

---

## Aggregate Functions

### COUNT
```sql
COUNT(*)                          -- all rows including NULLs
COUNT(expr)                       -- non-NULL values only
COUNT(DISTINCT expr)              -- unique non-NULL values
COUNTIF(condition)                -- rows where condition is TRUE (= COUNT(*) FILTER)
```

### SUM / AVG / MIN / MAX
```sql
SUM(expr)
SUM(DISTINCT expr)
AVG(expr)
MIN(expr)
MAX(expr)
```
All ignore NULL values. `DISTINCT` deduplicates before aggregating.

### APPROX_COUNT_DISTINCT
```sql
APPROX_COUNT_DISTINCT(expr)
```
Uses HyperLogLog++ for a fast approximation. Prefer over `COUNT(DISTINCT ...)` on large tables when an exact count isn't required.

### ARRAY_AGG
```sql
ARRAY_AGG(expr)
ARRAY_AGG(DISTINCT expr)
ARRAY_AGG(expr IGNORE NULLS)
ARRAY_AGG(expr ORDER BY other_col DESC)
ARRAY_AGG(expr ORDER BY other_col LIMIT 5)
ARRAY_AGG(expr IGNORE NULLS ORDER BY ts DESC LIMIT 10)
```
- Returns `NULL` if there are zero input rows
- Returns an array containing `NULL` if any value is null (unless `IGNORE NULLS`)
- Order is non-deterministic without `ORDER BY`

### STRING_AGG
```sql
STRING_AGG(expr)                               -- comma-separated by default
STRING_AGG(expr, ' | ')                        -- custom delimiter
STRING_AGG(DISTINCT expr, ',')
STRING_AGG(expr, ',' ORDER BY expr)
```
NULL values are silently ignored.

### ANY_VALUE
```sql
ANY_VALUE(expr)                    -- arbitrary non-NULL value from the group
ANY_VALUE(expr HAVING MAX other)   -- value of expr from the row where other is MAX
ANY_VALUE(expr HAVING MIN other)   -- value of expr from the row where other is MIN
```

`HAVING MAX/MIN` also works with `ARRAY_AGG` and `STRING_AGG`:
```sql
-- Get the name of the employee with the highest salary per dept
SELECT dept, ANY_VALUE(name HAVING MAX salary) AS top_earner
FROM employees GROUP BY dept
```

### LOGICAL_AND / LOGICAL_OR
```sql
LOGICAL_AND(bool_expr)   -- TRUE only if all are TRUE; NULLs ignored
LOGICAL_OR(bool_expr)    -- TRUE if any is TRUE; NULLs ignored
```

### GROUP BY Modifiers

```sql
GROUP BY ROLLUP(a, b, c)        -- (a,b,c), (a,b), (a), ()
GROUP BY CUBE(a, b)             -- (a,b), (a,), (,b), ()
GROUP BY GROUPING SETS((a,b), (a), ())
```

Identify which grouping level produced a row:
```sql
SELECT
  dept,
  role,
  SUM(salary),
  GROUPING(dept) AS dept_is_total,    -- 1 when dept is aggregated away
  GROUPING(role) AS role_is_total
FROM employees
GROUP BY ROLLUP(dept, role)
```

---

## Window / Analytic Functions

### OVER Clause Syntax

```sql
function() OVER (
  [PARTITION BY partition_expr [, ...]]
  [ORDER BY sort_expr [ASC|DESC] [NULLS {FIRST|LAST}] [, ...]]
  [window_frame]
)
```

### Window Frame Specification

```sql
{ROWS | RANGE} BETWEEN frame_start AND frame_end
```

Frame boundaries:
- `UNBOUNDED PRECEDING` — first row of the partition
- `n PRECEDING` — n rows/range units before current row
- `CURRENT ROW`
- `n FOLLOWING`
- `UNBOUNDED FOLLOWING` — last row of the partition

Common frames:
```sql
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW     -- running total
ROWS BETWEEN 2 PRECEDING AND CURRENT ROW             -- 3-row sliding window
ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING  -- full partition
RANGE BETWEEN INTERVAL 7 DAY PRECEDING AND CURRENT ROW   -- 7-day rolling (on DATE/TIMESTAMP)
```

`ROWS` counts physical rows; `RANGE` uses value-based boundaries — use `ROWS` by default unless you specifically need value-range semantics.

### Named Windows

Define once, reference many times:
```sql
SELECT
  SUM(sales) OVER w AS running_sum,
  AVG(sales) OVER w AS running_avg
FROM daily_sales
WINDOW w AS (PARTITION BY region ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
```

### Common Analytic Functions

```sql
SUM(expr) OVER (...)
AVG(expr) OVER (...)
COUNT(expr) OVER (...)
MIN(expr) OVER (...)
MAX(expr) OVER (...)

FIRST_VALUE(expr) OVER (...)
LAST_VALUE(expr) OVER (PARTITION BY ... ORDER BY ... ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
NTH_VALUE(expr, n) OVER (...)

LAG(expr [, offset [, default]]) OVER (...)    -- value from n rows before
LEAD(expr [, offset [, default]]) OVER (...)   -- value from n rows after
```

`LAST_VALUE` requires `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` — without it, the frame ends at the current row and it returns the current row's value (a common mistake).

### Respecting / Ignoring NULLs

```sql
LAST_VALUE(col IGNORE NULLS) OVER (ORDER BY ts)   -- last non-NULL value
FIRST_VALUE(col IGNORE NULLS) OVER (ORDER BY ts)
LAG(col IGNORE NULLS) OVER (ORDER BY ts)
LEAD(col IGNORE NULLS) OVER (ORDER BY ts)
```

---

## Numbering / Ranking Functions

All require `ORDER BY` in the `OVER` clause. None support window frames.

| Function | Ties | Gaps | Range |
|---|---|---|---|
| `ROW_NUMBER()` | No ties — always unique | N/A | 1…N |
| `RANK()` | Same rank for ties | Yes (1,2,2,4) | 1…N |
| `DENSE_RANK()` | Same rank for ties | No (1,2,2,3) | 1…N |
| `PERCENT_RANK()` | Proportional | N/A | [0, 1] |
| `CUME_DIST()` | Cumulative fraction | N/A | (0, 1] |
| `NTILE(n)` | Bucket assignment | N/A | 1…n |

```sql
SELECT
  dept, name, salary,
  ROW_NUMBER() OVER (PARTITION BY dept ORDER BY salary DESC) AS row_num,
  RANK()       OVER (PARTITION BY dept ORDER BY salary DESC) AS rnk,
  DENSE_RANK() OVER (PARTITION BY dept ORDER BY salary DESC) AS dense_rnk,
  NTILE(4)     OVER (ORDER BY salary)                        AS quartile
FROM employees
```

**Top-N per group** (use QUALIFY):
```sql
SELECT * FROM employees
QUALIFY ROW_NUMBER() OVER (PARTITION BY dept ORDER BY salary DESC) <= 3
```

---

## Array Functions

### Accessing Elements

```sql
arr[OFFSET(0)]          -- 0-indexed; raises error if out of bounds
arr[ORDINAL(1)]         -- 1-indexed; raises error if out of bounds
arr[SAFE_OFFSET(0)]     -- returns NULL instead of error
arr[SAFE_ORDINAL(1)]    -- returns NULL instead of error
```

Always prefer `SAFE_OFFSET` / `SAFE_ORDINAL` when index may be out of range.

### Functions

```sql
ARRAY_LENGTH(arr)                        -- number of elements
ARRAY_CONCAT(arr1, arr2 [, ...])         -- concatenate arrays
ARRAY_REVERSE(arr)                       -- reverse element order
ARRAY_TO_STRING(arr, delimiter)          -- join to string
ARRAY_TO_STRING(arr, delimiter, null_text)  -- replace NULLs with null_text

ARRAY_FIRST(arr)                         -- first element (NULL if empty)
ARRAY_LAST(arr)                          -- last element (NULL if empty)
ARRAY_SLICE(arr, start_offset, length)   -- subsequence

GENERATE_ARRAY(start, end [, step])      -- e.g., GENERATE_ARRAY(1, 5) → [1,2,3,4,5]
GENERATE_DATE_ARRAY(start, end [, INTERVAL n {DAY|WEEK|MONTH|YEAR}])
GENERATE_TIMESTAMP_ARRAY(start, end, INTERVAL n {SECOND|MINUTE|HOUR|DAY})
```

### UNNEST

Converts an array to a set of rows:
```sql
-- In FROM clause
SELECT elem FROM UNNEST([1, 2, 3]) AS elem

-- CROSS JOIN to flatten a column
SELECT t.id, tag
FROM my_table t
CROSS JOIN UNNEST(t.tags) AS tag

-- With position
SELECT t.id, tag, pos
FROM my_table t
CROSS JOIN UNNEST(t.tags) AS tag WITH OFFSET AS pos
ORDER BY t.id, pos
```

### ARRAY_AGG (aggregate → array)

```sql
SELECT user_id, ARRAY_AGG(event_type ORDER BY ts) AS event_sequence
FROM events
GROUP BY user_id
```

---

## JSON Functions

### Core Distinction

| Function | Input | Returns | Use When |
|---|---|---|---|
| `JSON_QUERY` | JSON or STRING | **JSON** value | Keep structure, extract objects/arrays |
| `JSON_VALUE` | JSON or STRING | **STRING** | Extract scalar value as string |
| `JSON_QUERY_ARRAY` | JSON or STRING | **ARRAY\<JSON\>** | Extract array of JSON values |
| `JSON_VALUE_ARRAY` | JSON or STRING | **ARRAY\<STRING\>** | Extract array of scalar strings |

Legacy aliases (`JSON_EXTRACT`, `JSON_EXTRACT_SCALAR`, `JSON_EXTRACT_ARRAY`, `JSON_EXTRACT_STRING_ARRAY`) still work — prefer the modern names.

### Extraction

```sql
-- Returns JSON type (preserves structure)
JSON_QUERY('{"a": {"b": 10}}', '$.a.b')         -- JSON: 10
JSON_QUERY('{"arr": [1,2,3]}', '$.arr')          -- JSON: [1,2,3]

-- Returns STRING (scalars only; non-scalar → NULL)
JSON_VALUE('{"name": "Alice"}', '$.name')        -- STRING: "Alice"
JSON_VALUE('{"a": [1,2]}', '$.a')                -- NULL (non-scalar)

-- Returns ARRAY<JSON>
JSON_QUERY_ARRAY('{"items":[1,"x",null]}', '$.items')

-- Returns ARRAY<STRING>
JSON_VALUE_ARRAY('["a","b","c"]')
```

JSONPath notation:
- `$.field` — top-level field
- `$.nested.field` — nested field
- `$.arr[0]` — array element by index
- `$.arr[*]` — all array elements

### Type Conversion

```sql
-- STRING → native JSON type
PARSE_JSON('{"x": 1}')

-- SQL value → native JSON
TO_JSON(STRUCT(1 AS a, 'hello' AS b))            -- JSON: {"a":1,"b":"hello"}

-- SQL value → STRING representation
TO_JSON_STRING(my_struct)
TO_JSON_STRING(my_struct, pretty_print => TRUE)
```

### LAX Functions (NULL on mismatch instead of error)

```sql
LAX_INT64(json_val)      -- NULL if not convertible to INT64
LAX_FLOAT64(json_val)
LAX_BOOL(json_val)
LAX_STRING(json_val)
```

Strict equivalents (`INT64()`, `FLOAT64()`, etc.) raise errors on type mismatch.

### Useful Utilities

```sql
JSON_TYPE(json_val)             -- "string", "number", "boolean", "array", "object", "null"
JSON_ARRAY(1, 'two', NULL)      -- JSON: [1,"two",null]
JSON_OBJECT('k', 'v', 'n', 42) -- JSON: {"k":"v","n":42}
JSON_STRIP_NULLS(json_val)      -- remove null-valued keys
JSON_KEYS(json_val)             -- ARRAY<STRING> of object keys
```

### Common Patterns

```sql
-- Extract from STRING column containing JSON
SELECT
  JSON_VALUE(payload, '$.user.id')                    AS user_id,
  CAST(JSON_VALUE(payload, '$.count') AS INT64)       AS cnt,
  LAX_INT64(JSON_QUERY(payload, '$.count'))           AS cnt_safe
FROM events

-- Unnest a JSON array stored as STRING
SELECT item
FROM my_table,
UNNEST(JSON_VALUE_ARRAY(json_col, '$.tags')) AS item

-- Convert row to JSON string (useful for debugging)
SELECT TO_JSON_STRING(t) AS row_json FROM my_table AS t LIMIT 10
```

---

## Common Mistakes

- **`LAST_VALUE` without full frame**: without `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING`, it returns the current row value — always specify the frame
- **`ARRAY_AGG` with NULLs**: returns an array containing `NULL` unless `IGNORE NULLS` is specified
- **`JSON_VALUE` on non-scalar**: returns `NULL` silently — use `JSON_QUERY` to check if a path contains an object/array
- **`arr[0]` syntax**: BigQuery requires `arr[OFFSET(0)]` or `arr[SAFE_OFFSET(0)]`, not bare `arr[0]`
- **DISTINCT + ORDER BY in aggregates**: most aggregates do not allow both together — `ARRAY_AGG` is an exception
- **`COUNT(DISTINCT ...)` on large tables**: use `APPROX_COUNT_DISTINCT` unless the exact value is required
