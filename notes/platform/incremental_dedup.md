# Incremental Dedup Implementation

## Overview

The incremental dedup feature implements an efficient data synchronization mechanism that tracks changes between sync runs and handles record deletions, updates, and insertions. This document outlines the technical implementation of the incremental dedup functionality.

## Key Components

### 1. ProcessDeletionsService

Located in `process_deletions_service.rb`, this service handles the detection and processing of deleted records between sync runs.

Key features:
- Uses Redis to track primary key signatures across sync runs
- Compares signatures between current and previous runs to detect deletions
- Creates deletion records for removed data

Reference implementation: 
ruby:platform/app/services/etl/extractors/convert_read_record/process_deletions_service.rb
startLine: 1
endLine: 88

### 2. IncrementalDedupService

Located in `incremental_dedup_service.rb`, this service manages the deduplication process for incremental syncs.

Key features:
- Generates and stores signatures for primary keys and data
- Handles record deduplication using signature comparison
- Manages Redis storage for tracking records across runs

Reference implementation:
ruby:platform/app/services/etl/extractors/convert_read_record/incremental_dedup_service.rb
startLine: 1
endLine: 113

## Data Model

### SyncWriteRecord
- Stores processed records with their signatures and destination actions
- Implements signature generation for both primary keys and data
- Supports multiple destination actions (create, insert, update, delete)

Key fields:
- `primary_key_signature`: Unique identifier for record based on primary keys
- `data_signature`: Hash of the entire record data
- `destination_action`: Type of action to perform (create, insert, update, delete)

## Implementation Details

### 1. Signature Generation

Two types of signatures are generated for each record:

1. Primary Key Signature: 
   - A unique hash generated from the record's primary key fields
   - Uses SHA-256 to create a consistent, deterministic signature
   - Only includes designated primary key fields to track record identity

2. Data Signature:
   - A hash of all record data fields (excluding metadata)
   - Also uses SHA-256 for consistency
   - Used to detect changes in record content, even when primary key remains the same
   - Includes all data fields except system fields like created_at, updated_at

### 2. Deletion Detection

The process for detecting deletions involves:

1. Storing primary key signatures in Redis for each sync run
2. Comparing signatures between current and previous runs
3. Creating deletion records for missing signatures
4. Excluding already processed deletions

### 3. Record Processing Flow

1. Record Ingestion:
   - Records are received and processed in batches
   - Signatures are generated for each record
   - Records are stored in Redis with TTL of 7 days

2. Deduplication:
   - Compare incoming record signatures with existing ones
   - Skip exact duplicates (matching both primary key and data signatures)
   - Create new records for changed data

3. Deletion Processing:
   - Run after all records are processed
   - Compare signatures between sync runs
   - Create deletion records for missing data

## Performance Considerations

1. Database Indexing:
   - Indexes on primary_key_signature and data_signature
   - Compound index on [signature, sync_id] for efficient lookups

2. Redis Usage:
   - TTL of 7 days for sync run data
   - Set operations for efficient signature comparison
   - Minimal memory footprint using only signatures

## Error Handling

1. Invalid Primary Keys:
   - Skip records with missing primary key values
   - Log warnings for invalid primary key configurations

2. Duplicate Processing:
   - Handle duplicate records gracefully
   - Skip exact duplicates to prevent unnecessary processing

## Future Improvements

1. Potential Enhancements:
   - Implement batch processing for large datasets
   - Add support for custom comparison logic
   - Introduce conflict resolution strategies

2. Performance Optimizations:
   - Implement parallel processing for signature generation
   - Optimize Redis usage for large datasets
   - Add caching for frequently accessed signatures