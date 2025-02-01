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
  isLoading 
}: { 
  chatHistory?: Chat[];
  isLoading: boolean;
}) {
  return (
    <div className="flex flex-col pl-8 h-full bg-white border-l border-slate-200">
      <div className="flex flex-col h-full">
        <h2 className="text-xl font-semibold text-slate-800 mb-6">History</h2>
        <div className="space-y-6 overflow-y-auto h-[calc(100vh-200px)]">
          {isLoading ? (
            <div className="space-y-4">
              {[1, 2, 3].map((i) => (
                <ChatHistorySkeleton key={i} />
              ))}
            </div>
          ) : chatHistory?.length ? (
            chatHistory.map((chat: Chat) => (
              <div key={chat.id} className="group cursor-pointer">
                <TooltipProvider delayDuration={50}>
                  <Tooltip>
                    <TooltipTrigger asChild>
                      <div className="flex items-start gap-3 p-3 rounded-lg hover:bg-slate-50 transition-colors">
                        <div className="border border-slate-200 p-2 rounded-lg bg-white shadow-sm group-hover:border-slate-300 transition-colors min-w-[36px] min-h-[36px] flex items-center justify-center">
                          <img 
                            src={chat.icon_url || "/icon-data-agent.svg"} 
                            className="w-5 h-5" 
                            alt="Data Agent"
                            style={{ display: 'block' }}
                          />
                        </div>
                        <div className="flex-1">
                          <h3 className="text-base font-medium text-slate-800 group-hover:text-slate-900">
                            {chat.title}
                          </h3>
                          <p className="text-sm text-slate-500 group-hover:text-slate-600 line-clamp-2">
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
            <div className="group">
              <TooltipProvider delayDuration={50}>
                <Tooltip>
                  <TooltipTrigger asChild>
                    <div className="flex items-start gap-3 rounded-lg">
                      <div className="border border-slate-200 p-2 rounded-lg bg-white shadow-sm">
                        <ChatBubbleIcon className="w-5 h-5 text-slate-400" />
                      </div>
                      <div>
                        <h3 className="text-base font-medium text-slate-800">
                          No Chat History
                        </h3>
                        <p className="text-sm text-slate-500 line-clamp-2">
                          Start a conversation with the Data Agent to see your history appear here
                        </p>
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
            </div>
          )}
        </div>
      </div>
    </div>
  );
} 