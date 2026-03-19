# Checklist de Seguridad — Pre-deploy

Verificar ANTES de deployar cualquier proyecto.

## Inputs y validación
- [ ] Inputs del usuario sanitizados (HTML, SQL, shell)
- [ ] Validación de tipos y rangos en API endpoints
- [ ] File uploads: verificar tipo MIME, tamaño máximo, nombre seguro
- [ ] URLs: validar scheme (no javascript:, data:)

## Secrets y credenciales
- [ ] Sin credenciales hardcodeadas en código
- [ ] .env en .gitignore
- [ ] API keys en variables de entorno o secrets manager
- [ ] Tokens con permisos mínimos necesarios (least privilege)
- [ ] Secrets rotados si fueron expuestos alguna vez

## Base de datos
- [ ] Queries parametrizadas (nunca string interpolation)
- [ ] RLS habilitado en tablas con datos de usuario (Supabase)
- [ ] Backups configurados
- [ ] Conexiones con TLS

## Autenticación y autorización
- [ ] Auth en todos los endpoints que lo requieran
- [ ] Tokens con expiración
- [ ] Rate limiting en login y endpoints públicos
- [ ] CORS configurado (no wildcard * en producción)

## API y red
- [ ] HTTPS en producción
- [ ] Headers de seguridad (HSTS, X-Content-Type-Options, etc.)
- [ ] Errores no exponen stack traces ni info interna al usuario
- [ ] Timeouts configurados en requests externos

## Logs y monitoreo
- [ ] Logs no contienen passwords, tokens, ni PII
- [ ] Errores críticos alertan (no solo loguean)
- [ ] Health checks en servicios críticos

## Dependencies
- [ ] Sin vulnerabilidades conocidas (`npm audit`, `pip audit`)
- [ ] Versiones pinneadas (no latest/*)
- [ ] Lock files (package-lock.json, poetry.lock) commiteados

## Docker (si aplica)
- [ ] No correr como root dentro del container
- [ ] .dockerignore incluye .env, .git, node_modules
- [ ] Imágenes base con versión específica (no :latest)
- [ ] Secrets NO en build args ni en layers
