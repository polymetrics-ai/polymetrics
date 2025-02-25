import apiClient from './apiClient';

export const getChatHistory = async () => {
  const response = await apiClient.get("/api/v1/agents/data_agent/history");
  return response.data.data;
};

export const createChat = async (query: string, title?: string) => {
  const response = await apiClient.post("/api/v1/agents/data_agent/chat", {
    chat: {
      query,
      title: title || 'New Chat'
    }
  });
  return response.data;
};

export const getMessages = async (chatId?: number) => {
  const endpoint = `/api/v1/agents/data_agent/chats/${chatId}/messages`;

  const response = await apiClient.get(endpoint);
  return response.data.data;
};