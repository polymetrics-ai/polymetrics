import { createLazyFileRoute, useNavigate } from '@tanstack/react-router';
import { useQuery } from '@tanstack/react-query';
import { Button } from '@/components/ui/button';
import { DataTable } from '@/components/DataTable';
import { getConnectorList } from '@/service';
import Loader from '@/components/Loader';

export const Route = createLazyFileRoute('/_authenticated/connectors/')({
    component: Connectors
});

export function Connectors() {

    const navigate = useNavigate();

    const getConnectors = useQuery({
        queryKey: ['connectors'],
        queryFn:  getConnectorList
    })

    if (getConnectors.isLoading)
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
        <div className="flex-1 h-full flex items-start justify-center">
            
        </div>
    </main>
    )

    const { data } = getConnectors?.data;
        
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
            <div className="flex-1 h-full flex items-start  justify-center">
                {/* <DataTable list={data} columns={[]} /> */}
                <Loader/>
            </div>
        </main>
    );
}
