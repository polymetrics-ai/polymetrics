import { useState } from 'react';
import { createLazyFileRoute, useParams } from '@tanstack/react-router';
import { useQuery } from '@tanstack/react-query';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import ChatHistory from '@/components/data-agent/ChatHistory';
import { UserMessage } from '@/components/data-agent/UserMessage';
import { SystemMessage } from '@/components/data-agent/SystemMessage';
import { PipelineStepper } from '@/components/data-agent/PipelineStepper';
import { getMessages, getChatHistory } from '@/service/dataAgent';
import { useToast } from "@/hooks/useToast";
import { defineStepper } from '@stepperize/react';
import { dataAgentSteps } from '@/constants/constants';
import { useNavigate } from '@tanstack/react-router';

const { useStepper } = defineStepper(...dataAgentSteps);

export const Route = createLazyFileRoute('/_authenticated/data-agent/$chatId')({
  component: ChatView
});

function ChatView() {
  const { chatId } = useParams({ from: '/_authenticated/data-agent/$chatId' });
  const { toast } = useToast();
  const [query, setQuery] = useState<string>('');
  const navigate = useNavigate();

  // TODO: Update to use websocket
  const { data: messages, isLoading: isMessagesLoading } = useQuery({
    queryKey: ['dataAgentMessages', chatId],
    queryFn: () => getMessages(chatId),
    refetchInterval: 5000,
    refetchOnWindowFocus: false
  });

  const stepper = useStepper();

  const { data: chatHistory, isLoading: isChatHistoryLoading } = useQuery({
    queryKey: ['dataAgentChatHistory'],
    queryFn: getChatHistory
  });

  const handleSendQuery = async () => {
    try {
      if (query.trim()) {
        // TODO: Add message submission API call
        // await sendMessage(chatId, query);
        setQuery('');
      }
    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to send message",
        variant: "destructive",
      });
    }
  };

  return (
    <main className="grid grid-cols-5 my-8 mr-8 bg-slate-100 h-[calc(100vh-4rem)]">
      <div className="col-span-4 overflow-hidden flex-grow">
        <div className="flex flex-1 flex-col bg-slate-100 h-full">
          <div className="px-10 py-8 h-full flex flex-col">
            <div className="flex items-center gap-2 mb-8">
              <div className="bg-emerald-100 p-2 rounded-full">
                <img 
                  src="/icon-data-agent.svg" 
                  className="w-6 h-6" 
                  alt="Data Agent" 
                />
              </div>
              <h1 className="text-2xl font-semibold text-slate-800">Data Agent</h1>
            </div>

            <div className="flex-1 overflow-y-auto space-y-6 pr-4">
              {messages?.map((message) => {
                if (message.role === 'user') {
                  return (
                    <UserMessage 
                      key={message.id} 
                      query={message.content} 
                    />
                  );
                }
                if (message.message_type === 'pipeline') {
                  return (
                    <PipelineStepper
                      key={message.id}
                      stepper={stepper}
                      pipelineData={message.pipeline_data}
                    />
                  );
                }
                return (
                  <SystemMessage 
                    key={message.id} 
                    message={message.content} 
                  />
                );
              })}
              {isMessagesLoading && (
                <div className="text-center text-slate-500">
                  Loading messages...
                </div>
              )}
            </div>

            <div className="mt-4 chat-input-transition input-bar-enter-active">
              <div className="flex bg-white border border-slate-200 shadow-sm focus-within:ring-2 focus-within:ring-emerald-500">
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
      <div className="w-80 overflow-hidden border-l border-slate-200">
        <ChatHistory 
          chatHistory={chatHistory}
          isLoading={isChatHistoryLoading}
          onChatSelect={(chatId) => navigate({ to: `/data-agent/${chatId}` })}
          activeChatId={chatId}
        />
      </div>
    </main>
  );
} 