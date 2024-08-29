import axios, { AxiosInstance, AxiosRequestConfig, AxiosResponse, AxiosError } from 'axios';
import { useAuthStore } from '../store/authStore';

const { VITE_API_BASE_URL } = import.meta.env;

const apiClient: AxiosInstance = axios.create({
    baseURL: VITE_API_BASE_URL,
    headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json'
    }
});

// apiClient.interceptors.request.use(
//     (config) => {
//         if (config.url !== '/auth' &&  config.url !== '/auth/sign_in') {
//         const token = useAuthStore.getState().getAccessToken();
//         const {accessToken, uid,  client} = token?.accessToken
//         if (accessToken && uid && client) {
//             config.headers['access-token'] = token.accessToken;
//             config.headers['uid'] = token.uid;
//             config.headers['client'] = token.client;
//         }
//     }
//         return config
//     }
// );
// apiClient.interceptors.response.use(
//   (response) => {
//     // Check if this is a login response
//     if (response.config.url === '/auth/sign_in') {
//         useAuthStore.getState().clearAccessToken();
//         const accessToken = response.headers['access-token'];
//         const uid = response.headers['uid'];
//         const client = response.headers['client'];
//         if (accessToken && uid && client) {
//             const token: Token = {
//                 accessToken,
//                 uid,
//                 client

//             }
//             useAuthStore.getState().setAccessToken(token);
//         }
//     }
//     if (response.config.url === '/auth/sign_up' || response.config.url === '/auth/sign_out') {
//         useAuthStore.getState().clearAccessToken();
//     }

//     return response;
//   },
//   (error: AxiosError) => {
//     return Promise.reject(error);
//   }
// );

apiClient.interceptors.request.use((config: AxiosRequestConfig) => {
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
