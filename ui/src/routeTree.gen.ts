/* prettier-ignore-start */

/* eslint-disable */

// @ts-nocheck

// noinspection JSUnusedGlobalSymbols

// This file is auto-generated by TanStack Router

import { createFileRoute } from '@tanstack/react-router'

// Import Routes

import { Route as rootRoute } from './routes/__root'
import { Route as SignupImport } from './routes/signup'
import { Route as LoginImport } from './routes/login'
import { Route as AuthenticatedImport } from './routes/_authenticated'
import { Route as IndexImport } from './routes/index'
import { Route as SignupIndexImport } from './routes/signup.index'
import { Route as LoginIndexImport } from './routes/login.index'

// Create Virtual Routes

const AuthenticatedSettingsIndexLazyImport = createFileRoute(
  '/_authenticated/settings/',
)()
const AuthenticatedDocumentationIndexLazyImport = createFileRoute(
  '/_authenticated/documentation/',
)()
const AuthenticatedDataAgentIndexLazyImport = createFileRoute(
  '/_authenticated/data-agent/',
)()
const AuthenticatedDashboardIndexLazyImport = createFileRoute(
  '/_authenticated/dashboard/',
)()
const AuthenticatedConnectorsIndexLazyImport = createFileRoute(
  '/_authenticated/connectors/',
)()
const AuthenticatedConnectionsIndexLazyImport = createFileRoute(
  '/_authenticated/connections/',
)()
const AuthenticatedChartsIndexLazyImport = createFileRoute(
  '/_authenticated/charts/',
)()
const AuthenticatedConnectorsNewLazyImport = createFileRoute(
  '/_authenticated/connectors/new',
)()
const AuthenticatedConnectorsIdLazyImport = createFileRoute(
  '/_authenticated/connectors/$id',
)()

// Create/Update Routes

const SignupRoute = SignupImport.update({
  path: '/signup',
  getParentRoute: () => rootRoute,
} as any)

const LoginRoute = LoginImport.update({
  path: '/login',
  getParentRoute: () => rootRoute,
} as any)

const AuthenticatedRoute = AuthenticatedImport.update({
  id: '/_authenticated',
  getParentRoute: () => rootRoute,
} as any)

const IndexRoute = IndexImport.update({
  path: '/',
  getParentRoute: () => rootRoute,
} as any)

const SignupIndexRoute = SignupIndexImport.update({
  path: '/',
  getParentRoute: () => SignupRoute,
} as any)

const LoginIndexRoute = LoginIndexImport.update({
  path: '/',
  getParentRoute: () => LoginRoute,
} as any)

const AuthenticatedSettingsIndexLazyRoute =
  AuthenticatedSettingsIndexLazyImport.update({
    path: '/settings/',
    getParentRoute: () => AuthenticatedRoute,
  } as any).lazy(() =>
    import('./routes/_authenticated/settings/index.lazy').then((d) => d.Route),
  )

const AuthenticatedDocumentationIndexLazyRoute =
  AuthenticatedDocumentationIndexLazyImport.update({
    path: '/documentation/',
    getParentRoute: () => AuthenticatedRoute,
  } as any).lazy(() =>
    import('./routes/_authenticated/documentation/index.lazy').then(
      (d) => d.Route,
    ),
  )

const AuthenticatedDataAgentIndexLazyRoute =
  AuthenticatedDataAgentIndexLazyImport.update({
    path: '/data-agent/',
    getParentRoute: () => AuthenticatedRoute,
  } as any).lazy(() =>
    import('./routes/_authenticated/data-agent/index.lazy').then(
      (d) => d.Route,
    ),
  )

const AuthenticatedDashboardIndexLazyRoute =
  AuthenticatedDashboardIndexLazyImport.update({
    path: '/dashboard/',
    getParentRoute: () => AuthenticatedRoute,
  } as any).lazy(() =>
    import('./routes/_authenticated/dashboard/index.lazy').then((d) => d.Route),
  )

const AuthenticatedConnectorsIndexLazyRoute =
  AuthenticatedConnectorsIndexLazyImport.update({
    path: '/connectors/',
    getParentRoute: () => AuthenticatedRoute,
  } as any).lazy(() =>
    import('./routes/_authenticated/connectors/index.lazy').then(
      (d) => d.Route,
    ),
  )

const AuthenticatedConnectionsIndexLazyRoute =
  AuthenticatedConnectionsIndexLazyImport.update({
    path: '/connections/',
    getParentRoute: () => AuthenticatedRoute,
  } as any).lazy(() =>
    import('./routes/_authenticated/connections/index.lazy').then(
      (d) => d.Route,
    ),
  )

const AuthenticatedChartsIndexLazyRoute =
  AuthenticatedChartsIndexLazyImport.update({
    path: '/charts/',
    getParentRoute: () => AuthenticatedRoute,
  } as any).lazy(() =>
    import('./routes/_authenticated/charts/index.lazy').then((d) => d.Route),
  )

const AuthenticatedConnectorsNewLazyRoute =
  AuthenticatedConnectorsNewLazyImport.update({
    path: '/connectors/new',
    getParentRoute: () => AuthenticatedRoute,
  } as any).lazy(() =>
    import('./routes/_authenticated/connectors/new.lazy').then((d) => d.Route),
  )

const AuthenticatedConnectorsIdLazyRoute =
  AuthenticatedConnectorsIdLazyImport.update({
    path: '/connectors/$id',
    getParentRoute: () => AuthenticatedRoute,
  } as any).lazy(() =>
    import('./routes/_authenticated/connectors/$id.lazy').then((d) => d.Route),
  )

// Populate the FileRoutesByPath interface

declare module '@tanstack/react-router' {
  interface FileRoutesByPath {
    '/': {
      id: '/'
      path: '/'
      fullPath: '/'
      preLoaderRoute: typeof IndexImport
      parentRoute: typeof rootRoute
    }
    '/_authenticated': {
      id: '/_authenticated'
      path: ''
      fullPath: ''
      preLoaderRoute: typeof AuthenticatedImport
      parentRoute: typeof rootRoute
    }
    '/login': {
      id: '/login'
      path: '/login'
      fullPath: '/login'
      preLoaderRoute: typeof LoginImport
      parentRoute: typeof rootRoute
    }
    '/signup': {
      id: '/signup'
      path: '/signup'
      fullPath: '/signup'
      preLoaderRoute: typeof SignupImport
      parentRoute: typeof rootRoute
    }
    '/login/': {
      id: '/login/'
      path: '/'
      fullPath: '/login/'
      preLoaderRoute: typeof LoginIndexImport
      parentRoute: typeof LoginImport
    }
    '/signup/': {
      id: '/signup/'
      path: '/'
      fullPath: '/signup/'
      preLoaderRoute: typeof SignupIndexImport
      parentRoute: typeof SignupImport
    }
    '/_authenticated/connectors/$id': {
      id: '/_authenticated/connectors/$id'
      path: '/connectors/$id'
      fullPath: '/connectors/$id'
      preLoaderRoute: typeof AuthenticatedConnectorsIdLazyImport
      parentRoute: typeof AuthenticatedImport
    }
    '/_authenticated/connectors/new': {
      id: '/_authenticated/connectors/new'
      path: '/connectors/new'
      fullPath: '/connectors/new'
      preLoaderRoute: typeof AuthenticatedConnectorsNewLazyImport
      parentRoute: typeof AuthenticatedImport
    }
    '/_authenticated/charts/': {
      id: '/_authenticated/charts/'
      path: '/charts'
      fullPath: '/charts'
      preLoaderRoute: typeof AuthenticatedChartsIndexLazyImport
      parentRoute: typeof AuthenticatedImport
    }
    '/_authenticated/connections/': {
      id: '/_authenticated/connections/'
      path: '/connections'
      fullPath: '/connections'
      preLoaderRoute: typeof AuthenticatedConnectionsIndexLazyImport
      parentRoute: typeof AuthenticatedImport
    }
    '/_authenticated/connectors/': {
      id: '/_authenticated/connectors/'
      path: '/connectors'
      fullPath: '/connectors'
      preLoaderRoute: typeof AuthenticatedConnectorsIndexLazyImport
      parentRoute: typeof AuthenticatedImport
    }
    '/_authenticated/dashboard/': {
      id: '/_authenticated/dashboard/'
      path: '/dashboard'
      fullPath: '/dashboard'
      preLoaderRoute: typeof AuthenticatedDashboardIndexLazyImport
      parentRoute: typeof AuthenticatedImport
    }
    '/_authenticated/data-agent/': {
      id: '/_authenticated/data-agent/'
      path: '/data-agent'
      fullPath: '/data-agent'
      preLoaderRoute: typeof AuthenticatedDataAgentIndexLazyImport
      parentRoute: typeof AuthenticatedImport
    }
    '/_authenticated/documentation/': {
      id: '/_authenticated/documentation/'
      path: '/documentation'
      fullPath: '/documentation'
      preLoaderRoute: typeof AuthenticatedDocumentationIndexLazyImport
      parentRoute: typeof AuthenticatedImport
    }
    '/_authenticated/settings/': {
      id: '/_authenticated/settings/'
      path: '/settings'
      fullPath: '/settings'
      preLoaderRoute: typeof AuthenticatedSettingsIndexLazyImport
      parentRoute: typeof AuthenticatedImport
    }
  }
}

// Create and export the route tree

export const routeTree = rootRoute.addChildren({
  IndexRoute,
  AuthenticatedRoute: AuthenticatedRoute.addChildren({
    AuthenticatedConnectorsIdLazyRoute,
    AuthenticatedConnectorsNewLazyRoute,
    AuthenticatedChartsIndexLazyRoute,
    AuthenticatedConnectionsIndexLazyRoute,
    AuthenticatedConnectorsIndexLazyRoute,
    AuthenticatedDashboardIndexLazyRoute,
    AuthenticatedDataAgentIndexLazyRoute,
    AuthenticatedDocumentationIndexLazyRoute,
    AuthenticatedSettingsIndexLazyRoute,
  }),
  LoginRoute: LoginRoute.addChildren({ LoginIndexRoute }),
  SignupRoute: SignupRoute.addChildren({ SignupIndexRoute }),
})

/* prettier-ignore-end */

/* ROUTE_MANIFEST_START
{
  "routes": {
    "__root__": {
      "filePath": "__root.tsx",
      "children": [
        "/",
        "/_authenticated",
        "/login",
        "/signup"
      ]
    },
    "/": {
      "filePath": "index.tsx"
    },
    "/_authenticated": {
      "filePath": "_authenticated.jsx",
      "children": [
        "/_authenticated/connectors/$id",
        "/_authenticated/connectors/new",
        "/_authenticated/charts/",
        "/_authenticated/connections/",
        "/_authenticated/connectors/",
        "/_authenticated/dashboard/",
        "/_authenticated/data-agent/",
        "/_authenticated/documentation/",
        "/_authenticated/settings/"
      ]
    },
    "/login": {
      "filePath": "login.tsx",
      "children": [
        "/login/"
      ]
    },
    "/signup": {
      "filePath": "signup.tsx",
      "children": [
        "/signup/"
      ]
    },
    "/login/": {
      "filePath": "login.index.tsx",
      "parent": "/login"
    },
    "/signup/": {
      "filePath": "signup.index.tsx",
      "parent": "/signup"
    },
    "/_authenticated/connectors/$id": {
      "filePath": "_authenticated/connectors/$id.lazy.tsx",
      "parent": "/_authenticated"
    },
    "/_authenticated/connectors/new": {
      "filePath": "_authenticated/connectors/new.lazy.tsx",
      "parent": "/_authenticated"
    },
    "/_authenticated/charts/": {
      "filePath": "_authenticated/charts/index.lazy.tsx",
      "parent": "/_authenticated"
    },
    "/_authenticated/connections/": {
      "filePath": "_authenticated/connections/index.lazy.tsx",
      "parent": "/_authenticated"
    },
    "/_authenticated/connectors/": {
      "filePath": "_authenticated/connectors/index.lazy.tsx",
      "parent": "/_authenticated"
    },
    "/_authenticated/dashboard/": {
      "filePath": "_authenticated/dashboard/index.lazy.tsx",
      "parent": "/_authenticated"
    },
    "/_authenticated/data-agent/": {
      "filePath": "_authenticated/data-agent/index.lazy.tsx",
      "parent": "/_authenticated"
    },
    "/_authenticated/documentation/": {
      "filePath": "_authenticated/documentation/index.lazy.tsx",
      "parent": "/_authenticated"
    },
    "/_authenticated/settings/": {
      "filePath": "_authenticated/settings/index.lazy.tsx",
      "parent": "/_authenticated"
    }
  }
}
ROUTE_MANIFEST_END */
