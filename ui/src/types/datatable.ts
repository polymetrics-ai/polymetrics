import { ColumnDef } from '@tanstack/react-table';

export interface DataTableProps {
    data: Array<{ [key: string]: unknown }>;
    columns: ColumnDef<unknown>[];
}
