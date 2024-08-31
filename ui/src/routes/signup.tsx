import { createFileRoute } from '@tanstack/react-router';
import Header from '@/components/Header';
import Footer from '@/components/Footer';
import SignUpForm from '../components/SignUpForm';

export const Route = createFileRoute('/signup')({
    component: SignUpComponent
});

export function SignUpComponent() {
    return (
        <div className='flex h-dvh flex-col justify-between overflow-hidden"'>
            <Header />
            <SignUpForm
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
