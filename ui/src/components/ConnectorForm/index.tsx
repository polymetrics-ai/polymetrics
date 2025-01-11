import React, { forwardRef, useImperativeHandle } from 'react';
import { withTheme } from '@rjsf/core';
import validator from '@rjsf/validator-ajv8';
import { RJSFSchema } from '@rjsf/utils';
import { Definition } from '@/hooks/useConnectorDefinitions';
import { generateForm } from '@/components/rjsf';
import { IChangeEvent } from '@rjsf/core';

const Form = generateForm();

export interface ConnectorFormRef {
    submitForm: () => void;
}

interface ConnectorFormProps {
    definition: Definition;
    onSubmit: (data: any) => void;
    readOnly?: boolean;
    ref: any;
    connectorData?: any;
}

const ConnectorForm = forwardRef<ConnectorFormRef, ConnectorFormProps>(
    ({ definition, onSubmit, readOnly = false, connectorData }, ref) => {
        const { connection_specification } = definition;
        const formRef = React.useRef<any>();


        useImperativeHandle(ref, () => ({
            submitForm: () => {
                formRef.current.submit();
            },
        }));
        
        const handleSubmit = (data: IChangeEvent<any, RJSFSchema, any>) => {
            onSubmit(data.formData);
        };

        if (!connection_specification) {
            return (
                <div className="flex flex-col items-center justify-center p-8">
                    <p className="text-slate-600">
                        This connector is coming soon. Configuration is not available yet.
                    </p>
                </div>
            );
        }

        const formData = connectorData?.configuration || {};

        return (
            <div className="flex flex-col w-full px-10 overflow-y-auto">
                <Form
                    ref={formRef}
                    schema={connection_specification as RJSFSchema}
                    validator={validator}
                    formData={formData}
                    onSubmit={handleSubmit}
                    uiSchema={{
                        "ui:submitButtonOptions": {
                            norender: true,
                        },
                        "ui:readonly": readOnly
                    }}
                />
            </div>
        );
    }
);

ConnectorForm.displayName = 'ConnectorForm';

export default ConnectorForm;