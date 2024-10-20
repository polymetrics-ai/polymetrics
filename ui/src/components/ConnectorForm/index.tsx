import React, { forwardRef, useImperativeHandle } from 'react';
import { z } from 'zod';
import { zodResolver } from '@hookform/resolvers/zod';
import { useForm, UseFormReturn } from 'react-hook-form';
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

export interface ConnectorFormRef {
    submitForm: () => void;
}
export interface ConnectorFormProps {
    form: UseFormReturn<z.infer<typeof ConnectorSchema>>; // Update type here
    // ref: React.Ref<HTMLFormElement>
    onSubmit?: (data: z.infer<typeof ConnectorSchema>) => void;
    setIsDisabled: () => void;
}
const ConnectorForm: React.FC<ConnectorFormProps> = forwardRef(({ form, onSubmit }, ref) => {
    useImperativeHandle(ref, () => ({
        submitForm: () => form.handleSubmit(onSubmit)()
    }));

    return (
        <div className="flex flex-col w-full px-10">
            <Form {...form}>
                <form className="flex flex-col w-full" onSubmit={form.handleSubmit(onSubmit)}>
                    {connectorFields.map((input, index) => (
                        <FormField
                            key={index}
                            control={form.control}
                            name={input.field || input.label?.toLowerCase()}
                            render={({ field }) => (
                                <FormItem className="flex mt-6 flex-col items-start self-stretch">
                                    <FormLabel className="text-sm font-semibold tracking-tighter">
                                        {input.label}
                                    </FormLabel>
                                    <FormControl>
                                        <>
                                            <Input
                                                className="text-sm my-2.5 font-normal"
                                                {...field}
                                            />
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
});

export default ConnectorForm;
