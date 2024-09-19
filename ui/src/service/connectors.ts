import apiClient from './apiClient';
import { postConnectorPayload } from '@/types/payload';

const getConnectorList = () => {
    return apiClient.get('api/v1/connectors');
};

const postConnector = (payload: postConnectorPayload) => {
    return apiClient.get('api/v1/connectors', payload);
};

export { getConnectorList, postConnector };
