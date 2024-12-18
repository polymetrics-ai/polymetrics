import { useEffect, useMemo } from 'react';
import { createLazyFileRoute, useNavigate, useRouterState } from '@tanstack/react-router';
import { useQuery } from '@tanstack/react-query';
import { Button } from '@/components/ui/button';
import { Table } from '@/components/Table';
import Status from '@/components/Status';
import Loader from '@/components/Loader';
import ConnectorType from '@/components/ConnectorType';
import { getConnectors } from '@/service';
import { getTimeStamp } from '@/lib/date-helper';
import { useToast } from '@/hooks/useToast';
import { Toaster } from '@/components/ui';

// Define the expected response type
interface ConnectorResponse {
    data: unknown; // Adjust the type as necessary
}

export const Route = createLazyFileRoute('/_authenticated/connectors/')({
    component: Connectors
});

export function Connectors() {
    const { toast } = useToast();
    const navigate = useNavigate();

    const state = useRouterState({ select: (s) => s.location.state });

    const { data: { data } = { data: [] }, isLoading } = useQuery<ConnectorResponse>({
        queryKey: ['connectors'],
        queryFn: getConnectors
    });


    useEffect(() => {
        if (state.showToast) {
            toast({
                title: '',
                description: state?.message
                // action: (
                //     <ToastAction altText="Goto schedule to undo">Undo</ToastAction>
                // ),
            });
        }
    }, [state]);

    const columns = useMemo(
        () => [
            {
                header: 'STATUS',
                accessorKey: 'connected',
                cell: (row: { getValue: () => boolean }) => <Status isConnected={row.getValue()} />
            },
            {
                header: 'NAME',
                accessorKey: 'name'
            },
            {
                header: 'CONNECTOR',
                accessorKey: 'connector_class_name',
                cell: (row: { getValue: () => string; icon_url: string }) => (
                    <ConnectorType icon={row.icon_url} name={row.getValue()}></ConnectorType>
                )
            },
            {
                header: 'LAST UPDATED',
                accessorKey: 'updated_at',
                cell: (row: { getValue: () => string }) => getTimeStamp(row.getValue().toString())
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
                    onClick={() => navigate({ to: '/connectors/new' })}
                >
                    <img className="" src="/icon-plus.svg" />
                    Add Connectors
                </Button>
            </div>
            <div className="flex-1 h-full flex items-start mt-10 justify-center">
                {isLoading ? <Loader /> : <Table data={data} columns={columns} />}
                <Toaster />
            </div>
        </main>
    );
}
