import { z } from 'zod';

export const LoginSchema = z.object({
    email: z.string().email(),
    password: z.string()
});

//Extending Login Schema as Signup contains login params
export const SignUpSchema = LoginSchema.extend({
    organization_name: z.string(),
    name: z.string(),
    password_confirmation: z.string()
});

export const ConnectorSchema = z.object({
    name: z.string(),
    description: z.string(),
    personal_access_token: z.string(),
    repository: z.string()
});
