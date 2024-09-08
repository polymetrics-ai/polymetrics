export const loginFields = [
    { label: 'Email', field: 'email', placeholder: 'Enter your email' },
    { label: 'Password', field: 'password', placeholder: 'Enter your password' }
];
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

export const MENU_ICONS = {
    routeIcons: [
        {
            label: 'Dashboard',
            value: '/dashboard',
            icon: '/icon-dashboard.svg',
            className: ''
        },
        {
            label: 'Charts',
            value: '/charts',
            icon: '/icon-charts.svg',
            className: ''
        },
        {
            label: 'Connectors',
            value: '/connectors',
            icon: '/icon-connectors.svg',
            className: ''
        },
        {
            label: 'Connections',
            value: '/connections',
            icon: '/icon-connections.svg',
            className: ''
        }
    ],
    userIcons: [
        {
            label: 'Settings',
            value: '',
            icon: '/icon-settings.svg',
            className: ''
        },
        {
            label: 'Documentation',
            value: '',
            icon: '/icon-documentation.svg',
            className: ''
        },
        {
            label: 'Logout',
            value: '',
            icon: '/icon-avatar.svg',
            className: 'hover:bg-transparent'
        }
    ]
};

export const menuIconsType = typeof MENU_ICONS;
