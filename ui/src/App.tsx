import { RouterProvider, createRouter } from '@tanstack/react-router';
import useAuthStore from './store/authStore';
import { routeTree } from './routeTree.gen';

//Setting up a router instance
const router = createRouter({
    routeTree,
    context: {
        auth: undefined!
    }
});

declare module '@tanstack/react-router' {
    interface Register {
        router: typeof router;
    }
}

function App() {
    const auth = useAuthStore();
    return <RouterProvider router={router} context={{ auth }} />;
}

export default App;
