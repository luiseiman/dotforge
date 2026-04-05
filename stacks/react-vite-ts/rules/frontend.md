---
globs: "src/**/*.{ts,tsx,js,jsx}"
---

# React / Vite / TypeScript Rules

## Stack
React 18+, Vite, TypeScript strict mode, Tailwind CSS, Zustand for state management.

## Patterns
- Functional components only. No class components.
- Global state: Zustand stores in `stores/`. Outside React: `useStore.getState()`
- Local state: useState for ephemeral UI. No Zustand for single-component state.
- Styling: Tailwind utility classes. CSS custom properties for theming. Never hardcode colors.
- Icons: lucide-react or heroicons. One package per project.

## TypeScript
- `strict: true` in tsconfig.json. No exceptions.
- `any` is forbidden. Use `unknown` + type guard if the type is dynamic.
- Interfaces for objects, types for unions/intersections.
- Props types defined next to the component, not in a separate file.

## Errors
- ALWAYS `toast.error()` or equivalent in catch. Never empty catch.
- Error boundaries for critical UI sections.

## URLs and env
- `import.meta.env.VITE_*` for environment variables.
- API base: `import.meta.env.VITE_API_URL || '/api'`

## Testing
- Vitest + React Testing Library
- Test behavior, not implementation: `screen.getByRole()` > `container.querySelector()`
- Mock only external APIs with MSW or vi.mock

## WebSocket
- Custom hook with auto-reconnect and exponential backoff
- Cleanup in useEffect return (close connection)
- Connection state: `connected | connecting | disconnected`
- Messages: JSON.parse with try/catch, never assume valid format

## Dev Proxy
- Configure proxy in `vite.config.ts` for `/api` and `/ws` to backend
- Do not hardcode backend URLs in development
- Pattern: `server.proxy` in vite config

## Build
- `npm run dev` → development
- `npm run build` → production (verify 0 TS errors)
- `npm run test` → vitest
