import React from 'react';
import { getTitleCase } from '@/lib/helper';
import { DEFAULT_CONNECTOR_ICON } from '@/constants/constants';

export interface ConnectorTypeProps {
    className?: string;
    icon: string;
    name: string;
}

const ConnectorType: React.FC<ConnectorTypeProps> = ({ icon, name }) => {
    const handleImageError = (e: React.SyntheticEvent<HTMLImageElement>) => {
        e.currentTarget.src = DEFAULT_CONNECTOR_ICON;
    };

    return (
        <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-full bg-white border-1 border-slate-200">
                <img
                    className="w-4.5 h-4.5 p-2 shrink-0"
                    src={icon || DEFAULT_CONNECTOR_ICON}
                    alt={`${name} icon`}
                    onError={handleImageError}
                />
            </div>
            <span className="text-sm font-medium text-slate-800">{getTitleCase(name)}</span>
        </div>
    );
};

export default ConnectorType;
