import { useQuery } from '@tanstack/react-query';
import { getDefinitions } from '@/service';
import { ConnectorDefinitionResponse, APIError } from '@/types/connector';

export const CACHE_TIME = 1000 * 60 * 60; // 1 hour

interface ConnectionProperty {
    type: string;
    title: string;
    description: string;
    minLength?: number;
    pattern?: string;
}

interface ConnectionSpecification {
    $schema: string;
    type: string;
    title: string;
    description: string;
    properties: {
        name: ConnectionProperty;
        description: ConnectionProperty;
        personalAccessToken: ConnectionProperty;
        repository: ConnectionProperty;
    };
    required: string[];
}

export interface Definition {
    name: string;
    integration_type: string;
    language: 'ruby';
    class_name: string;
    operations: Array<'connect' | 'read' | 'write'>;
    definition_status: 'certified';
    version: string;
    maintainer: string;
    icon_url: string;
    connection_specification: ConnectionSpecification;
}

export function useDefinitionQuery() {
    const query = useQuery({
        queryKey: ['definitions'],
        queryFn: async () => {
            const response = await getDefinitions();
            return response.data;
        },
        staleTime: 5 * 60 * 1000,
        refetchOnMount: false,
        refetchOnWindowFocus: false
    });

    return query;
}

