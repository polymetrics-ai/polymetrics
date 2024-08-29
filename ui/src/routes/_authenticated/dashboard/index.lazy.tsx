import { createLazyFileRoute } from '@tanstack/react-router';

export const Route = createLazyFileRoute('/_authenticated/dashboard/')({
    component: () => <div>Hello /_authenticated/dashboard/!</div>
});
