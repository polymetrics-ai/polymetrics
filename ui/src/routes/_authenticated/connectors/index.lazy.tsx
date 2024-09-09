import { createLazyFileRoute } from '@tanstack/react-router';
import { Button } from '@/components/ui/button';

export const Route = createLazyFileRoute('/_authenticated/connectors/')({
    component: Connectors
});

export function Connectors() {

    return (
        <main className="flex-1 flex flex-col my-8 mr-8 px-10 py-8 bg-slate-100">
            <div className="flex justify-between h-8.5">
                <span className="self-start text-2xl font-semibold">Connectors</span>
                <Button className="self-end gap-2" onClick={() => console.log('dashbaord')}>
                    <img className="" src="/icon-plus.svg" />
                    Add Connectors
                </Button>
            </div>
            <div className="flex-1 h-full flex items-center justify-center">
                <div className="flex flex-col items-center"></div>
            </div>
        </main>
    );
}
