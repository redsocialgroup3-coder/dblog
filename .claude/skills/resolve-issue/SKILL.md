---
name: resolve-issue
description: Resuelve un issue del proyecto dBLog de forma autónoma. Lee el issue de GitHub, mueve a In Progress, implementa la solución con una red de agentes especializados, crea PR, el tech-lead revisa y mergea si aprueba.
---

# Resolve Issue Skill

Skill orquestador que resuelve un issue del repositorio dBLog usando una red de agentes especializados.

## Triggers

- `resolve-issue`, `/resolve-issue`
- "resuelve el issue", "trabaja en el issue", "implementa el issue"
- "resolve issue #N", "trabaja en el #N"

## Configuración

- **Repo**: redsocialgroup3-coder/dblog
- **Project**: dBLog (#2) — ID: PVT_kwHOD-AIPc4BTUZZ
- **Token**: embebido en la URL remota del repo. Extraer con:
  ```bash
  DBLOG_GH_TOKEN=$(git remote get-url origin | sed 's|https://[^:]*:\([^@]*\)@.*|\1|')
  ```
- **IMPORTANTE**: SIEMPRE usar `GH_TOKEN=$DBLOG_GH_TOKEN` como prefijo en TODOS los comandos `gh`. NUNCA usar el `gh auth` global (que es `orlando-marques`). Este repo pertenece al usuario `redsocialgroup3-coder`.

## REGLA CRÍTICA: Leer antes de ejecutar

**OBLIGATORIO**: Antes de empezar cualquier issue, el orquestador DEBE leer este archivo con la herramienta Read:
```
Read: .claude/skills/resolve-issue/SKILL.md
```
No reconstruir el flujo de memoria. No improvisar pasos. Seguir este documento como checklist literal.

## Gestión del Project Board

**IMPORTANTE**: Los PRs van a `main` directamente (no hay rama develop), por lo tanto `Closes #N` en el body del PR cerrará el issue automáticamente al mergear. El orquestador es responsable de:
- Mover el issue en el Project Board en cada transición de estado

### IDs del Project Board (referencia rápida)

```
Project ID:     PVT_kwHOD-AIPc4BTUZZ
Status Field:   PVTSSF_lAHOD-AIPc4BTUZZzhAmDDY
Todo:           818591f4
In Progress:    194926f8
In Review:      90b9e9f3
Done:           6abcf8a7
```

### Mutación para mover un issue

```bash
GH_TOKEN=$DBLOG_GH_TOKEN gh api graphql -f query='
mutation {
  updateProjectV2ItemFieldValue(input: {
    projectId: "PVT_kwHOD-AIPc4BTUZZ",
    itemId: "'$ITEM_ID'",
    fieldId: "PVTSSF_lAHOD-AIPc4BTUZZzhAmDDY",
    value: {singleSelectOptionId: "'$STATUS_OPTION_ID'"}
  }) { projectV2Item { id } }
}'
```

### Obtener item ID de un issue

```bash
ITEM_ID=$(GH_TOKEN=$DBLOG_GH_TOKEN gh api graphql -f query='
query {
  repository(owner: "redsocialgroup3-coder", name: "dblog") {
    issue(number: '$ISSUE_NUM') {
      projectItems(first: 5) {
        nodes { id }
      }
    }
  }
}' -q ".data.repository.issue.projectItems.nodes[0].id")
```

## Flujo completo

### Paso 0: Preparación

1. Recibir el número de issue como argumento (ej: `/resolve-issue 5`)
2. Extraer el token: `DBLOG_GH_TOKEN=$(git remote get-url origin | sed 's|https://[^:]*:\([^@]*\)@.*|\1|')`
3. Obtener los datos del issue con `GH_TOKEN=$DBLOG_GH_TOKEN gh issue view N --repo redsocialgroup3-coder/dblog --json title,body,labels`
4. **Determinar el componente** según los labels del issue:
   - Label `app` → cambios en `dblog-app/` (Flutter)
   - Label `api` → cambios en `dblog-api/` (FastAPI)
   - Ambos labels → cambios en ambos directorios
5. **Obtener el item ID del issue** en el Project (guardar en variable, se usa en todo el flujo)
6. **Mover el issue a "In Progress"** (option: `194926f8`)
7. Hacer checkout a `main` y pull: `git checkout main && git pull origin main`
8. Crear rama feature desde main: `feat/issue-N-descripcion-corta`
9. Hacer checkout a la rama

### Paso 1: Exploración y Planificación (en paralelo)

Lanzar **dos agentes en paralelo**:

**Agent: explorer**
- Prompt: "Explora el proyecto dBLog. La tarea es: [título y body del issue]. Los labels indican que afecta a: [app/api/ambos]. Reporta la estructura actual, archivos relacionados, patrones existentes y componentes reutilizables."

**Agent: planner**
- Prompt: "Diseña el plan técnico para implementar este issue: [título y body del issue]. Componente(s) afectado(s): [app/api/ambos]. Contexto del proyecto: monorepo con Flutter app + FastAPI backend."

### Paso 2: Implementación

Con los resultados de Explorer y Planner, lanzar agente(s) según el componente:

**Si tiene label `app` → Agent: flutter-developer**
- Prompt: "Implementa la siguiente tarea en el proyecto dBLog (directorio dblog-app/).

  ## Issue
  [título y body del issue]

  ## Contexto del codebase (del Explorer)
  [resultado del explorer]

  ## Plan técnico (del Planner)
  [resultado del planner]

  Sigue el plan paso a paso. Trabaja dentro de dblog-app/."

**Si tiene label `api` → Agent: fastapi-developer**
- Prompt: "Implementa la siguiente tarea en el proyecto dBLog (directorio dblog-api/).

  ## Issue
  [título y body del issue]

  ## Contexto del codebase (del Explorer)
  [resultado del explorer]

  ## Plan técnico (del Planner)
  [resultado del planner]

  Sigue el plan paso a paso. Trabaja dentro de dblog-api/."

**Si tiene ambos labels**: lanzar ambos agentes en paralelo con sus respectivos contextos.

### Paso 3: Revisión + PR (en paralelo)

Con la implementación completa, lanzar **en paralelo**:

**Agent: reviewer**
- Prompt: "Revisa los cambios realizados para el issue #N del proyecto dBLog. Verifica calidad, convenciones del proyecto y buenas prácticas. Los archivos nuevos/modificados son: [lista de archivos]."

**Orquestador (en paralelo con el reviewer):**
- Hacer commit de los cambios
- Push de la rama
- Crear el PR hacia **main** vinculado al issue con 'Closes #N'
- **IMPORTANTE**: Usar siempre `GH_TOKEN=$DBLOG_GH_TOKEN` en todos los comandos `gh`
- **Mover el issue a "In Review"** (option: `90b9e9f3`)

**Después de que ambos terminen:**

**Si el reviewer reporta bugs (🔴)**:
- Corregir los bugs
- Push a la misma rama (el PR se actualiza automáticamente)
- Re-ejecutar el reviewer
- Repetir hasta que apruebe (máximo 3 iteraciones)

**Si el reviewer aprueba (✅)** o solo tiene sugerencias (🟢):
- Continuar al Paso 4

### Paso 4: Tech Lead — Revisión, aprobación y merge

Lanzar:

**Agent: tech-lead**
- Prompt: "Revisa el PR #[número del PR] del proyecto dBLog.

  ## Issue
  [título del issue]

  ## Cambios realizados
  [resumen de lo implementado]

  Lee el diff del PR, evalúa correctness y calidad. Si todo está bien, aprueba y mergea con squash. Si hay problemas, comenta y rechaza."

**Si el tech-lead aprueba y mergea (✅)**:
- **Mover el issue a "Done"** en el Project (option: `6abcf8a7`)
- Continuar al Paso 5 (memorias)

**Si el tech-lead rechaza (⚠️)**:
- Leer los comentarios del tech-lead
- Volver al Paso 2 (implementación) con los cambios solicitados como contexto adicional
- Después de corregir, push a la misma rama (el PR se actualiza automáticamente)
- Volver al Paso 4 para que el tech-lead re-revise
- Si falla 3 veces, informar al usuario y pedir guía

### Paso 5: Actualizar memorias de agentes

Después de completar todo el flujo, el orquestador debe actualizar las memorias de cada agente que participó. Para cada agente, evaluar si hubo aprendizajes nuevos y actualizar su archivo `.claude/agents/<nombre>.memory.md`.

**Qué guardar en cada memoria:**

- **explorer.memory.md**: Rutas descubiertas, estructura del proyecto que cambió, archivos clave encontrados
- **planner.memory.md**: Decisiones arquitectónicas tomadas, trade-offs evaluados, patrones que funcionaron
- **flutter-developer.memory.md**: Packages que funcionaron/fallaron, patrones de código aceptados por el reviewer, widgets creados reutilizables
- **fastapi-developer.memory.md**: Endpoints creados, patrones de código aceptados, modelos definidos
- **reviewer.memory.md**: Bugs detectados, falsos positivos, excepciones válidas
- **tech-lead.memory.md**: Criterios que bloquearon PRs, patrones aceptados/rechazados, decisiones de merge

**Reglas de actualización:**
- Solo agregar información nueva y no obvia
- Mantener las secciones existentes (Aprendizajes, Patrones del proyecto, Errores a evitar)
- Agregar entries con fecha: `- [2026-03-31] descripción del aprendizaje`
- Si una entrada anterior ya no es válida, eliminarla o marcarla como resuelta

### Paso 6: Reporte final

Informar al usuario:
- URL del PR (mergeado o pendiente)
- Resumen de lo implementado
- Estado del issue en el project (Done si mergeado)
- Resultado de la revisión del tech-lead
- Memorias actualizadas (qué agentes aprendieron algo nuevo)

## Checklist de validación por issue

**OBLIGATORIO**: Antes de pasar al siguiente issue o reportar al usuario, verificar TODOS estos puntos. Si alguno falta, completarlo antes de continuar.

```
□ Issue movido a "In Progress" al iniciar (Paso 0)
□ Reviewer ejecutado y aprobó (Paso 3)
□ PR creado hacia main (Paso 3)
□ Issue movido a "In Review" al crear PR (Paso 3)
□ Tech-lead revisó, comentó y mergeó (Paso 4)
□ Issue movido a "Done" en el Project (Paso 4)
□ Memorias de agentes actualizadas (Paso 5)
□ main actualizado (git checkout main && git pull) antes del siguiente issue
```

## Autonomía total

Los agentes deben operar de forma **completamente autónoma** sin preguntar ni pedir confirmación al usuario en ningún momento del flujo. Reglas:

- **NO preguntar** al usuario qué approach tomar — el planner decide
- **NO pedir confirmación** antes de implementar — el developer implementa directamente
- **NO pedir aprobación** para crear PR — el orquestador lo crea
- **NO pedir permiso** para mergear — el tech-lead decide solo
- **NO preguntar** si debe continuar cuando el reviewer encuentra bugs — corregir automáticamente y re-revisar
- **NO informar** al usuario hasta que todo el flujo esté completo (Paso 6: Reporte final)
- Tomar decisiones técnicas propias basándose en los patrones existentes del proyecto
- Si hay ambigüedad en el issue, interpretar la opción más razonable y documentar la decisión en el PR

**Excepción:** Solo informar al usuario si hay un error irrecuperable (credenciales inválidas, issue inexistente, fallo persistente tras 3 intentos).

## REGLA CRÍTICA: Token de GitHub

**SIEMPRE** extraer el token de la URL remota y usarlo como `GH_TOKEN=`:
```bash
DBLOG_GH_TOKEN=$(git remote get-url origin | sed 's|https://[^:]*:\([^@]*\)@.*|\1|')
GH_TOKEN=$DBLOG_GH_TOKEN gh <cualquier comando>
```

**NUNCA** usar `gh` sin el prefijo `GH_TOKEN=`. El `gh auth` global está configurado con otro usuario (`orlando-marques`) que NO tiene acceso a este repo. Todo debe ir con el token de `redsocialgroup3-coder`.

## Manejo de errores

- Si el issue no existe: informar al usuario
- Si el push falla: verificar credenciales y reintentar (máximo 2 veces)
- Si el reviewer encuentra bugs: corregir automáticamente y re-revisar (máximo 3 iteraciones)
- Si el tech-lead rechaza: corregir según sus comentarios y re-enviar (máximo 3 intentos)
- Si la API del project falla: crear el PR igual e informar en el reporte final
- Si todo falla tras los reintentos máximos: informar al usuario con el contexto completo

## Ejemplo de uso

```
/resolve-issue 5
```

Esto resolverá el issue #5 de forma completamente autónoma: explorar → planificar → implementar → revisar → PR → tech-lead merge → Done. El usuario solo recibe el reporte final.
