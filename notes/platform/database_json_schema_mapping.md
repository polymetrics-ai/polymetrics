# Database to JSON Schema Mapping Principles

## Overview

This document outlines the standardized approach for mapping database types to JSON Schema across different database systems (PostgreSQL, DuckDB, MySQL, etc.) while maintaining data integrity and compatibility.

## Core Principles

1. Type Standardization
   - Use the most inclusive numeric type for each database
   - Maintain consistent type mapping across different databases
   - Preserve precision and scale where applicable

2. Schema Organization
   - Each database connector maintains its own mapping.json
   - Common type definitions shared across databases
   - Database-specific types handled individually

3. Type Categories

### Numeric Types
- Integer Types  ```json
  {
    "type": "integer",
    "minimum": -9223372036854775808,
    "maximum": 9223372036854775807
  }  ```
- Decimal/Numeric Types  ```json
  {
    "type": "string",
    "format": "decimal"
  }  ```

### String Types
- Character Types (VARCHAR, TEXT, CHAR)
- Binary Types (BLOB, BYTEA)
- Specialized Types (UUID, JSON)

### Temporal Types
- Timestamp Types (with/without timezone)
- Date Types
- Time Types
- Interval/Duration Types

### Complex Types
- Arrays/Lists
- Structured Types (STRUCT, ROW)
- Key-Value Types (MAP, HSTORE)

## Implementation Guidelines

1. Mapping File Structure   ```
   database_connector/
   ├── mapping.json
   ├── connection_specification.json
   └── metadata.json   ```

2. Type Resolution Rules
   - Always map to the most precise compatible JSON Schema type
   - Handle NULL values consistently across all types
   - Support array types through nested schemas

3. Database-Specific Considerations

   PostgreSQL:
   - Handle custom types
   - Support for arrays and composites
   - JSONB specific handling

   DuckDB:
   - Struct and Map types
   - Time precision handling
   - List type support

   MySQL:
   - ENUM type handling
   - Spatial data types
   - JSON type support

## Best Practices

1. Type Mapping
   - Use references ($ref) for common types
   - Maintain explicit NULL handling
   - Document precision/scale requirements

2. Schema Evolution
   - Version control for mappings
   - Backward compatibility support
   - Migration path documentation

3. Validation
   - Format validation for specialized types
   - Range validation for numeric types
   - Pattern validation for structured strings

## Example Implementation

Reference the mapping.json structure: 

json:ruby_connectors/lib/ruby_connectors/duckdb_connector/mapping.json

## Integration Points

1. ETL Pipeline
   - Type conversion during data extraction
   - Validation during transformation
   - Load-time type checking

2. Schema Management
   - Automatic schema generation
   - Schema validation
   - Type inference

3. Error Handling
   - Type conversion errors
   - Validation failures
   - Precision loss detection

## Future Considerations

1. Extensibility
   - Support for new database types
   - Custom type mapping definitions
   - Plugin system for type handlers

2. Performance
   - Caching of type definitions
   - Optimized validation
   - Batch processing support

3. Monitoring
   - Type conversion metrics
   - Validation success rates
   - Schema evolution tracking 