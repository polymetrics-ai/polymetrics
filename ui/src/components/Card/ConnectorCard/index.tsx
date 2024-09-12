import React from 'react';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip';

export interface ConnectorCardProps {
    name: string;
    icon: string;
}

const ConnectorCard: React.FC<ConnectorCardProps> = ({ name, icon }) => {
    return (
        <TooltipProvider delayDuration={100}>
            <Tooltip>
                <TooltipTrigger>
                    <div className="flex gap-2.5 items-center p-4 border border-solid bg-white border-slate-300 min-h-[80px] min-w-[220px] shadow-[0px_3px_8px_-2px_rgba(203,213,225,0.60)]">
                        <div className=" flex w-11 h-11 rounded-full border border-slate-200 bg-white items-center justify-center">
                            <img className="w-4.5 h-4.5" src={icon} alt="Icon" />
                        </div>
                        <div className="flex flex-1 min-w-0 items-start justify-start whitespace-pre-wrap">
                            <div className="text-sm text-slate-800 truncate">{name}</div>
                        </div>
                    </div>
                </TooltipTrigger>
                <TooltipContent className='bg-zinc-800 text-white py-2 px-2'>
                   {name}
                </TooltipContent>
            </Tooltip>
           
        </TooltipProvider>
    );
};

export default ConnectorCard;
