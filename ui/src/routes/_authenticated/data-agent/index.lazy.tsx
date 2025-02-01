import * as React from 'react';
import { createLazyFileRoute } from '@tanstack/react-router';
import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Separator } from '@/components/ui/separator';
import { defineStepper } from '@stepperize/react';
import { dataAgentSteps } from '@/constants/constants';
import { DataAgentThinking } from "@/components/DataAgentThinking";
import ConnectorIdentified from '@/components/data-agent/ConnectorIdentified';
import ConnectorConfiguration from '@/components/data-agent/ConnectorConfiguration';
import SyncInitiated from '@/components/data-agent/SyncInitiated';
import QueryBlock from '@/components/data-agent/QueryBlock';
import DataPresented from '@/components/data-agent/DataPresented';
import { useQuery } from '@tanstack/react-query';
import { getChatHistory } from '@/service/dataAgent';
import ChatHistory from '@/components/data-agent/ChatHistory';

const { useStepper } = defineStepper(...dataAgentSteps);

export const Route = createLazyFileRoute('/_authenticated/data-agent/')({
    component: DataAgent
});

export function DataAgent() {
    const [query, setQuery] = useState<string>('');
    const stepper = useStepper();

    const { data: chatHistory, isLoading } = useQuery({
        queryKey: ['dataAgentChatHistory'],
        queryFn: getChatHistory
    });

    const handleSendQuery = () => {
        if (query.trim()) {
            stepper.next();
        }
    };

    return (
        <main className="grid grid-cols-5 my-8 mr-8 bg-slate-100">
            <div className="col-span-4 overflow-hidden flex-grow">
                <div className="flex flex-1 flex-col bg-slate-100 h-full">
                    <div className="px-10 py-8 h-full flex flex-col">
                        <div className="flex items-center gap-2 mb-8">
                            <div className="bg-emerald-100 p-2 rounded-full">
                                <img src="/icon-data-agent.svg" className="w-6 h-6" alt="Data Agent" />
                            </div>
                            <h1 className="text-2xl font-semibold text-slate-800">Data Agent</h1>
                        </div>

                        {/* Scrollable content area */}
                        <div className="flex-1 overflow-y-auto">
                            {/* User Message */}
                            <div className="flex justify-end mb-8">
                                <div className="flex flex-col items-end">
                                    <div className="bg-emerald-700 shadow-sm p-6 rounded-none max-w-2xl">
                                        <p className="text-white font-medium">{query || "How many users have starred our github repo"}</p>
                                    </div>
                                    <span className="text-xs text-slate-500 mt-2 mr-2">You</span>
                                </div>
                            </div>

                            {/* System Message */}
                            <div className="flex justify-start mb-8 ml-2">
                                <div className="flex flex-col items-start">
                                    <div className="bg-emerald-50 ring-2 ring-emerald-600 shadow-sm p-6 rounded-none max-w-2xl">
                                        <p className="text-emerald-800 font-medium">
                                            I'll help you analyze the data from your GitHub repository. Let me think about the best way to structure this pipeline...
                                        </p>
                                    </div>
                                    <span className="text-xs text-slate-500 mt-2 ml-2">Data Agent</span>
                                </div>
                            </div>

                            {/* System Message (Stepper) */}
                            <div className="flex justify-start">
                                <div className="flex-1 min-h-[400px] max-w-2xl">
                                    <DataAgentThinking />
                                    <div className="flex justify-start mb-4">
                                        <h3 className="text-base font-medium text-slate-800">Pipeline</h3>
                                    </div>
                                    <nav aria-label="Pipeline Steps" className="group">
                                        <ol className="flex flex-col" aria-orientation="vertical">
                                            {stepper.all.map((step, index, array) => (
                                                <React.Fragment key={step.id}>
                                                    <li className="flex items-start gap-4">
                                                        <div className="flex flex-col items-center">
                                                            <div className={`w-8 h-8 rounded-full flex items-center justify-center ${
                                                                stepper.current.id === step.id ? 'bg-white border-2 border-emerald-500' : 
                                                                index < stepper.all.indexOf(stepper.current) ? 'bg-emerald-500 text-white' : 
                                                                'bg-white border-2 border-slate-300'
                                                            }`}>
                                                                {step.id === 'connector-identified' && (
                                                                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" 
                                                                        stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                                                                        <path d="M12 22v-5" />
                                                                        <path d="M9 7V2" />
                                                                        <path d="M15 7V2" />
                                                                        <path d="M6 13V8h12v5a4 4 0 0 1-4 4h-4a4 4 0 0 1-4-4Z" />
                                                                    </svg>
                                                                )}
                                                                {step.id === 'connector-configured' && (
                                                                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" 
                                                                        stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                                                                        <path d="M2 12h5" />
                                                                        <path d="M17 12h5" />
                                                                        <path d="M7 12a5 5 0 0 1 5-5h0a5 5 0 0 1 5 5h0a5 5 0 0 1-5 5h0a5 5 0 0 1-5-5Z" />
                                                                    </svg>
                                                                )}
                                                                {step.id === 'sync-initiated' && (
                                                                  <svg width="15" height="15" viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M1.90321 7.29677C1.90321 10.341 4.11041 12.4147 6.58893 12.8439C6.87255 12.893 7.06266 13.1627 7.01355 13.4464C6.96444 13.73 6.69471 13.9201 6.41109 13.871C3.49942 13.3668 0.86084 10.9127 0.86084 7.29677C0.860839 5.76009 1.55996 4.55245 2.37639 3.63377C2.96124 2.97568 3.63034 2.44135 4.16846 2.03202L2.53205 2.03202C2.25591 2.03202 2.03205 1.80816 2.03205 1.53202C2.03205 1.25588 2.25591 1.03202 2.53205 1.03202L5.53205 1.03202C5.80819 1.03202 6.03205 1.25588 6.03205 1.53202L6.03205 4.53202C6.03205 4.80816 5.80819 5.03202 5.53205 5.03202C5.25591 5.03202 5.03205 4.80816 5.03205 4.53202L5.03205 2.68645L5.03054 2.68759L5.03045 2.68766L5.03044 2.68767L5.03043 2.68767C4.45896 3.11868 3.76059 3.64538 3.15554 4.3262C2.44102 5.13021 1.90321 6.10154 1.90321 7.29677ZM13.0109 7.70321C13.0109 4.69115 10.8505 2.6296 8.40384 2.17029C8.12093 2.11718 7.93465 1.84479 7.98776 1.56188C8.04087 1.27898 8.31326 1.0927 8.59616 1.14581C11.4704 1.68541 14.0532 4.12605 14.0532 7.70321C14.0532 9.23988 13.3541 10.4475 12.5377 11.3662C11.9528 12.0243 11.2837 12.5586 10.7456 12.968L12.3821 12.968C12.6582 12.968 12.8821 13.1918 12.8821 13.468C12.8821 13.7441 12.6582 13.968 12.3821 13.968L9.38205 13.968C9.10591 13.968 8.88205 13.7441 8.88205 13.468L8.88205 10.468C8.88205 10.1918 9.10591 9.96796 9.38205 9.96796C9.65819 9.96796 9.88205 10.1918 9.88205 10.468L9.88205 12.3135L9.88362 12.3123C10.4551 11.8813 11.1535 11.3546 11.7585 10.6738C12.4731 9.86976 13.0109 8.89844 13.0109 7.70321Z" fill="currentColor" fill-rule="evenodd" clip-rule="evenodd"></path></svg>
                                                                )}
                                                                {step.id === 'query-generated' && (
                                                                  <svg width="15" height="15" viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M10 6.5C10 8.433 8.433 10 6.5 10C4.567 10 3 8.433 3 6.5C3 4.567 4.567 3 6.5 3C8.433 3 10 4.567 10 6.5ZM9.30884 10.0159C8.53901 10.6318 7.56251 11 6.5 11C4.01472 11 2 8.98528 2 6.5C2 4.01472 4.01472 2 6.5 2C8.98528 2 11 4.01472 11 6.5C11 7.56251 10.6318 8.53901 10.0159 9.30884L12.8536 12.1464C13.0488 12.3417 13.0488 12.6583 12.8536 12.8536C12.6583 13.0488 12.3417 13.0488 12.1464 12.8536L9.30884 10.0159Z" fill="currentColor" fill-rule="evenodd" clip-rule="evenodd"></path></svg>
                                                                )}
                                                                {step.id === 'data-presented' && (
                                                                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" 
                                                                        stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                                                                        <path d="M3 3h18v18H3z"/>
                                                                        <path d="M3 9h18"/>
                                                                        <path d="M3 15h18"/>
                                                                        <path d="M9 3v18"/>
                                                                        <path d="M15 3v18"/>
                                                                    </svg>
                                                                )}
                                                            </div>
                                                            {index < array.length - 1 && (
                                                                <Separator 
                                                                    orientation="vertical" 
                                                                    className={`h-full w-[2px] ${
                                                                        index < stepper.all.indexOf(stepper.current) ? 'bg-emerald-500' : 'bg-slate-200'
                                                                    }`}
                                                                    style={{
                                                                        marginTop: '8px',
                                                                        marginBottom: '-8px',
                                                                        height: step.id === 'connector-configured' ? '120px' :
                                                                               step.id === 'sync-initiated' ? '140px' :
                                                                               '100px'
                                                                    }}
                                                                />
                                                            )}
                                                        </div>
                                                        <div className="flex-1 pt-1 pb-8">
                                                            <h3 className="text-base font-medium text-slate-800 mb-2">{step.title}</h3>
                                                            <p className="text-sm text-slate-500 mb-6">{step.description}</p>
                                                            
                                                            {step.id === 'connector-identified' && <ConnectorIdentified />}
                                                            {step.id === 'connector-configured' && <ConnectorConfiguration />}
                                                            {step.id === 'sync-initiated' && <SyncInitiated />}
                                                            {step.id === 'query-generated' && <QueryBlock />}
                                                            {step.id === 'data-presented' && <DataPresented />}
                                                        </div>
                                                    </li>
                                                </React.Fragment>
                                            ))}
                                        </ol>
                                    </nav>
                                </div>
                            </div>
                        </div>

                        {/* Fixed input at bottom */}
                        <div className="mt-4">
                            <div className="flex bg-white border border-slate-200 shadow-sm focus-within:ring-2 focus-within:ring-emerald-500 focus-within:border-emerald-500">
                                <Input 
                                    className="flex-1 border-0 shadow-none placeholder:text-slate-400 py-6 px-4 rounded-none focus-visible:ring-0"
                                    placeholder="Ask agent to setup a pipeline..."
                                    value={query}
                                    onChange={(e) => setQuery(e.target.value)}
                                    onKeyDown={(e) => e.key === 'Enter' && handleSendQuery()}
                                />
                                <Button 
                                    onClick={handleSendQuery}
                                    className="bg-emerald-600 hover:bg-emerald-700 rounded-none px-8 mx-2 my-2"
                                >
                                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                                        <line x1="22" y1="2" x2="11" y2="13"></line>
                                        <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
                                    </svg>
                                </Button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div className="w-80 overflow-hidden">
                <ChatHistory chatHistory={chatHistory} isLoading={isLoading} />
            </div>
        </main>
    );
} 