export interface AuthState {
    accessToken: string | null;
    uid: string | null;
    client: string | null;
    isAuthenticated: boolean;
    setAuthData: (accessToken: string, uid: string, client: string) => void;
    clearAuthData: () => void;
    hasValidAuthData: () => boolean;
}

export interface AUTH_ROUTES {
    SIGN_IN: '/auth';
    SIGN_UP: '/auth/sign_up';
    SIGN_OUT: '/auth/sign_out';
}
