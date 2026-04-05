---
globs: "**/*.java,**/pom.xml,**/build.gradle*"
---

# Java / Spring Boot Rules

## System Prompt Overrides
- ALWAYS add Javadoc to public methods and classes
- ALWAYS include @param and @return tags

## Stack
Java 21+, Spring Boot 3.x, Maven or Gradle. Records for DTOs. Virtual threads when available.

## Patterns
- Controller → Service → Repository layering (no business logic in controllers)
- `@RestController` with `@RequestMapping` prefix per resource
- DTOs as Java records: `record UserResponse(Long id, String name) {}`
- Dependency injection via constructor (not field injection with `@Autowired`)
- `@Transactional` on service methods, never on controllers

## Project Structure
```
src/main/java/com/example/app/
  controller/    # REST controllers (thin)
  service/       # Business logic
  repository/    # JPA repositories
  model/         # Entities
  dto/           # Request/response records
  config/        # Spring configuration
  exception/     # Custom exceptions + global handler
```

## Testing
- `./mvnw test` or `./gradlew test`
- `@SpringBootTest` for integration tests (loads full context)
- `@WebMvcTest` for controller-only tests (mock services)
- `@DataJpaTest` for repository tests (in-memory H2)
- Testcontainers for external dependencies (DB, Redis, Kafka)

## Error Handling
- `@ControllerAdvice` + `@ExceptionHandler` for global error handling
- Custom exceptions extending `RuntimeException` with HTTP status
- Never return raw exception messages to clients
- Validate with `@Valid` + Bean Validation annotations

## Common Mistakes
- `@Transactional` on private methods — Spring proxies can't intercept
- Lazy loading outside transaction scope → `LazyInitializationException`
- Missing `@ComponentScan` when packages are outside main app package
- N+1 queries: use `@EntityGraph` or `JOIN FETCH` in JPQL
