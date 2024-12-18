import React from 'react';
import {
    createFileRoute,
    Outlet,
    redirect,
    useNavigate,
    useLocation
} from '@tanstack/react-router';
import useAuthStore from '@/store/authStore';
import NavBar from '@/components/NavBar';
import { Toaster } from '@/components/ui/toaster';
import { signOut } from '@/service';

export const Route = createFileRoute('/_authenticated')({
    component: AuthLayout,
    beforeLoad: async () => {
        const { isAuthenticated } = useAuthStore.getState();
        console.log(isAuthenticated);
        if (!isAuthenticated) {
            throw redirect({
                to: '/login'
            });
        }
    }
});

function AuthLayout() {
    const navigate = useNavigate();

    const onSignOut = () => {
        signOut()
            .then((resp) => {
                console.log(resp);
                if (resp) useAuthStore.getState().clearAuthData();
                navigate({ to: '/login' });
            })
            .catch((error) => {
                console.log(error);
                if (error?.status === 404) useAuthStore.getState().clearAuthData();
                navigate({ to: '/login' });
            });
    };

    return (
        <div className="h-dvh w-full flex">
            <NavBar onSignOut={onSignOut} />
            <Outlet />
        </div>
    );
}
