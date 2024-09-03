export interface AuthState {
    accessToken: string | null;
    uid: string | null;
    client: string | null;
    isAuthenticated: boolean;
    setAuthData: (accessToken: string, uid: string, client: string) => void;
    clearAuthData: () => void;
    hasValidAuthData: () => boolean;
}

export interface SignInCredentials {
    email: string;
    password: string;
}

export interface SignUpCredentials {
    organization_name: string;
    email: string;
    name: string;
    password: string;
    password_confirmation: string;
}
