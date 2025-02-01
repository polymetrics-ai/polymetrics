import { FC } from 'react';

interface ConnectorIdentifiedProps {}

export const ConnectorIdentified: FC<ConnectorIdentifiedProps> = () => {
    return (
        <div className="mt-4">
            <div className="flex items-center">
                <div className="flex items-center gap-2 bg-white p-3 border border-slate-200 rounded-sm min-w-[180px]">
                    <div className="border border-slate-200 p-1.5 rounded-full">
                        <img src="/connectors/github.svg" className="w-4 h-4" alt="Github" />
                    </div>
                    <span className="text-sm font-medium text-slate-700">GitHub</span>
                </div>
                <div className="flex items-center gap-2 bg-white p-3 border border-slate-200 rounded-sm min-w-[180px] ml-4">
                    <div className="border border-slate-200 p-1.5 rounded-full">
                        <img src="/connectors/duckdb.svg" className="w-4 h-4" alt="DuckDB" />
                    </div>
                    <span className="text-sm font-medium text-slate-700">DuckDB</span>
                </div>
            </div>
        </div>
    );
};

export default ConnectorIdentified; 