import React from 'react';
import { useForm } from 'react-hook-form';
import { useNavigate } from '@tanstack/react-router';
import { z } from 'zod';
import { zodResolver } from '@hookform/resolvers/zod';
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
import apiClient from '@/service/apiClient';
import { AxiosResponse, AxiosError } from 'axios';
import { signUpFields } from '@/constants/constants';

interface SignUpProps {
    onLogIn: () => void;
    onTerms: () => void;
    onPrivacyPolicy: () => void;
}

const FormSchema = z.object({
    organization_name: z.string(),
    name: z.string(),
    email: z.string().email(),
    password: z.string(),
    password_confirmation: z.string()
});

const SignUp: React.FC<SignUpProps> = ({ onLogIn, onTerms, onPrivacyPolicy }) => {
    const navigate = useNavigate();

    const form = useForm<z.infer<typeof FormSchema>>({
        resolver: zodResolver(FormSchema),
        defaultValues: {
            organization_name: '',
            name: '',
            email: '',
            password: '',
            password_confirmation: ''
        }
    });

    const onSignUp = (data: z.infer<typeof FormSchema>) => {
        const payload = {
            ...data
        };

        apiClient
            .post('/auth', payload)
            .then((response: AxiosResponse) => {
                navigate({ to: '/login' });
            })
            .catch((error: AxiosError) => {
                console.error('Login error:', error);
            });
    };

    return (
        <div className="flex flex-col justify-center items-center">
            <main className="flex flex-col px-7 pt-8 pb-7 box-border border border-solid bg-slate-50 border-slate-200 max-w-[480px] z-10 absolute">
                <header className="flex flex-col justify-center items-center self-center max-w-full text-center w-[26.5rem]">
                    <h1 className="text-xl text-center font-semibold tracking-normal leading-7 text-slate-800">
                        Get started with Polymetrics
                    </h1>
                    <p className="mt-1 text-sm text-center tracking-normal leading-none text-slate-400">
                        Sign up and create your account
                    </p>
                </header>
                <Form {...form}>
                    <form className="flex flex-col mt-8 w-full">
                        {signUpFields.map((input, index) => (
                            <FormField
                                key={index}
                                control={form.control}
                                name={input?.field?.toLocaleLowerCase()}
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
                        <Button className="mb-6" onClick={form.handleSubmit(onSignUp)}>
                            Sign Up
                        </Button>
                        <div className="flex gap-1 h-2 justify-center items-center w-full p-0 my-auto text-xs tracking-normal self-stretch">
                            <p className="text-slate-600">Do you have an account?</p>
                            <Button variant="link" className="p-0 text-xs" onClick={onLogIn}>
                                Log In
                            </Button>
                        </div>
                    </form>
                </Form>
            </main>
            <div className="relative top-44 z-0 scale-90">
                <img src="/bg-connector-illustration.svg" alt="Connectors" />
            </div>
        </div>
    );
};

export default SignUp;
