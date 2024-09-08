import React from 'react';
import { z } from 'zod';
import { zodResolver } from '@hookform/resolvers/zod';
import { useForm } from 'react-hook-form';
import { useNavigate } from '@tanstack/react-router';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import {
    Form,
    FormControl,
    FormField,
    FormItem,
    FormLabel,
    FormMessage
} from '@/components/ui/form';
import { loginFields, signUpFields } from '@/constants/constants';
import { user } from '@/service';
import { SignUpCredentials, SignInCredentials } from '@/types/user';
import { AxiosResponse, AxiosError } from 'axios';

interface AuthFormProps {
    login: boolean;
    onToggle: () => void;
    onForgotPassword?: () => void;
    onTerms?: () => void;
    onPrivacyPolicy?: () => void;
}

const AuthForm: React.FC<AuthFormProps> = ({
    login,
    onToggle,
    onForgotPassword,
    onTerms,
    onPrivacyPolicy
}) => {
    const navigate = useNavigate();

    const LoginSchema = z.object({
        email: z.string().email(),
        password: z.string()
    });

    const SignUpSchema = z.object({
        organization_name: z.string(),
        name: z.string(),
        email: z.string().email(),
        password: z.string(),
        password_confirmation: z.string()
    });

    const FormSchema = login ? LoginSchema : SignUpSchema;

    const form = useForm<z.infer<typeof FormSchema>>({
        resolver: zodResolver(FormSchema),
        defaultValues: login
            ? { email: '', password: '' }
            : {
                  organization_name: '',
                  name: '',
                  email: '',
                  password: '',
                  password_confirmation: ''
              }
    });

    const onSubmit = (data: z.infer<typeof FormSchema>) => {
        if (login) {
            user.signIn(data)
                .then(() => navigate({ to: '/dashboard', replace: true }))
                .catch((error: AxiosError) => {
                    if (error.status === 401) navigate({ to: '/login', replace: true });
                });
        } else {
            user.signUp(data)
                .then(() => navigate({ to: '/dashboard' }))
                .catch((error: AxiosError) => console.error('Signup error:', error));
        }
    };

    const fields = login ? loginFields : signUpFields;

    return (
        <div className="flex flex-col justify-center items-center">
            <main className="flex flex-col px-7 pt-8 pb-7 box-border border border-solid bg-slate-50 border-slate-200 max-w-[480px] z-10 absolute">
                <div className="flex flex-col justify-center items-center self-center max-w-full text-center w-[26.5rem]">
                    <h1 className="text-xl text-center font-semibold tracking-normal leading-7 text-slate-800">
                        {login ? 'Welcome back' : 'Get started with Polymetrics'}
                    </h1>
                    <p className="mt-1 text-sm text-center tracking-normal leading-none text-slate-400">
                        {login
                            ? 'Enter your details to log in to your account'
                            : 'Sign up and create your account'}
                    </p>
                </div>
                <Form {...form}>
                    <form className="flex flex-col mt-8 w-full">
                        {fields.map((input, index) => (
                            <FormField
                                key={index}
                                control={form.control}
                                name={input.field || input.label?.toLowerCase()}
                                render={({ field }) => (
                                    <FormItem className="flex flex-col mb-4 items-start self-stretch">
                                        <FormLabel className="mb-2 text-sm font-semibold tracking-tighter">
                                            {input.label}
                                        </FormLabel>
                                        <FormControl>
                                            <Input
                                                className="text-sm font-normal"
                                                placeholder={input.placeholder}
                                                {...field}
                                            />
                                        </FormControl>
                                        <FormMessage />
                                    </FormItem>
                                )}
                            />
                        ))}
                        {login && (
                            <div className="flex justify-end items-end mb-8 w-full text-xs tracking-normal">
                                <Button
                                    variant="link"
                                    onClick={onForgotPassword}
                                    className="text-xs font-semibold cursor-pointer self-end p-0 h-4.5"
                                >
                                    Forgot Password?
                                </Button>
                            </div>
                        )}
                        {!login && (
                            <div className="flex justify-start items-start mb-8 w-full text-xs tracking-normall leading-5 text-emerald-600">
                                <p className="gap-2 self-stretch my-auto min-w-[240px]">
                                    <span className="text-slate-500">
                                        By creating an account, I agree to the{' '}
                                    </span>
                                    <Button
                                        variant="link"
                                        onClick={onTerms}
                                        className="text-xs font-semibold cursor-pointer self-end p-0 h-4.5 text-emerald-600"
                                    >
                                        Terms
                                    </Button>
                                    <span className="text-slate-500"> and </span>
                                    <Button
                                        variant="link"
                                        onClick={onPrivacyPolicy}
                                        className="text-xs font-semibold cursor-pointer self-end p-0 h-4.5 text-emerald-600"
                                    >
                                        Privacy Policy
                                    </Button>
                                </p>
                            </div>
                        )}
                        <Button className="mb-6" onClick={form.handleSubmit(onSubmit)}>
                            {login ? 'Log in' : 'Sign Up'}
                        </Button>
                        <div className="flex gap-1 h-2 justify-center items-center w-full p-0 my-auto text-xs tracking-normal self-stretch">
                            <p className="text-slate-600">
                                {login ? "Don't have an account?" : 'Do you have an account?'}
                            </p>
                            <Button variant="link" className="text-xs" onClick={onToggle}>
                                {login ? 'Sign up' : 'Log In'}
                            </Button>
                        </div>
                    </form>
                </Form>
            </main>
            <div className="relative top-44 z-0 scale-90">
                <img src="/bg-connector-illustration.svg" alt="Connectors" className="" />
            </div>
        </div>
    );
};

export default AuthForm;
