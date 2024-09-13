import React from 'react';
import { z } from 'zod';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Input } from '@/components/ui/input';
import {
    Form,
    FormControl,
    FormField,
    FormItem,
    FormLabel,
    FormMessage
} from '@/components/ui/form';
import { ConnectorSchema } from '@/lib/schema';
import { connectorFields } from '@/constants/constants';

export interface ConnectorFormProps {
    data: object;
}
const ConnectorForm: React.FC<ConnectorFormProps> = () => {
    const form = useForm<z.infer<typeof ConnectorSchema>>({
        resolver: zodResolver(ConnectorSchema),
        defaultValues: {
            name: '',
            description: '',
            personal_access_token: '',
            repository: ''
        }
    });

    return (
        <div className="flex flex-col w-full px-10">
            <Form {...form}>
                <form className="flex flex-col w-full">
                    {connectorFields.map((input, index) => (
                        <FormField
                            key={index}
                            control={form.control}
                            name={input?.label?.toLocaleLowerCase()}
                            render={({ field }) => (
                                <FormItem className="flex mt-6 flex-col items-start self-stretch">
                                    <FormLabel className="text-sm font-semibold tracking-tighter">
                                        {input.label}
                                    </FormLabel>
                                    <FormControl>
                                        <>
                                        <Input className="text-sm my-2.5 font-normal" {...field} />
                                        <p className="font-normal text-xs fold-semibold text-slate-500">
                                            {input.placeholder}
                                        </p>
                                        </>
                                       
                                    </FormControl>
                                    <FormMessage />
                                </FormItem>
                            )}
                        />
                    ))}
                </form>
            </Form>
        </div>
    );
};

export default ConnectorForm;
