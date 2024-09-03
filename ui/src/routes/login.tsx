import { createFileRoute, redirect } from '@tanstack/react-router';
import Header from '@/components/Header';
import Footer from '@/components/Footer';
import LoginForm from '../components/LoginForm';
import { AuthContext } from '@/store/authStore';
export const Route = createFileRoute('/login')({
    component: LoginComponent,
    beforeLoad: async ({ context }: { context: { auth: AuthContext } }) => {
        const { isAuthenticated } = context.auth;
        if (isAuthenticated) {
            throw redirect({
                to: '/dashboard'
            });
        }
    }
});

export function LoginComponent() {
    return (
        <div className='flex h-dvh flex-col justify-between overflow-hidden"'>
            <Header />
            <LoginForm
                onSignUp={() => {
                    /* Handle sign up */
                }}
                onForgotPassword={() => {
                    /* Handle forgot password */
                }}
            />
            <Footer />
        </div>
    );
}
