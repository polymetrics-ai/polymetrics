import React from 'react';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip';
import { getTitleCase } from '@/lib/helper';

export interface ConnectorCardProps {
    key: string;
    definition: any;
    isActive: boolean;
    handleOnSelection: (name: string) => void;
}

const ConnectorCard: React.FC<ConnectorCardProps> = ({
    definition,
    isActive,
    handleOnSelection
}) => {
    const {name, definition_status, icon_url, } = definition;
    return (
        <TooltipProvider delayDuration={100}>
            <Tooltip>
                <TooltipTrigger>
                    <div
                        className={`flex gap-2.5 items-center p-4 border border-solid border-slate-300 min-h-[80px] min-w-[220px] shadow-[0px_3px_8px_-2px_rgba(203,213,225,0.60)] ${isActive ? 'bg-slate-300' : 'bg-white'}`}
                        onClick={() => handleOnSelection(name)}
                    >
                        <div className=" flex w-11 h-11 rounded-full border border-slate-200 bg-white items-center justify-center">
                            <img className="w-4.5 h-4.5" src={icon_url} alt="Icon" />
                        </div>
                        <div className="flex flex-1 min-w-0 items-start justify-start whitespace-pre-wrap">
                            <div className="text-sm text-slate-800 truncate">
                                {getTitleCase(name)}
                            </div>
                        </div>
                    </div>
                </TooltipTrigger>
                <TooltipContent className="bg-zinc-800 text-white py-2 px-2">
                    {getTitleCase(name)}
                </TooltipContent>
            </Tooltip>
        </TooltipProvider>
    );
};

export default ConnectorCard;
