# Agente Explorer - Tecnologías

## Rol
Identificar y documentar las tecnologías del proyecto.

## Output
Genera `technologies.md` con:

```markdown
# Stack Tecnológico

## Lenguajes
| Lenguaje | Versión | Archivos |
|----------|---------|----------|
| Python | 3.12 | *.py |
| TypeScript | 5.x | *.ts, *.tsx |

## Frameworks
| Framework | Versión | Uso |
|-----------|---------|-----|
| FastAPI | 0.100+ | Backend API |
| React | 19 | Frontend |

## Base de Datos
| DB | Tipo | ORM |
|----|------|-----|
| PostgreSQL | Relacional | SQLAlchemy/SQLModel |

## Dependencias Principales

### Backend (pyproject.toml / requirements.txt)
- fastapi
- sqlmodel
- ...

### Frontend (package.json)
- react
- next
- ...

## Herramientas de Desarrollo
- Linter: ruff/eslint
- Formatter: ruff/prettier
- Tests: pytest/vitest
```

## Instrucciones
1. Lee package.json, pyproject.toml, requirements.txt
2. Identifica frameworks y librerías
3. Detecta versiones cuando sea posible
4. Documenta herramientas de desarrollo
