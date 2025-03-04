'use client';

import * as React from 'react';
import {
    ColumnDef,
    ColumnFiltersState,
    SortingState,
    VisibilityState,
    flexRender,
    getCoreRowModel,
    getFilteredRowModel,
    getPaginationRowModel,
    getSortedRowModel,
    useReactTable
} from '@tanstack/react-table';
import { ArrowUpDown } from 'lucide-react';
import { Button } from '@/components/ui/button';
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow
} from '@/components/ui/table';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip';

interface QueryData {
    [key: string]: string | number;
}

interface DataPresentedProps {
    queryData?: QueryData[];
    limit?: number;
    totalRecords?: number;
}

export default function DataPresented({ queryData, limit, totalRecords }: DataPresentedProps) {
    const [sorting, setSorting] = React.useState<SortingState>([]);
    const [columnFilters, setColumnFilters] = React.useState<ColumnFiltersState>([]);
    const [columnVisibility, setColumnVisibility] = React.useState<VisibilityState>({});

    // Dynamic column generation
    const columns = React.useMemo(() => {
        if (!queryData?.length) return [];

        return Object.keys(queryData[0]).map((key) => ({
            accessorKey: key,
            header: ({ column }) => (
                <TooltipProvider>
                    <Tooltip>
                        <TooltipTrigger asChild>
                            <Button
                                variant="ghost"
                                onClick={() => column.toggleSorting(column.getIsSorted() === 'asc')}
                                className="px-3 py-2 text-left text-xs font-medium text-slate-600 hover:text-slate-800 w-full justify-between"
                            >
                                <span className="truncate">
                                    {key.replace(/_/g, ' ').toUpperCase()}
                                </span>
                                <ArrowUpDown className="ml-1 h-3.5 w-3.5 opacity-50" />
                            </Button>
                        </TooltipTrigger>
                        <TooltipContent>
                            <p>{key.replace(/_/g, ' ').toUpperCase()}</p>
                        </TooltipContent>
                    </Tooltip>
                </TooltipProvider>
            ),
            cell: ({ row }) => {
                const value = row.getValue(key);
                return (
                    <TooltipProvider>
                        <Tooltip>
                            <TooltipTrigger asChild>
                                <div className="px-3 py-2.5 text-sm text-slate-700 font-normal">
                                    {typeof value === 'string' && value.startsWith('http') ? (
                                        <div className="max-w-[150px] truncate">
                                            <a
                                                href={value as string}
                                                target="_blank"
                                                rel="noopener noreferrer"
                                                className="text-blue-600 hover:text-blue-800 hover:underline"
                                            >
                                                {value as string}
                                            </a>
                                        </div>
                                    ) : (
                                        <div className="max-w-[150px] truncate">{value}</div>
                                    )}
                                </div>
                            </TooltipTrigger>
                            <TooltipContent>
                                <p>{value as string}</p>
                            </TooltipContent>
                        </Tooltip>
                    </TooltipProvider>
                );
            }
        }));
    }, [queryData]);

    const table = useReactTable({
        data: queryData || [],
        columns: columns as ColumnDef<QueryData>[],
        onSortingChange: setSorting,
        onColumnFiltersChange: setColumnFilters,
        getCoreRowModel: getCoreRowModel(),
        getPaginationRowModel: getPaginationRowModel(),
        getSortedRowModel: getSortedRowModel(),
        getFilteredRowModel: getFilteredRowModel(),
        onColumnVisibilityChange: setColumnVisibility,
        state: {
            sorting,
            columnFilters,
            columnVisibility
        },
        initialState: {
            pagination: {
                pageSize: 10
            }
        }
    });

    // Calculate dynamic height based on number of rows
    const rowCount = table.getRowModel().rows?.length || 0;
    const emptyTable = rowCount === 0;

    // Calculate column width based on number of columns
    const columnCount = columns.length || 1;
    const columnWidth = `${Math.max(100 / columnCount, 120)}px`;

    return (
        <div className="mt-6 w-full">
            <div
                className="rounded-lg border border-slate-200 bg-white w-full shadow-sm flex flex-col"
                style={{ maxHeight: '500px' }}
            >
                {/* Fixed Header */}
                <div className="sticky top-0 z-10">
                    <table className="w-full border-collapse table-fixed">
                        <thead className="bg-slate-50 border-b border-slate-200">
                            {table.getHeaderGroups().map((headerGroup) => (
                                <tr key={headerGroup.id}>
                                    {headerGroup.headers.map((header) => (
                                        <th
                                            key={header.id}
                                            className="h-11 text-left align-middle font-medium text-slate-500 px-0"
                                            style={{ width: columnWidth }}
                                        >
                                            {header.isPlaceholder
                                                ? null
                                                : flexRender(
                                                      header.column.columnDef.header,
                                                      header.getContext()
                                                  )}
                                        </th>
                                    ))}
                                </tr>
                            ))}
                        </thead>
                    </table>
                </div>

                {/* Scrollable Table Body */}
                <div className="overflow-y-auto overflow-x-auto flex-grow">
                    <table className="w-full border-collapse table-fixed">
                        <tbody>
                            {table.getRowModel().rows?.length ? (
                                table.getRowModel().rows.map((row, i) => (
                                    <tr
                                        key={row.id}
                                        className={`
                                            border-b border-slate-100 
                                            ${i % 2 === 0 ? 'bg-white' : 'bg-slate-50/50'}
                                            hover:bg-slate-100 transition-colors
                                        `}
                                    >
                                        {row.getVisibleCells().map((cell) => (
                                            <td
                                                key={cell.id}
                                                className="p-0"
                                                style={{ width: columnWidth }}
                                            >
                                                {flexRender(
                                                    cell.column.columnDef.cell,
                                                    cell.getContext()
                                                )}
                                            </td>
                                        ))}
                                    </tr>
                                ))
                            ) : (
                                <tr>
                                    <td
                                        colSpan={columns.length}
                                        className="h-24 text-center text-slate-500"
                                    >
                                        No results found.
                                    </td>
                                </tr>
                            )}
                        </tbody>
                    </table>
                </div>

                {/* Fixed Pagination Controls */}
                <div className="border-t border-slate-200 bg-white flex-shrink-0 sticky bottom-0 z-10">
                    <div className="flex items-center justify-between py-3 px-4">
                        <div className="text-sm text-slate-500 font-medium">
                            {totalRecords
                                ? `Showing ${Math.min(rowCount, 10)} of ${totalRecords} records`
                                : rowCount > 0
                                  ? `Showing ${rowCount} records`
                                  : ''}
                        </div>
                        <div className="flex space-x-2">
                            <Button
                                variant="outline"
                                size="sm"
                                onClick={() => table.previousPage()}
                                disabled={!table.getCanPreviousPage()}
                                className="text-xs h-8 px-3 rounded-md border-slate-200 text-slate-600 hover:bg-slate-50"
                            >
                                Previous
                            </Button>
                            <Button
                                variant="outline"
                                size="sm"
                                onClick={() => table.nextPage()}
                                disabled={!table.getCanNextPage()}
                                className="text-xs h-8 px-3 rounded-md border-slate-200 text-slate-600 hover:bg-slate-50"
                            >
                                Next
                            </Button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}
