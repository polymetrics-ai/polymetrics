import React from 'react';
import { flexRender, getCoreRowModel, useReactTable } from '@tanstack/react-table';
import { DataTableProps } from '@/types/datatable';
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow
} from '@/components/ui/table';
const DataTable: React.FC<DataTableProps> = ({ data, columns }) => {
    console.log({ data });
    const table = useReactTable({
        data: data?.data ? data.data : [],
        columns,
        getCoreRowModel: getCoreRowModel(),
    });

    // Use the 'table' variable to render the table
    return (
        <Table>
            <TableHeader className="[&_tr]:border-b-0">
                {table.getHeaderGroups().map((headerGroup) => (
                    <TableRow key={headerGroup.id} className="space-x-3">
                        {headerGroup.headers.map((header) => (
                            <TableHead className="text-slate-400" key={header.id}>
                                {flexRender(header.column.columnDef.header, header.getContext())}
                            </TableHead>
                        ))}
                    </TableRow>
                ))}
            </TableHeader>
            <TableBody>
                {table.getRowModel().rows.map((rowEl) => (
                    <TableRow key={rowEl.id}>
                        {rowEl.getVisibleCells().map((cellEl) => {
                            console.log(cellEl.getValue())
                            return(<TableCell key={cellEl.id}>
                                {flexRender(cellEl.column.columnDef.cell, cellEl.getContext())}
                            </TableCell>)
                            
})}
                    </TableRow>
                ))}
            </TableBody>
        </Table>
    );
};
export default DataTable;
