import { useRef } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
    createLazyFileRoute,
    useParams,
    useRouterState
} from '@tanstack/react-router';
import Loader from '@/components/Loader';
import ConnectorForm, { ConnectorFormRef } from '@/components/ConnectorForm';
import { getConnector } from '@/service';
import { Connector } from '@/types/connector';
import { useDefinitionQuery } from '@/hooks/useConnectorDefinitions';

export const Route = createLazyFileRoute('/_authenticated/connectors/$id')({
    component: EditConnector
});

function EditConnector() {
    const connectorState = useRouterState({ select: (s) => s.location.state });
    const formRef = useRef<ConnectorFormRef>(null);
    const id = useParams({
        from: '/_authenticated/connectors/$id',
        select: (params) => params.id
    });

    const { data: connector, isLoading: isConnectorLoading } = useQuery<Connector>({
        queryKey: ['connector', id],
        queryFn: () => getConnector(id),
        enabled: !connectorState // Only fetch if we don't have state
    });

    const { data: definitions, isLoading: isDefinitionLoading } = useDefinitionQuery();
    const connectorData = connectorState || connector;
    
    const selectedDefinition = definitions?.find(
        def => def.class_name.toLowerCase() === connectorData?.connector_class_name?.toLowerCase()
    );

    if (isDefinitionLoading || isConnectorLoading) {
        return <Loader />;
    }

    if (!connectorData || !selectedDefinition) {
        return (
            <div className="flex flex-col items-center justify-center p-8">
                <p className="text-slate-600">
                    Connector not found or configuration unavailable.
                </p>
            </div>
        );
    }

    return (
        <main className="flex-1 flex flex-col my-8 mr-8 bg-slate-100">
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
                        <div className="text-base font-semibold tracking-normal text-slate-800">
                            View Connector
                        </div>
                    </div>
                </div>
            </div>
            <div className="flex-1 flex flex-col my-8 px-10">
                <ConnectorForm
                    ref={formRef}
                    onSubmit={() => {}}
                    connectorData={connectorData}
                    definition={selectedDefinition}
                    readOnly={true}
                />
            </div>
        </main>
    );
}
