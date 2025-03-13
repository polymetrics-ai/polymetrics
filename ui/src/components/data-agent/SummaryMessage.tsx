import { FC } from 'react';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';

interface SummaryMessageProps {
  summaryData: string;
}

export const SummaryMessage: FC<SummaryMessageProps> = ({ summaryData }) => (
  <div className="flex justify-start mb-8 ml-2">
    <div className="flex flex-col items-start w-full max-w-2xl">
      <div className="bg-emerald-50 ring-2 ring-emerald-600 shadow-sm p-6 rounded-none prose">
        <ReactMarkdown remarkPlugins={[remarkGfm]}>{summaryData}</ReactMarkdown>
      </div>
      <span className="text-xs text-slate-500 mt-2 ml-2">Data Agent Summary</span>
    </div>
  </div>
);
