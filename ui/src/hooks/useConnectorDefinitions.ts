import { useQuery } from '@tanstack/react-query';
import { getDefinitions } from '@/service';

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
    type: string;
    language: 'ruby';
    class_name: string;
    operations: Array<'connect' | 'read' | 'write'>;
    definition_status: 'certified';
    version: string;
    maintainer: string;
    icon_url: string;
    connection_specification: ConnectionSpecification;
}
export const useDefinitionQuery = () => {
    return useQuery<Definition[], Error>({
        queryKey: ['definitions'],
        queryFn: async () => {
            try {
                const { data } = await getDefinitions();
                console.log('data ', data)
                if (!data) {
                    throw new Error('Failed to fetch definitions');
                }
                return data;
            } catch (error) {
                throw new Error(error instanceof Error ? error.message : 'Error fetching definitions');
            }
        },
        staleTime: CACHE_TIME,
        cacheTime: CACHE_TIME,
        refetchOnMount: false,
        refetchOnWindowFocus: false,
        retry: 1
    });
};

