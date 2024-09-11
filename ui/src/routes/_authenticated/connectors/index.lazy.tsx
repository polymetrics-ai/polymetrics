import { createLazyFileRoute, useNavigate } from '@tanstack/react-router';
import { Button } from '@/components/ui/button';
import { DataTable } from '@/components/DataTable';

export const Route = createLazyFileRoute('/_authenticated/connectors/')({
    component: Connectors
});

export function Connectors() {
    const navigate = useNavigate();
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
                <DataTable data={[]} columns={[]} />
            </div>
        </main>
    );
}
