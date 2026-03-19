---
globs: "supabase/**,**/migrations/**"
---

# Supabase Rules

## Migrations
- Una migración por cambio lógico. Nombre descriptivo: `YYYYMMDDHHMMSS_add_<entity>_table.sql`
- SIEMPRE crear migración reversible (incluir DOWN aunque no se use)
- RLS (Row Level Security) OBLIGATORIO en toda tabla con datos de usuario
- Después de crear tabla: verificar que RLS está habilitado

## RLS Policies
- Política por defecto: DENY ALL. Crear policies explícitas.
- Nombre de policy descriptivo: `users_select_own`, `admin_all_access`
- Verificar con `supabase db lint` después de cambios

## Edge Functions
- Deno runtime. Import maps en `supabase/functions/import_map.json`
- CORS headers explícitos en cada función
- Verificar JWT por defecto (--no-verify-jwt solo con justificación)

## Tipos
- Generar tipos TS: `supabase gen types typescript --project-id <id>`
- Regenerar después de cada migración

## Errores comunes
- Olvidar RLS → datos expuestos públicamente
- Foreign key sin ON DELETE → registros huérfanos
- Trigger que referencia función inexistente → migración silenciosamente rota
