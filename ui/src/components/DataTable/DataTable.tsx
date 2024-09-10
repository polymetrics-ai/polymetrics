import React from 'react';
import { RowModel, useReactTable } from '@tanstack/react-table';
import { DataTableProps } from '@/types/datatable';
import Status from '../Status';
import ConnectorType from '@/components/ConnectorType';
import {
    Table,
    TableBody,
    TableCaption,
    TableCell,
    TableHead,
    TableHeader,
    TableRow
} from '@/components/ui/table';
import { getTimeStamp } from '@/lib/date-helper';



const DataTable: React.FC<DataTableProps> = ({ data, columns }) => {
    const table = useReactTable({
        data,
        columns,
        getCoreRowModel: function (table: Table<any>): () => RowModel<any> {
            throw new Error('Function not implemented.');
        }
    });

    // Use the 'table' variable to render the table
    return (
        <Table>
            <TableHeader className="[&_tr]:border-b-0">
                <TableRow className="space-x-3">
                    <TableHead className="text-slate-400">STATUS</TableHead>
                    <TableHead>NAME</TableHead>
                    <TableHead>CONNECTOR</TableHead>
                    <TableHead className="">DESTINATION</TableHead>
                </TableRow>
            </TableHeader>
            <TableBody>
                <TableRow>
                    <TableCell className="font-medium pl-5">
                        <Status isConnected={true} />
                    </TableCell>
                    <TableCell>Default Analytics DB</TableCell>
                    <TableCell>
                        <ConnectorType className="" icon={''} name={'Linkedin'} />
                    </TableCell>
                    <TableCell className="">
                        <ConnectorType
                            className=""
                            icon={
                                'https://raw.githubusercontent.com/polymetrics-ai/polymetrics/main/public/connector_icons/duckdb.svg'
                            }
                            name={'Duck DB'}
                        />
                    </TableCell>
                </TableRow>
            </TableBody>
        </Table>
    );
};
export default DataTable;
