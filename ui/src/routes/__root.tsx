import { Outlet, createRootRouteWithContext, redirect } from '@tanstack/react-router';
import { Toaster } from '@/components/ui/toaster';
import { AuthContext } from '../store/authStore';
import { RouterContext } from '../types/types';
import '../index.css';

type RouterContext = {
    authentication: AuthContext;
};

export const Route = createRootRouteWithContext<RouterContext>()({
    component: RootLayout,
    beforeLoad: async ({ context }) => {
        const { isAuthenticated } = context.auth;
        console.log(isAuthenticated);
        if (!isAuthenticated) {
            throw redirect({
                to: '/login'
            });
        }
    },
    notFoundComponent: () => {
        return (
            <p className="flex h-dvh w-full items-center justify-center bg-background text-foreground">
                <div className="flex items-center space-x-3">
                    <h1 className="text-2xl">404</h1>
                    <span className="h-10 w-px bg-accent" />
                    <span className="text-sm">This page could not be found</span>
                </div>
            </p>
        );
    }
});

export default function RootLayout() {
    return (
        <>
            <Outlet />
            <Toaster />
        </>
    );
}
