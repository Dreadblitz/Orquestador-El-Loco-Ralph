# Ralph Orchestrator

Sistema de orquestación multi-agente para desarrollo autónomo con Claude Code.

---

## Quick Start

```bash
# Ejecutar con una tarea
./orchestrator.sh "Implementar sistema de autenticación JWT"

# Usar PRD existente
./orchestrator.sh --prd spec/existing/prd.json

# Con debug
DEBUG=1 ./orchestrator.sh "Mi tarea"
```

---

## Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                   RALPH ORCHESTRATOR                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  INPUT ──▶ EXPLORE ──▶ PLAN ──▶ PRD ──▶ EXECUTE ──▶ REVIEW  │
│                                                              │
│  Fases:                                                      │
│  1. Exploración: Agentes analizan codebase (paralelo)       │
│  2. Planificación: Agentes diseñan solución (paralelo)      │
│  3. Generación PRD: Crea PRD.json con waves                 │
│  4. Ejecución: Ralph loop coordina Coders/Reviewers         │
│  5. Revisión Final: Security + Tests + Architecture         │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Estructura del Proyecto

```
ralph/
├── orchestrator.sh          # Entry point principal
├── scripts/
│   ├── utils.sh             # Funciones comunes
│   ├── agent_launcher.sh    # Lanzador de agentes
│   └── ralph.sh             # Loop de ejecución
├── agents/                  # Prompts de agentes
│   ├── coder.md
│   ├── reviewer.md
│   ├── explorer_*.md
│   ├── planner_*.md
│   └── *_reviewer.md
├── templates/               # Templates JSON/MD
└── spec/                    # Output de ejecuciones
```

---

## Agentes Disponibles

### Exploración
| Agente | Rol |
|--------|-----|
| explorer_structure | Analiza estructura de carpetas |
| explorer_tech | Identifica tecnologías |
| explorer_patterns | Detecta patrones de código |
| explorer_tests | Analiza infraestructura de tests |
| explorer_deps | Mapea dependencias |

### Planificación
| Agente | Rol |
|--------|-----|
| planner_architecture | Diseña arquitectura |
| planner_api | Define contratos de API |
| planner_database | Diseña modelos y migraciones |
| planner_frontend | Planifica componentes UI |
| planner_testing | Estrategia de tests |
| planner_consolidator | Genera plan unificado |

### Ejecución
| Agente | Rol |
|--------|-----|
| coder | Implementa código |
| reviewer | Revisa y da feedback |
| browser_tester | Tests E2E con browser |

### Revisión Final
| Agente | Rol |
|--------|-----|
| security_reviewer | Auditoría de seguridad |
| tests_reviewer | Calidad de tests |
| architecture_reviewer | Revisión arquitectónica |

---

## Configuración

### Variables de Entorno

| Variable | Default | Descripción |
|----------|---------|-------------|
| MAX_PARALLEL_AGENTS | 6 | Agentes en paralelo por wave |
| MAX_CODER_ITERATIONS | 3 | Reintentos por tarea |
| DEBUG | 0 | Habilitar logging debug |
| PROJECT_PATH | pwd | Path del proyecto a trabajar |

---

## Flujo de Waves

```
Wave 1 (paralelo):  [Coder1] [Coder2] [Coder3] [Coder4] [Coder5] [Coder6]
                         │       │       │       │       │       │
                         ▼       ▼       ▼       ▼       ▼       ▼
                    [Reviewer] ◀─── Feedback loop (máx 3 iter)
                         │
                         ▼
Wave 2 (paralelo):  [Coder1] [Coder2] ...
```

**Regla clave:** El orquestador NO escribe código. Solo coordina agentes.

---

## Tests E2E

Para tests de browser, usar el skill `agent-browser`:

```
/agent-browser navegar a http://localhost:3000
/agent-browser click en "Login"
/agent-browser llenar campo email con "test@test.com"
/agent-browser capturar screenshot
```

---

## Output

Cada ejecución genera:

```
spec/[execution_id]/
├── input.md              # Prompt original
├── metadata.json         # Config de ejecución
├── context/              # Output de explorers
├── plan/                 # Output de planners
├── prd.json              # PRD para Ralph loop
├── communication/        # Mensajes entre agentes
├── logs/                 # Logs de ejecución
├── progress.txt          # Log de progreso
└── reports/
    ├── security_review.md
    ├── tests_review.md
    ├── architecture_review.md
    └── FINAL_REPORT.md
```

---

## Troubleshooting

### Error: Claude Code no instalado
```bash
npm install -g @anthropic-ai/claude-code
```

### Error: jq no instalado
```bash
sudo apt install jq
```

### Loop no termina
- Verificar `MAX_CODER_ITERATIONS`
- Revisar `progress.txt` para ver dónde se atasca
- Cancelar con Ctrl+C

### Agente falla repetidamente
- Revisar logs en `spec/[id]/logs/`
- Verificar que el prompt del agente es claro
- Considerar dividir la tarea en subtareas

---

## Buenas Prácticas

1. **Prompts claros**: Describe la tarea con detalle suficiente
2. **Scope acotado**: Mejor varias ejecuciones pequeñas que una gigante
3. **Revisar PRD**: Antes de ejecutar, revisar que las waves tienen sentido
4. **Monitorear**: `tail -f spec/[id]/progress.txt`
5. **Backup**: El código se commitea, pero ten backup antes de ejecutar

---

## Ejemplo Completo

```bash
# 1. Iniciar orchestrator con tarea
./orchestrator.sh "Agregar endpoint REST para gestión de productos con CRUD completo, validaciones y tests"

# 2. Monitorear progreso (otra terminal)
tail -f spec/*/progress.txt

# 3. Ver estado de waves
cat spec/*/prd.json | jq '.waves[] | {id, name, status}'

# 4. Ver reporte final
cat spec/*/reports/FINAL_REPORT.md
```

---

*Ralph Orchestrator v1.0.0*
