import { createFileRoute } from '@tanstack/react-router';
import  ConnectorCard from '@/components/ConnectorCard';
import { CONNECTORS_LIST } from '@/constants/constants';

export const Route = createFileRoute('/_authenticated/connectors/add-connector/')({
    component: AddConnector
});

function AddConnector() {
    const connectors = CONNECTORS_LIST;
    return (
        <main className="grid grid-cols-5 my-8 mr-8 bg-slate-100">
            <div className="col-span-4 overflow-hidden">
                <div className="flex flex-col rounded bg-slate-100">
                    <div className="flex flex-wrap gap-10 py-5 px-10 w-full text-sm font-medium tracking-normal rounded border-b border-solid border-b-slate-200 text-slate-400">
                        <div className="flex gap-2 items-center">
                            <img
                                loading="lazy"
                                src="https://cdn.builder.io/api/v1/image/assets/TEMP/bd0c97c745cbbb04ffeee09cee4d7da48101c69bf6fb8643645400c2d7840c14?placeholderIfAbsent=true&apiKey=698d28bd40454379b0c73734472477dd"
                                className="object-contain shrink-0 w-7 aspect-square"
                            />
                            <div className="flex gap-2 items-center">
                                <div className="">Connectors</div>
                                <div className="">/</div>
                                <div className=" text-base font-semibold tracking-normal text-slate-800">
                                    Add Connector
                                </div>
                            </div>
                        </div>
                        <div className="flex gap-4"/>
                    </div>
                    <div className="flex flex-col mx-10 mt-8">
                        <div className="flex flex-col">
                            <div className="text-xl font-semibold tracking-tight leading-none text-slate-800">
                                Choose a new connector
                            </div>
                            <div className="flex flex-wrap gap-2 items-center px-3 py-2 mt-4 text-sm tracking-normal leading-none border border-solid bg-slate-100 border-slate-300 text-slate-400 max-md:max">
                                <img
                                    loading="lazy"
                                    src="https://cdn.builder.io/api/v1/image/assets/TEMP/be2561a109d1565b2f6dc40f77612947ad4c1a4e5a1f59e43768da82f8329a0d?placeholderIfAbsent=true&apiKey=698d28bd40454379b0c73734472477dd"
                                    className="object-contain shrink-0 self-stretch my-auto w-4 aspect-square"
                                />
                                <div className="self-stretch my-auto">Search for connectors</div>
                            </div>
                            <div className="grid grid-flow-row grid-cols-3 gap-4 mt-8 text-base font-medium tracking-normal text-slate-800 max-h-[calc(100vh-200px)] overflow-y-auto">
                            {connectors.map((item, key) => (
                                <ConnectorCard key={key} name={item.name} icon={item.icon}/>
                            ))}
                        </div>
                        </div>
                        
                    </div>
                </div>
            </div>
            <div className="col-span-1 overflow-hidden">
                <div className="flex flex-col justify-between px-8 pt-14 pb-8 mx-auto w-full bg-white max-w-[480px]">
                    <div className="flex flex-col w-full">
                        <div className="self-start text-xs font-medium tracking-normal text-center text-slate-400">
                            STEPS TO COMPLETE
                        </div>
                        <div className="flex relative flex-col mt-5 w-full">
                            <div className="absolute left-4 top-5 z-0 w-0 border-2 border-dashed bg-slate-300 border-slate-300 h-[85px] min-h-[85px]" />
                            <div className="flex overflow-hidden z-0 gap-2 items-start w-full">
                                <div className="flex overflow-hidden flex-col justify-center p-0.5 w-8 text-xs font-semibold tracking-normal text-emerald-600 whitespace-nowrap">
                                    <div className="px-3 pt-1.5 pb-4 w-7 h-7 bg-white rounded-full border-2 border-emerald-600 border-solid fill-white stroke-[1.5px] stroke-emerald-600">
                                        1
                                    </div>
                                </div>
                                <div className="flex flex-col flex-1 shrink basis-0">
                                    <div className="text-base font-medium tracking-normal text-slate-800">
                                        Choose connector
                                    </div>
                                    <div className="text-sm tracking-normal leading-5 text-slate-400">
                                        Lorem ispsum something about connectors
                                    </div>
                                </div>
                            </div>
                            <div className="flex overflow-hidden z-0 gap-2 items-start mt-6 w-full">
                                <div className="flex overflow-hidden flex-col justify-center p-0.5 w-8 text-xs font-semibold tracking-normal whitespace-nowrap text-slate-400">
                                    <div className="px-2.5 pt-1.5 pb-3.5 w-7 h-7 bg-white rounded-full border-2 border-solid border-slate-200 fill-white stroke-[1.5px] stroke-slate-200">
                                        2
                                    </div>
                                </div>
                                <div className="flex flex-col flex-1 shrink basis-0">
                                    <div className="text-base font-medium tracking-normal text-slate-800">
                                        Configure connector
                                    </div>
                                    <div className="text-sm tracking-normal leading-5 text-slate-400">
                                        Lorem ispsum something about configuring connectors
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div className="flex overflow-hidden flex-col px-4 pt-4 pb-3 w-full bg-emerald-50 rounded-sm border border-emerald-200 border-solid mt-[464px]">
                        <div className="flex gap-4 items-start w-full">
                            <img
                                loading="lazy"
                                src="https://cdn.builder.io/api/v1/image/assets/TEMP/bae6df7d4fb58ee33e6394f0114576898aa5b0a119459cc047aa876c3865c71c?placeholderIfAbsent=true&apiKey=698d28bd40454379b0c73734472477dd"
                                className="object-contain shrink-0 w-14 aspect-square"
                            />
                            <div className="flex flex-col flex-1 shrink basis-0">
                                <div className="text-base font-medium tracking-normal text-slate-800">
                                    Contact Support
                                </div>
                                <div className="text-sm tracking-normal leading-5 text-slate-500">
                                    We’re here to help! Chat with us if you have any questions.
                                </div>
                            </div>
                        </div>
                        <div className="flex gap-0.5 items-center pr-16 pl-20 mt-1 w-full text-sm font-semibold tracking-normal leading-none text-emerald-500">
                            <div className="gap-2.5 self-stretch py-2 my-auto rounded-md bg-white bg-opacity-0">
                                Chat with us
                            </div>
                            <img
                                loading="lazy"
                                src="https://cdn.builder.io/api/v1/image/assets/TEMP/cfb49d3e6a1808bf21e101ab7c0f23d51b11f3604f1bad360927bd0906c83d19?placeholderIfAbsent=true&apiKey=698d28bd40454379b0c73734472477dd"
                                className="object-contain shrink-0 self-stretch my-auto w-3.5 aspect-square"
                            />
                        </div>
                    </div>
                </div>
            </div>
        </main>
    );
}
