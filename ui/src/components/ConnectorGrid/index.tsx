import React from 'react';
import Loader from '../Loader';
import { ConnectorCard } from '../Card';
import { useDefinitionQuery } from '@/hooks/useConnectorDefinitions'

export interface ActiveConnectorState {
    connector_class_name: string;
    icon_url: string;
}

export interface ConnectorGridProps {
    active?: ActiveConnectorState;
    setActive?: React.Dispatch<React.SetStateAction<ActiveConnectorState>>;
    handleOnClickGrid?: () => void;
}

const ConnectorGrid: React.FC<ConnectorGridProps> = ({ active, setActive }) => {
    
    /* Load the definitions for the Grid to be rendered */
    let {data, error, isLoading } = useDefinitionQuery();
    const definitons = data?.data
    
    const handleOnSelection = (grid: ActiveConnectorState) => {
        if (setActive) {
            setActive(grid);
        }
    };
    
    if (isLoading) return <Loader/>;
    if (error) return <>Error:{error.message}</>;

    return (
        <div className="overflow-y-auto px-10">
            <div className="grid grid-flow-row grid-cols-4 gap-3 text-base font-medium tracking-normal text-slate-800 h-full flex-grow">
                {definitons.map((def: any) => (
                    <ConnectorCard
                        key={def.name}
                        definition={def}
                        isActive={  
                            active?.connector_class_name?.toLocaleLowerCase() ===
                            def.name.toLocaleLowerCase()
                        }
                        handleOnSelection={() =>
                            handleOnSelection({
                                connector_class_name: def.name.toLowerCase(),
                                icon_url: def.icon
                            })
                        }
                    />
                ))}
            </div>
        </div>
    );
};

export default ConnectorGrid;
