import * as React from 'react';
import { createLazyFileRoute, useNavigate } from '@tanstack/react-router';
import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { defineStepper } from '@stepperize/react';
import { dataAgentSteps } from '@/constants/constants';
import { DataAgentThinking } from "@/components/DataAgentThinking";
import { useQuery } from '@tanstack/react-query';
import { getChatHistory, getMessages, createChat } from '@/service/dataAgent';
import ChatHistory from '@/components/data-agent/ChatHistory';
import { UserMessage } from '@/components/data-agent/UserMessage'
import { SystemMessage } from '@/components/data-agent/SystemMessage'
import { PipelineStepper } from '@/components/data-agent/PipelineStepper'

const { useStepper } = defineStepper(...dataAgentSteps);

export const Route = createLazyFileRoute('/_authenticated/data-agent/')({
    component: DataAgentIndex
});

function DataAgentIndex() {
    const navigate = useNavigate();
    const [query, setQuery] = useState<string>('');

    const handleNewChat = async () => {
        try {
            const response = await createChat(query);
            navigate({ to: `/data-agent/${response.data.id}` });
        } catch (error) {
            // Handle error
        }
    };

    const { data: chatHistory, isLoading } = useQuery({
        queryKey: ['dataAgentChatHistory'],
        queryFn: getChatHistory
    });

    return (
        <main className="grid grid-cols-5 my-8 mr-8 bg-slate-100">
            <div className="col-span-4 overflow-hidden flex-grow">
                <div className="flex flex-1 flex-col bg-slate-100 h-full items-center justify-center">
                    <div className="max-w-2xl text-center">
                        <div className="bg-emerald-100 p-4 rounded-full w-fit mx-auto mb-6">
                            <img src="/icon-data-agent.svg" className="w-12 h-12" alt="Data Agent" />
                        </div>
                        <h1 className="text-3xl font-semibold text-slate-800 mb-4">
                            Data Agent Assistant
                        </h1>
                        <p className="text-slate-600 mb-8">
                            Start by asking the Data Agent to create a new pipeline, analyze your data, 
                            or answer questions about your connectors.
                        </p>
                        <div className="mt-4 chat-input-transition">
                            <div className="flex bg-white border border-slate-200 shadow-sm focus-within:ring-2 focus-within:ring-emerald-500">
                                <Input
                                    className="flex-1 border-0 shadow-none placeholder:text-slate-400 py-6 px-4 rounded-none focus-visible:ring-0"
                                    placeholder="Ask agent to setup a pipeline..."
                                    value={query}
                                    onChange={(e) => setQuery(e.target.value)}
                                    onKeyDown={(e) => e.key === 'Enter' && handleNewChat()}
                                />
                                <Button
                                    onClick={handleNewChat}
                                    className="bg-emerald-600 hover:bg-emerald-700 rounded-none px-8 mx-2 my-2"
                                >
                                    <svg
                                        xmlns="http://www.w3.org/2000/svg"
                                        width="20"
                                        height="20"
                                        viewBox="0 0 24 24"
                                        fill="none"
                                        stroke="currentColor"
                                        strokeWidth="2"
                                        strokeLinecap="round"
                                        strokeLinejoin="round"
                                    >
                                        <path d="M22 2 11 13" />
                                        <path d="M22 2 15 22 11 13 2 9 22 2z" />
                                    </svg>
                                </Button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div className="w-80 overflow-hidden">
                <ChatHistory 
                    chatHistory={chatHistory}
                    isLoading={isLoading}
                    onChatSelect={(chatId) => navigate({ to: `/data-agent/${chatId}` })}
                    activeChatId={null}
                />
            </div>
        </main>
    );
} 