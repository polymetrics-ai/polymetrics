import apiClient from './apiClient';
import { postConnectorPayload } from '@/types/payload';
import { ConnectorResponse, ConnectorDefinitionResponse, APIError, Connector } from '@/types/connector';

const handleError = (error: any): never => {
    const apiError: APIError = {
        message: error.response?.data?.message || 'An unexpected error occurred',
        status: error.response?.status || 500
    };
    throw apiError;
};

const getConnectors = async (): Promise<ConnectorResponse> => {
    try {
        const response = await apiClient.get<ConnectorResponse>('api/v1/connectors');
        return response.data;
    } catch (error) {
        throw handleError(error);
    }
};

const getDefinitions = async (): Promise<ConnectorDefinitionResponse> => {
    try {
        const response = await apiClient.get<ConnectorDefinitionResponse>('api/v1/connectors/definitions');
        return response.data;
    } catch (error) {
        throw handleError(error);
    }
};

const postConnector = async (payload: postConnectorPayload): Promise<Connector> => {
    try {
        const response = await apiClient.post<Connector>('api/v1/connectors', payload);
        return response.data;
    } catch (error) {
        throw handleError(error);
    }
};

const putConnector = async (id: string, payload: postConnectorPayload): Promise<Connector> => {
    try {
        const response = await apiClient.put<Connector>(`api/v1/connectors/${id}`, payload);
        return response.data;
    } catch (error) {
        throw handleError(error);
    }
};

export { getConnectors, getDefinitions, postConnector, putConnector };
