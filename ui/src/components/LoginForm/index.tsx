import React from 'react';
import { useForm } from 'react-hook-form';
import { z } from 'zod';
import { zodResolver } from '@hookform/resolvers/zod';
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

import { AxiosResponse, AxiosError } from 'axios';
import { loginFields } from '@/constants/constants';
import { user } from '@/service';

interface LoginFormProps {
    onSignUp: () => void;
    onForgotPassword: () => void;
}

const FormSchema = z.object({
    email: z.string().email(),
    password: z.string()
});

const LoginForm: React.FC<LoginFormProps> = ({ onSignUp, onForgotPassword }) => {
    const navigate = useNavigate();

    const form = useForm<z.infer<typeof FormSchema>>({
        resolver: zodResolver(FormSchema),
        defaultValues: {
            name: '',
            description: '',
            personal_access_token: '',
            repository: ''
        }
    });

    const onLogin = (data: z.infer<typeof FormSchema>) => {
        const payload = {
            email: data.email,
            password: data.password
        };

        user.signIn(payload)
            .then((response: AxiosResponse) => {
                // useAuthStore.
                navigate({ to: '/dashboard', replace: true });
            })
            .catch((error: AxiosError) => {
                if (error.status === 401) navigate({ to: '/login', replace: true });
            });
    };

    return (
        <div className="flex flex-col justify-center items-center">
            <main className="flex flex-col px-7 pt-8 pb-7 box-border border border-solid bg-slate-50 border-slate-200 max-w-[480px] z-10 absolute">
                <div className="flex flex-col justify-center items-center self-center max-w-full text-center w-[26.5rem]">
                    <h1 className="text-xl text-center font-semibold tracking-normal leading-7 text-slate-800">
                        Welcome back
                    </h1>
                    <p className="mt-1 text-sm text-center tracking-normal leading-none text-slate-400">
                        Enter your details to log in to your account
                    </p>
                </div>
                <Form {...form}>
                    <form className="flex flex-col mt-8 w-full">
                        {loginFields.map((input, index) => (
                            <FormField
                                key={index}
                                control={form.control}
                                name={input?.label?.toLocaleLowerCase()}
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
                        <div className="flex justify-end items-end mb-8 w-full text-xs tracking-normal">
                            <Button
                                variant="link"
                                onClick={onForgotPassword}
                                className="text-xs font-semibold cursor-pointer self-end p-0 h-4.5"
                            >
                                Forgot Password?
                            </Button>
                        </div>
                        <Button className="mb-6" onClick={form.handleSubmit(onLogin)}>
                            Log in
                        </Button>
                        <div className="flex gap-1 h-2 justify-center items-center w-full p-0 my-auto text-xs tracking-normal self-stretch">
                            <p className="text-slate-600">Don't have an account?</p>
                            <Button variant="link" className="text-xs" onClick={onSignUp}>
                                Sign up
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

export default LoginForm;
