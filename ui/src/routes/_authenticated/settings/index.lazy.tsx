import { createLazyFileRoute } from '@tanstack/react-router';
import { Separator } from '@/components/ui';
import { Button } from '@/components/ui/button';

export const Route = createLazyFileRoute('/_authenticated/settings/')({
    component: Settings
});

export function Settings() {
    return (
        <main className="flex-1 flex flex-col my-8 mr-8 px-10 py-8 bg-slate-100">
            <div className="flex justify-between h-8.5">
                <span className="self-start text-2xl text-slate-800 font-semibold">Settings</span>
                {/* <Button className="self-end gap-2 hidden" onClick={() => console.log('dashbaord')}>
                    <img className="" src="/icon-plus.svg" />
                    Add Dashboard
                </Button> */}
            </div>
            <div className="flex-1 h-full flex items-center justify-center">
                <div className="flex flex-col items-center">
                    <Button className="h-20 w-20 p-0 shadow-none bg-transparent hover:bg-transparent ring-0 focus:ring-0">
                        <img className="h-full w-full" src="/dashboard.svg" />
                    </Button>
                    <Separator className="my-2" />
                    <span className="text-base text-slate-400">Coming Soon</span>
                </div>
            </div>
        </main>
    );
}
