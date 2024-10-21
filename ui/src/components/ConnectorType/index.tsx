import React from 'react';

export interface ConnectorTypeProps {
    className?: string;
    icon: string;
    name: string;
}

const ConnectorType: React.FC<ConnectorTypeProps> = ({ icon, name }) => {
    return (
        <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-full bg-white border-1 border-slate-200">
                <img
                    className="w-4.5 h-4.5 p-2 shrink-0"
                    src={
                        icon !==''
                            ? icon
                            : 'https://raw.githubusercontent.com/polymetrics-ai/polymetrics/main/public/connector_icons/github.svg'
                    }
                />
            </div>
            <span className="text-sm font-medium text-slate-800">{name}</span>
        </div>
    );
};

export default ConnectorType;
