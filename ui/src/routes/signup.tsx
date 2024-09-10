import { createFileRoute } from '@tanstack/react-router';
import Header from '@/components/Header';
import Footer from '@/components/Footer';
import AuthForm from '../components/AuthForm';

export const Route = createFileRoute('/signup')({
    component: SignUpComponent
});

export function SignUpComponent() {
    return (
        <div className='flex h-dvh flex-col justify-between overflow-hidden"'>
            <Header />
            <AuthForm
                login={false}
                onLogIn={() => {
                    /* Handle login */
                }}
                onTerms={() => {
                    /* Handle terms */
                }}
                onPrivacyPolicy={() => {
                    /* Handle privacy policy */
                }}
            />
            <Footer />
        </div>
    );
}
