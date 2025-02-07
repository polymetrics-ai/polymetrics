import { FC } from 'react';
import {
    Tooltip,
    TooltipContent,
    TooltipProvider,
    TooltipTrigger,
} from "@/components/ui/tooltip";

interface SyncStream {
    status: string;
    stream_name: string;
    last_synced_at: string;
}

interface SyncInitiatedProps {
    syncs?: SyncStream[];
}

const getStatusColor = (status: string) => {
    switch (status.toLowerCase()) {
        case 'synced':
            return 'bg-emerald-500';
        case 'syncing':
            return 'bg-amber-500';
        case 'error':
            return 'bg-red-500';
        case 'queued':
            return 'bg-blue-500';
        default:
            return 'bg-slate-500';
    }
};

const getStatusDescription = (status: string) => {
    switch (status.toLowerCase()) {
        case 'synced':
            return 'Sync completed';
        case 'syncing':
            return 'Sync in progress';
        case 'error':
            return 'Failed to sync';
        case 'queued':
            return 'Waiting to sync';
        default:
            return 'Unknown status';
    }
};

const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
        day: 'numeric',
        month: 'short',
        year: 'numeric'
    });
};

const SyncInitiated: FC<SyncInitiatedProps> = ({ syncs }) => {
    if (!syncs?.length) return null;

    return (
        <div className="mt-4">
            <div className="w-full border border-slate-200 rounded-sm bg-white">
                <table className="w-full">
                    <thead>
                        <tr className="border-b border-slate-200">
                            <th className="text-left text-xs font-medium text-slate-500 px-4 py-3">
                                <div className="flex items-center">
                                    <span>STATUS</span>
                                    <div className="w-2 h-2 ml-2"></div>
                                </div>
                            </th>
                            <th className="text-left text-xs font-medium text-slate-500 px-4 py-3">STREAM NAME</th>
                            <th className="text-left text-xs font-medium text-slate-500 px-4 py-3">LAST SYNCED</th>
                        </tr>
                    </thead>
                    <tbody>
                        {syncs.map((sync, index) => (
                            <tr 
                                key={`${sync.stream_name}-${index}`}
                                className={`border-b border-slate-200 ${
                                    index % 2 === 1 ? 'bg-slate-50' : ''
                                }`}
                            >
                                <td className="px-4 py-3">
                                    <div className="flex items-center">
                                        <TooltipProvider>
                                            <Tooltip delayDuration={0}>
                                                <TooltipTrigger>
                                                    <div 
                                                        className={`w-2 h-2 rounded-full ${getStatusColor(sync.status)} ml-2`}
                                                    />
                                                </TooltipTrigger>
                                                <TooltipContent 
                                                    side="right"
                                                    className="bg-slate-900 text-white px-2 py-1 text-xs"
                                                >
                                                    {getStatusDescription(sync.status)}
                                                </TooltipContent>
                                            </Tooltip>
                                        </TooltipProvider>
                                    </div>
                                </td>
                                <td className="px-4 py-3 text-sm text-slate-700">{sync.stream_name}</td>
                                <td className="px-4 py-3 text-sm text-slate-700">{formatDate(sync.last_synced_at)}</td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        </div>
    );
};

export default SyncInitiated; 