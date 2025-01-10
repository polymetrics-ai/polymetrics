import { createFileRoute, redirect } from '@tanstack/react-router';
import useAuthStore from '@/store/authStore';

export const Route = createFileRoute('/')({
    beforeLoad: async () => {
        const { isAuthenticated } = useAuthStore.getState();
        
        if (isAuthenticated) {
            throw redirect({
                to: '/dashboard'
            });
        } else {
            throw redirect({
                to: '/login'
            });
        }
    }
});
