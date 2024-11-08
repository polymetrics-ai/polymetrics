import { useMemo } from 'react';
import { createLazyFileRoute, useNavigate } from '@tanstack/react-router';
import { useQuery } from '@tanstack/react-query';
import { Button } from '@/components/ui/button';
import { Table } from '@/components/Table';
import Status from '@/components/Status';
import Loader from '@/components/Loader';
import ConnectorType from '@/components/ConnectorType';
import { getConnectorList } from '@/service';
import { getTimeStamp } from '@/lib/date-helper';

export const Route = createLazyFileRoute('/_authenticated/connectors/')({
    component: Connectors
});

export function Connectors() {
    const navigate = useNavigate();

    const getConnectors = useQuery({
        queryKey: ['connectors'],
        queryFn: getConnectorList
    });

    const list = getConnectors?.data?.data || [];

    const columns = useMemo(
        () => [
            {
                header: 'STATUS',
                accessorKey: 'connected',
                cell: (row: { getValue: () => boolean }) => (<Status isConnected={row.getValue()}/>)
            },
            {
                header: 'NAME',
                accessorKey: 'name',
                // accessorFn: (row) => row.name,
            },
            {
                header: 'CONNECTOR',
                accessorKey: 'connector_class_name',
                cell: (row) => (<ConnectorType icon={row.icon_url} name={row.getValue()}></ConnectorType>)
            },
            {
                header: 'LAST UPDATED',
                accessorKey: 'updated_at',
                cell: (row) => getTimeStamp(row.getValue().toString())
            }
        ],
        []
    );

    return (
        <main className="flex-1 flex flex-col my-8 mr-8 px-10 py-8 bg-slate-100">
            <div className="flex justify-between h-8.5">
                <span className="self-start text-2xl text-slate-800 font-semibold">Connectors</span>
                <Button
                    className="self-end gap-2"
                    onClick={() => navigate({ to: '/connectors/add-connector' })}
                >
                    <img className="" src="/icon-plus.svg" />
                    Add Connectors
                </Button>
            </div>
            <div className="flex-1 h-full flex items-start mt-10 justify-center">
                {getConnectors.isLoading ? <Loader /> : <Table data={list} columns={columns} />}
            </div>
        </main>
    );
}
