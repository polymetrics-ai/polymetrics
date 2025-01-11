import React from 'react';
import Loader from '../Loader';
import { ConnectorCard } from '../Card';
import { Definition, useDefinitionQuery } from '@/hooks/useConnectorDefinitions'

export interface ActiveConnectorState {
    connector_class_name: string;
    icon_url: string;
}

export interface ConnectorGridProps {
    active?: ActiveConnectorState;
    setActive?: React.Dispatch<React.SetStateAction<ActiveConnectorState>>;
    onSelect?: (definition: Definition) => void;
}

const ConnectorGrid: React.FC<ConnectorGridProps> = ({ active, setActive, onSelect }) => {
    const {data: definitions, error, isLoading} = useDefinitionQuery();
    
    const handleOnSelection = (definition: Definition) => {
        if (setActive) {
            setActive({
                connector_class_name: definition.name.toLowerCase(),
                icon_url: definition.icon_url
            });
        }
        if (onSelect) {
            onSelect(definition);
        }
    };
    
    if (isLoading) return <Loader/>;
    if (error) return <>Error:{error.message}</>;
    if (!definitions) return <>No connectors found</>;

    return (
        <div className="overflow-y-auto px-10">
            <div className="grid grid-flow-row grid-cols-4 gap-3 text-base font-medium tracking-normal text-slate-800 h-full flex-grow">
                {definitions.map((def: Definition) => (
                    <ConnectorCard
                        key={def.name}
                        definition={def}
                        isActive={active?.connector_class_name?.toLocaleLowerCase() === def.name.toLocaleLowerCase()}
                        handleOnSelection={() => handleOnSelection(def)}
                    />
                ))}
            </div>
        </div>
    );
};

export default ConnectorGrid;