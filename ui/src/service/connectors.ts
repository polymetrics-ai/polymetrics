import apiClient from './apiClient';
import { postConnectorPayload } from '@/types/payload';

const getConnectors = () : Promise<void> => {
    return apiClient.get('api/v1/connectors');
};

const postConnector = (payload: postConnectorPayload): Promise<void> => {
    return apiClient.post('api/v1/connectors', payload);
};

const putConnector = (id: string, payload: postConnectorPayload): Promise<void> => {
    return apiClient.put(`api/v1/connectors/${id}`, payload);
}

export { getConnectors, postConnector , putConnector };
