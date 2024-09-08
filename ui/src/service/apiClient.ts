import axios, { AxiosInstance, InternalAxiosRequestConfig, AxiosResponse } from 'axios';
import useAuthStore from '../store/authStore';

const { VITE_API_BASE_URL } = import.meta.env;

const apiClient: AxiosInstance = axios.create({
    baseURL: VITE_API_BASE_URL,
    headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json'
    }
});

apiClient.interceptors.request.use((config: InternalAxiosRequestConfig) => {
    const { accessToken, uid, client } = useAuthStore.getState();
    const isAuthRoute = ['/auth', '/auth/sign_in'].includes(config.url || '');

    if (accessToken && uid && client && !isAuthRoute) {
        config.headers['access-token'] = accessToken;
        config.headers['uid'] = uid;
        config.headers['client'] = client;
    }

    return config;
});

apiClient.interceptors.response.use((response: AxiosResponse) => {
    const accessToken = response.headers['access-token'];
    const uid = response.headers['uid'];
    const client = response.headers['client'];

    if (accessToken && uid && client) {
        useAuthStore.getState().setAuthData(accessToken, uid, client);
    }

    return response;
});

export default apiClient;
