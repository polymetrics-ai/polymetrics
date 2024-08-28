import axios from 'axios';
import useTokenStore from '../hooks/useTokenStorage';

const { VITE_API_BASE_URL} = import.meta.env;

const apiClient = axios.create({
    baseURL: VITE_API_BASE_URL,
    headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
    }
});

apiClient.interceptors.request.use(
    (config) => {
        const accessToken = useTokenStore.getState().getAccessToken();
        if (accessToken) {
            config.headers.Authorization = `Bearer ${accessToken}`;
        }
        return config;
    },
    (error) => {
        return Promise.reject(error);
    }
);

apiClient.interceptors.response.use(
    (response) => {
        const accessToken = response.headers['access-token']
        if (accessToken) {
            useTokenStore.getState().setAccessToken(accessToken);
        }
        return response;
    },
    (error) => {
        if (error.response.status === 401) {
            useTokenStore.getState().clearAccessToken();
            window.location.href = '/login';
        }
           return error;
    }
);

export default apiClient;