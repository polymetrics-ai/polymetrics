import React from 'react';
import { ConnectorCard } from '../Card';
import { CONNECTORS_LIST } from '@/constants/constants';

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
    
    const handleOnSelection = (grid: ActiveConnectorState) => {
        if (setActive) {
            setActive(grid);
        }
    };
    const connectors = CONNECTORS_LIST;
    return (
        <div className="overflow-y-auto px-10">
            <div className="grid grid-flow-row grid-cols-4 gap-3 text-base font-medium tracking-normal text-slate-800 h-full flex-grow">
                {connectors.map((item) => (
                    <ConnectorCard
                        key={item.name}
                        name={item.name}
                        icon={item.icon}
                        isActive={active?.connector_class_name?.toLocaleLowerCase() === item.name.toLocaleLowerCase()}
                        handleOnSelection={() => handleOnSelection({ 
                            connector_class_name: item.name.toLowerCase(),
                            icon_url: item.icon 
                        })}
                    />
                ))}
            </div>
        </div>
    );
};

export default ConnectorGrid;
