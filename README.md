# Orquestador El Loco Ralph

Sistema de orquestación multi-agente para desarrollo autónomo con Claude Code.

```
    ____        __      __       __                      ____        __      __
   / __ \____ _/ /___  / /_     / /   ____  _________   / __ \____ _/ /___  / /_
  / /_/ / __ `/ / __ \/ __ \   / /   / __ \/ ___/ __ \ / /_/ / __ `/ / __ \/ __ \
 / _, _/ /_/ / / /_/ / / / /  / /___/ /_/ / /__/ /_/ // _, _/ /_/ / / /_/ / / / /
/_/ |_|\__,_/_/ .___/_/ /_/  /_____/\____/\___/\____//_/ |_|\__,_/_/ .___/_/ /_/
             /_/                                                  /_/
```

---

## Concepto

Ralph es un **orquestador que NO escribe código**. Solo coordina agentes especializados de Claude Code para completar tareas complejas de desarrollo de forma autónoma.

```
PROMPT ──▶ EXPLORAR ──▶ PLANIFICAR ──▶ EJECUTAR ──▶ REVISAR
   │           │             │             │            │
   ▼           ▼             ▼             ▼            ▼
"Crear      5 agentes     6 agentes    Coder +      3 agentes
 login"     analizan      diseñan      Reviewer     revisan
            tu código     solución     en ciclo     calidad
```

---

## Instalación

### Requisitos

- [Claude Code CLI](https://github.com/anthropics/claude-code) instalado
- `jq` para procesamiento JSON
- Bash 4+

### Clonar e Instalar

```bash
# Clonar repositorio
git clone https://github.com/Dreadblitz/Orquestador-El-Loco-Ralph.git
cd Orquestador-El-Loco-Ralph

# Dar permisos de ejecución
chmod +x orchestrator.sh scripts/*.sh

# (Opcional) Instalar slash command
mkdir -p ~/.claude/commands
cp commands/ralph.md ~/.claude/commands/
# Editar el path en ~/.claude/commands/ralph.md si es necesario
```

---

## Uso

### Ejecución Directa

```bash
# Ejecutar con una tarea
./orchestrator.sh "Implementar sistema de autenticación JWT"

# Usar PRD existente
./orchestrator.sh --prd spec/existing/prd.json

# Con debug
DEBUG=1 ./orchestrator.sh "Mi tarea"

# Especificar proyecto diferente
./orchestrator.sh "tarea" --project-path /ruta/al/proyecto
```

### Slash Command (Claude Code)

Si instalaste el slash command:

```
/ralph Crear API REST para gestión de usuarios con CRUD
/ralph Agregar sistema de notificaciones por email
/ralph Refactorizar módulo de pagos usando patrón Strategy
```

---

## Las 5 Fases

| Fase | Qué hace | Agentes |
|------|----------|---------|
| **1. Exploración** | Analiza el proyecto actual | 5 explorers (paralelo) |
| **2. Planificación** | Diseña la solución completa | 6 planners (paralelo) |
| **3. PRD Generation** | Crea tareas organizadas en waves | Consolidator |
| **4. Ejecución** | Implementa el código | Coder → Reviewer (ciclo) |
| **5. Revisión Final** | Valida calidad | Security, Tests, Architecture |

---

## Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                   RALPH ORCHESTRATOR                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  INPUT ──▶ EXPLORE ──▶ PLAN ──▶ PRD ──▶ EXECUTE ──▶ REVIEW  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                    WAVES (Paralelo)                   │   │
│  │  Wave 1: [Task1] [Task2] [Task3] ← sin dependencias  │   │
│  │      ↓                                                │   │
│  │  Wave 2: [Task4] [Task5] ← dependen de Wave 1        │   │
│  │      ↓                                                │   │
│  │  Wave N: [TaskN]                                      │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Ciclo Coder-Reviewer

```
┌─────────────────────────────────────────┐
│              WAVE (paralelo)            │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐   │
│  │Coder1│ │Coder2│ │Coder3│ │Coder4│   │
│  └──┬───┘ └──┬───┘ └──┬───┘ └──┬───┘   │
│     │        │        │        │        │
│     ▼        ▼        ▼        ▼        │
│  ┌──────────────────────────────────┐   │
│  │          REVIEWER                │   │
│  │  ✓ Aprobado → Siguiente tarea    │   │
│  │  ✗ Feedback → Volver a Coder     │   │
│  └──────────────────────────────────┘   │
│           (máx 3 intentos)              │
└─────────────────────────────────────────┘
```

---

## Agentes Disponibles (18 total)

### Exploración (5)
| Agente | Rol |
|--------|-----|
| `explorer_structure` | Analiza estructura de carpetas |
| `explorer_tech` | Identifica tecnologías |
| `explorer_patterns` | Detecta patrones de código |
| `explorer_tests` | Analiza infraestructura de tests |
| `explorer_deps` | Mapea dependencias |

### Planificación (6)
| Agente | Rol |
|--------|-----|
| `planner_architecture` | Diseña arquitectura |
| `planner_api` | Define contratos de API |
| `planner_database` | Diseña modelos y migraciones |
| `planner_frontend` | Planifica componentes UI |
| `planner_testing` | Estrategia de tests |
| `planner_consolidator` | Genera plan unificado |

### Ejecución (3)
| Agente | Rol |
|--------|-----|
| `coder` | Implementa código |
| `reviewer` | Revisa y da feedback |
| `browser_tester` | Tests E2E con browser |

### Revisión Final (3)
| Agente | Rol |
|--------|-----|
| `security_reviewer` | Auditoría de seguridad |
| `tests_reviewer` | Calidad de tests |
| `architecture_reviewer` | Revisión arquitectónica |

---

## Estructura del Proyecto

```
ralph/
├── orchestrator.sh          # Entry point principal
├── scripts/
│   ├── utils.sh             # Funciones comunes
│   ├── agent_launcher.sh    # Lanzador de agentes
│   └── ralph.sh             # Loop de ejecución
├── agents/                  # Prompts de agentes (17 archivos)
├── templates/               # Templates JSON/MD
├── commands/                # Slash command para Claude Code
│   └── ralph.md
└── spec/                    # Output de ejecuciones
```

---

## Output de Ejecución

Cada ejecución genera una carpeta en `spec/`:

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

## Monitoreo

Durante la ejecución puedes monitorear el progreso:

```bash
# Progreso en tiempo real
tail -f spec/*/progress.txt

# Estado de waves
cat spec/*/prd.json | jq '.waves[] | {id, name, status}'

# Ver reporte final
cat spec/*/reports/FINAL_REPORT.md
```

---

## Configuración

### Variables de Entorno

| Variable | Default | Descripción |
|----------|---------|-------------|
| `MAX_PARALLEL_AGENTS` | 6 | Agentes en paralelo por wave |
| `MAX_CODER_ITERATIONS` | 3 | Reintentos por tarea |
| `DEBUG` | 0 | Habilitar logging debug |
| `PROJECT_PATH` | pwd | Path del proyecto a trabajar |

---

## Concepto: Waves

**Wave** = Grupo de tareas SIN dependencias entre sí que pueden ejecutarse en paralelo.

```
Wave 1: [Crear modelos] [Crear schemas] [Crear config]  ← paralelo
           ↓
Wave 2: [Crear endpoints] [Crear services]              ← paralelo
           ↓
Wave 3: [Crear tests] [Integrar frontend]               ← paralelo
```

**Regla:** Una wave NO empieza hasta que la anterior termine completamente.

---

## Troubleshooting

### Error: Claude Code no instalado
```bash
npm install -g @anthropic-ai/claude-code
```

### Error: jq no instalado
```bash
# Ubuntu/Debian
sudo apt install jq

# macOS
brew install jq
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

## Basado en

- [Ralph Loop](https://www.youtube.com/watch?v=eD4CEZ-_-sk) - Concepto original de All About AI
- [Ralph Wiggum Plugin](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum) - Plugin oficial de Anthropic
- [Claude Code CLI](https://github.com/anthropics/claude-code)

---

## Licencia

MIT

---

*Orquestador El Loco Ralph v1.0.0*
