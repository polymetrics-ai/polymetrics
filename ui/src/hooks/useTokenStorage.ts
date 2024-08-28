import { create } from 'zustand';
import { persist } from 'zustand/middleware'

interface TokenStore {
  accessToken: string | null;
  setAccessToken: (accessToken: string) => void;
  clearAccessToken: () => void;
  getAccessToken: () => string | null;
}

const useTokenStore = create<TokenStore>()(
  persist(
    (set, get) => ({
      accessToken: null,
      setAccessToken: (accessToken) => set({ accessToken }),
      clearAccessToken: () => set({ accessToken: null }),
      getAccessToken: () => get().accessToken,
    }),
    {
      name: 'token-storage',
      partialize: (state) => ({ accessToken: state.accessToken}),
    }
  )
);

export default useTokenStore;