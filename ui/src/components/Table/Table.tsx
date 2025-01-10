import React from 'react';
import { useNavigate } from '@tanstack/react-router';
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
    const navigate = useNavigate();

    const table = useReactTable({
        data: data ?? [],
        columns,
        getCoreRowModel: getCoreRowModel()
    });

    const handleRowNavigation = (rowData: any) => {
        navigate({
            to: `/connectors/${rowData?.id}`,
            state: rowData
        });
    };

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
                {table.getRowModel().rows.map((rowEl) => {
                    return (
                        <TableRow
                            key={rowEl.id}
                            role="button"
                            tabIndex={0}
                            aria-label={`View details for ${rowEl?.original?.name || 'connector'}`}
                            onClick={() => handleRowNavigation(rowEl.original)}
                            onKeyDown={(e) => {
                                if (e.key === 'Enter' || e.key === ' ') {
                                    e.preventDefault();
                                    handleRowNavigation(rowEl.original);
                                }
                            }}
                        >
                            {rowEl.getVisibleCells().map((cellEl) => (
                                <TableCell key={cellEl.id}>
                                    {flexRender(
                                        cellEl.column.columnDef.cell,
                                        cellEl.getContext()
                                    )}
                                </TableCell>
                            ))}
                        </TableRow>
                    );
                })}
            </TableBody>
        </Table>
    );
};
export default DataTable;
