import { ChatBubbleIcon } from "@radix-ui/react-icons";
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import { Chat } from "@/types/dataAgent";

const EMPTY_STATE_CHAT_DESCRIPTION = "This chat session is dedicated to managing and executing data integration tasks through the Data Agent. It tracks ETL pipelines, connection configurations, and query executions.";

const ChatHistorySkeleton = () => (
  <div className="group">
    <div className="flex items-start gap-3 rounded-lg">
      <div className="border border-slate-200 p-2 rounded-lg bg-white">
        <div className="w-5 h-5 bg-slate-200 rounded animate-pulse" />
      </div>
      <div className="flex-1">
        <div className="h-5 w-32 bg-slate-200 rounded mb-2 animate-pulse" />
        <div className="h-4 w-64 bg-slate-200 rounded animate-pulse" />
      </div>
    </div>
  </div>
);

export default function ChatHistory({ 
  chatHistory,
  isLoading,
  onChatSelect,
  activeChatId
}: { 
  chatHistory?: Chat[];
  isLoading: boolean;
  onChatSelect: (chatId: number) => void;
  activeChatId: number | null;
}) {
  return (
    <div className="w-80 overflow-hidden h-full">
      <div className="flex flex-col h-full bg-white border-l border-slate-200">
        <h2 className="text-xl font-semibold text-slate-800 mb-6 px-8">History</h2>
        <div className="flex-1 overflow-y-auto px-4 space-y-2">
          {isLoading ? (
            <div className="space-y-2">
              {[1, 2, 3].map((i) => (
                <ChatHistorySkeleton key={i} />
              ))}
            </div>
          ) : chatHistory?.length ? (
            chatHistory.map((chat: Chat) => (
              <div 
                key={chat.id}
                className={`group cursor-pointer p-3 rounded-lg ${
                  activeChatId === chat.id ? 'bg-slate-100' : 'hover:bg-slate-50'
                } transition-colors`}
                onClick={() => onChatSelect(chat.id)}
              >
                <TooltipProvider delayDuration={50}>
                  <Tooltip>
                    <TooltipTrigger asChild>
                      <div className="flex items-start gap-3">
                        <div className="border border-slate-200 p-2 rounded-lg bg-white shadow-sm min-w-[36px] min-h-[36px] flex items-center justify-center">
                          <img 
                            src={chat.icon_url || "/icon-data-agent.svg"} 
                            className="w-5 h-5" 
                            alt="Data Agent"
                          />
                        </div>
                        <div className="flex-1">
                          <h3 className="text-sm font-medium text-slate-800">
                            {chat.title}
                          </h3>
                          <p className="text-xs text-slate-500 line-clamp-2">
                            {chat.description || "Data Agent Chat"}
                          </p>
                          <div className="mt-1 text-xs text-slate-400">
                            {new Date(chat.created_at).toLocaleDateString('en-US', {
                              year: 'numeric',
                              month: 'short',
                              day: 'numeric',
                              hour: 'numeric',
                              minute: '2-digit',
                              hour12: true
                            })}
                          </div>
                        </div>
                      </div>
                    </TooltipTrigger>
                    <TooltipContent 
                      className="bg-slate-900 text-white max-w-xs p-3"
                      side="right"
                      sideOffset={5}
                    >
                      {chat.description || "Data Agent Chat"}
                    </TooltipContent>
                  </Tooltip>
                </TooltipProvider>
              </div>
            ))
          ) : (
            <TooltipProvider delayDuration={50}>
              <Tooltip>
                <TooltipTrigger asChild>
                  <div className="p-3">
                    <div className="flex items-start gap-3">
                      <div className="border border-slate-200 p-2 rounded-lg bg-white shadow-sm">
                        <ChatBubbleIcon className="w-5 h-5 text-slate-400" />
                      </div>
                      <div>
                        <h3 className="text-sm font-medium text-slate-800">
                          No Chat History
                        </h3>
                        <p className="text-xs text-slate-500 line-clamp-2">
                          Start a conversation with the Data Agent to see your history appear here
                        </p>
                      </div>
                    </div>
                  </div>
                </TooltipTrigger>
                <TooltipContent 
                  className="bg-slate-900 text-white max-w-xs p-3"
                  side="right"
                  sideOffset={5}
                >
                  {EMPTY_STATE_CHAT_DESCRIPTION}
                </TooltipContent>
              </Tooltip>
            </TooltipProvider>
          )}
        </div>
      </div>
    </div>
  );
} 