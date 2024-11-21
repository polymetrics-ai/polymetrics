import { useState, useRef } from 'react';
import { useMutation , useQueryClient } from '@tanstack/react-query';
import { z } from 'zod';
import { zodResolver } from '@hookform/resolvers/zod';
import { createLazyFileRoute, useNavigate, useParams, useRouterState } from '@tanstack/react-router';
import { useForm } from 'react-hook-form';
import { ContactCard } from '@/components/Card';
import SearchBar from '@/components/Search';
import ConnectorGrid, { ActiveConnectorState } from '@/components/ConnectorGrid';
import { Button } from '@/components/ui';
import Loader from '@/components/Loader';
import ConnectorForm, { ConnectorFormRef } from '@/components/ConnectorForm';
import VerticalStepper from '@/components/VerticalStepper';
import { connectorSteps } from '@/constants/constants';
import { ConnectorSchema } from '@/lib/schema';
import { defineStepper } from '@stepperize/react';
import { putConnector } from '@/service';
import { postConnectorPayload } from '@/types/payload';

export const Route = createLazyFileRoute('/_authenticated/connectors/$id')({
    component: EditConnector
});

const { useStepper } = defineStepper(...connectorSteps);

function EditConnector() {
   
    // State Variables
    const connectorState = useRouterState({select: s=>s.location.state});
    const [active, setActive] = useState<ActiveConnectorState>({ connector_class_name : connectorState?.connector_class_name, icon_url: connectorState?.icon_url });
    const formRef = useRef<ConnectorFormRef>(null);
    const [isLoading, setIsLoading] = useState<boolean>(false);

    // Hook Functions
    const id = useParams({
        from: '/_authenticated/connectors/$id',
        select: (params) => params.id,
    });
    const stepper = useStepper();
    const navigate = useNavigate();

    const queryClient = useQueryClient();
    
    const mutation = useMutation({
        mutationFn: async (payload: {id: string, data: postConnectorPayload}) => {
            const {id , data} = payload;
            const response = await putConnector(id, data);
            return response;
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['connectors'] , refetchType: 'active'});

            navigate({ to: '/connectors', replace: true, state: {showToast : true , message: 'Connector Successfully Updated'} });
        }
    });

    const form = useForm<z.infer<typeof ConnectorSchema>>({
        resolver: zodResolver(ConnectorSchema),
        defaultValues: {
            name:  connectorState?.name || '',
            description: connectorState?.description || '',
            personal_access_token: connectorState?.configuration?.personal_access_token || '',
            repository: connectorState?.configuration?.repository || '',
        }
    });

    const {
        formState: { isValid }
    } = form;

    const handleSubmit = (data: z.infer<typeof ConnectorSchema>) => {
        const { name, description, repository, personal_access_token } = data;
        const payload = {
            connector: {
                configuration: {
                    repository,
                    personal_access_token
                },
                name,
                description,
                connector_class_name: active?.connector_class_name,
                connector_language: 'ruby'
            }
        };
        mutation.mutate({ id, data: payload });
    };

    const onPrev = () => {
        stepper.prev();
    };

    const onNext = () => {
        if (!stepper.isLast) {
            stepper.next();
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
                                    Edit Connectors
                                </div>
                            </div>
                        </div>
                        <div className="flex gap-4" />
                    </div>
                    {stepper.current.id === 'select-connector' ? (
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
                            {isLoading ? (
                                <Loader />
                            ) : (
                                <ConnectorGrid active={active} setActive={setActive} />
                            )}
                        </div>
                    ) : (
                        <div className="flex flex-col my-8 overflow-hidden flex-grow">
                            {isLoading ? (
                                <Loader />
                            ) : (
                                <ConnectorForm form={form} ref={formRef} onSubmit={handleSubmit} connectorData={connectorState} isEditMode={true} />
                            )}
                        </div>
                    )}
                    <div className="flex h-20 py-5 px-10 justify-between w-full text-sm font-medium tracking-normal border-t border-solid border-b-slate-200 text-slate-400">
                        <Button
                            variant={'outline'}
                            className={`${stepper.current.index === 0 ? 'hidden' : 'border-emerald-600 hover:bg-white hover:text-emerald-600 text-emerald-600'}`}
                            onClick={onPrev}
                        >
                            Back
                        </Button>
                        <Button
                            className="ml-auto"
                            onClick={onNext}
                            disabled={stepper.isLast && !isValid}
                        >
                            {`${stepper.isLast ? 'Connect' : 'Next'}`}
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
                            <VerticalStepper stepper={stepper} />
                            <ContactCard />
                        </div>
                    </div>
                </div>
            </div>
        </main>
    );
}
