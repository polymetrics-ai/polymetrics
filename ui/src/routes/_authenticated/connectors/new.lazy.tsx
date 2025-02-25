import { useState, useRef } from 'react';
import { z } from 'zod';
import { createLazyFileRoute, useNavigate } from '@tanstack/react-router';
import { useQuery } from '@tanstack/react-query';
import { zodResolver } from '@hookform/resolvers/zod';
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
import { Definition } from '@/hooks/useConnectorDefinitions';
import { postConnector } from '@/service/connectors';
import { useToast } from "@/hooks/useToast";

export const Route = createLazyFileRoute('/_authenticated/connectors/new')({
    component: AddConnector
});

const { useStepper } = defineStepper(...connectorSteps);

function AddConnector() {
    const formRef = useRef<ConnectorFormRef>(null);
    const [active, setActive] = useState<ActiveConnectorState>({
        connector_class_name: '',
        icon_url: ''
    });
    const [isLoading, setIsLoading] = useState<boolean>(false);
    const [selectedDefinition, setSelectedDefinition] = useState<Definition | null>(null);

    const stepper = useStepper();
    const navigate = useNavigate();
    const { toast } = useToast();

    const form = useForm<z.infer<typeof ConnectorSchema>>({
        resolver: zodResolver(ConnectorSchema),
        defaultValues: {
            name: '',
            description: '',
            personal_access_token: '',
            repository: ''
        },
        mode: 'onChange'
    });


    const handleConnectorSelection = (def: Definition) => {
        console.log('Connector selected:', def);
        setActive({
            connector_class_name: def.class_name,
            icon_url: def.icon_url
        });
        setSelectedDefinition(def);
        console.log('Calling stepper.next()');
        stepper.next();
        console.log('Current step:', stepper.current);
    };
    
    const handleFormSubmit = async (formData: any) => {
        try {
            const payload = {
                connector: {
                    ...formData,
                    configuration: {
                        ...formData
                    },
                    connector_class_name: selectedDefinition?.class_name,
                    connector_language: selectedDefinition?.language,
                    integration_type: selectedDefinition?.integration_type
                }
            };
            
            const response = await postConnector(payload);
            
            if (response.data.connected) {
                navigate({ 
                    to: '/connectors',
                    replace: true,
                    state: { showToast: true, message: "Connector created successfully", type: "success" }
                });
            } else {
                toast({
                    title: "Error",
                    description: response.data.error_message || "Failed to create connector",
                    variant: "destructive",
                });
            }
        } catch (error) {
            console.error('Error Payload:', error);
            toast({
                title: "Error",
                description: "Failed to create connector. Please try again.",
                variant: "destructive",
            });
        }
    };

    const onPrev = () => {
        stepper.prev();
    };

    const onNext = () => {
        if (!stepper.isLast) {
            stepper.next();
        } else {
            if (form.formState.isValid) {
                formRef.current?.submitForm();
                handleFormSubmit(form.getValues());
            }
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
                                <ConnectorGrid active={active} onSelect={handleConnectorSelection} />
                            )}
                        </div>
                    ) : (
                        <div className="flex flex-col my-8 overflow-y-auto flex-grow">
                            {isLoading ? (
                                <Loader />
                            ) : (
                                <ConnectorForm 
                                    ref={formRef}
                                    definition={selectedDefinition!} 
                                    onSubmit={handleFormSubmit}
                                />
                            )}
                        </div>
                    )}
                    <div className="flex h-20 py-5 px-10 justify-between w-full text-sm font-medium tracking-normal border-t border-solid border-b-slate-200 text-slate-400">
                        <Button
                            variant={'outline'}
                            className={`${
                                stepper.current.index === 0 
                                ? 'hidden' 
                                : 'bg-slate-100 border-emerald-600 hover:bg-slate-200 hover:text-emerald-600 text-emerald-600'
                            }`}
                            onClick={onPrev}
                        >
                            Back
                        </Button>
                        <div className="flex ml-auto">
                            {!stepper.isLast && (
                                <Button
                                    className="mr-2"
                                    onClick={onNext}
                                >
                                    Next
                                </Button>
                            )}
                            {stepper.isLast && (
                                <Button
                                    className="ml-auto"
                                    onClick={() => formRef.current?.submitForm()}
                                >
                                    Connect
                                </Button>
                            )}
                        </div>
                    </div>
                </div>
            </div>
            <div className="w-96 overflow-hidden">
                <div className="flex flex-col pl-8 pt-8 h-full bg-white">
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
