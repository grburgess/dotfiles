---
name: bigquery-loading-export
description: BigQuery data ingestion and export for data engineers — loading from Cloud Storage via bq CLI (bq load for CSV, NDJSON, Parquet, Avro) and DDL (LOAD DATA statement), creating external tables (CREATE EXTERNAL TABLE with OPTIONS, bq mk --external_table_definition), querying hive-partitioned external data, and exporting data (bq extract, EXPORT DATA DDL, supported formats and compression). CLI and SQL only. Apply when loading data from GCS, creating external tables, querying federated/external data, or exporting BigQuery tables.
---

# BigQuery Loading and Export

---

## Loading Data from Cloud Storage

### bq load — Core Syntax

```bash
bq --location=LOCATION load \
  [--source_format=FORMAT] \
  [flags] \
  DATASET.TABLE \
  SOURCE_URI [SOURCE_URI ...] \
  [SCHEMA]
```

`LOCATION` should match the dataset region (e.g., `US`, `EU`, `us-central1`).

`SCHEMA` is one of:
- Path to a JSON schema file: `./schema.json`
- Inline schema: `col1:STRING,col2:INT64,col3:FLOAT64` (no RECORD, no descriptions, no REQUIRED)
- Omit if using `--autodetect`

---

### Loading CSV

```bash
bq load \
  --source_format=CSV \
  --autodetect \
  mydataset.mytable \
  gs://mybucket/data/*.csv
```

**Common flags:**

| Flag | Default | Notes |
|---|---|---|
| `--autodetect` | false | Infer schema from file |
| `--skip_leading_rows` | 0 | Number of header rows to skip |
| `--field_delimiter` | `,` | Use `\t` for tab-delimited |
| `--null_marker` | (none) | String to treat as NULL (e.g., `""`, `"NULL"`, `"NA"`) |
| `--quote` | `"` | Field enclosure character |
| `--allow_jagged_rows` | false | Treat missing trailing fields as NULL |
| `--allow_quoted_newlines` | false | Allow `\n` inside quoted fields |
| `--ignore_unknown_values` | false | Skip extra fields not in schema |
| `--max_bad_records` | 0 | Tolerated error rows before job fails |
| `--encoding` | UTF-8 | File character encoding |
| `--time_zone` | UTC | Timezone for TIMESTAMP parsing |
| `--replace` | false | Overwrite existing table |
| `--append_table` | false | Append to existing table |

```bash
# Skip header, tab-delimited, treat "N/A" as NULL
bq load \
  --source_format=CSV \
  --skip_leading_rows=1 \
  --field_delimiter='\t' \
  --null_marker='N/A' \
  --max_bad_records=10 \
  mydataset.mytable \
  gs://mybucket/data.tsv \
  ./schema.json

# Append to partitioned table
bq load \
  --source_format=CSV \
  --append_table \
  --time_partitioning_type=DAY \
  --time_partitioning_field=event_date \
  mydataset.events \
  gs://mybucket/events_2024_03_01.csv \
  ./schema.json
```

**CSV gotchas:**
- Nested/repeated (RECORD/ARRAY) data is **not** supported in CSV
- BOM characters in UTF-8 files cause silent parse errors — strip them first
- Compressed (gzip) and uncompressed files **cannot be mixed** in one load job
- Gzip max file size: 4 GB
- `DATE` must use `YYYY-MM-DD` format; custom formats via `--date_format`

---

### Loading NDJSON (Newline-Delimited JSON)

Each JSON object must be on its own line — JSON arrays spanning multiple lines are not supported.

```bash
bq load \
  --source_format=NEWLINE_DELIMITED_JSON \
  --autodetect \
  mydataset.mytable \
  gs://mybucket/data/*.json
```

```bash
# With explicit schema, ignore unknown fields
bq load \
  --source_format=NEWLINE_DELIMITED_JSON \
  --ignore_unknown_values \
  mydataset.mytable \
  gs://mybucket/data.json \
  ./schema.json
```

**JSON gotchas:**
- Large integers outside `[-2^53+1, 2^53-1]` must be passed as strings
- `DATE`: must be `YYYY-MM-DD`; `TIMESTAMP`: `YYYY-MM-DD HH:MM:SS[.fraction][+offset]`

---

### Loading Parquet

Parquet is self-describing — schema is auto-detected from the file, no `--autodetect` flag needed.

```bash
bq load \
  --source_format=PARQUET \
  mydataset.mytable \
  gs://mybucket/data/*.parquet

# Append
bq load \
  --source_format=PARQUET \
  --noreplace \
  mydataset.mytable \
  gs://mybucket/newdata.parquet

# Overwrite
bq load \
  --source_format=PARQUET \
  --replace \
  mydataset.mytable \
  gs://mybucket/newdata.parquet
```

When loading multiple Parquet files with different schemas: BigQuery uses the alphabetically **last** file for schema derivation. If files may have diverging schemas, specify `--reference_file_schema_uri`:
```bash
--reference_file_schema_uri="gs://mybucket/canonical.parquet"
```

Supported Parquet compression: `GZip`, `LZO_1C`, `LZO_1X`, `LZ4_RAW`, `Snappy`, `ZSTD`.

Wildcard restriction: cannot mix schemas across wildcard-matched files.

---

### Loading Avro

```bash
bq load \
  --source_format=AVRO \
  --use_avro_logical_types \
  mydataset.mytable \
  gs://mybucket/data/*.avro
```

`--use_avro_logical_types` maps Avro logical types to BigQuery equivalents (e.g., Avro `date` → BigQuery `DATE`). Without it they fall back to primitive types.

---

## LOAD DATA DDL Statement

SQL alternative to `bq load`. Runs as a query job.

```sql
-- Overwrite table
LOAD DATA OVERWRITE mydataset.mytable
(user_id STRING, ts TIMESTAMP, amount NUMERIC)
FROM FILES (
  format = 'CSV',
  uris = ['gs://mybucket/data/*.csv'],
  skip_leading_rows = 1
);

-- Append to table
LOAD DATA INTO mydataset.mytable
FROM FILES (
  format = 'NEWLINE_DELIMITED_JSON',
  uris = ['gs://mybucket/data/*.json']
);

-- Parquet (schema inferred)
LOAD DATA OVERWRITE mydataset.mytable
FROM FILES (
  format = 'PARQUET',
  uris = ['gs://mybucket/data/*.parquet']
);
```

**`FROM FILES` options:**

| Option | Values | Notes |
|---|---|---|
| `format` | `'CSV'`, `'JSON'`, `'PARQUET'`, `'AVRO'`, `'ORC'` | Required |
| `uris` | `['gs://...']` | Array, supports wildcards |
| `skip_leading_rows` | integer | CSV only |
| `field_delimiter` | string | CSV only |
| `null_marker` | string | CSV: value to treat as NULL |
| `quote` | string | CSV: field enclosure character |
| `allow_jagged_rows` | bool | CSV |
| `allow_quoted_newlines` | bool | CSV |
| `ignore_unknown_values` | bool | JSON/CSV |
| `max_bad_records` | integer | |
| `hive_partition_uri_prefix` | string | For hive-partitioned GCS data |
| `require_hive_partition_filter` | bool | |

---

## External Tables

Query GCS data directly without loading — data stays in Cloud Storage.

**Limitations vs native tables:** read-only (no DML), no caching, no clustering, no export jobs, no copying, no wildcard table queries, no BI Engine support, no time travel (except Iceberg).

### CREATE EXTERNAL TABLE DDL

```sql
-- CSV external table
CREATE EXTERNAL TABLE mydataset.external_csv
OPTIONS (
  format = 'CSV',
  uris = ['gs://mybucket/data/*.csv'],
  skip_leading_rows = 1,
  field_delimiter = ','
);

-- Parquet external table (schema auto-detected)
CREATE EXTERNAL TABLE mydataset.external_parquet
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://mybucket/parquet/*.parquet']
);

-- NDJSON with explicit schema in DDL
CREATE EXTERNAL TABLE mydataset.external_json (
  user_id   STRING,
  event_ts  TIMESTAMP,
  payload   JSON
)
OPTIONS (
  format = 'NEWLINE_DELIMITED_JSON',
  uris = ['gs://mybucket/events/*.json']
);
```

### bq CLI — External Table

```bash
# Create using a table definition JSON file
bq mk --table --external_table_definition=def.json mydataset.ext_table

# Create with autodetect
bq mk \
  --table \
  --external_table_definition='{"sourceFormat":"CSV","autodetect":true,"sourceUris":["gs://bucket/data.csv"]}' \
  mydataset.ext_table
```

Table definition file (`def.json`):
```json
{
  "sourceFormat": "CSV",
  "sourceUris": ["gs://mybucket/data/*.csv"],
  "autodetect": true,
  "csvOptions": {
    "skipLeadingRows": 1,
    "fieldDelimiter": ",",
    "encoding": "UTF-8"
  }
}
```

### Location Requirement

The Cloud Storage bucket and BigQuery dataset must be in the same region or both in a multi-region that covers the bucket's region. E.g.: a `us-central1` bucket must use a `us-central1` or `US` dataset.

---

## Hive-Partitioned External Tables

Queries GCS data organized as `key=value` directory partitions:

```
gs://my_bucket/events/dt=2024-01-01/region=us/
gs://my_bucket/events/dt=2024-01-01/region=eu/
gs://my_bucket/events/dt=2024-01-02/region=us/
```

### Create with DDL

```sql
CREATE EXTERNAL TABLE mydataset.hive_events
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://my_bucket/events/*'],
  hive_partition_uri_prefix = 'gs://my_bucket/events',
  require_hive_partition_filter = FALSE
);
```

Hive partition detection modes (set in bq CLI / table definition):
- `AUTO` — infer names and types (STRING, INTEGER, DATE, TIMESTAMP)
- `STRINGS` — all partition keys become STRING
- `CUSTOM` — specify types inline: `gs://bucket/events/{dt:DATE}/{region:STRING}`

### Querying Hive-Partitioned Tables

Partition keys become regular columns — BigQuery prunes files that don't match:
```sql
SELECT *
FROM mydataset.hive_events
WHERE dt = '2024-01-01'          -- pruned to that day's files
  AND region = 'us'

-- Date range
WHERE dt BETWEEN '2024-01-01' AND '2024-01-07'
```

**Partition filter requirement**: if `require_hive_partition_filter = TRUE`, queries without a qualifying filter raise an error. The filter must reference partition columns independently — `WHERE dt = 'x' OR data_col = 'y'` does not qualify.

Limitations:
- Maximum 10 partition keys per table
- Partition keys and file data columns cannot share names
- Only GoogleSQL supported

---

## Exporting Data

### bq extract — Export Table to Cloud Storage

```bash
bq extract \
  --destination_format=CSV \
  mydataset.mytable \
  gs://mybucket/export/output-*.csv

# Parquet with Snappy compression
bq extract \
  --destination_format=PARQUET \
  --compression=SNAPPY \
  mydataset.mytable \
  gs://mybucket/export/output-*.parquet

# Compressed CSV
bq extract \
  --destination_format=CSV \
  --compression=GZIP \
  mydataset.mytable \
  gs://mybucket/export/output-*.csv.gz
```

Use `*` wildcard in the destination URI when the table is large — BigQuery shards the output across multiple files automatically. Tables > 1 GB require a wildcard URI.

**Supported formats and compression:**

| Format | Compression |
|---|---|
| `CSV` | `GZIP`, `NONE` |
| `NEWLINE_DELIMITED_JSON` | `GZIP`, `NONE` |
| `AVRO` | `DEFLATE`, `SNAPPY`, `NONE` |
| `PARQUET` | `GZIP`, `SNAPPY`, `ZSTD`, `NONE` |

Additional flags:
```bash
--print_header=false      # CSV: omit header row
--field_delimiter='\t'    # CSV: tab-separated
--use_avro_logical_types  # Avro: use logical types for dates/times
```

### EXPORT DATA DDL

```sql
EXPORT DATA
  OPTIONS (
    uri = 'gs://mybucket/export/output-*.csv',
    format = 'CSV',
    overwrite = TRUE,
    header = TRUE,
    field_delimiter = ','
  )
AS SELECT * FROM mydataset.mytable WHERE date >= '2024-01-01';
```

`EXPORT DATA` runs as a query job and exports the **query result** — not a stored table. Use this to export filtered or transformed data without creating an intermediate table.

Supported `format` values: `'CSV'`, `'JSON'`, `'AVRO'`, `'PARQUET'`.

PARQUET-specific options:
```sql
OPTIONS (
  uri = 'gs://mybucket/out-*.parquet',
  format = 'PARQUET',
  compression = 'SNAPPY',
  overwrite = TRUE
)
```

---

## Common Mistakes

- **CSV with nested/repeated columns**: CSV does not support ARRAY or STRUCT — use Parquet, Avro, or JSON for nested data
- **Mixed compressed/uncompressed in one load job**: not allowed — use separate load jobs
- **Missing wildcard on large exports**: `bq extract` will fail without a `*` wildcard URI for tables that produce multiple shards
- **External table DML**: external tables are read-only — `INSERT`, `UPDATE`, `DELETE`, `MERGE` are not supported
- **Cross-region bucket/dataset**: bucket and dataset must share the same region; mismatches cause load/query failures
- **Hive filter with OR**: `WHERE partition_col = 'x' OR data_col = 'y'` does not satisfy a partition filter requirement — the partition predicate must stand alone
- **`LOAD DATA` vs `bq load` column types**: `LOAD DATA` schema declared inline uses GoogleSQL types (`STRING`, `INT64`, `TIMESTAMP`); `bq load` JSON schema uses legacy type names (`STRING`, `INTEGER`, `TIMESTAMP`)
- **JSON large integers**: integers outside `[-2^53+1, 2^53-1]` corrupt silently in JSON load — pass them as strings and CAST on read
- **Autodetect schema with all-string columns in CSV**: BigQuery won't reliably detect header row — add a numeric column or provide the schema explicitly
