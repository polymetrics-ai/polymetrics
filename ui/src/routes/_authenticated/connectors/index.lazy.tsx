import { createLazyFileRoute } from '@tanstack/react-router';

export const Route = createLazyFileRoute('/_authenticated/connectors/')({
    component: () => <div>Hello /_authenticated/connectors/!</div>
});
