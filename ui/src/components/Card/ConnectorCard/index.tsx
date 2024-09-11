import React from 'react';
import ConnectorType from '../../ConnectorType';

export interface ConnectorCardProps {
    name: string;
    icon: string;
}

const ConnectorCard: React.FC<ConnectorCardProps> = ({ name, icon }) => {
    return (
        <div className="flex gap-2.5 items-center p-4 border border-solid bg-white border-slate-300 min-h-[80px] min-w-[220px] shadow-[0px_3px_8px_-2px_rgba(203,213,225,0.60)]">
            <div className="flex-shrink-0 w-12 h-12 rounded-full border border-slate-200 bg-white flex items-center justify-center">
                <img className="w-6 h-6" src={icon} alt="Icon" />
            </div>
            {name && (
                <div className="flex-1 min-w-0">
                    <p className="text-base text-slate-800 truncate">{name}</p>
                </div>
            )}
        </div>
    );
};

export default ConnectorCard;
