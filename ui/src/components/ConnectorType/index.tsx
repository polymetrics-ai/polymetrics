import React from 'react';
import { getTitleCase } from '@/lib/helper';
import { DEFAULT_CONNECTOR_ICON } from '@/constants/constants';

export interface ConnectorTypeProps {
    className?: string;
    icon: string;
    name: string;
}

const ConnectorType: React.FC<ConnectorTypeProps> = ({ icon, name }) => {
    const [iconSrc, setIconSrc] = React.useState(icon || DEFAULT_CONNECTOR_ICON);

    const handleImageError = (e: React.SyntheticEvent<HTMLImageElement>) => {
        const localIconPath = `/connectors/${name.toLowerCase()}.svg`;     
        if (iconSrc !== localIconPath) {
            setIconSrc(localIconPath);
        } else {
            setIconSrc(DEFAULT_CONNECTOR_ICON);
        }
    };

    return (
        <div className="flex items-center gap-3">
            <div className="flex items-center justify-center w-9 h-9 rounded-full bg-white border border-slate-200 p-1">
                <img
                    className="w-full h-full object-contain"
                    src={iconSrc}
                    alt={`${name} icon`}
                    onError={handleImageError}
                />
            </div>
            <span className="text-sm font-medium text-slate-800">{getTitleCase(name)}</span>
        </div>
    );
};

export default ConnectorType;
