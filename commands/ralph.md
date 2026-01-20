# /ralph - Orquestador Multi-Agente

Ejecuta el Ralph Orchestrator para desarrollo autónomo con agentes especializados.

---

## Argumento Recibido

```
TAREA: $ARGUMENTS
```

---

## Instrucciones

Ejecuta el siguiente comando bash para iniciar el Ralph Orchestrator:

```bash
# NOTA: Ajusta este path a tu instalación local
~/Orquestador-El-Loco-Ralph/orchestrator.sh "$ARGUMENTS"
```

### Flujo de Ejecución

El orchestrator ejecutará automáticamente:

1. **EXPLORACIÓN** (5 agentes en paralelo)
   - Analizar estructura del proyecto
   - Detectar tecnologías
   - Identificar patrones existentes
   - Mapear tests y dependencias

2. **PLANIFICACIÓN** (6 agentes en paralelo)
   - Diseñar arquitectura
   - Definir contratos de API
   - Planificar base de datos
   - Estrategia de testing

3. **GENERACIÓN DE PRD**
   - Crear PRD.json con waves paralelas
   - Agrupar tareas sin dependencias

4. **EJECUCIÓN** (Ralph Loop)
   - Coordinar agentes Coder (hasta 6 paralelo)
   - Ciclo: Coder → Reviewer → Feedback
   - Máximo 3 reintentos por tarea

5. **REVISIÓN FINAL** (3 agentes en paralelo)
   - Security Reviewer
   - Tests Reviewer
   - Architecture Reviewer

### Monitoreo

Durante la ejecución puedes monitorear con:

```bash
# Progreso en tiempo real
tail -f ~/Orquestador-El-Loco-Ralph/spec/*/progress.txt

# Estado de waves
cat ~/Orquestador-El-Loco-Ralph/spec/*/prd.json | jq '.waves[] | {id, name, status}'
```

### Output

Los resultados se guardan en:
- `spec/[execution_id]/reports/FINAL_REPORT.md`
- Commits atómicos en git

---

## Ejemplos de Uso

```
/ralph Crear API REST para gestión de usuarios con CRUD y autenticación JWT
/ralph Agregar sistema de notificaciones por email con templates
/ralph Refactorizar módulo de pagos usando patrón Strategy
/ralph Implementar tests E2E para flujo de checkout
```

---

## Opciones Avanzadas

Si necesitas opciones específicas, ejecuta manualmente:

```bash
# Usar PRD existente
~/Orquestador-El-Loco-Ralph/orchestrator.sh --prd spec/existing/prd.json

# Especificar proyecto diferente
~/Orquestador-El-Loco-Ralph/orchestrator.sh "tarea" --project-path /ruta/al/proyecto

# Con debug
DEBUG=1 ~/Orquestador-El-Loco-Ralph/orchestrator.sh "tarea"
```

---

## Instalación del Slash Command

Para usar `/ralph` en cualquier proyecto:

```bash
# Copiar a comandos de Claude Code
cp ~/Orquestador-El-Loco-Ralph/commands/ralph.md ~/.claude/commands/

# Editar el path si es necesario
nano ~/.claude/commands/ralph.md
```
