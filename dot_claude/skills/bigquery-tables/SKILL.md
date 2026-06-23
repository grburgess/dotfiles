---
name: bigquery-tables
description: BigQuery table and schema management for data engineers — DDL (CREATE TABLE, CREATE OR REPLACE TABLE, CREATE TABLE IF NOT EXISTS, CREATE TABLE AS SELECT), schema definition (JSON format, inline DDL, bq CLI), time partitioning (PARTITION BY DATE/TIMESTAMP column or ingestion time), range partitioning, clustering (CLUSTER BY, up to 4 columns), table properties (expiry, labels, description), bq CLI table commands (mk, show, rm, cp, update), and INFORMATION_SCHEMA queries. Apply when designing tables, writing DDL, managing table schemas, or using bq CLI for table operations.
---

# BigQuery Table and Schema Management

---

## CREATE TABLE DDL

### Basic Table

```sql
CREATE TABLE mydataset.my_table (
  user_id     STRING NOT NULL,
  event_type  STRING,
  ts          TIMESTAMP,
  amount      NUMERIC,
  tags        ARRAY<STRING>,
  metadata    STRUCT<source STRING, version INT64>
)
OPTIONS (
  description = 'User event stream',
  labels      = [('env', 'prod'), ('team', 'analytics')],
  expiration_timestamp = TIMESTAMP '2025-12-31 00:00:00 UTC'
);
```

### Variants

```sql
CREATE OR REPLACE TABLE mydataset.my_table (...)  -- drops and recreates
CREATE TABLE IF NOT EXISTS mydataset.my_table (...) -- no-op if exists
```

### CREATE TABLE AS SELECT (CTAS)

```sql
CREATE TABLE mydataset.summary AS
SELECT
  user_id,
  COUNT(*)     AS event_count,
  MAX(ts)      AS last_seen
FROM mydataset.events
GROUP BY user_id;
```

With explicit schema + options:
```sql
CREATE TABLE mydataset.summary
PARTITION BY DATE(ts)
CLUSTER BY user_id
OPTIONS (require_partition_filter = TRUE)
AS SELECT * FROM mydataset.source_table;
```

---

## Schema Definition

### Column Modes

| Mode | Behavior |
|---|---|
| `NULLABLE` | Allows NULL (default when mode is omitted) |
| `NOT NULL` | Disallows NULL (equivalent to `REQUIRED` in JSON schema) |
| `REPEATED` | Column is an ARRAY — shorthand for `ARRAY<type>` |

### Supported Types in DDL

`INT64`, `FLOAT64`, `NUMERIC`, `BIGNUMERIC`, `BOOL`, `STRING`, `BYTES`, `DATE`, `TIME`, `DATETIME`, `TIMESTAMP`, `INTERVAL`, `GEOGRAPHY`, `JSON`, `RANGE<DATE|DATETIME|TIMESTAMP>`, `ARRAY<T>`, `STRUCT<...>`

### JSON Schema File Format

Used with `bq mk --table` and `bq load`. Must use JSON for RECORD types, descriptions, or non-NULLABLE modes.

```json
[
  {"name": "user_id",    "type": "STRING",    "mode": "REQUIRED",  "description": "Unique user identifier"},
  {"name": "score",      "type": "NUMERIC",   "mode": "NULLABLE"},
  {"name": "tags",       "type": "STRING",    "mode": "REPEATED"},
  {
    "name": "address",
    "type": "RECORD",
    "mode": "NULLABLE",
    "fields": [
      {"name": "city",    "type": "STRING"},
      {"name": "country", "type": "STRING", "mode": "REQUIRED"}
    ]
  }
]
```

Column name rules: letters, digits, underscores; max 300 characters. Forbidden prefixes: `_TABLE_`, `_FILE_`, `_PARTITION_`, `_ROW_TIMESTAMP`, `__ROOT__`.

Default value expressions (set in schema):
```json
{"name": "created_at", "type": "TIMESTAMP", "defaultValueExpression": "CURRENT_TIMESTAMP()"}
```

Allowed defaults: `CURRENT_DATE`, `CURRENT_DATETIME`, `CURRENT_TIME`, `CURRENT_TIMESTAMP`, `GENERATE_UUID`, `RAND`, `SESSION_USER`, `ST_GEOGPOINT`.

---

## Time Partitioning

Partitioning improves query performance and cost by allowing BigQuery to skip irrelevant partitions.

### Partition on a Column

```sql
-- Partition by DATE column
CREATE TABLE mydataset.events (
  event_date  DATE    NOT NULL,
  user_id     STRING,
  event_type  STRING
)
PARTITION BY event_date;

-- Partition by TIMESTAMP column (truncated to DAY)
CREATE TABLE mydataset.logs (
  ts          TIMESTAMP NOT NULL,
  message     STRING
)
PARTITION BY DATE(ts);

-- Other granularities
PARTITION BY DATETIME_TRUNC(created_at, MONTH)
PARTITION BY TIMESTAMP_TRUNC(ts, HOUR)
PARTITION BY TIMESTAMP_TRUNC(ts, YEAR)
```

Valid granularities: `HOUR`, `DAY` (default), `MONTH`, `YEAR`.

### Ingestion-Time Partitioning

Partition on when data was loaded (no partition column in the table):

```sql
CREATE TABLE mydataset.events
PARTITION BY _PARTITIONDATE          -- DATE pseudo-column
OPTIONS (...)
(...columns...)
```

Or use `_PARTITIONTIME` (TIMESTAMP). Reference in queries:
```sql
SELECT * FROM mydataset.events
WHERE _PARTITIONDATE = '2024-03-01'

-- Range of partitions
WHERE _PARTITIONDATE BETWEEN '2024-01-01' AND '2024-03-31'
```

### Partition Expiry

```sql
OPTIONS (partition_expiration_days = 90)  -- auto-expire partitions after 90 days
```

### Require Partition Filter

```sql
OPTIONS (require_partition_filter = TRUE)
```

Queries without a qualifying partition filter will error. A filter qualifies when it references the partition column directly (not inside an expression or OR with a non-partition column).

---

## Range Partitioning

Partition numeric data into explicit ranges:

```sql
CREATE TABLE mydataset.user_data (
  user_id   INT64,
  region    STRING,
  score     FLOAT64
)
PARTITION BY RANGE_BUCKET(user_id, GENERATE_ARRAY(0, 1000000, 10000));
-- creates partitions: [0,10000), [10000,20000), ..., [990000,1000000), UNPARTITIONED
```

- Partitions non-DATE numeric columns (`INT64`)
- Values outside the range go into the `UNPARTITIONED` partition
- The `GENERATE_ARRAY` call is evaluated at table creation time

---

## Clustering

```sql
CREATE TABLE mydataset.orders (
  order_id    STRING,
  customer_id STRING,
  order_date  DATE,
  status      STRING,
  amount      NUMERIC
)
PARTITION BY order_date
CLUSTER BY customer_id, status;
```

Rules:
- Maximum **4 clustering columns**
- Must be top-level, non-repeated columns
- Allowed types: `BOOL`, `DATE`, `DATETIME`, `TIMESTAMP`, `INT64`, `NUMERIC`, `BIGNUMERIC`, `STRING`, `GEOGRAPHY`, `RANGE`
- Column order matters: filter on leading columns for best pruning
- `PARTITION BY` and `CLUSTER BY` can be combined — partition pruning happens first, then clustering within partitions

**Cost caveat:** Clustering does not give pre-execution cost estimates — unlike partitioning, bytes scanned is only known after execution.

**Adding clustering to existing table:**
```sql
ALTER TABLE mydataset.my_table CLUSTER BY col1, col2;
```
Existing data is not automatically reclustered — submit a DML operation (e.g., `UPDATE ... WHERE TRUE`) to trigger reclustering.

---

## ALTER TABLE

```sql
-- Add a column
ALTER TABLE mydataset.my_table
ADD COLUMN new_col STRING;

-- Add column with position (FIRST / AFTER)
ALTER TABLE mydataset.my_table
ADD COLUMN new_col INT64 AFTER existing_col;

-- Rename column (requires schema check — renames do not cascade)
ALTER TABLE mydataset.my_table
RENAME COLUMN old_name TO new_name;

-- Drop a column
ALTER TABLE mydataset.my_table
DROP COLUMN col_name;

-- Relax mode (REQUIRED → NULLABLE)
ALTER TABLE mydataset.my_table
ALTER COLUMN col_name DROP NOT NULL;

-- Set column default
ALTER TABLE mydataset.my_table
ALTER COLUMN created_at SET DEFAULT CURRENT_TIMESTAMP();

-- Change table options
ALTER TABLE mydataset.my_table
SET OPTIONS (description = 'Updated description', expiration_timestamp = NULL);
```

---

## bq CLI — Table Commands

### Create Table

```bash
# From JSON schema file
bq mk --table mydataset.mytable schema.json

# Inline schema (no RECORD, no descriptions, no REQUIRED mode)
bq mk -t mydataset.mytable col1:STRING,col2:FLOAT64,col3:INTEGER

# With partitioning and clustering
bq mk --table \
  --time_partitioning_type=DAY \
  --time_partitioning_field=event_date \
  --clustering_fields=user_id,status \
  --description="Event log" \
  --label=env:prod \
  mydataset.mytable schema.json

# With expiry (seconds)
bq mk -t --expiration 86400 mydataset.temp_table schema.json
```

### Inspect Table

```bash
bq show mydataset.mytable                     # summary with schema
bq show --schema mydataset.mytable            # schema only (machine-readable)
bq show --format=prettyjson mydataset.mytable # full metadata as JSON
bq show --schema --format=prettyjson mydataset.mytable > schema.json  # export schema
```

### List Tables

```bash
bq ls mydataset                               # all tables in dataset
bq ls --max_results=100 mydataset
```

### Delete Table

```bash
bq rm -t mydataset.mytable                    # prompts for confirmation
bq rm -f -t mydataset.mytable                 # force delete without prompt
```

### Copy Table

```bash
bq cp source_dataset.source_table dest_dataset.dest_table
bq cp -a source_dataset.source_table dest_dataset.dest_table  # append
bq cp -f source_dataset.source_table dest_dataset.dest_table  # overwrite
```

### Update Table Properties

```bash
bq update --description "New description" mydataset.mytable
bq update --expiration 3600 mydataset.mytable           # set expiry in seconds
bq update --label key:value mydataset.mytable
bq update --clear_label key mydataset.mytable
```

### Create Table from Query

```bash
bq query \
  --destination_table project:dataset.table \
  --use_legacy_sql=false \
  --replace \
  'SELECT * FROM mydataset.source WHERE date >= "2024-01-01"'

# Append mode
bq query \
  --destination_table project:dataset.table \
  --append_table \
  --use_legacy_sql=false \
  'SELECT ...'
```

---

## INFORMATION_SCHEMA

Query table metadata without `bq show`:

```sql
-- List tables in dataset
SELECT table_name, table_type, creation_time, row_count, size_bytes
FROM mydataset.INFORMATION_SCHEMA.TABLES

-- Get column info
SELECT column_name, data_type, is_nullable, column_default
FROM mydataset.INFORMATION_SCHEMA.COLUMNS
WHERE table_name = 'my_table'
ORDER BY ordinal_position

-- Check clustering columns
SELECT column_name, clustering_ordinal_position
FROM mydataset.INFORMATION_SCHEMA.COLUMNS
WHERE table_name = 'my_table'
  AND clustering_ordinal_position IS NOT NULL
ORDER BY clustering_ordinal_position

-- Check partition info
SELECT *
FROM mydataset.INFORMATION_SCHEMA.PARTITIONS
WHERE table_name = 'my_table'
ORDER BY partition_id DESC
LIMIT 20

-- Recent jobs
SELECT job_id, creation_time, state, total_bytes_processed, query
FROM region-us.INFORMATION_SCHEMA.JOBS_BY_PROJECT
WHERE creation_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 DAY)
  AND statement_type = 'SELECT'
ORDER BY total_bytes_processed DESC
LIMIT 20
```

---

## Common Mistakes

- **Inline bq CLI schema for RECORD columns**: inline schema (`field:type`) does not support RECORD/STRUCT, REQUIRED mode, or descriptions — always use a JSON schema file for these
- **Partition filter on expression**: `WHERE DATE(ts) = '2024-01-01'` qualifies for partition pruning; `WHERE EXTRACT(YEAR FROM ts) = 2024` does not — BigQuery needs a direct comparison
- **Adding clustering to existing table**: `ALTER TABLE ... CLUSTER BY` changes future data only — existing data must be reclustered manually
- **`PARTITION BY ts` on TIMESTAMP column**: use `PARTITION BY DATE(ts)` or `PARTITION BY TIMESTAMP_TRUNC(ts, DAY)` — bare TIMESTAMP partitioning requires `TIMESTAMP_TRUNC`
- **Range partitioning on FLOAT64**: only `INT64` columns are supported for range partitioning
- **`require_partition_filter = TRUE` with OR conditions**: `WHERE partition_col = 'x' OR non_partition_col = 'y'` does not satisfy the requirement — the filter must reference the partition column independently
