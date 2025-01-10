export interface Connector {
    id: string;
    name: string;
    description: string;
    connector_class_name: string;
    connector_language: string;
    connected: boolean;
    icon_url: string;
    updated_at: string;
    configuration: Record<string, any>;
}

export interface ConnectorResponse {
    data: Connector[];
}

export interface ConnectorDefinitionResponse {
    data: Definition[];
}

export interface APIError {
    message: string;
    status: number;
}