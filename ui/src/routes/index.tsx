import { createFileRoute, redirect } from '@tanstack/react-router';
import useAuthStore from '@/store/authStore'; // Removed AuthContext as it's unused

export const Route = createFileRoute('/')({
    beforeLoad: async () => {
        const { isAuthenticated } = useAuthStore.getState();
        console.log(isAuthenticated);
        if (isAuthenticated) {
            throw redirect({
                to: '/dashboard'
            });
        }
    }
});
