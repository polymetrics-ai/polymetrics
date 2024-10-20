import { useState, useRef } from 'react';
import { z } from 'zod';
import { createFileRoute } from '@tanstack/react-router';
import { ContactCard } from '@/components/Card';
import SearchBar from '@/components/Search';
import ConnectorGrid from '@/components/ConnectorGrid';
import { Button } from '@/components/ui';
import Loader from '@/components/Loader';
import ConnectorForm, { ConnectorFormRef } from '@/components/ConnectorForm';
import VerticalStepper from '@/components/VerticalStepper';
import { ConnectorSchema } from '@/lib/schema';

export const Route = createFileRoute('/_authenticated/connectors/add-connector/')({
    component: AddConnector
});

function AddConnector() {
    const formRef = useRef<ConnectorFormRef>(null);
    const [steps, setSteps] = useState<number>(0);
    const [isLoading, setIsLoading] = useState<boolean>(false);

    const handleSubmit = (data: z.infer<typeof ConnectorSchema>) => {
        console.log('data', data);
        const { name, description, repository, personal_access_token } = data;
        const payload = {
            connector: {
                configuration: {
                    repository,
                    personal_access_token
                },
                name,
                description,
                connector_class_name: name.toLowerCase(),
                connector_language: 'ruby'
            }
        };
    };

    const onPrev = () => {
        setSteps((prev) => prev - 1);
    };
    const onNext = () => {
        if (steps === 0) {
            setSteps((prev) => prev + 1);
        } else {
            formRef.current?.submitForm();
        }
    };

    return (
        <main className="grid grid-cols-4 my-8 mr-8 bg-slate-100">
            <div className="col-span-3 overflow-hidden flex-grow">
                <div className="flex flex-1 flex-col bg-slate-100 h-full">
                    <div className="flex h-19 flex-wrap gap-10 py-5 px-10 w-full text-sm font-medium tracking-normal rounded border-b border-solid border-b-slate-200 text-slate-400">
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
                        <div className="flex gap-4" />
                    </div>
                    {steps === 0 ? (
                        <div className="flex flex-col my-8 overflow-hidden flex-grow">
                            <div className="mx-10 text-xl font-semibold tracking-tight leading-none text-slate-800">
                                Choose a new connector
                            </div>
                            <div className="mx-10 mt-4 mb-8 cursor-pointer bg-white border-slate-300">
                                <SearchBar
                                    placeholder="Search for Connectors"
                                    onSearch={() => console.log('Searching')}
                                />
                            </div>
                            {isLoading ? <Loader /> : <ConnectorGrid />}
                        </div>
                    ) : (
                        <div className="flex flex-col my-8 overflow-hidden flex-grow">
                            {isLoading ? (
                                <Loader />
                            ) : (
                                <ConnectorForm ref={formRef} onSubmit={handleSubmit} />
                            )}
                        </div>
                    )}
                    <div className="flex h-20 py-5 px-10 justify-between w-full text-sm font-medium tracking-normal border-t border-solid border-b-slate-200 text-slate-400">
                        <Button
                            className={`${steps === 0 ? 'hidden' : ''}`}
                            onClick={() => onPrev()}
                        >
                            Back
                        </Button>
                        <Button className="ml-auto" onClick={() => onNext()}>
                            Next
                        </Button>
                    </div>
                </div>
            </div>
            <div className="col-span-1 gap-0 w-full overflow-hidden">
                <div className="flex flex-col pl-8 pt-8 h-full bg-white max-w-[24rem]">
                    <div className="flex flex-col h-full">
                        <div className="self-start text-xs font-medium tracking-normal text-center text-slate-400">
                            STEPS TO COMPLETE
                        </div>
                        <div className="flex flex-col justify-between flex-wrap mt-5 h-full">
                            <VerticalStepper />
                            <ContactCard />
                        </div>
                    </div>
                </div>
            </div>
        </main>
    );
}
