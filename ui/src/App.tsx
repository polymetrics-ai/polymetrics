import { RouterProvider, createRouter } from '@tanstack/react-router';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import useAuthStore from './store/authStore';
import { routeTree } from './routeTree.gen';

//Setting up a router instance
const router = createRouter({
    routeTree,
    context: {
        auth: undefined!
    }
});

// Create a client
const queryClient = new QueryClient();

declare module '@tanstack/react-router' {
    interface Register {
        router: typeof router;
    }
}

function App() {
    const auth = useAuthStore();
    return (
        <QueryClientProvider client={queryClient}>
            <RouterProvider router={router} context={{ auth }} />
        </QueryClientProvider>
    );
}

export default App;
