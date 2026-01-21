# 🤖 Ralph Orchestrator

> Sistema de orquestación multi-agente para desarrollo autónomo con Claude Code

```
    ____        __      __       __                      ____        __      __
   / __ \____ _/ /___  / /_     / /   ____  _________   / __ \____ _/ /___  / /_
  / /_/ / __ `/ / __ \/ __ \   / /   / __ \/ ___/ __ \ / /_/ / __ `/ / __ \/ __ \
 / _, _/ /_/ / / /_/ / / / /  / /___/ /_/ / /__/ /_/ // _, _/ /_/ / / /_/ / / / /
/_/ |_|\__,_/_/ .___/_/ /_/  /_____/\____/\___/\____//_/ |_|\__,_/_/ .___/_/ /_/
             /_/                                                  /_/
```

[![Claude Code](https://img.shields.io/badge/Claude%20Code-Compatible-blue)](https://claude.ai)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.0.0-orange)](CHANGELOG.md)

---

## ✨ Características

- **🔄 Orquestación Multi-Agente**: Coordina 18 agentes especializados
- **📊 5 Fases de Ejecución**: Input → Exploración → Planificación → Ejecución → Revisión
- **⚡ Ejecución Paralela**: Hasta 6 agentes simultáneos por wave
- **🔁 Feedback Loop**: Executor/Validator iteran hasta aprobar
- **🛡️ Revisión Final**: Security, Tests y Architecture automáticos
- **📈 Reportes JSON**: Métricas y scores consolidados
- **🎯 7 Task Types**: code, documentation, testing, refactoring, etc.

---

## 🚀 Quick Start

### Requisitos

```bash
# Claude Code CLI
npm install -g @anthropic-ai/claude-code

# Dependencias del sistema
sudo apt install jq bc
```

### Instalación

```bash
# Clonar repositorio
git clone https://github.com/Dreadblitz/ralph.git
cd ralph

# Dar permisos de ejecución
chmod +x orchestrator.sh scripts/*.sh
```

### Uso Básico

```bash
# Ejecutar con una tarea
./orchestrator.sh "Implementar sistema de autenticación JWT"

# Con PRD existente
./orchestrator.sh --prd spec/existing/prd.json

# Con debug
DEBUG=1 ./orchestrator.sh "Mi tarea"

# Especificar proyecto diferente
./orchestrator.sh "tarea" --project-path /ruta/al/proyecto
```

---

## 📐 Arquitectura

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         RALPH ORCHESTRATOR                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  FASE 1        FASE 2         FASE 3       FASE 4a      FASE 4b     FASE 5  │
│  ──────        ──────         ──────       ───────      ───────     ──────  │
│  INPUT ──▶ EXPLORATION ──▶ PLANNING ──▶ PRD GEN ──▶ RALPH LOOP ──▶ REVIEW  │
│                                                                              │
│  • input.md    • 6 Explorers  • 6 Planners • prd.json  • Executor   • 3 Rev │
│  • metadata    • context/     • plan/      • Waves     • Validator  • JSON  │
│                • Paralelo     • Paralelo   • Tasks     • Feedback   • Score │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Ralph Loop (Fase 4b)

```
┌─────────────────────────────────────────────────────────────────┐
│                    WAVE (paralelo, max 6)                        │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐           │
│  │Executor 1│ │Executor 2│ │Executor 3│ │Executor 4│           │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘           │
│       │            │            │            │                   │
│       ▼            ▼            ▼            ▼                   │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐           │
│  │Validator1│ │Validator2│ │Validator3│ │Validator4│           │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘           │
│       │            │            │            │                   │
│       ▼            ▼            ▼            ▼                   │
│   approved?    approved?    approved?    approved?               │
│   ✓ next       ✓ next       ✗ retry      ✓ next                 │
│                             (max 3)                              │
└─────────────────────────────────────────────────────────────────┘

**Regla clave:** El orquestador NO escribe código. Solo coordina agentes.
```

---

## 🤖 Agentes Disponibles (18 total)

### Fase 2: Exploración (6 agentes)

| Agente | Output | Rol |
|--------|--------|-----|
| `explorer_classifier` | `context/classification.json` | Clasifica tipo de tarea y contexto |
| `explorer_task` | `context/task_analysis.md` | Analiza requerimientos |
| `explorer_domain` | `context/domain_analysis.md` | Identifica conceptos de dominio |
| `explorer_constraints` | `context/constraints.md` | Detecta limitaciones y NFRs |
| `explorer_codebase` | `context/codebase_analysis.md` | Mapea estructura y patrones |
| `explorer_stack` | `context/stack_analysis.md` | Analiza tecnologías |

### Fase 3: Planificación (6 agentes)

| Agente | Output | Rol |
|--------|--------|-----|
| `planner_architecture` | `plan/architecture.md` | Diseña arquitectura técnica |
| `planner_api` | `plan/api_contracts.md` | Define endpoints y contratos |
| `planner_database` | `plan/database.md` | Diseña modelos y migraciones |
| `planner_frontend` | `plan/frontend.md` | Planifica componentes UI |
| `planner_testing` | `plan/testing_strategy.md` | Estrategia de tests |
| `planner_consolidator` | `plan/IMPLEMENTATION_PLAN.md` | Genera plan unificado |

### Fase 4b: Ejecución (2 agentes)

| Agente | Output | Rol |
|--------|--------|-----|
| `executor` | `communication/executor_{id}_output.json` | Implementa tareas (7 tipos) |
| `validator` | `communication/validator_{id}_feedback.json` | Valida y genera feedback |

### Fase 5: Revisión Final (3 agentes)

| Agente | Output | Rol |
|--------|--------|-----|
| `security_reviewer` | `reports/security_review.json` | Auditoría OWASP, secrets |
| `tests_reviewer` | `reports/tests_review.json` | Cobertura, calidad |
| `architecture_reviewer` | `reports/architecture_review.json` | SOLID, dependencias |

---

## 📊 Task Types Soportados

El executor y validator adaptan su comportamiento según el tipo:

| Tipo | Descripción | Hace Commit |
|------|-------------|-------------|
| `code` | Implementación de funcionalidades | Sí |
| `documentation` | Crear/actualizar docs | Sí |
| `configuration` | Modificar configs | Sí |
| `research` | Investigación y análisis | No |
| `testing` | Escribir tests | Sí |
| `refactoring` | Refactorizar código | Sí |
| `general` | Tareas no clasificadas | Sí |

---

## 📁 Estructura del Proyecto

```
ralph/
├── orchestrator.sh          # Entry point principal
├── CLAUDE.md                # Instrucciones para Claude Code
├── README.md                # Este archivo
├── scripts/
│   ├── utils.sh             # Funciones comunes
│   ├── agent_launcher.sh    # Lanzador de agentes
│   └── ralph.sh             # Loop de ejecución
├── agents/                  # 18 prompts de agentes
│   ├── explorer_*.md        # 6 explorers
│   ├── planner_*.md         # 6 planners
│   ├── executor.md
│   ├── validator.md
│   ├── *_reviewer.md        # 3 revisores
│   └── browser_tester.md
├── templates/               # Templates JSON/MD
└── spec/                    # Output de ejecuciones
```

---

## 📈 Output de Ejecución

```
spec/[execution_id]/
├── input.md                    # Prompt original
├── metadata.json               # Config de ejecución
├── context/                    # Output de explorers (Fase 2)
│   ├── classification.json
│   ├── task_analysis.md
│   ├── domain_analysis.md
│   ├── constraints.md
│   ├── codebase_analysis.md
│   └── stack_analysis.md
├── plan/                       # Output de planners (Fase 3)
│   ├── architecture.md
│   ├── api_contracts.md
│   ├── database.md
│   ├── frontend.md
│   ├── testing_strategy.md
│   └── IMPLEMENTATION_PLAN.md
├── prd.json                    # PRD con waves y tareas
├── communication/              # Executor/Validator (Fase 4b)
│   ├── executor_*_output.json
│   └── validator_*_feedback.json
├── logs/
├── progress.txt                # Log en tiempo real
└── reports/                    # Revisiones finales (Fase 5)
    ├── security_review.json
    ├── tests_review.json
    ├── architecture_review.json
    ├── FINAL_REPORT.json
    └── FINAL_REPORT.md
```

---

## ⚙️ Configuración

| Variable | Default | Descripción |
|----------|---------|-------------|
| `MAX_PARALLEL_AGENTS` | 6 | Agentes en paralelo por wave |
| `MAX_ITERATIONS` | 100 | Iteraciones máximas del loop |
| `MAX_CODER_ITERATIONS` | 3 | Reintentos por tarea |
| `DEBUG` | 0 | Habilitar logging debug |
| `PROJECT_PATH` | pwd | Path del proyecto |

---

## 🔍 Monitoreo

```bash
# Progreso en tiempo real
tail -f spec/*/progress.txt

# Estado de waves
cat spec/*/prd.json | jq '.waves[] | {id, name, status}'

# Scores de revisión final
cat spec/*/reports/FINAL_REPORT.json | jq '.review_scores'

# Ver reporte final
cat spec/*/reports/FINAL_REPORT.md
```

---

## 🐛 Troubleshooting

| Error | Solución |
|-------|----------|
| Claude Code no instalado | `npm install -g @anthropic-ai/claude-code` |
| jq no instalado | `sudo apt install jq` |
| bc no instalado (scores = 0) | `sudo apt install bc` |
| Loop no termina | Revisar `progress.txt`, Ctrl+C |
| Validator rechaza | Ver `validator_*_feedback.json` |

---

## 💡 Buenas Prácticas

1. **Prompts claros**: Describe la tarea con detalle suficiente
2. **Scope acotado**: Mejor varias ejecuciones pequeñas que una gigante
3. **Revisar PRD**: Antes de ejecutar, revisar que las waves tienen sentido
4. **Monitorear**: `tail -f spec/[id]/progress.txt`
5. **Backup**: El código se commitea, pero ten backup antes de ejecutar
6. **Task types**: Usar el tipo correcto mejora validación

---

## 📝 Ejemplo Completo

```bash
# 1. Ejecutar tarea
./orchestrator.sh "Agregar CRUD de productos con validaciones y tests"

# 2. Monitorear (otra terminal)
tail -f spec/*/progress.txt

# 3. Ver scores
cat spec/*/reports/FINAL_REPORT.json | jq '.review_scores'

# 4. Ver resultado
cat spec/*/reports/FINAL_REPORT.md
```

---

## 📚 Referencias

- [Ralph Loop](https://www.youtube.com/watch?v=eD4CEZ-_-sk) - Concepto original de All About AI
- [Claude Code CLI](https://github.com/anthropics/claude-code)

---

## 🤝 Contribuir

1. Fork el repositorio
2. Crear branch (`git checkout -b feature/nueva-feature`)
3. Commit cambios (`git commit -m 'feat: agregar feature'`)
4. Push (`git push origin feature/nueva-feature`)
5. Crear Pull Request

---

## 📄 Licencia

MIT License

---

*Ralph Orchestrator v1.0.0*
