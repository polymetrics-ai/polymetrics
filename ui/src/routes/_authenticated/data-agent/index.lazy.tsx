import * as React from 'react';
import { createLazyFileRoute } from '@tanstack/react-router';
import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { defineStepper } from '@stepperize/react';
import { dataAgentSteps } from '@/constants/constants';
import { DataAgentThinking } from "@/components/DataAgentThinking";
import { useQuery } from '@tanstack/react-query';
import { getChatHistory } from '@/service/dataAgent';
import ChatHistory from '@/components/data-agent/ChatHistory';
import { UserMessage } from '@/components/data-agent/UserMessage'
import { SystemMessage } from '@/components/data-agent/SystemMessage'
import { PipelineStepper } from '@/components/data-agent/PipelineStepper'

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
                            <UserMessage query={query} />

                            {/* System Message */}
                            <SystemMessage message="I'll help you analyze the data from your GitHub repository. Let me think about the best way to structure this pipeline..." />

                            {/* Data Agent Thinking */}
                            <DataAgentThinking />

                            {/* Pipeline Message (Stepper) */}
                            <PipelineStepper stepper={stepper} />
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