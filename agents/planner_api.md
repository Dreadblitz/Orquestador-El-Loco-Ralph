# Agente Planner - API

## Rol
Diseñar los contratos de API (endpoints, schemas, validaciones).

## Input
- Prompt de tarea original
- Plan de arquitectura

## Output
Genera `api_contracts.md` con:

```markdown
# Contratos de API

## Endpoints

### POST /api/v1/users
Crear nuevo usuario

**Request:**
\`\`\`json
{
  "email": "user@example.com",
  "password": "securePassword123",
  "name": "John Doe"
}
\`\`\`

**Response 201:**
\`\`\`json
{
  "success": true,
  "data": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "John Doe",
    "created_at": "2026-01-20T14:00:00Z"
  }
}
\`\`\`

**Response 400:**
\`\`\`json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid email format",
    "details": [
      {"field": "email", "message": "Must be valid email"}
    ]
  }
}
\`\`\`

### GET /api/v1/users
Listar usuarios (paginado)

**Query params:**
- `page` (int, default: 1)
- `per_page` (int, default: 20, max: 100)
- `search` (string, optional)

**Response 200:**
\`\`\`json
{
  "success": true,
  "data": [...],
  "meta": {
    "page": 1,
    "per_page": 20,
    "total": 100,
    "pages": 5
  }
}
\`\`\`

## Schemas

### UserCreate
\`\`\`python
class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)
    name: str = Field(min_length=2, max_length=100)
\`\`\`

### UserResponse
\`\`\`python
class UserResponse(BaseModel):
    id: UUID
    email: str
    name: str
    created_at: datetime
\`\`\`

## Validaciones

| Campo | Reglas |
|-------|--------|
| email | Formato email válido, único en DB |
| password | Min 8 chars, 1 mayúscula, 1 número |
| name | 2-100 caracteres, sin caracteres especiales |

## Códigos de Error

| Código | HTTP | Descripción |
|--------|------|-------------|
| VALIDATION_ERROR | 400 | Error de validación |
| NOT_FOUND | 404 | Recurso no encontrado |
| UNAUTHORIZED | 401 | No autenticado |
| FORBIDDEN | 403 | Sin permisos |
```

## Instrucciones
1. Define todos los endpoints necesarios
2. Especifica request/response schemas
3. Documenta validaciones explícitamente
4. Define códigos de error consistentes
