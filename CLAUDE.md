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
┌─────────────────────────────────────────────────────────────────────────────┐
│                         RALPH ORCHESTRATOR                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  FASE 1        FASE 2         FASE 3       FASE 4a      FASE 4b     FASE 5  │
│  ──────        ──────         ──────       ───────      ───────     ──────  │
│  INPUT ──▶ EXPLORATION ──▶ PLANNING ──▶ PRD GEN ──▶ RALPH LOOP ──▶ REVIEW  │
│                                                                              │
│  Detalle:                                                                    │
│  1. Input: Recibe prompt del usuario                                        │
│  2. Exploración: 6 explorers analizan contexto (paralelo)                   │
│  3. Planificación: 6 planners diseñan solución (paralelo)                   │
│  4a. PRD Generation: Genera prd.json con waves y tareas                     │
│  4b. Ralph Loop: Executor/Validator iteran hasta completar                  │
│  5. Revisión Final: Security + Tests + Architecture                         │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Estructura del Proyecto

```
ralph/
├── orchestrator.sh          # Entry point principal
├── CLAUDE.md                # Este archivo
├── scripts/
│   ├── utils.sh             # Funciones comunes (logging, JSON, estado)
│   ├── agent_launcher.sh    # Lanzador de agentes Claude Code
│   └── ralph.sh             # Loop de ejecución (Fase 4b + 5)
├── agents/                  # Prompts de agentes (18 total)
│   ├── explorer_*.md        # 6 explorers
│   ├── planner_*.md         # 6 planners
│   ├── executor.md          # Ejecutor de tareas
│   ├── validator.md         # Validador de resultados
│   ├── *_reviewer.md        # 3 revisores finales
│   └── browser_tester.md    # Tester E2E
├── templates/               # Templates JSON/MD (5 archivos)
└── spec/                    # Output de ejecuciones
```

---

## Agentes Disponibles

### Fase 2: Exploración (6 agentes)

| Agente | Output | Rol |
|--------|--------|-----|
| explorer_classifier | `context/classification.json` | Clasifica tipo de tarea y contexto |
| explorer_task | `context/task_analysis.md` | Analiza requerimientos explícitos/implícitos |
| explorer_domain | `context/domain_analysis.md` | Identifica conceptos de dominio |
| explorer_constraints | `context/constraints.md` | Detecta limitaciones y NFRs |
| explorer_codebase | `context/codebase_analysis.md` | Mapea estructura y patrones (si has_code) |
| explorer_stack | `context/stack_analysis.md` | Analiza tecnologías y dependencias (si has_code) |

### Fase 3: Planificación (6 agentes)

| Agente | Output | Rol |
|--------|--------|-----|
| planner_architecture | `plan/architecture.md` | Diseña arquitectura técnica |
| planner_api | `plan/api_contracts.md` | Define endpoints y contratos |
| planner_database | `plan/database.md` | Diseña modelos y migraciones |
| planner_frontend | `plan/frontend.md` | Planifica componentes UI |
| planner_testing | `plan/testing_strategy.md` | Estrategia de tests |
| planner_consolidator | `plan/IMPLEMENTATION_PLAN.md` | Genera plan unificado con waves |

### Fase 4b: Ejecución (2 agentes)

| Agente | Output | Rol |
|--------|--------|-----|
| executor | `communication/executor_{task_id}_output.json` | Implementa tareas según tipo |
| validator | `communication/validator_{task_id}_feedback.json` | Valida y genera feedback |

### Fase 5: Revisión Final (3 agentes)

| Agente | Output | Rol |
|--------|--------|-----|
| security_reviewer | `reports/security_review.json` | Auditoría OWASP, secrets, configs |
| tests_reviewer | `reports/tests_review.json` | Cobertura, calidad, edge cases |
| architecture_reviewer | `reports/architecture_review.json` | SOLID, dependencias, patrones |

---

## Task Types Soportados

El executor y validator adaptan su comportamiento según el tipo de tarea:

| Tipo | Descripción | Hace Commit |
|------|-------------|-------------|
| `code` | Implementación de funcionalidades | Sí |
| `documentation` | Crear/actualizar documentación | Sí |
| `configuration` | Modificar configs (yaml, json, env) | Sí |
| `research` | Investigación y análisis | No |
| `testing` | Escribir tests | Sí |
| `refactoring` | Refactorizar código existente | Sí |
| `general` | Tareas no clasificadas | Sí (si modifica) |

---

## Configuración

### Variables de Entorno

| Variable | Default | Descripción |
|----------|---------|-------------|
| `MAX_PARALLEL_AGENTS` | 6 | Agentes en paralelo por wave |
| `MAX_ITERATIONS` | 100 | Iteraciones máximas del loop principal |
| `MAX_CODER_ITERATIONS` | 3 | Reintentos por tarea fallida |
| `DEBUG` | 0 | Habilitar logging debug |
| `PROJECT_PATH` | pwd | Path del proyecto a trabajar |

---

## Flujo de Ejecución

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ RALPH LOOP (Fase 4b)                                                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Wave 1 (paralelo, max 6):                                                  │
│    [Executor1] ──▶ [Validator1] ──▶ approved? ──▶ next task                │
│    [Executor2] ──▶ [Validator2] ──▶ rejected? ──▶ retry (max 3)            │
│    [Executor3] ──▶ [Validator3] ──▶ ...                                    │
│         │                                                                    │
│         ▼                                                                    │
│  Wave 2 (cuando Wave 1 completa):                                           │
│    [Executor1] ──▶ [Validator1] ──▶ ...                                    │
│         │                                                                    │
│         ▼                                                                    │
│  ... hasta completar todas las waves                                        │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘

**Regla clave:** El orquestador NO escribe código. Solo coordina agentes.
```

---

## Output

Cada ejecución genera:

```
spec/[execution_id]/
├── input.md                    # Prompt original del usuario
├── metadata.json               # Config de ejecución
├── context/                    # Output de explorers (Fase 2)
│   ├── classification.json
│   ├── task_analysis.md
│   ├── domain_analysis.md
│   ├── constraints.md
│   ├── codebase_analysis.md    # (si has_code=true)
│   └── stack_analysis.md       # (si has_code=true)
├── plan/                       # Output de planners (Fase 3)
│   ├── architecture.md
│   ├── api_contracts.md
│   ├── database.md
│   ├── frontend.md
│   ├── testing_strategy.md
│   └── IMPLEMENTATION_PLAN.md
├── prd.json                    # PRD con waves y tareas
├── communication/              # Mensajes executor/validator (Fase 4b)
│   ├── executor_*_output.json
│   └── validator_*_feedback.json
├── logs/                       # Logs de ejecución
├── progress.txt                # Log de progreso en tiempo real
└── reports/                    # Revisiones finales (Fase 5)
    ├── security_review.json
    ├── tests_review.json
    ├── architecture_review.json
    ├── FINAL_REPORT.json       # Consolidado JSON
    └── FINAL_REPORT.md         # Consolidado Markdown
```

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

## Troubleshooting

### Error: Claude Code no instalado
```bash
npm install -g @anthropic-ai/claude-code
```

### Error: jq no instalado
```bash
sudo apt install jq
```

### Error: bc no instalado (scores muestran 0)
```bash
sudo apt install bc
```

### Loop no termina
- Verificar `MAX_ITERATIONS` y `MAX_CODER_ITERATIONS`
- Revisar `progress.txt` para ver dónde se atasca
- Cancelar con Ctrl+C

### Agente falla repetidamente
- Revisar logs en `spec/[id]/logs/`
- Verificar que el prompt del agente es claro
- Considerar dividir la tarea en subtareas

### Validator siempre rechaza
- Revisar `communication/validator_*_feedback.json` para ver issues
- Verificar que task_type es correcto en PRD
- Revisar criterios de validación en `agents/validator.md`

---

## Buenas Prácticas

1. **Prompts claros**: Describe la tarea con detalle suficiente
2. **Scope acotado**: Mejor varias ejecuciones pequeñas que una gigante
3. **Revisar PRD**: Antes de ejecutar, revisar que las waves tienen sentido
4. **Monitorear**: `tail -f spec/[id]/progress.txt`
5. **Backup**: El código se commitea, pero ten backup antes de ejecutar
6. **Task types**: Usar el tipo correcto mejora validación

---

## Ejemplo Completo

```bash
# 1. Iniciar orchestrator con tarea
./orchestrator.sh "Agregar endpoint REST para gestión de productos con CRUD completo, validaciones y tests"

# 2. Monitorear progreso (otra terminal)
tail -f spec/*/progress.txt

# 3. Ver estado de waves
cat spec/*/prd.json | jq '.waves[] | {id, name, status}'

# 4. Ver scores de revisión final
cat spec/*/reports/FINAL_REPORT.json | jq '.review_scores'

# 5. Ver reporte final
cat spec/*/reports/FINAL_REPORT.md
```

---

## Dependencias

| Comando | Uso | Instalación |
|---------|-----|-------------|
| `claude` | CLI de Claude Code | `npm install -g @anthropic-ai/claude-code` |
| `jq` | Manipulación JSON | `sudo apt install jq` |
| `bc` | Cálculos matemáticos | `sudo apt install bc` |

---

*Ralph Orchestrator v1.0.0*
