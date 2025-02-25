import apiClient from './apiClient';

export const getChatHistory = async () => {
  try {
    const response = await apiClient.get("/api/v1/agents/data_agent/history");
    return response.data.data;
  } catch (error) {
    console.error("Error fetching chat history:", error);
    throw error;
  }
};

export const createChat = async (query: string, title?: string) => {
  try {
    const response = await apiClient.post("/api/v1/agents/data_agent/chat", {
      chat: {
        query,
        title: title || 'New Chat'
      }
    });
    return response.data;
  } catch (error) {
    console.error("Error creating chat:", error);
    throw error;
  }
};

export const getMessages = async (chatId?: number) => {
  const endpoint = `/api/v1/agents/data_agent/chats/${chatId}/messages`;

  try {
    const response = await apiClient.get(endpoint);
    return response.data.data;
  } catch (error) {
    console.error("Error fetching messages:", error);
    throw error;
  }
};