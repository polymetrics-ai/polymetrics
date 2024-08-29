import { createFileRoute, redirect } from '@tanstack/react-router';

export const Route = createFileRoute('/')({
  beforeLoad: async ({ context }) => {
    const { isAuthenticated } = context.auth;
    console.log(isAuthenticated);
    if (isAuthenticated) {
        throw redirect({
            to: '/dashboard'
        });
    }
}
});
