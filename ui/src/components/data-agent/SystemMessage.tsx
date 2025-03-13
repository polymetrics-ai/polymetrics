import { FC } from 'react';

interface SystemMessageProps {
    message: string;
    isQuestion?: boolean;
}

export const SystemMessage: FC<SystemMessageProps> = ({ message, isQuestion = false }) => (
    <div className="flex justify-start mb-8 ml-2">
        <div className="flex flex-col items-start">
            <div
                className={`bg-emerald-50 ring-2 ${isQuestion ? 'ring-amber-500' : 'ring-emerald-600'} shadow-sm p-6 rounded-none max-w-2xl`}
            >
                <p className="text-emerald-800 font-medium">{message}</p>
            </div>
            <span className="text-xs text-slate-500 mt-2 ml-2">Data Agent</span>
        </div>
    </div>
);
