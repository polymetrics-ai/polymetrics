/** Fields for login **/
export const loginFields = [
    { label: 'Email', field: 'email', placeholder: 'Enter your email' },
    { label: 'Password', field: 'password', placeholder: 'Enter your password' }
];
/** Fields for Signup **/
export const signUpFields = [
    { label: 'Organisation', field: 'organization_name', placeholder: 'Enter your company name' },
    { label: 'Name', field: 'name', placeholder: 'Enter your name' },
    { label: 'Email', field: 'email', placeholder: 'Enter your email' },
    { label: 'Password', field: 'password', placeholder: 'Enter your password' },
    {
        label: 'Confirm Password',
        field: 'password_confirmation',
        placeholder: 'Enter your password again'
    }
];
/** NavBar Icons**/
export const NAV_ICONS = {
    routeIcons: [
        {
            label: 'Dashboard',
            value: '/dashboard',
            icon: '/icon-dashboard.svg'
        },
        {
            label: 'Charts',
            value: '/charts',
            icon: '/icon-charts.svg'
        },
        {
            label: 'Connectors',
            value: '/connectors',
            icon: '/icon-connectors.svg'
        },
        {
            label: 'Connections',
            value: '/connections',
            icon: '/icon-connections.svg'
        }
    ],
    userIcons: [
        {
            label: 'Settings',
            value: '/settings',
            icon: '/icon-settings.svg'
        },
        {
            label: 'Documentation',
            value: '/documentation',
            icon: '/icon-documentation.svg'
        },
        {
            label: 'Logout',
            value: '',
            icon: '/icon-avatar.svg'
        }
    ]
};

export const menuIconsType = typeof NAV_ICONS;

export const CONNECTORS_LIST = [
    {
        name: 'Github',
        icon: '/connectors/github.svg'
    },
    {
        name: 'Duck DB',
        icon: '/connectors/duckdb.svg'
    },
    {
        name: 'Salesforce CRM',
        icon: '/connectors/salesforce.svg'
    },
    {
        name: 'LinkedIn Ads',
        icon: '/connectors/linkedin.svg'
    },
    {
        name: 'Facebook Marketing',
        icon: '/connectors/facebook.svg'
    },
    {
        name: 'Tiktok Marketing',
        icon: '/connectors/tiktok.svg'
    },
    {
        name: 'Stripe',
        icon: '/connectors/stripe.svg'
    },
    {
        name: 'Braze',
        icon: '/connectors/braze.svg'
    },
    {
        name: 'ClickUp',
        icon: '/connectors/clickup.svg'
    },
    {
        name: 'Google Analytics 4 (GA4) aaaaaaaaaaaaaaaaaaaaaaaa',
        icon: '/connectors/google-analytics.svg'
    },
    {
        name: 'Facebook Marketing',
        icon: '/connectors/facebook.svg'
    },
    {
        name: 'Klaviyo',
        icon: '/connectors/klaviyo.svg'
    },
    {
        name: 'Google Ads',
        icon: '/connectors/google-ads.svg'
    }
];

export const connectorFields = [
    { label: 'Name', field: 'name', placeholder: 'Add Name for the Connector' },
    {
        label: 'Description',
        field: 'description',
        placeholder: 'Add Description for the Connector'
    },
    { label: 'Personal Access Token', field: 'personal_access_token', placeholder: '' },
    {
        label: 'Respository',
        field: 'repository',
        placeholder: 'Repository name should follow the pattern */* i.e rails/rails'
    }
];

export const connectorSteps = [
    {
        id: 'choose-connector',
        title: 'Choose connector',
        description: 'Lorem ispsum something about connectors'
    },
    {
        id: 'configure-connector',
        title: 'Configure connector',
        description: 'Lorem ispsum something about connectors'
    },
];
