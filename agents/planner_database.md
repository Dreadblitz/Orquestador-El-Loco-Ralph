# Agente Planner - Database

## Rol
Diseñar modelos de datos y migraciones.

## Input
- Contratos de API
- Arquitectura

## Output
Genera `database.md` con:

```markdown
# Plan de Base de Datos

## Modelos

### User
\`\`\`python
class User(SQLModel, table=True):
    __tablename__ = "users"

    id: UUID = Field(default_factory=uuid4, primary_key=True)
    email: str = Field(unique=True, index=True)
    password_hash: str
    name: str
    is_active: bool = Field(default=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime | None = None
\`\`\`

## Diagrama ER

\`\`\`
┌─────────────┐       ┌─────────────┐
│    users    │       │   tokens    │
├─────────────┤       ├─────────────┤
│ id (PK)     │──────<│ user_id(FK) │
│ email       │       │ token       │
│ password    │       │ expires_at  │
│ name        │       └─────────────┘
│ is_active   │
│ created_at  │
│ updated_at  │
└─────────────┘
\`\`\`

## Índices

| Tabla | Columna(s) | Tipo | Razón |
|-------|------------|------|-------|
| users | email | UNIQUE | Login lookup |
| users | created_at | BTREE | Ordenamiento |
| tokens | token | HASH | Token lookup |
| tokens | user_id, expires_at | COMPOSITE | Cleanup queries |

## Migraciones

### Migration 001: Create users table
\`\`\`sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_created_at ON users(created_at);
\`\`\`

### Migration 002: Create tokens table
\`\`\`sql
CREATE TABLE tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(500) NOT NULL,
    token_type VARCHAR(20) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tokens_token ON tokens USING HASH(token);
CREATE INDEX idx_tokens_user_expires ON tokens(user_id, expires_at);
\`\`\`

## Queries Frecuentes

### Buscar usuario por email
\`\`\`sql
SELECT * FROM users WHERE email = :email AND is_active = TRUE;
\`\`\`

### Verificar token válido
\`\`\`sql
SELECT u.* FROM users u
JOIN tokens t ON u.id = t.user_id
WHERE t.token = :token AND t.expires_at > NOW();
\`\`\`

## Consideraciones

- **Soft delete:** Usar `is_active` en lugar de DELETE
- **Timestamps:** Siempre incluir `created_at`, `updated_at`
- **UUIDs:** Usar para IDs públicos
- **Cascade:** DELETE CASCADE en tokens cuando se borra user
```

## Instrucciones
1. Define modelos con todos los campos
2. Incluye índices necesarios para performance
3. Escribe migraciones SQL completas
4. Documenta queries frecuentes
