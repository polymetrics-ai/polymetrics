import apiClient from './apiClient';
import { postConnectorPayload } from '@/types/payload';

const getConnectorList = () => {
    return apiClient.get('/connectors');
};

const postConnector = (payload: postConnectorPayload) => {
    return apiClient.get('/connectors', payload);
};

export { getConnectorList, postConnector };
