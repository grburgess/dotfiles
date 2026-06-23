---
name: bigquery-sql
description: BigQuery GoogleSQL query syntax — SELECT variants, FROM, JOINs, WHERE, GROUP BY (incl. ROLLUP/CUBE/GROUPING SETS/ALL), HAVING, QUALIFY, ORDER BY, LIMIT, WITH CTEs (incl. RECURSIVE), set operators, subqueries, pipe syntax (|>), and TABLESAMPLE. Apply when writing or reviewing BigQuery SQL queries, debugging syntax errors, or choosing between standard and pipe syntax.
---

# BigQuery GoogleSQL Query Syntax

## Clause Order

```sql
WITH cte AS (...)
SELECT [ALL | DISTINCT] ...
FROM ...
  [JOIN ...]
[WHERE ...]
[GROUP BY ...]
[HAVING ...]
[QUALIFY ...]           -- BigQuery-specific: filters window function results
[ORDER BY ...]
[LIMIT n [OFFSET k]]
```

**Logical evaluation order**: `FROM → WHERE → GROUP BY → HAVING → SELECT → QUALIFY → ORDER BY → LIMIT`

---

## SELECT Clause

```sql
SELECT *                              -- all columns
SELECT * EXCEPT (col1, col2)          -- all columns minus specified ones
SELECT * REPLACE (expr AS col)        -- substitute a column value, keep all others
SELECT ALL ...                        -- default, keeps duplicates
SELECT DISTINCT ...                   -- deduplicate output rows
```

`EXCEPT` and `REPLACE` can be combined:
```sql
SELECT * EXCEPT (raw_ts) REPLACE (TIMESTAMP(raw_ts) AS ts)
FROM my_table
```

---

## FROM Clause

```sql
FROM table_name [[AS] alias]
FROM dataset.table
FROM project.dataset.table
FROM (subquery) [AS] alias
FROM UNNEST(array_expr) [AS] alias [WITH OFFSET]
FROM table TABLESAMPLE SYSTEM (n PERCENT)
```

---

## JOIN Types

```sql
[INNER] JOIN t2 ON condition
LEFT [OUTER] JOIN t2 ON condition
RIGHT [OUTER] JOIN t2 ON condition
FULL [OUTER] JOIN t2 ON condition
CROSS JOIN t2                         -- no ON clause
JOIN t2 USING (col1, col2)            -- columns must have identical names
```

**CROSS JOIN UNNEST** — the standard way to flatten repeated/array fields:
```sql
SELECT t.id, elem
FROM my_table AS t
CROSS JOIN UNNEST(t.tags) AS elem
```

With element index:
```sql
SELECT t.id, elem, pos
FROM my_table AS t
CROSS JOIN UNNEST(t.tags) AS elem WITH OFFSET AS pos
```

---

## WHERE Clause

- Evaluated before aggregation — cannot reference SELECT aliases
- Cannot reference window functions (use QUALIFY for that)

```sql
WHERE status = 'active'
  AND created_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  AND id IN (SELECT id FROM allowed)
  AND EXISTS (SELECT 1 FROM other WHERE other.ref = t.id)
```

---

## GROUP BY Clause

```sql
GROUP BY col1, col2
GROUP BY ALL                          -- groups by every non-aggregate SELECT expression
GROUP BY ROLLUP(a, b, c)             -- subtotals: (a,b,c), (a,b), (a), ()
GROUP BY CUBE(a, b)                  -- all combinations: (a,b), (a), (b), ()
GROUP BY GROUPING SETS((a,b), (a), ())  -- explicit grouping sets
```

`GROUP BY ALL` avoids manually listing every non-aggregate column:
```sql
SELECT user_id, date, COUNT(*) AS cnt
FROM events
GROUP BY ALL
```

Identify which grouping level produced a row with `GROUPING()`:
```sql
SELECT dept, role, SUM(salary), GROUPING(dept) AS is_dept_total
FROM employees
GROUP BY ROLLUP(dept, role)
```

---

## HAVING Clause

Filters after aggregation. Can reference aggregate functions and GROUP BY expressions.

```sql
HAVING COUNT(*) > 10
  AND SUM(revenue) >= 1000
```

---

## QUALIFY Clause (BigQuery-specific)

Filters rows based on window function results — avoids wrapping in a subquery.

**Without QUALIFY** (verbose):
```sql
SELECT * FROM (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY ts DESC) AS rn
  FROM events
) WHERE rn = 1
```

**With QUALIFY** (idiomatic BigQuery):
```sql
SELECT *
FROM events
QUALIFY ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY ts DESC) = 1
```

The window function can be referenced by alias (if defined in SELECT) or written inline in QUALIFY:
```sql
SELECT *, RANK() OVER (PARTITION BY dept ORDER BY salary DESC) AS rnk
FROM employees
QUALIFY rnk <= 3
```

---

## ORDER BY Clause

```sql
ORDER BY col1 ASC, col2 DESC
ORDER BY col1 NULLS FIRST          -- move NULLs to top
ORDER BY col1 NULLS LAST           -- push NULLs to bottom (default for ASC)
```

Default NULL ordering: `ASC → NULLS LAST`, `DESC → NULLS FIRST`.

---

## LIMIT / OFFSET

```sql
LIMIT 100
LIMIT 100 OFFSET 200
```

Without `ORDER BY`, row selection is non-deterministic.

---

## WITH Clauses (CTEs)

```sql
WITH
  base AS (
    SELECT * FROM raw_events WHERE date >= '2024-01-01'
  ),
  aggregated AS (
    SELECT user_id, COUNT(*) AS cnt FROM base GROUP BY ALL
  )
SELECT * FROM aggregated WHERE cnt > 5
```

**Recursive CTEs** require the `RECURSIVE` keyword:
```sql
WITH RECURSIVE nums AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n + 1 FROM nums WHERE n < 10
)
SELECT * FROM nums
```

---

## Set Operators

```sql
query1 UNION ALL query2            -- all rows, keeps duplicates (most common)
query1 UNION DISTINCT query2       -- deduplicates combined result
query1 INTERSECT DISTINCT query2   -- rows present in both
query1 EXCEPT DISTINCT query2      -- rows in query1 not in query2
```

- Column count and types must match across operands
- `STRUCT` and `ARRAY` columns cannot be used with `UNION`, `INTERSECT`, or `EXCEPT DISTINCT`, or with `SELECT DISTINCT`

---

## Subqueries

```sql
-- Scalar subquery
SELECT (SELECT MAX(val) FROM t) AS max_val

-- In FROM
SELECT * FROM (SELECT a, b FROM t WHERE cond) AS sub

-- Correlated
SELECT * FROM t1
WHERE val > (SELECT AVG(val) FROM t2 WHERE t2.k = t1.k)

-- EXISTS
WHERE EXISTS (SELECT 1 FROM t2 WHERE t2.ref = t1.id)

-- NOT IN (careful with NULLs — prefer NOT EXISTS)
WHERE id NOT IN (SELECT id FROM exclusions WHERE id IS NOT NULL)
```

---

## TABLESAMPLE

Samples approximately n% of table blocks. Cost-effective for exploration.

```sql
SELECT * FROM my_table TABLESAMPLE SYSTEM (1 PERCENT)
```

- Only on base tables — not subqueries, CTEs, or views
- Result is approximate; not reproducible between runs

---

## Pipe Syntax (`|>`)

Pipe syntax chains operations left-to-right instead of nesting. Starts with `FROM`, not `SELECT`.

```sql
FROM mydataset.orders
|> WHERE status = 'complete'
|> AGGREGATE SUM(amount) AS total, COUNT(*) AS cnt
   GROUP BY customer_id
|> ORDER BY total DESC
|> LIMIT 10
```

### All Pipe Operators

| Operator | Purpose |
|---|---|
| `SELECT` | Project/transform columns (replaces, doesn't add) |
| `EXTEND` | Add computed columns without dropping existing ones |
| `WHERE` | Filter rows |
| `AGGREGATE ... GROUP BY` | Group and aggregate (replaces `SELECT ... GROUP BY`) |
| `ORDER BY` | Sort results |
| `LIMIT` | Restrict row count |
| `JOIN` | Join with another table |
| `WINDOW` | Add window function columns |
| `RENAME old AS new` | Rename a column |
| `DROP col` | Remove a specific column |
| `SET col = expr` | Update a column value in place |
| `PIVOT` | Rotate rows to columns |
| `UNPIVOT` | Rotate columns to rows |
| `AS alias` | Assign alias to current relation |
| `CALL tvf(...)` | Call a table-valued function |
| `TABLESAMPLE SYSTEM (n PERCENT)` | Sample rows |

### Key Differences from Standard SQL

```sql
-- Standard SQL: add a column requires subquery or CTE
SELECT *, price * qty AS revenue FROM orders

-- Pipe: EXTEND adds without rewriting column list
FROM orders
|> EXTEND price * qty AS revenue

-- Pipe: DROP removes without listing all kept columns
|> DROP raw_internal_field

-- Pipe: AGGREGATE syntax
|> AGGREGATE COUNT(*) AS n, AVG(score) AS avg_score
   GROUP BY category
```

Pipe queries can mix with standard SQL via CTEs:
```sql
WITH base AS (
  FROM events
  |> WHERE type = 'click'
  |> AGGREGATE COUNT(*) AS clicks GROUP BY page_id
)
SELECT * FROM base ORDER BY clicks DESC
```

---

## Common Mistakes

- **Referencing SELECT aliases in WHERE**: not allowed — use a subquery or CTE
- **NOT IN with NULLs**: if the subquery can return NULLs, `NOT IN` returns no rows — prefer `NOT EXISTS`
- **QUALIFY without a window function**: QUALIFY only works with window function results
- **CROSS JOIN producing row explosion**: expected behavior — each left row joins to every right row
- **`UNION` without `ALL`**: deduplication is expensive and usually unintended; almost always want `UNION ALL`
