import { FC } from 'react';
import { motion } from 'framer-motion';

interface ConnectorConfigurationProps {}

export const ConnectorConfiguration: FC<ConnectorConfigurationProps> = () => {
    return (
        <div className="mt-4">
            <div className="flex items-center gap-6">
                <div className="flex items-center gap-2 bg-white p-3 border border-slate-200 rounded-sm min-w-[180px]">
                    <div className="border border-slate-200 p-1.5 rounded-full">
                        <img src="/connectors/github.svg" className="w-4 h-4" alt="Github" />
                    </div>
                    <span className="text-sm font-medium text-slate-700">GitHub Rails Repo</span>
                </div>
                
                <motion.div
                    animate={{
                        x: [0, 10, 0],
                    }}
                    transition={{
                        duration: 1.5,
                        repeat: Infinity,
                        ease: "easeInOut",
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

                <div className="flex items-center gap-2 bg-white p-3 border border-slate-200 rounded-sm min-w-[180px]">
                    <div className="border border-slate-200 p-1.5 rounded-full">
                        <img src="/connectors/duckdb.svg" className="w-4 h-4" alt="DuckDB" />
                    </div>
                    <span className="text-sm font-medium text-slate-700">Default Analytics DB</span>
                </div>
            </div>
        </div>
    );
};

export default ConnectorConfiguration; 