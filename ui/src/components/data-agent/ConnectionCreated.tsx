import { FC } from 'react';
import { motion } from 'framer-motion';

interface ConnectionCreatedProps {
  source?: {
    name: string;
    icon_url: string;
  };
  destination?: {
    name: string;
    icon_url: string;
    is_default?: boolean;
  };
  streams?: string[];
}

export const ConnectionCreated: FC<ConnectionCreatedProps> = ({ source, destination, streams }) => {
  return (
    <div className="mt-4">
      {streams && (
        <div className="mb-4">
          <div className="inline-flex flex-wrap items-center gap-2 py-1 rounded-md">
            <span className="text-xs font-medium text-emerald-600">
              Selected streams:
            </span>
            {streams.map((stream) => (
              <span
                key={stream}
                className="px-2 py-1 bg-emerald-600 text-white text-xs font-medium rounded-md"
              >
                {stream}
              </span>
            ))}
          </div>
        </div>
      )}

      <div className="flex items-center gap-6">
        {source && (
          <div className="flex items-center gap-2 bg-white p-3 border border-slate-200 rounded-sm min-w-[180px]">
            <div className="border border-slate-200 p-1.5 rounded-full">
              <img src={source.icon_url} className="w-4 h-4" alt={source.name} />
            </div>
            <span className="text-sm font-medium text-slate-700">{source.name}</span>
          </div>
        )}

        <motion.div
          animate={{
            x: [0, 10, 0]
          }}
          transition={{
            duration: 1.5,
            repeat: Infinity,
            ease: 'easeInOut'
          }}
        >
          <svg
            width="24"
            height="24"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            className="text-emerald-600"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <path d="M5 12h14" />
            <path d="m12 5 7 7-7 7" />
          </svg>
        </motion.div>

        {destination && (
          <div className="flex items-center gap-2 bg-white p-3 border border-slate-200 rounded-sm min-w-[180px]">
            <div className="border border-slate-200 p-1.5 rounded-full">
              <img
                src={destination.icon_url}
                className="w-4 h-4"
                alt={destination.name}
              />
            </div>
            <span className="text-sm font-medium text-slate-700">
              {destination.name}
              {destination.is_default && (
                <span className="text-slate-400 ml-1">(default)</span>
              )}
            </span>
          </div>
        )}
      </div>
    </div>
  );
};

export default ConnectionCreated;