// src/stores/authStore.ts
import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { AuthState } from '@/types/user';

export const useAuthStore = create<AuthState>()(
    persist(
        (set, get) => ({
            accessToken: null,
            uid: null,
            client: null,
            isAuthenticated: false,
            setAuthData: (accessToken: string, uid: string, client: string) =>
                set({ accessToken, uid, client, isAuthenticated: true }),
            clearAuthData: () =>
                set({ accessToken: null, uid: null, client: null, isAuthenticated: false }),
            hasValidAuthData: () => {
                const { accessToken, uid, client } = get();
                return !!(accessToken && uid && client);
            }
        }),
        {
            name: 'auth-storage'
        }
    )
);

export type AuthContext = ReturnType<typeof useAuthStore>;

export default useAuthStore;
