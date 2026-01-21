<div align="center">

```
 ███████╗ ██╗          ██╗       ██████╗   ██████╗  ██████╗
 ██╔════╝ ██║          ██║      ██╔═══██╗ ██╔════╝ ██╔═══██╗
 █████╗   ██║          ██║      ██║   ██║ ██║      ██║   ██║
 ██╔══╝   ██║          ██║      ██║   ██║ ██║      ██║   ██║
 ███████╗ ███████╗     ███████╗ ╚██████╔╝ ╚██████╗ ╚██████╔╝
 ╚══════╝ ╚══════╝     ╚══════╝  ╚═════╝   ╚═════╝  ╚═════╝

 ██████╗   █████╗  ██╗      ██████╗  ██╗  ██╗
 ██╔══██╗ ██╔══██╗ ██║      ██╔══██╗ ██║  ██║
 ██████╔╝ ███████║ ██║      ██████╔╝ ███████║
 ██╔══██╗ ██╔══██║ ██║      ██╔═══╝  ██╔══██║
 ██║  ██║ ██║  ██║ ███████╗ ██║      ██║  ██║
 ╚═╝  ╚═╝ ╚═╝  ╚═╝ ╚══════╝ ╚═╝      ╚═╝  ╚═╝
```

### 🤖 Sistema de Orquestación Multi-Agente para Desarrollo Autónomo

[![Claude Code](https://img.shields.io/badge/Claude%20Code-Opus%204-blue?style=for-the-badge&logo=anthropic)](https://claude.ai)
[![Version](https://img.shields.io/badge/Version-1.0.0-green?style=for-the-badge)](CHANGELOG.md)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)
[![Shell](https://img.shields.io/badge/Shell-Bash-orange?style=for-the-badge&logo=gnu-bash)](https://www.gnu.org/software/bash/)

**Ralph coordina 18 agentes especializados en 5 fases para implementar tareas de desarrollo de forma autónoma.**

[Inicio Rápido](#-quick-start) •
[Arquitectura](#-architecture-overview) •
[Agentes](#-agents-catalog) •
[Documentación](#-output-structure)

</div>

---

## ✨ Highlights

| Feature | Descripción |
|---------|-------------|
| 🔄 **Multi-Agente** | 18 agentes especializados trabajando en coordinación |
| 📊 **5 Fases** | Input → Exploración → Planificación → Ejecución → Revisión |
| ⚡ **Paralelo** | Hasta 6 agentes simultáneos por wave |
| 🔁 **Iterativo** | Loop Executor/Validator con feedback hasta aprobar |
| 🛡️ **Triple Review** | Security + Tests + Architecture automáticos |
| 📈 **Métricas** | Reportes JSON con scores consolidados |
| 🎯 **7 Task Types** | code, documentation, testing, refactoring, etc. |

---

## 📑 Table of Contents

- [Architecture Overview](#-architecture-overview)
- [System Phases](#-system-phases)
  - [Phase 1: Input & Setup](#phase-1-input--setup)
  - [Phase 2: Exploration](#phase-2-exploration)
  - [Phase 3: Planning](#phase-3-planning)
  - [Phase 4: Execution](#phase-4-execution)
  - [Phase 5: Final Review](#phase-5-final-review)
- [Quick Start](#-quick-start)
- [CLI Reference](#-cli-reference)
- [Agents Catalog](#-agents-catalog)
- [Task Types](#-task-types)
- [Output Structure](#-output-structure)
- [Configuration](#-configuration)
- [Monitoring](#-monitoring)
- [Troubleshooting](#-troubleshooting)
- [Examples](#-examples)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🏗 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                              RALPH ORCHESTRATOR v1.0                                     │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                          │
│   ┌──────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────────────────┐  │
│   │  FASE 1  │───▶│   FASE 2     │───▶│   FASE 3     │───▶│        FASE 4            │  │
│   │  INPUT   │    │ EXPLORATION  │    │  PLANNING    │    │   PRD + RALPH LOOP       │  │
│   │  SETUP   │    │  (paralelo)  │    │  (paralelo)  │    │     (iterativo)          │  │
│   └──────────┘    └──────────────┘    └──────────────┘    └──────────────────────────┘  │
│        │                 │                   │                        │                 │
│        ▼                 ▼                   ▼                        ▼                 │
│   ┌──────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────────────────┐  │
│   │input.md  │    │  6 Explorers │    │  6 Planners  │    │  Executor ⟷ Validator    │  │
│   │metadata  │    │              │    │              │    │      (max 3 retry)       │  │
│   └──────────┘    └──────────────┘    └──────────────┘    └──────────────────────────┘  │
│                          │                   │                        │                 │
│                          ▼                   ▼                        ▼                 │
│                    ┌──────────┐        ┌──────────┐           ┌──────────────┐          │
│                    │ context/ │        │  plan/   │           │   FASE 5     │          │
│                    └──────────┘        └──────────┘           │   REVIEW     │          │
│                                                               │  (paralelo)  │          │
│                                                               └──────────────┘          │
│                                                                      │                  │
│                                                                      ▼                  │
│                                                               ┌──────────────┐          │
│                                                               │   reports/   │          │
│                                                               │ FINAL_REPORT │          │
│                                                               └──────────────┘          │
│                                                                                          │
│  ════════════════════════════════════════════════════════════════════════════════════   │
│                                                                                          │
│   📊 Components:  18 agents  │  5 phases  │  7 task types  │  3 reviewers              │
│   ⚡ Parallelism: max 6 agents/wave  │  async execution  │  background jobs            │
│   🔄 Iterations:  max 100 loop  │  max 3 retry/task  │  feedback-driven               │
│                                                                                          │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

### Principio Fundamental

> **El orquestador NO escribe código.** Solo coordina agentes especializados que realizan el trabajo.

### Flujo de Datos

```
User Prompt ──▶ input.md ──▶ Explorers ──▶ context/*.md
                                              │
                                              ▼
                                         classification.json
                                              │
                            ┌─────────────────┼─────────────────┐
                            ▼                 ▼                 ▼
                    planner_arch      planner_api       planner_db
                            │                 │                 │
                            └─────────────────┼─────────────────┘
                                              ▼
                                   IMPLEMENTATION_PLAN.md
                                              │
                                              ▼
                                          prd.json
                                              │
                     ┌────────────────────────┼────────────────────────┐
                     ▼                        ▼                        ▼
                  Wave 1                   Wave 2                   Wave N
               (parallel)               (parallel)               (parallel)
                     │                        │                        │
                     ▼                        ▼                        ▼
              [Exec→Valid]            [Exec→Valid]            [Exec→Valid]
                     │                        │                        │
                     └────────────────────────┼────────────────────────┘
                                              ▼
                                    Triple Review (parallel)
                                              │
                                              ▼
                                       FINAL_REPORT
```

---

## 🔄 System Phases

### Phase 1: Input & Setup

**Responsable:** `orchestrator.sh` → `setup_execution()`

| Componente | Descripción |
|------------|-------------|
| **Input** | Prompt del usuario o archivo PRD existente |
| **Output** | Directorio `spec/{exec_id}/` inicializado |
| **Archivos** | `input.md`, `metadata.json` |

```bash
# Estructura creada
spec/{timestamp}_{random}/
├── input.md          # Prompt original
├── metadata.json     # Configuración de ejecución
├── context/          # (vacío, para Fase 2)
├── plan/             # (vacío, para Fase 3)
├── communication/    # (vacío, para Fase 4)
├── logs/             # (vacío, para logs)
└── reports/          # (vacío, para Fase 5)
```

**metadata.json:**
```json
{
  "execution_id": "20260121_143052_abc123",
  "timestamp": "2026-01-21T14:30:52Z",
  "model": "opus",
  "project_path": "/path/to/project",
  "status": "initialized"
}
```

---

### Phase 2: Exploration

**Responsable:** `orchestrator.sh` → `run_exploration_phase()`

> Analiza el contexto del proyecto y la tarea solicitada.

#### Ejecución en 2 Etapas

```
┌────────────────────────────────────────────────────────────────────────────┐
│                        FASE 2: EXPLORACIÓN                                  │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ETAPA 1 (secuencial):                                                    │
│   ┌─────────────────────┐                                                  │
│   │ explorer_classifier │──▶ classification.json                           │
│   └─────────────────────┘                                                  │
│              │                                                              │
│              ▼ (condiciona siguiente etapa)                                │
│                                                                             │
│   ETAPA 2 (paralelo, hasta 5 agentes):                                     │
│   ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐             │
│   │ explorer_task   │ │ explorer_domain │ │explorer_constrs │             │
│   └─────────────────┘ └─────────────────┘ └─────────────────┘             │
│           │                   │                    │                       │
│           ▼                   ▼                    ▼                       │
│   task_analysis.md    domain_analysis.md   constraints.md                  │
│                                                                             │
│   ┌─────────────────┐ ┌─────────────────┐  (si has_code=true)             │
│   │explorer_codebase│ │ explorer_stack  │                                  │
│   └─────────────────┘ └─────────────────┘                                  │
│           │                   │                                            │
│           ▼                   ▼                                            │
│   codebase_analysis.md  stack_analysis.md                                  │
│                                                                             │
└────────────────────────────────────────────────────────────────────────────┘
```

#### Explorers Reference

| Agente | Output | Descripción |
|--------|--------|-------------|
| `explorer_classifier` | `classification.json` | Clasifica tarea, detecta `has_code`, `has_api`, `has_database`, `has_frontend`, `scope` |
| `explorer_task` | `task_analysis.md` | Extrae requerimientos explícitos e implícitos, prioridades, criterios de éxito |
| `explorer_domain` | `domain_analysis.md` | Identifica entidades de dominio, reglas de negocio, vocabulario |
| `explorer_constraints` | `constraints.md` | Detecta NFRs, limitaciones técnicas, compliance, performance targets |
| `explorer_codebase` | `codebase_analysis.md` | Mapea estructura de código, patrones existentes, archivos clave |
| `explorer_stack` | `stack_analysis.md` | Analiza tecnologías, dependencias, versiones, compatibilidades |

#### classification.json Schema

```json
{
  "task_type": "feature|bugfix|refactoring|documentation|testing",
  "scope": "small|medium|large",
  "complexity": "low|medium|high",
  "has_code": true,
  "has_api": true,
  "has_database": false,
  "has_frontend": true,
  "has_tests": true,
  "technologies": ["typescript", "react", "node"],
  "estimated_waves": 3
}
```

---

### Phase 3: Planning

**Responsable:** `orchestrator.sh` → `run_planning_phase()`

> Diseña la solución técnica basándose en el contexto explorado.

#### Planners Adaptativos

Los planners se ejecutan **condicionalmente** según `classification.json`:

```
┌────────────────────────────────────────────────────────────────────────────┐
│                        FASE 3: PLANIFICACIÓN                                │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   SIEMPRE se ejecutan:                                                     │
│   ┌───────────────────┐ ┌───────────────────┐                              │
│   │planner_architecture│ │ planner_testing  │                              │
│   └───────────────────┘ └───────────────────┘                              │
│            │                     │                                          │
│            ▼                     ▼                                          │
│     architecture.md      testing_strategy.md                                │
│                                                                             │
│   CONDICIONALES (según classification.json):                               │
│   ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐             │
│   │  planner_api    │ │ planner_database│ │planner_frontend │             │
│   │ (si has_api)    │ │(si has_database)│ │(si has_frontend)│             │
│   └─────────────────┘ └─────────────────┘ └─────────────────┘             │
│            │                   │                   │                        │
│            ▼                   ▼                   ▼                        │
│    api_contracts.md      database.md        frontend.md                    │
│                                                                             │
│   SIEMPRE AL FINAL (secuencial, espera a los demás):                       │
│   ┌───────────────────────┐                                                │
│   │ planner_consolidator  │──▶ IMPLEMENTATION_PLAN.md                      │
│   └───────────────────────┘                                                │
│                                                                             │
└────────────────────────────────────────────────────────────────────────────┘
```

#### Planners Reference

| Agente | Output | Condición | Descripción |
|--------|--------|-----------|-------------|
| `planner_architecture` | `architecture.md` | Siempre | Componentes, capas, dependencias, diagramas |
| `planner_api` | `api_contracts.md` | `has_api=true` | Endpoints REST, request/response schemas, validaciones |
| `planner_database` | `database.md` | `has_database=true` | Modelos, migraciones, índices, constraints |
| `planner_frontend` | `frontend.md` | `has_frontend=true` | Componentes React, estado, rutas, UI/UX |
| `planner_testing` | `testing_strategy.md` | Siempre | Estrategia de tests, cobertura targets, edge cases |
| `planner_consolidator` | `IMPLEMENTATION_PLAN.md` | Siempre (último) | Consolida todo en plan con waves y tasks |

#### IMPLEMENTATION_PLAN.md → prd.json

El consolidator genera un plan estructurado que se transforma en `prd.json`:

```
IMPLEMENTATION_PLAN.md                    prd.json
┌────────────────────────┐               ┌────────────────────────┐
│ ## Wave 1: Foundation  │               │ {                      │
│ - Task 1.1: Setup DB   │      ─▶       │   "waves": [{          │
│ - Task 1.2: Models     │               │     "id": "wave_1",    │
│                        │               │     "tasks": [...]     │
│ ## Wave 2: API         │               │   }]                   │
│ - Task 2.1: Endpoints  │               │ }                      │
└────────────────────────┘               └────────────────────────┘
```

---

### Phase 4: Execution

**Responsable:** `scripts/ralph.sh` → `execute_wave()`, `execute_task()`

> Implementa las tareas definidas en el PRD mediante el loop Executor-Validator.

#### Ralph Loop

```
┌───────────────────────────────────────────────────────────────────────────────┐
│                           RALPH LOOP (Fase 4b)                                 │
├───────────────────────────────────────────────────────────────────────────────┤
│                                                                                │
│   Para cada Wave (secuencial):                                                │
│   ┌─────────────────────────────────────────────────────────────────────────┐ │
│   │                    WAVE N (paralelo, max 6 tasks)                       │ │
│   │                                                                          │ │
│   │   ┌───────────┐   ┌───────────┐   ┌───────────┐   ┌───────────┐        │ │
│   │   │  Task 1   │   │  Task 2   │   │  Task 3   │   │  Task N   │        │ │
│   │   │           │   │           │   │           │   │           │        │ │
│   │   │ ┌───────┐ │   │ ┌───────┐ │   │ ┌───────┐ │   │ ┌───────┐ │        │ │
│   │   │ │Executor│ │   │ │Executor│ │   │ │Executor│ │   │ │Executor│ │        │ │
│   │   │ └───┬───┘ │   │ └───┬───┘ │   │ └───┬───┘ │   │ └───┬───┘ │        │ │
│   │   │     │     │   │     │     │   │     │     │   │     │     │        │ │
│   │   │     ▼     │   │     ▼     │   │     ▼     │   │     ▼     │        │ │
│   │   │ ┌───────┐ │   │ ┌───────┐ │   │ ┌───────┐ │   │ ┌───────┐ │        │ │
│   │   │ │Validtr│ │   │ │Validtr│ │   │ │Validtr│ │   │ │Validtr│ │        │ │
│   │   │ └───┬───┘ │   │ └───┬───┘ │   │ └───┬───┘ │   │ └───┬───┘ │        │ │
│   │   │     │     │   │     │     │   │     │     │   │     │     │        │ │
│   │   │  approved?│   │  approved?│   │  approved?│   │  approved?│        │ │
│   │   │   ✓/✗    │   │   ✓/✗    │   │   ✓/✗    │   │   ✓/✗    │        │ │
│   │   └───────────┘   └───────────┘   └───────────┘   └───────────┘        │ │
│   │         │               │               │               │              │ │
│   │         └───────────────┴───────────────┴───────────────┘              │ │
│   │                                   │                                     │ │
│   │                                   ▼                                     │ │
│   │                         ┌─────────────────┐                            │ │
│   │                         │ All approved?   │                            │ │
│   │                         │   YES → Next    │                            │ │
│   │                         │   NO  → Retry   │                            │ │
│   │                         │   (max 3/task)  │                            │ │
│   │                         └─────────────────┘                            │ │
│   └─────────────────────────────────────────────────────────────────────────┘ │
│                                                                                │
│   Repeat for Wave N+1...                                                      │
│                                                                                │
└───────────────────────────────────────────────────────────────────────────────┘
```

#### Executor

El **Executor** implementa la tarea según su `task_type`:

| Task Type | Comportamiento | Output |
|-----------|----------------|--------|
| `code` | Implementa funcionalidades, escribe código | Archivos modificados/creados |
| `documentation` | Crea/actualiza documentación | Archivos .md |
| `configuration` | Modifica configs (yaml, json, env) | Archivos de config |
| `research` | Investiga, analiza, reporta | Markdown con findings |
| `testing` | Escribe tests | Archivos de test |
| `refactoring` | Refactoriza código existente | Código mejorado |
| `general` | Tareas no clasificadas | Variable |

**Output:** `communication/executor_{task_id}_output.json`

```json
{
  "task_id": "task_1_1",
  "status": "completed",
  "files_modified": ["src/api/users.ts", "src/models/User.ts"],
  "files_created": ["src/api/users.test.ts"],
  "summary": "Implemented user CRUD endpoints",
  "commits": ["abc123: feat: add user endpoints"]
}
```

#### Validator

El **Validator** evalúa el trabajo del Executor según criterios específicos por `task_type`:

| Task Type | Criterios de Validación |
|-----------|-------------------------|
| `code` | Tests pasan, código limpio, sin errores de lint, funcionalidad correcta |
| `documentation` | Formato correcto, completo, sin typos, enlaces válidos |
| `configuration` | Sintaxis válida, valores correctos, no secrets expuestos |
| `research` | Información relevante, fuentes citadas, conclusiones claras |
| `testing` | Cobertura adecuada, assertions correctos, edge cases cubiertos |
| `refactoring` | Funcionalidad preservada, mejoras visibles, tests pasan |
| `general` | Completitud, calidad general |

**Output:** `communication/validator_{task_id}_feedback.json`

```json
{
  "task_id": "task_1_1",
  "approved": true,
  "score": 85,
  "feedback": "Implementation is correct. Minor suggestion: add input validation.",
  "issues": [],
  "suggestions": ["Add Zod schema for request validation"]
}
```

---

### Phase 5: Final Review

**Responsable:** `scripts/ralph.sh` → `execute_final_review()`, `generate_final_report()`

> Triple revisión automática de Security, Tests y Architecture.

```
┌────────────────────────────────────────────────────────────────────────────┐
│                        FASE 5: REVISIÓN FINAL                               │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   PARALELO (3 reviewers simultáneos):                                      │
│                                                                             │
│   ┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐          │
│   │ security_reviewer│ │  tests_reviewer  │ │architect_reviewer│          │
│   └────────┬─────────┘ └────────┬─────────┘ └────────┬─────────┘          │
│            │                    │                    │                     │
│            ▼                    ▼                    ▼                     │
│   ┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐          │
│   │security_review   │ │  tests_review    │ │architecture_     │          │
│   │    .json         │ │     .json        │ │   review.json    │          │
│   └──────────────────┘ └──────────────────┘ └──────────────────┘          │
│            │                    │                    │                     │
│            └────────────────────┼────────────────────┘                     │
│                                 │                                          │
│                                 ▼                                          │
│                    ┌─────────────────────────┐                             │
│                    │   generate_final_report │                             │
│                    └────────────┬────────────┘                             │
│                                 │                                          │
│                                 ▼                                          │
│                    ┌─────────────────────────┐                             │
│                    │    FINAL_REPORT.json    │                             │
│                    │    FINAL_REPORT.md      │                             │
│                    └─────────────────────────┘                             │
│                                                                             │
└────────────────────────────────────────────────────────────────────────────┘
```

#### Reviewers Reference

| Reviewer | Output | Focus |
|----------|--------|-------|
| `security_reviewer` | `security_review.json` | OWASP Top 10, secrets exposure, input validation, auth/authz |
| `tests_reviewer` | `tests_review.json` | Coverage, test quality, edge cases, assertions |
| `architecture_reviewer` | `architecture_review.json` | SOLID principles, dependencies, patterns, scalability |

#### FINAL_REPORT.json Schema

```json
{
  "execution_id": "20260121_143052_abc123",
  "status": "completed",
  "duration_minutes": 45,
  "waves_completed": 3,
  "tasks_completed": 12,
  "tasks_failed": 0,
  "review_scores": {
    "security": 92,
    "tests": 88,
    "architecture": 95,
    "overall": 91.67
  },
  "issues": {
    "critical": 0,
    "high": 1,
    "medium": 3,
    "low": 5
  },
  "recommendations": [
    "Add rate limiting to API endpoints",
    "Increase test coverage for edge cases"
  ]
}
```

---

## 🚀 Quick Start

### Prerequisites

| Dependency | Version | Installation |
|------------|---------|--------------|
| Claude Code CLI | Latest | `npm install -g @anthropic-ai/claude-code` |
| jq | 1.6+ | `sudo apt install jq` |
| bc | Any | `sudo apt install bc` |
| Bash | 4.0+ | Pre-installed |

### Installation

```bash
# Clone repository
git clone https://github.com/Dreadblitz/Orquestador-El-Loco-Ralph.git
cd Orquestador-El-Loco-Ralph

# Make scripts executable
chmod +x orchestrator.sh scripts/*.sh

# Verify installation
./orchestrator.sh --help
```

### First Run

```bash
# Basic execution
./orchestrator.sh "Implementar sistema de autenticación JWT"

# With existing PRD
./orchestrator.sh --prd spec/existing/prd.json

# With debug logging
DEBUG=1 ./orchestrator.sh "Mi tarea"

# Specify different project
./orchestrator.sh "tarea" --project-path /path/to/project
```

---

## 📖 CLI Reference

### Syntax

```bash
./orchestrator.sh [OPTIONS] "TASK_DESCRIPTION"
./orchestrator.sh --prd PATH_TO_PRD
```

### Options

| Option | Description | Example |
|--------|-------------|---------|
| `--prd <path>` | Use existing PRD file | `--prd spec/my/prd.json` |
| `--project-path <path>` | Target project directory | `--project-path /home/user/myapp` |
| `--help` | Show help message | `--help` |

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DEBUG` | `0` | Enable verbose logging (`0`/`1`) |
| `MAX_PARALLEL_AGENTS` | `6` | Max agents per wave |
| `MAX_ITERATIONS` | `100` | Max loop iterations |
| `MAX_CODER_ITERATIONS` | `3` | Max retries per task |
| `PROJECT_PATH` | `$(pwd)` | Target project path |

### Examples

```bash
# Feature implementation
./orchestrator.sh "Agregar endpoint REST para gestión de productos con CRUD, validaciones y tests"

# Bug fix
./orchestrator.sh "Corregir bug de autenticación donde el token expira prematuramente"

# Refactoring
./orchestrator.sh "Refactorizar módulo de pagos para usar patrón Strategy"

# Documentation
./orchestrator.sh "Documentar API REST con OpenAPI 3.0"

# Testing
./orchestrator.sh "Agregar tests de integración para el módulo de usuarios"
```

---

## 🤖 Agents Catalog

### Overview

Ralph coordina **18 agentes especializados** organizados por fase:

```
┌─────────────────────────────────────────────────────────────────┐
│                     AGENTS OVERVIEW                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   FASE 2: EXPLORATION (6 agents)                                │
│   ├── explorer_classifier    → classification.json              │
│   ├── explorer_task          → task_analysis.md                 │
│   ├── explorer_domain        → domain_analysis.md               │
│   ├── explorer_constraints   → constraints.md                   │
│   ├── explorer_codebase      → codebase_analysis.md             │
│   └── explorer_stack         → stack_analysis.md                │
│                                                                  │
│   FASE 3: PLANNING (6 agents)                                   │
│   ├── planner_architecture   → architecture.md                  │
│   ├── planner_api            → api_contracts.md                 │
│   ├── planner_database       → database.md                      │
│   ├── planner_frontend       → frontend.md                      │
│   ├── planner_testing        → testing_strategy.md              │
│   └── planner_consolidator   → IMPLEMENTATION_PLAN.md           │
│                                                                  │
│   FASE 4: EXECUTION (2 agents)                                  │
│   ├── executor               → executor_*_output.json           │
│   └── validator              → validator_*_feedback.json        │
│                                                                  │
│   FASE 5: REVIEW (3 agents)                                     │
│   ├── security_reviewer      → security_review.json             │
│   ├── tests_reviewer         → tests_review.json                │
│   └── architecture_reviewer  → architecture_review.json         │
│                                                                  │
│   BONUS: BROWSER (1 agent)                                      │
│   └── browser_tester         → E2E testing                      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Explorers (Phase 2)

<details>
<summary><b>explorer_classifier</b> - Task Classification</summary>

**File:** `agents/explorer_classifier.md`
**Output:** `context/classification.json`
**Execution:** Sequential (runs first)

**Responsibilities:**
- Classify task type (feature, bugfix, refactoring, etc.)
- Detect project characteristics (has_code, has_api, has_database, has_frontend)
- Estimate scope and complexity
- Identify technologies involved

**Output Schema:**
```json
{
  "task_type": "feature",
  "scope": "medium",
  "complexity": "high",
  "has_code": true,
  "has_api": true,
  "has_database": true,
  "has_frontend": false,
  "has_tests": true,
  "technologies": ["python", "fastapi", "postgresql"],
  "estimated_waves": 4
}
```
</details>

<details>
<summary><b>explorer_task</b> - Requirements Analysis</summary>

**File:** `agents/explorer_task.md`
**Output:** `context/task_analysis.md`
**Execution:** Parallel (after classifier)

**Responsibilities:**
- Extract explicit requirements from prompt
- Infer implicit requirements
- Define acceptance criteria
- Identify dependencies and blockers
- Prioritize features
</details>

<details>
<summary><b>explorer_domain</b> - Domain Analysis</summary>

**File:** `agents/explorer_domain.md`
**Output:** `context/domain_analysis.md`
**Execution:** Parallel (after classifier)

**Responsibilities:**
- Identify domain entities and relationships
- Define business rules
- Map domain vocabulary
- Identify bounded contexts
</details>

<details>
<summary><b>explorer_constraints</b> - Constraints Detection</summary>

**File:** `agents/explorer_constraints.md`
**Output:** `context/constraints.md`
**Execution:** Parallel (after classifier)

**Responsibilities:**
- Identify technical constraints
- Define non-functional requirements (NFRs)
- Detect compliance requirements
- Set performance targets
</details>

<details>
<summary><b>explorer_codebase</b> - Codebase Analysis</summary>

**File:** `agents/explorer_codebase.md`
**Output:** `context/codebase_analysis.md`
**Execution:** Parallel (if has_code=true)

**Responsibilities:**
- Map project structure
- Identify coding patterns
- Find key files and modules
- Detect code smells
</details>

<details>
<summary><b>explorer_stack</b> - Stack Analysis</summary>

**File:** `agents/explorer_stack.md`
**Output:** `context/stack_analysis.md`
**Execution:** Parallel (if has_code=true)

**Responsibilities:**
- Identify technologies and frameworks
- List dependencies and versions
- Check compatibility issues
- Recommend updates
</details>

### Planners (Phase 3)

<details>
<summary><b>planner_architecture</b> - Architecture Design</summary>

**File:** `agents/planner_architecture.md`
**Output:** `plan/architecture.md`
**Execution:** Parallel (always runs)

**Responsibilities:**
- Design system architecture
- Define components and layers
- Establish patterns and principles
- Create architecture diagrams
</details>

<details>
<summary><b>planner_api</b> - API Contracts</summary>

**File:** `agents/planner_api.md`
**Output:** `plan/api_contracts.md`
**Execution:** Parallel (if has_api=true)

**Responsibilities:**
- Define REST endpoints
- Design request/response schemas
- Specify validations
- Document authentication
</details>

<details>
<summary><b>planner_database</b> - Database Design</summary>

**File:** `agents/planner_database.md`
**Output:** `plan/database.md`
**Execution:** Parallel (if has_database=true)

**Responsibilities:**
- Design data models
- Plan migrations
- Define indexes and constraints
- Optimize queries
</details>

<details>
<summary><b>planner_frontend</b> - Frontend Planning</summary>

**File:** `agents/planner_frontend.md`
**Output:** `plan/frontend.md`
**Execution:** Parallel (if has_frontend=true)

**Responsibilities:**
- Design component hierarchy
- Plan state management
- Define routes
- Specify UI/UX patterns
</details>

<details>
<summary><b>planner_testing</b> - Testing Strategy</summary>

**File:** `agents/planner_testing.md`
**Output:** `plan/testing_strategy.md`
**Execution:** Parallel (always runs)

**Responsibilities:**
- Define testing strategy
- Set coverage targets
- Identify edge cases
- Plan test data
</details>

<details>
<summary><b>planner_consolidator</b> - Plan Consolidation</summary>

**File:** `agents/planner_consolidator.md`
**Output:** `plan/IMPLEMENTATION_PLAN.md`
**Execution:** Sequential (runs last)

**Responsibilities:**
- Consolidate all plans
- Organize into waves
- Define atomic tasks
- Establish dependencies
- Generate PRD structure
</details>

### Executors (Phase 4)

<details>
<summary><b>executor</b> - Task Implementation</summary>

**File:** `agents/executor.md`
**Output:** `communication/executor_{task_id}_output.json`

**Behavior by Task Type:**

| Type | Actions |
|------|---------|
| `code` | Write code, create files, run tests |
| `documentation` | Write/update docs, generate API docs |
| `configuration` | Modify configs, environment setup |
| `research` | Analyze, investigate, report findings |
| `testing` | Write tests, setup fixtures |
| `refactoring` | Restructure code, improve patterns |
| `general` | Variable based on description |
</details>

<details>
<summary><b>validator</b> - Quality Validation</summary>

**File:** `agents/validator.md`
**Output:** `communication/validator_{task_id}_feedback.json`

**Validation Criteria by Task Type:**

| Type | Criteria |
|------|----------|
| `code` | Tests pass, no lint errors, clean code |
| `documentation` | Complete, correct format, no typos |
| `configuration` | Valid syntax, correct values |
| `research` | Relevant info, sources cited |
| `testing` | Good coverage, correct assertions |
| `refactoring` | Behavior preserved, improvements visible |
| `general` | Completeness, quality |
</details>

### Reviewers (Phase 5)

<details>
<summary><b>security_reviewer</b> - Security Audit</summary>

**File:** `agents/security_reviewer.md`
**Output:** `reports/security_review.json`

**Checks:**
- OWASP Top 10 vulnerabilities
- Secrets exposure
- Input validation
- Authentication/Authorization
- SQL injection, XSS, CSRF
- Dependency vulnerabilities
</details>

<details>
<summary><b>tests_reviewer</b> - Test Quality</summary>

**File:** `agents/tests_reviewer.md`
**Output:** `reports/tests_review.json`

**Checks:**
- Code coverage percentage
- Test quality and readability
- Edge cases coverage
- Assertion correctness
- Test isolation
- Mock usage
</details>

<details>
<summary><b>architecture_reviewer</b> - Architecture Review</summary>

**File:** `agents/architecture_reviewer.md`
**Output:** `reports/architecture_review.json`

**Checks:**
- SOLID principles adherence
- Dependency management
- Design patterns usage
- Scalability considerations
- Code organization
- Module coupling
</details>

---

## 🎯 Task Types

Ralph soporta **7 tipos de tareas** con comportamiento adaptativo:

| Type | Description | Executor Actions | Validator Criteria | Commits |
|------|-------------|------------------|-------------------|---------|
| `code` | Feature implementation | Write code, create files, run tests | Tests pass, clean code, functionality works | ✅ Yes |
| `documentation` | Create/update docs | Write markdown, generate API docs | Format correct, complete, no typos | ✅ Yes |
| `configuration` | Modify configs | Update yaml/json/env files | Valid syntax, correct values, no secrets | ✅ Yes |
| `research` | Investigation & analysis | Analyze, search, compile findings | Relevant info, sources cited, clear conclusions | ❌ No |
| `testing` | Write tests | Create test files, setup fixtures | Good coverage, correct assertions, edge cases | ✅ Yes |
| `refactoring` | Restructure code | Reorganize, apply patterns, clean up | Behavior preserved, improvements visible | ✅ Yes |
| `general` | Unclassified tasks | Variable based on description | Completeness, quality | ✅ Yes* |

*General commits only if files are modified.

---

## 📁 Output Structure

Cada ejecución genera la siguiente estructura:

```
spec/{execution_id}/
│
├── input.md                              # 📝 Original user prompt
├── metadata.json                         # ⚙️ Execution configuration
│
├── context/                              # 📊 Phase 2: Exploration Results
│   ├── classification.json               # Task classification and flags
│   ├── task_analysis.md                  # Requirements breakdown
│   ├── domain_analysis.md                # Domain concepts and rules
│   ├── constraints.md                    # NFRs and limitations
│   ├── codebase_analysis.md              # Code structure (if has_code)
│   └── stack_analysis.md                 # Technology stack (if has_code)
│
├── plan/                                 # 📐 Phase 3: Planning Results
│   ├── architecture.md                   # System architecture design
│   ├── api_contracts.md                  # API endpoints (if has_api)
│   ├── database.md                       # Data models (if has_database)
│   ├── frontend.md                       # UI components (if has_frontend)
│   ├── testing_strategy.md               # Test strategy
│   └── IMPLEMENTATION_PLAN.md            # ⭐ Consolidated plan with waves
│
├── prd.json                              # 📋 Phase 4a: PRD with waves/tasks
│
├── communication/                        # 💬 Phase 4b: Executor/Validator Messages
│   ├── executor_task_1_1_output.json     # Executor output for task 1.1
│   ├── validator_task_1_1_feedback.json  # Validator feedback for task 1.1
│   ├── executor_task_1_2_output.json     # ...
│   └── validator_task_1_2_feedback.json  # ...
│
├── logs/                                 # 📝 Execution Logs
│   ├── phase2_exploration.log
│   ├── phase3_planning.log
│   ├── phase4_execution.log
│   └── phase5_review.log
│
├── progress.txt                          # 📊 Real-time progress log
│
└── reports/                              # 📈 Phase 5: Final Reviews
    ├── security_review.json              # 🔒 Security audit results
    ├── tests_review.json                 # 🧪 Test quality analysis
    ├── architecture_review.json          # 🏗️ Architecture assessment
    ├── FINAL_REPORT.json                 # ⭐ Consolidated JSON report
    └── FINAL_REPORT.md                   # ⭐ Human-readable report
```

---

## ⚙️ Configuration

### Default Configuration

```bash
# In orchestrator.sh and scripts/utils.sh
MAX_PARALLEL_AGENTS=6      # Agents per wave
MAX_ITERATIONS=100         # Main loop iterations
MAX_CODER_ITERATIONS=3     # Retries per failed task
DEBUG=0                    # Verbose logging
PROJECT_PATH=$(pwd)        # Target project
```

### Runtime Override

```bash
# Override with environment variables
MAX_PARALLEL_AGENTS=4 MAX_ITERATIONS=50 ./orchestrator.sh "My task"

# Enable debug mode
DEBUG=1 ./orchestrator.sh "My task"

# Different project
PROJECT_PATH=/home/user/myproject ./orchestrator.sh "My task"
```

### Agent Model Configuration

All agents use **Claude Opus** model for maximum capability:

```bash
# In scripts/agent_launcher.sh
CLAUDE_MODEL="opus"
```

---

## 📊 Monitoring

### Real-time Progress

```bash
# Watch progress in real-time
tail -f spec/*/progress.txt

# Example output:
# [2026-01-21 14:30:52] Phase 2: Starting exploration...
# [2026-01-21 14:31:05] explorer_classifier: completed
# [2026-01-21 14:32:15] explorer_task: completed
# [2026-01-21 14:32:18] explorer_domain: completed
# [2026-01-21 14:33:00] Phase 2: Completed
# [2026-01-21 14:33:01] Phase 3: Starting planning...
```

### Wave Status

```bash
# Check wave status
cat spec/*/prd.json | jq '.waves[] | {id, name, status}'

# Example output:
# {"id": "wave_1", "name": "Foundation", "status": "completed"}
# {"id": "wave_2", "name": "API Layer", "status": "in_progress"}
# {"id": "wave_3", "name": "Frontend", "status": "pending"}
```

### Task Status

```bash
# Check all task statuses
cat spec/*/prd.json | jq '.waves[].tasks[] | {id, title, status}'

# Check failed tasks
cat spec/*/prd.json | jq '.waves[].tasks[] | select(.status == "failed")'
```

### Final Scores

```bash
# View review scores
cat spec/*/reports/FINAL_REPORT.json | jq '.review_scores'

# Example output:
# {
#   "security": 92,
#   "tests": 88,
#   "architecture": 95,
#   "overall": 91.67
# }
```

### Full Report

```bash
# View human-readable final report
cat spec/*/reports/FINAL_REPORT.md

# Or open in browser
xdg-open spec/*/reports/FINAL_REPORT.md
```

---

## 🔧 Troubleshooting

### Common Errors

<details>
<summary><b>Claude Code not installed</b></summary>

```bash
# Error: claude: command not found

# Solution:
npm install -g @anthropic-ai/claude-code

# Verify:
claude --version
```
</details>

<details>
<summary><b>jq not installed</b></summary>

```bash
# Error: jq: command not found

# Solution (Ubuntu/Debian):
sudo apt install jq

# Solution (macOS):
brew install jq

# Verify:
jq --version
```
</details>

<details>
<summary><b>bc not installed (scores show 0)</b></summary>

```bash
# Symptom: All scores in FINAL_REPORT show 0

# Solution:
sudo apt install bc

# Verify:
bc --version
```
</details>

<details>
<summary><b>Loop doesn't terminate</b></summary>

```bash
# Symptom: Execution runs indefinitely

# Diagnosis:
tail -f spec/*/progress.txt  # Check where it's stuck

# Solutions:
# 1. Cancel with Ctrl+C
# 2. Check MAX_ITERATIONS (default: 100)
# 3. Check if a task is failing repeatedly (MAX_CODER_ITERATIONS: 3)

# View stuck tasks:
cat spec/*/prd.json | jq '.waves[].tasks[] | select(.status == "in_progress")'
```
</details>

<details>
<summary><b>Validator always rejects</b></summary>

```bash
# Symptom: Tasks keep failing validation

# Diagnosis:
cat spec/*/communication/validator_*_feedback.json | jq '.feedback, .issues'

# Common causes:
# 1. Task type mismatch - check prd.json task types
# 2. Tests failing - check test output
# 3. Lint errors - check code quality

# Solutions:
# 1. Update task type in prd.json
# 2. Fix failing tests
# 3. Review validator criteria in agents/validator.md
```
</details>

<details>
<summary><b>Agent fails repeatedly</b></summary>

```bash
# Symptom: Same agent keeps failing

# Diagnosis:
cat spec/*/logs/*.log | grep -A5 "ERROR"

# Common causes:
# 1. Invalid prompt in agent file
# 2. Missing context files
# 3. Claude API issues

# Solutions:
# 1. Review agent prompt in agents/
# 2. Check context/ and plan/ directories have required files
# 3. Retry after a few minutes
```
</details>

### Debug Mode

```bash
# Enable verbose logging
DEBUG=1 ./orchestrator.sh "My task"

# This will show:
# - Full agent prompts
# - API responses
# - File operations
# - State transitions
```

### Log Files

```bash
# View all logs
ls -la spec/*/logs/

# View specific phase log
cat spec/*/logs/phase4_execution.log

# Search for errors
grep -r "ERROR\|FAIL" spec/*/logs/
```

---

## 📚 Examples

### Example 1: REST API Implementation

```bash
./orchestrator.sh "Implementar API REST para gestión de productos con:
- CRUD completo (GET, POST, PUT, DELETE)
- Validación de datos con Zod
- Autenticación JWT
- Tests de integración
- Documentación OpenAPI"
```

**Expected waves:**
1. Foundation: Database models, base setup
2. API Layer: CRUD endpoints, validation
3. Auth: JWT implementation
4. Testing: Integration tests
5. Documentation: OpenAPI specs

### Example 2: Bug Fix

```bash
./orchestrator.sh "Corregir bug en módulo de pagos donde:
- Las transacciones fallan silenciosamente cuando el monto es 0
- No se registra el error en logs
- El usuario no recibe notificación"
```

**Expected waves:**
1. Investigation: Identify root cause
2. Fix: Implement validation and error handling
3. Logging: Add proper error logging
4. Notification: Add user feedback
5. Testing: Add regression tests

### Example 3: Refactoring

```bash
./orchestrator.sh "Refactorizar módulo de autenticación para:
- Aplicar patrón Strategy para diferentes providers (Google, GitHub, Email)
- Separar lógica de negocio de infraestructura
- Mejorar testabilidad
- Mantener backward compatibility"
```

**Expected waves:**
1. Analysis: Current state assessment
2. Interface: Define Strategy interface
3. Implementation: Create concrete strategies
4. Migration: Update existing code
5. Testing: Verify behavior preserved

---

## 🤝 Contributing

### Development Setup

```bash
# Fork and clone
git clone https://github.com/YOUR_USERNAME/Orquestador-El-Loco-Ralph.git
cd Orquestador-El-Loco-Ralph

# Create feature branch
git checkout -b feature/my-feature

# Make changes and test
DEBUG=1 ./orchestrator.sh "Test task"

# Commit with conventional commits
git commit -m "feat: add new feature description"

# Push and create PR
git push origin feature/my-feature
```

### Commit Convention

| Prefix | Description |
|--------|-------------|
| `feat:` | New feature |
| `fix:` | Bug fix |
| `docs:` | Documentation changes |
| `refactor:` | Code refactoring |
| `test:` | Test changes |
| `chore:` | Maintenance tasks |

### Agent Development

To create a new agent:

1. Create prompt file in `agents/new_agent.md`
2. Add launcher function in `scripts/agent_launcher.sh`
3. Integrate in appropriate phase
4. Update documentation

### Pull Request Guidelines

- [ ] Tests pass locally
- [ ] Documentation updated
- [ ] Follows existing code style
- [ ] Commit messages follow convention
- [ ] PR description explains changes

---

## 📜 License

MIT License - see [LICENSE](LICENSE) for details.

---

## 🙏 Credits

- **[All About AI](https://www.youtube.com/@AllAboutAI)** - Original Ralph Loop concept
- **[Anthropic](https://www.anthropic.com/)** - Claude Code CLI
- **Contributors** - Thanks to all who contribute to this project

---

<div align="center">

**Ralph Orchestrator v1.0.0**

Made with 🤖 by [Dreadblitz](https://github.com/Dreadblitz)

[⬆ Back to Top](#-highlights)

</div>
