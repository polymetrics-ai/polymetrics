/* prettier-ignore-start */

/* eslint-disable */

// @ts-nocheck

// noinspection JSUnusedGlobalSymbols

// This file is auto-generated by TanStack Router

// Import Routes

import { Route as rootRoute } from './routes/__root'
import { Route as SignupIndexImport } from './routes/signup.index'
import { Route as LoginIndexImport } from './routes/login.index'

// Create/Update Routes

const SignupIndexRoute = SignupIndexImport.update({
  path: '/signup/',
  getParentRoute: () => rootRoute,
} as any)

const LoginIndexRoute = LoginIndexImport.update({
  path: '/login/',
  getParentRoute: () => rootRoute,
} as any)

// Populate the FileRoutesByPath interface

declare module '@tanstack/react-router' {
  interface FileRoutesByPath {
    '/login/': {
      id: '/login/'
      path: '/login'
      fullPath: '/login'
      preLoaderRoute: typeof LoginIndexImport
      parentRoute: typeof rootRoute
    }
    '/signup/': {
      id: '/signup/'
      path: '/signup'
      fullPath: '/signup'
      preLoaderRoute: typeof SignupIndexImport
      parentRoute: typeof rootRoute
    }
  }
}

// Create and export the route tree

export const routeTree = rootRoute.addChildren({
  LoginIndexRoute,
  SignupIndexRoute,
})

/* prettier-ignore-end */

/* ROUTE_MANIFEST_START
{
  "routes": {
    "__root__": {
      "filePath": "__root.tsx",
      "children": [
        "/login/",
        "/signup/"
      ]
    },
    "/login/": {
      "filePath": "login.index.tsx"
    },
    "/signup/": {
      "filePath": "signup.index.tsx"
    }
  }
}
ROUTE_MANIFEST_END */
