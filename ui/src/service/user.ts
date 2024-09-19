import apiClient from './apiClient';
import { SignInCredentials, SignUpCredentials } from '../types/user';

const signIn = async (payload: SignInCredentials) => {
    return apiClient.post('/auth/sign_in', payload);
};

const signUp = async (payload: SignUpCredentials) => {
    return apiClient.post('/auth', payload);
};

const signOut = async () => {
    return apiClient.delete('/auth/sign_out');
};

export { signUp, signIn, signOut };
