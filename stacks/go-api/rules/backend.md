---
globs: "**/*.go,go.mod,go.sum"
---

# Go API Rules

## Stack
Go 1.22+, standard library `net/http` (or chi/echo for routing). Go modules for dependency management.

## Patterns
- Standard project layout: `cmd/`, `internal/`, `pkg/` (only if truly public)
- Handlers in `internal/handler/`, business logic in `internal/service/`
- `http.Handler` and `http.HandlerFunc` interfaces — compose middleware as wrappers
- Errors as values: return `error`, don't panic. Use `fmt.Errorf("context: %w", err)` for wrapping
- Context propagation: pass `context.Context` as first parameter everywhere

## Project Structure
```
cmd/
  server/main.go   # Entry point
internal/
  handler/          # HTTP handlers
  service/          # Business logic
  repository/       # Data access
  model/            # Domain types
  middleware/        # Auth, logging, recovery
pkg/                # Only truly reusable public packages
```

## Testing
- `go test ./...` from project root
- Table-driven tests: `tests := []struct{ name string; input; want }{ ... }`
- `httptest.NewRecorder()` + `httptest.NewRequest()` for handler tests
- `t.Parallel()` for independent tests
- Testify for assertions only if team prefers — standard library is fine

## Error Handling
- Always check returned errors — never `_ = someFunc()`
- Custom error types implementing `error` interface for domain errors
- HTTP error responses: `http.Error(w, msg, statusCode)` or JSON encoder
- Middleware recovery: catch panics, log, return 500

## Common Mistakes
- Goroutine leak: forgetting to cancel context or close channels
- Data race: shared state without mutex or channels — run `go test -race`
- `defer resp.Body.Close()` before checking `err` → nil pointer on error
- `json.NewDecoder` vs `json.Unmarshal`: decoder for streams, unmarshal for known-size
