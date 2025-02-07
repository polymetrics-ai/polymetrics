import { FC } from 'react';

interface ConnectorIdentifiedProps {
    connectors?: Array<{
        id: number;
        name: string;
        icon_url: string;
        display_name: string;
        is_default: boolean;
    }>;
}

export const ConnectorIdentified: FC<ConnectorIdentifiedProps> = ({ connectors }) => {
    return (
        <div className="mt-4">
            <div className="flex items-center">
                {connectors?.map((connector) => (
                    <div key={connector.id} className="flex items-center gap-2 bg-white p-3 border border-slate-200 rounded-sm min-w-[180px] ml-4 first:ml-0">
                        <div className="border border-slate-200 p-1.5 rounded-full">
                            <img 
                                src={connector.icon_url} 
                                className="w-4 h-4" 
                                alt={connector.name} 
                            />
                        </div>
                        <span className="text-sm font-medium text-slate-700">
                            {connector.name}
                            {connector.is_default && (
                                <span className="text-slate-400 ml-1">(default)</span>
                            )}
                        </span>
                    </div>
                ))}
            </div>
        </div>
    );
};

export default ConnectorIdentified; 