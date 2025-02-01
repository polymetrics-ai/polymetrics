import { FC } from 'react';

interface SyncInitiatedProps {}

const SyncInitiated: FC<SyncInitiatedProps> = () => {
    return (
        <div className="mt-4">
            <div className="w-full border border-slate-200 rounded-sm bg-white">
                <table className="w-full">
                    <thead>
                        <tr className="border-b border-slate-200">
                            <th className="text-left text-xs font-medium text-slate-500 px-4 py-3">STATUS</th>
                            <th className="text-left text-xs font-medium text-slate-500 px-4 py-3">STREAM NAME</th>
                            <th className="text-left text-xs font-medium text-slate-500 px-4 py-3">LAST SYNCED</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr className="border-b border-slate-200">
                            <td className="px-4 py-3">
                                <div className="flex items-center">
                                    <div 
                                        className="w-2 h-2 rounded-full bg-emerald-500 mr-2 cursor-help"
                                        title="Connected and syncing"
                                    ></div>
                                </div>
                            </td>
                            <td className="px-4 py-3 text-sm text-slate-700">Commit</td>
                            <td className="px-4 py-3 text-sm text-slate-700">11 Aug 2024</td>
                        </tr>
                        <tr className="border-b border-slate-200 bg-slate-50">
                            <td className="px-4 py-3">
                                <div className="flex items-center">
                                    <div 
                                        className="w-2 h-2 rounded-full bg-amber-500 mr-2 cursor-help"
                                        title="Sync in progress"
                                    ></div>
                                </div>
                            </td>
                            <td className="px-4 py-3 text-sm text-slate-700">Branch</td>
                            <td className="px-4 py-3 text-sm text-slate-700">11 Aug 2024</td>
                        </tr>
                        <tr>
                            <td className="px-4 py-3">
                                <div className="flex items-center">
                                    <div 
                                        className="w-2 h-2 rounded-full bg-red-500 mr-2 cursor-help"
                                        title="Failed to sync"
                                    ></div>
                                </div>
                            </td>
                            <td className="px-4 py-3 text-sm text-slate-700">SHA</td>
                            <td className="px-4 py-3 text-sm text-slate-700">11 Aug 2024</td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    );
};

export default SyncInitiated; 