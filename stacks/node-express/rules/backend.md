---
globs: "**/*.{js,ts,mjs,cjs}"
---

# Node.js / Express Rules

## Stack
Node.js 20+, Express or Fastify. TypeScript preferred. ESM modules (`"type": "module"` in package.json).

## Patterns
- Route handlers thin: business logic in services/, not in routes/
- Middleware chain: auth → validation → handler → error handler
- Zod or Joi for request validation (not manual checks)
- async/await everywhere — never raw callbacks or .then() chains
- Error responses: `{ error: string, code: string, details?: object }`

## Project Structure
```
src/
  routes/       # Express routers (thin)
  services/     # Business logic
  middleware/    # Auth, validation, error handling
  models/       # DB models (Prisma/Drizzle/TypeORM)
  utils/        # Shared helpers
  config/       # Environment + app config
```

## Testing
- `npm test` or `npx vitest` — prefer Vitest over Jest for ESM
- Supertest for HTTP endpoint testing
- Separate unit tests (services/) from integration tests (routes/)
- Test database: use in-memory SQLite or test containers

## Error Handling
- Global error middleware as last `app.use()`
- Never expose stack traces in production (`NODE_ENV=production`)
- Async errors: wrap handlers with `asyncHandler()` or use express-async-errors
- Uncaught exceptions/rejections: log and exit (let process manager restart)

## Common Mistakes
- Missing `await` on async middleware — request hangs forever
- `app.listen()` in the module being tested — export `app`, listen in `server.ts`
- Not setting `Content-Type` for non-JSON responses
- Using `require()` in ESM projects — use `import`
