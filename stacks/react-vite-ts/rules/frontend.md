---
globs: "src/**/*.{ts,tsx,js,jsx}"
---

# React / Vite / TypeScript Rules

## Stack
React 18+, Vite, TypeScript strict mode, Tailwind CSS, Zustand para state management.

## Patterns
- Componentes funcionales exclusivamente. No class components.
- State global: Zustand stores en `stores/`. Fuera de React: `useStore.getState()`
- State local: useState para UI ephemeral. No Zustand para estado de un solo componente.
- Styling: Tailwind utility classes. CSS custom properties para theming. Nunca hardcodear colores.
- Icons: lucide-react o heroicons. Un solo paquete por proyecto.

## TypeScript
- `strict: true` en tsconfig.json. Sin excepciones.
- Prohibido `any`. Usar `unknown` + type guard si el tipo es dinámico.
- Interfaces para objetos, types para unions/intersections.
- Props types definidas junto al componente, no en archivo separado.

## Errores
- SIEMPRE `toast.error()` o similar en catch. Nunca catch vacío.
- Error boundaries para secciones críticas de UI.

## URLs y env
- `import.meta.env.VITE_*` para variables de entorno.
- API base: `import.meta.env.VITE_API_URL || '/api'`

## Testing
- Vitest + React Testing Library
- Test behavior, no implementación: `screen.getByRole()` > `container.querySelector()`
- Mock solo APIs externas con MSW o vi.mock

## WebSocket
- Custom hook con auto-reconnect y backoff exponencial
- Cleanup en useEffect return (cerrar conexión)
- Estado de conexión: `connected | connecting | disconnected`
- Mensajes: JSON.parse con try/catch, nunca asumir formato válido

## Dev Proxy
- Configurar proxy en `vite.config.ts` para `/api` y `/ws` al backend
- No hardcodear URLs de backend en desarrollo
- Pattern: `server.proxy` en vite config

## Build
- `npm run dev` → development
- `npm run build` → production (verificar 0 errores TS)
- `npm run test` → vitest
