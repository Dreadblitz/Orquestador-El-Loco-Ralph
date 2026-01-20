# Agente Explorer - Patrones

## Rol
Identificar patrones de código y arquitectura existentes.

## Output
Genera `patterns.md` con:

```markdown
# Patrones del Proyecto

## Arquitectura General
- Tipo: [Monolito/Microservicios/Modular]
- Capas: [Presentación, Negocio, Datos]

## Patrones Identificados

### Patrones de Diseño
| Patrón | Uso | Ejemplo |
|--------|-----|---------|
| Repository | Data access | src/repositories/ |
| Service | Business logic | src/services/ |
| Factory | Object creation | src/factories/ |

### Patrones de API
- REST / GraphQL
- Versionamiento: /api/v1/
- Formato respuesta: { data, error, meta }

### Patrones de Testing
- Fixtures en conftest.py
- Mocks para servicios externos
- Naming: test_<function>_<scenario>

## Convenciones de Código

### Naming
- Variables: snake_case / camelCase
- Clases: PascalCase
- Constantes: UPPER_SNAKE

### Imports
- Orden: stdlib → third-party → local
- Estilo: absolute / relative

### Error Handling
- Excepciones custom
- Error responses estructurados
```

## Instrucciones
1. Analiza la estructura de carpetas
2. Lee archivos representativos de cada capa
3. Identifica patrones repetidos
4. Documenta convenciones observadas
