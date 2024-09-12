import React from 'react';
import { ConnectorCard } from '../Card';
import { CONNECTORS_LIST } from '@/constants/constants';

export interface ConnectorGridProps {
    list: Array<object>
}

const ConnectorGrid: React.FC<ConnectorGridProps> = ({list}) => {
    console.log(list)
    const connectors = CONNECTORS_LIST;
    return (
        <div className="overflow-y-auto px-10">
            <div className="grid grid-flow-row grid-cols-4 gap-3 text-base font-medium tracking-normal text-slate-800 h-full flex-grow">
                {connectors.map((item, key) => (
                    <ConnectorCard key={key} name={item.name} icon={item.icon} />
                ))}
            </div>
        </div>
    );
};

export default ConnectorGrid;
