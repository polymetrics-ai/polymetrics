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

const DataTable: React.FC<DataTableProps> = ({ list }) => {
    console.log({list});
    const {data} = list;
    // const table = useReactTable({
    //     data,
    //     columns,
    //     getCoreRowModel: function (table: Table<any>): () => RowModel<any> {
    //         throw new Error('Function not implemented.');
    //     }
    // });

    // Use the 'table' variable to render the table
    return (
        <Table>
            <TableHeader className="[&_tr]:border-b-0">
                <TableRow className="space-x-3">
                    <TableHead className="text-slate-400">STATUS</TableHead>
                    <TableHead>NAME</TableHead>
                    <TableHead>CONNECTOR</TableHead>
                    <TableHead className="">LAST UPDATED</TableHead>
                </TableRow>
            </TableHeader>
            <TableBody>
            {data && data.map((item)=>(
                <TableRow key={item.id}>
                <TableCell className="font-medium pl-5">
                    <Status isConnected={item.connected} />
                </TableCell>
                <TableCell>{item.name}</TableCell>
                <TableCell>
                    <ConnectorType className="" icon={item.icon_url} name={item.connector_class_name} />
                </TableCell>
                <TableCell className="">
                   {getTimeStamp(item.updated_at)}
                </TableCell>
            </TableRow>
            ))}
                
            </TableBody>
        </Table>
    );
};
export default DataTable;
