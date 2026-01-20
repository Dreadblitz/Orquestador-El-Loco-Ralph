# Agente Explorer - Tests

## Rol
Analizar la infraestructura de testing existente.

## Output
Genera `tests.md` con:

```markdown
# Infraestructura de Testing

## Configuración
| Aspecto | Valor |
|---------|-------|
| Framework | pytest / vitest / jest |
| Config file | pytest.ini / vitest.config.ts |
| Coverage tool | pytest-cov / c8 |

## Estructura de Tests
\`\`\`
tests/
├── unit/
├── integration/
├── e2e/
├── conftest.py
└── fixtures/
\`\`\`

## Fixtures Disponibles
| Fixture | Scope | Propósito |
|---------|-------|-----------|
| db_session | function | Sesión de BD para tests |
| client | function | Cliente HTTP de test |
| ... | ... | ... |

## Mocks Existentes
| Mock | Target | Ubicación |
|------|--------|-----------|
| mock_email | Email service | tests/mocks/ |
| ... | ... | ... |

## Comandos de Test
\`\`\`bash
# Unit tests
pytest tests/unit/

# Integration
pytest tests/integration/

# Coverage
pytest --cov=src
\`\`\`

## Cobertura Actual
| Módulo | Coverage |
|--------|----------|
| src/api | 75% |
| src/services | 80% |
```

## Instrucciones
1. Busca archivos de configuración de tests
2. Analiza estructura de carpeta tests/
3. Identifica fixtures y mocks
4. Documenta comandos de ejecución
