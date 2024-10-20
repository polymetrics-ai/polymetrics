export interface githubConfig {
    repository: string;
    personal_access_token: string;
}

// export interface githubConnector {
//     connector: {
//         configuration: githubConfig,
//         name: string;
//         connector_class_name: string;
//         description: string;
//         connector_language: string;
//     }
// }

export interface postConnectorPayload {
    connector: {
        configuration: githubConfig;
        name: string;
        connector_class_name: string;
        description: string;
        connector_language: string;
    };
}
