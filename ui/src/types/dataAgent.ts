export interface Chat {
  id: number;
  title: string;
  description: string;
  status: string;
  created_at: string;
  icon_url?: string;
  last_message: {
    content: any;
    role: string;
    message_type: string;
    created_at: string;
  };
  message_count: number;
}

export interface ChatResponse extends Array<Chat> {} 