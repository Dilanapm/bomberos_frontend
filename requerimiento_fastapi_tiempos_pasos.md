# Requerimiento FastAPI: tiempos reales por paso (detecciones instantáneas)

## Contexto (flujo actual)
1. La app Flutter se conecta a FastAPI por WebSocket para clasificación en tiempo real:
   - WS: `ws://<FASTAPI>/api/epp/classify/stream`
   - Flutter envía `session_id` y `timestamp` (segundos) por frame.
2. Al finalizar, Flutter solicita a FastAPI la evaluación final:
   - HTTP: `POST http://<FASTAPI>/api/epp/evaluate` con `{ "session_id": "..." }`
3. FastAPI responde un resultado que incluye `laravel_payload`.
4. Flutter **guarda** la evaluación enviando `laravel_payload` a Laravel:
   - `POST /evaluations` (aprendiz) o `POST /instructor/evaluations` (instructor)
5. Luego, Flutter consulta el detalle para mostrarlo:
   - `GET /evaluations/{id}`

## Problema observado
En la UI de detalle (puntos clave), el tiempo de cada paso se muestra como `00:00`.

La causa no está en Flutter: Flutter muestra el tiempo usando `steps[].duration` (mm:ss). En los datos que se guardan, los campos `time_start`, `time_end` y `duration` están llegando como `0.0`.

### Evidencia (log real)
En consola (Dio log) al guardar la evaluación, se observa que Flutter envía a Laravel:

- `steps_evaluation[*].time_start: 0.0`
- `steps_evaluation[*].time_end: 0.0`
- `steps_evaluation[*].duration: 0.0`

Es decir: esos tiempos ya vienen sin calcular en el payload.

## Objetivo
Que FastAPI calcule y entregue **tiempos reales por paso** basados en los timestamps/confianza del stream.

Además, hay un caso importante:
- Algunas posturas/pasos se detectan **en un instante** (1–2 frames). En ese caso la duración puede ser ~0s, pero igual necesitamos el **momento exacto** (un “detectado en 00:23”).

## Qué se necesita que FastAPI entregue
Para cada paso dentro de `laravel_payload.steps_evaluation[]`:

Campos mínimos (ya existen, pero hoy vienen en 0):
- `time_start` (float, segundos desde inicio de sesión)
- `time_end` (float, segundos)
- `duration` (float, segundos)

Campos recomendados para resolver detecciones instantáneas:
- `peak_time` (float) → timestamp del frame con mayor confianza para ese paso.
- `peak_confidence` (float 0..1) → confianza máxima.
- `detection_type` (string) → `"instant"` o `"segment"`.

### Reglas de cálculo (umbral)
Definir un umbral (por ejemplo `TH = 0.75`).

Para cada paso:
1. Filtrar eventos del timeline del paso con `confidence >= TH`.
2. Si no hay eventos:
   - `detected = false`
   - `time_start/time_end/duration = null` (recomendado) **o** 0, pero idealmente `null` para no confundir.
3. Si hay eventos:
   - `peak_time` = tiempo del evento con mayor confianza.
   - `peak_confidence` = esa confianza.
   - Agrupar eventos contiguos en segmentos (según frame-rate o gaps pequeños).
   - Elegir el segmento “principal” (por ejemplo el de mayor duración o el que contiene `peak_time`).
   - `time_start` = inicio del segmento
   - `time_end` = fin del segmento
   - `duration` = `time_end - time_start`
   - Si el segmento tiene 1 solo frame (o duración < 0.5s):
     - `detection_type = "instant"`
     - `time_start = peak_time`, `time_end = peak_time`, `duration = 0.0`
   - Si no:
     - `detection_type = "segment"`

### Nota importante: mapeo step_id vs step_number
En Laravel, `steps[].step_number` viene 1..6.
En el timeline suele venir 0..5.

Regla:
- `step_number = step_detected + 1`

(Esto evita errores de correlación.)

## Ejemplo de JSON esperado

### Caso 1: detección instantánea
```json
{
  "step_number": 6,
  "step_name": "Postura final",
  "score": 0.80,
  "status": "correcto",
  "detected": true,
  "feedback": "Paso realizado correctamente.",
  "time_start": 23.84,
  "time_end": 23.84,
  "duration": 0.0,
  "peak_time": 23.84,
  "peak_confidence": 0.93,
  "detection_type": "instant"
}
```

### Caso 2: detección sostenida
```json
{
  "step_number": 4,
  "step_name": "Casco",
  "score": 0.90,
  "status": "correcto",
  "detected": true,
  "feedback": "Correcto",
  "time_start": 41.20,
  "time_end": 46.70,
  "duration": 5.5,
  "peak_time": 44.10,
  "peak_confidence": 0.98,
  "detection_type": "segment"
}
```

### Caso 3: no detectado
```json
{
  "step_number": 1,
  "step_name": "Pantalón y botas",
  "score": 0.0,
  "status": "incorrecto",
  "detected": false,
  "feedback": "No se realizó",
  "time_start": null,
  "time_end": null,
  "duration": null,
  "peak_time": null,
  "peak_confidence": null,
  "detection_type": null
}
```

## Sobre el timeline (tamaño del payload)
El `timeline` completo puede ser muy grande y hoy Flutter no lo usa directamente para mostrar el detalle.

Recomendación:
- Mantener `GET /evaluations/{id}` liviano: devolver solo `steps` con tiempos calculados + errores/comentarios.
- Exponer timeline detallado como opcional:
  - `GET /evaluations/{id}/timeline?page=N` (paginado)
  - o `GET /evaluations/{id}?include=timeline`.

## Criterios de aceptación (para probar)
1. Ejecutar un entrenamiento real.
2. Llamar a FastAPI `POST /api/epp/evaluate` con el `session_id`.
3. Verificar que `laravel_payload.steps_evaluation[*].time_start/time_end/duration` **ya no sean 0** (cuando hay detección) y que para pasos instantáneos exista `peak_time`.
4. Guardar evaluación en Laravel.
5. En Flutter, al ver el detalle, los pasos deben mostrar tiempos distintos de `00:00` cuando corresponde.

