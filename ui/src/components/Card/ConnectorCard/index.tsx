import React from 'react';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip';
import { getTitleCase } from '@/lib/helper';
import { Definition } from '@/hooks/useConnectorDefinitions';
import { DEFAULT_CONNECTOR_ICON } from '@/constants/constants';

export interface ConnectorCardProps {
    key: string;
    definition: Definition;
    isActive: boolean;
    handleOnSelection: (name: string) => void;
}

const DEFAULT_NAME = 'Unnamed Connector';

const ConnectorCard: React.FC<ConnectorCardProps> = ({
    definition,
    isActive,
    handleOnSelection
}) => {
    const {name, icon_url } = definition;
    
    return (
        <TooltipProvider delayDuration={100}>
            <Tooltip>
                <TooltipTrigger>
                    <div
                        className={`flex gap-2.5 items-center p-4 border border-solid border-slate-300 min-h-[80px] min-w-[220px] shadow-[0px_3px_8px_-2px_rgba(203,213,225,0.60)] ${isActive ? 'bg-slate-300' : 'bg-white'}`}
                        onClick={() => handleOnSelection(name ?? DEFAULT_NAME)}
                    >
                        <div className="flex w-11 h-11 rounded-full border border-slate-200 bg-white items-center justify-center">
                            <img 
                                className="w-4.5 h-4.5" 
                                src={icon_url ?? DEFAULT_CONNECTOR_ICON} 
                                alt={`${name ?? DEFAULT_NAME} Icon`} 
                            />
                        </div>
                        <div className="flex flex-1 min-w-0 items-start justify-start whitespace-pre-wrap">
                            <div className="text-sm text-slate-800 truncate">
                                {getTitleCase(name ?? DEFAULT_NAME)}
                            </div>
                        </div>
                    </div>
                </TooltipTrigger>
                <TooltipContent className="bg-zinc-800 text-white py-2 px-2">
                    {getTitleCase(name ?? DEFAULT_NAME)}
                </TooltipContent>
            </Tooltip>
        </TooltipProvider>
    );
};

export default ConnectorCard;
