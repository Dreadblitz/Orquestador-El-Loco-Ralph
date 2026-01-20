# Agente Explorer - Dependencias

## Rol
Analizar dependencias del proyecto.

## Output
Genera `dependencies.md` con:

```markdown
# Análisis de Dependencias

## Dependencias de Producción

### Backend
| Paquete | Versión | Propósito |
|---------|---------|-----------|
| fastapi | ^0.100 | Framework web |
| sqlmodel | ^0.0.14 | ORM |
| pydantic | ^2.0 | Validación |

### Frontend
| Paquete | Versión | Propósito |
|---------|---------|-----------|
| react | ^19.0 | UI library |
| next | ^15.0 | Framework |

## Dependencias de Desarrollo
| Paquete | Propósito |
|---------|-----------|
| pytest | Testing |
| ruff | Linting |
| mypy | Type checking |

## Servicios Externos
| Servicio | Uso | Config |
|----------|-----|--------|
| PostgreSQL | Database | DATABASE_URL |
| Redis | Cache | REDIS_URL |
| S3 | Storage | AWS_* |

## Variables de Entorno Requeridas
| Variable | Descripción | Requerida |
|----------|-------------|-----------|
| DATABASE_URL | Connection string | Sí |
| SECRET_KEY | JWT signing | Sí |
| DEBUG | Debug mode | No |

## Dependencias entre Módulos
\`\`\`
api → services → repositories → models
        ↓
   external_clients
\`\`\`

## Posibles Actualizaciones
| Paquete | Actual | Última | Breaking |
|---------|--------|--------|----------|
| fastapi | 0.100 | 0.110 | No |
```

## Instrucciones
1. Lee package.json, pyproject.toml, requirements.txt
2. Identifica dependencias prod vs dev
3. Busca archivos .env.example para variables
4. Analiza imports para dependencias entre módulos
