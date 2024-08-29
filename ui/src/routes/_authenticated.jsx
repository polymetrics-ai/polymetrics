import { createFileRoute, Outlet, redirect } from '@tanstack/react-router';

export const Route = createFileRoute('/_authenticated')({
    beforeLoad: async ({ context }) => {
        const { isAuthenticated } = context.auth;
        console.log(isAuthenticated);
        if (!isAuthenticated) {
            throw redirect({
                to: '/login'
            });
        }
    }
});
