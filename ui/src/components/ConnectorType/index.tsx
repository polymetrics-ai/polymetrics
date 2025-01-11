import React from 'react';
import { getTitleCase } from '@/lib/helper';
import { DEFAULT_CONNECTOR_ICON } from '@/constants/constants';

export interface ConnectorTypeProps {
    className?: string;
    icon: string;
    name: string;
}

const ConnectorType: React.FC<ConnectorTypeProps> = ({ icon, name }) => {
    const [iconSrc, setIconSrc] = React.useState(icon);

    // Log initial props
    console.log('ConnectorType Props:', { icon, name });

    const handleImageError = (e: React.SyntheticEvent<HTMLImageElement>) => {
        console.log('Image load error for:', iconSrc);
        
        // Try to load local icon first
        const localIconPath = `/connectors/${name.toLowerCase()}.svg`;
        console.log('Attempting to load local icon:', localIconPath);
        
        setIconSrc(localIconPath);

        // If local icon also fails, use default
        e.currentTarget.onerror = () => {
            console.log('Local icon failed, using default:', DEFAULT_CONNECTOR_ICON);
            setIconSrc(DEFAULT_CONNECTOR_ICON);
        };
        e.currentTarget.src = localIconPath;
    };

    // Log whenever iconSrc changes
    React.useEffect(() => {
        console.log('Current iconSrc:', iconSrc);
    }, [iconSrc]);

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
