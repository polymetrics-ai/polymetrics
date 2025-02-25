import { FC } from 'react';

interface ConnectorIdentifiedProps {
  connectors?: Array<{
    id: number;
    name: string;
    icon_url: string;
    display_name: string;
  }>;
}

export const ConnectorIdentified: FC<ConnectorIdentifiedProps> = ({ connectors }) => {
  return (
    <div className="mt-4">
      <div className="grid grid-cols-3 gap-4">
        {connectors?.map((connector) => (
          <div
            key={connector.id}
            className="flex items-center gap-2 bg-white p-3 border border-slate-200 rounded-sm min-w-[180px]"
          >
            <div className="border border-slate-200 p-1.5 rounded-full">
              <img
                src={connector.icon_url}
                className="w-4 h-4"
                alt={connector.name}
              />
            </div>
            <span className="text-sm font-medium text-slate-700 truncate">
              {connector.display_name}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
};

export default ConnectorIdentified;