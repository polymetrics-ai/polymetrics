import { z } from 'zod';

export const LoginSchema = z.object({
    email: z.string().email(),
    password: z.string()
});

//Extending Login Schema as Signup contains login params
export const SignUpSchema = LoginSchema.extend({
    organization_name: z.string(),
    name: z.string().min(2).max(70),
    password_confirmation: z.string()
});

export const ConnectorSchema = z.object({
    name: z.string().min(2).max(70),
    description: z.string(),
    personal_access_token: z
        .string()
        .regex(/^github_pat_[a-zA-Z0-9]{22}_[a-zA-Z0-9]{59}$/, 'This is an invalid Github PAT'),
    repository: z
        .string()
        .regex(/^[a-zA-Z0-9_.-]+\/[a-zA-Z0-9_.-]+$/, 'This is an invalid Github Repository Name')
});
