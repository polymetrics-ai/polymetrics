import { createFileRoute } from '@tanstack/react-router';
import Header from '@/components/Header';
import Footer from '@/components/Footer';
import LoginForm from '../components/LoginForm';

export const Route = createFileRoute('/login/')({
    component: LoginComponent
});

export function LoginComponent() {
    return (
        <div className='flex h-dvh flex-col justify-between overflow-hidden"'>
            <Header />
            <LoginForm />
            <Footer />
        </div>
    );
}
