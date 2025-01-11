import React from 'react';
import {
    Tooltip,
    TooltipContent,
    TooltipProvider,
    TooltipTrigger,
} from "@/components/ui/tooltip";

export interface StatusProps {
    isConnected: boolean;
}

const Status: React.FC<StatusProps> = ({ isConnected }) => {
    return (
        <div className="flex items-center gap-3 pl-3">
            <TooltipProvider delayDuration={50}>
                <Tooltip>
                    <TooltipTrigger asChild>
                        <div
                            className={`w-2.5 h-2.5 rounded-full ${
                                isConnected ? 'bg-green-500' : 'bg-red-500'
                            }`}
                        />
                    </TooltipTrigger>
                    <TooltipContent
                        className="bg-slate-900 text-white"
                        side="right"
                        sideOffset={5}
                    >
                        {isConnected ? 'Active' : 'Inactive'}
                    </TooltipContent>
                </Tooltip>
            </TooltipProvider>
        </div>
    );
};

export default Status;
