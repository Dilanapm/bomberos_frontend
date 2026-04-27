● Entendido el problema. En ambas funciones (evaluate_exercise y send_results_to_laravel) los campos time_start,
  time_end y duration están hardcodeados en 0.0, pero la sesión ya tiene toda la data necesaria en
  clasificaciones_detalle (con timestamp y confianza por frame). El fix es crear una función helper que calcule los
  tiempos reales por paso usando esa data.

  Voy a implementar los cambios:

● Update(app\api\routes\epp.py)
  ⎿  Added 70 lines
      384
      385
      386  # ============================================================
      387 +# Utility: Calcular tiempos reales por paso desde el historial
      388 +# ============================================================
      389 +
      390 +_TIME_THRESHOLD = 0.75   # confianza mínima para considerar una detección válida
      391 +_GAP_SECONDS    = 2.0    # gap máximo entre eventos para pertenecer al mismo segmento
      392 +_MIN_DURATION   = 0.5    # duración mínima (s) para considerar "segment" en vez de "instant"
      393 +
      394 +
      395 +def _compute_step_times(clasificaciones_detalle: list, created_at: float, step_id: int) -> dict:
      396 +    """
      397 +    Calcula time_start, time_end, duration, peak_time, peak_confidence y detection_type
      398 +    para un paso dado, filtrando eventos con confianza >= _TIME_THRESHOLD.
      399 +
      400 +    Returns dict con esos campos (o None en cada campo si el paso no fue detectado).
      401 +    """
      402 +    null_result = {
      403 +        "time_start": None, "time_end": None, "duration": None,
      404 +        "peak_time": None, "peak_confidence": None, "detection_type": None
      405 +    }
      406 +
      407 +    events = [
      408 +        {"time": round(c["timestamp"] - created_at, 2), "confidence": c["confianza"]}
      409 +        for c in clasificaciones_detalle
      410 +        if c["paso_id"] == step_id and c["confianza"] >= _TIME_THRESHOLD
      411 +    ]
      412 +
      413 +    if not events:
      414 +        return null_result
      415 +
      416 +    # Pico de confianza
      417 +    peak_event = max(events, key=lambda e: e["confidence"])
      418 +    peak_time = peak_event["time"]
      419 +    peak_confidence = round(peak_event["confidence"], 4)
      420 +
      421 +    # Agrupar en segmentos contiguos (gap > _GAP_SECONDS separa segmentos)
      422 +    events_sorted = sorted(events, key=lambda e: e["time"])
      423 +    segments: list[list] = []
      424 +    current: list = [events_sorted[0]]
      425 +    for ev in events_sorted[1:]:
      426 +        if ev["time"] - current[-1]["time"] <= _GAP_SECONDS:
      427 +            current.append(ev)
      428 +        else:
      429 +            segments.append(current)
      430 +            current = [ev]
      431 +    segments.append(current)
      432 +
      433 +    # Segmento principal: el que contiene peak_time (o el más largo si no hay)
      434 +    main_segment = next(
      435 +        (s for s in segments if min(e["time"] for e in s) <= peak_time <= max(e["time"] for e in s)),
      436 +        max(segments, key=len)
      437 +    )
      438 +
      439 +    seg_start = min(e["time"] for e in main_segment)
      440 +    seg_end   = max(e["time"] for e in main_segment)
      441 +    seg_dur   = round(seg_end - seg_start, 2)
      442 +
      443 +    if seg_dur < _MIN_DURATION:
      444 +        return {
      445 +            "time_start": peak_time, "time_end": peak_time, "duration": 0.0,
      446 +            "peak_time": peak_time, "peak_confidence": peak_confidence,
      447 +            "detection_type": "instant"
      448 +        }
      449 +    return {
      450 +        "time_start": round(seg_start, 2), "time_end": round(seg_end, 2), "duration": seg_dur,
      451 +        "peak_time": peak_time, "peak_confidence": peak_confidence,
      452 +        "detection_type": "segment"
      453 +    }
      454 +
      455 +
      456 +# ============================================================
      457  # ENDPOINTS
      458  # ============================================================
      459

● Ahora reemplazo el bloque hardcodeado dentro de send_results_to_laravel:

● Update(app\api\routes\epp.py)
  ⎿  Added 5 lines, removed 6 lines
      286          for i, (internal_name, human_name) in enumerate(zip(step_names_internal, step_names_human)):
      287              score = evaluation_result['scores'].get(internal_name, 0.0)
      288              is_correct = internal_name in evaluation_result['correctos']
      289 -
      289 +            times = _compute_step_times(session_data.clasificaciones_detalle, session_data.created_at,
          + i)
      290 +
      291              steps_evaluation.append({
      292                  "step_number": i + 1,
      293                  "step_name": human_name,
      294                  "score": round(score, 4),
      295                  "status": "correcto" if is_correct else "incorrecto",
      295 -                "detected": score > 0.3,  # umbral de detección
      296 -                "feedback": f"Paso realizado correctamente." if is_correct else f"Mejorar ejecución de
          - {human_name.lower()}.",
      297 -                "time_start": 0.0,  # FastAPI no tiene info temporal por paso (opcional)
      298 -                "time_end": 0.0,
      299 -                "duration": 0.0
      296 +                "detected": score > 0.3,
      297 +                "feedback": "Paso realizado correctamente." if is_correct else f"Mejorar ejecución de
          +{human_name.lower()}.",
      298 +                **times,
      299              })
      300
      301          # Construir timeline desde clasificaciones_detalle

● Ahora el mismo reemplazo dentro de evaluate_exercise:

● Update(app\api\routes\epp.py)
  ⎿  Added 3 lines, removed 3 lines
      589      for i, (internal_name, human_name) in enumerate(zip(step_names_internal, step_names_human)):
      590          score = result['scores'].get(internal_name, 0.0)
      591          is_correct = internal_name in result['correctos']
      592 +        times = _compute_step_times(session.clasificaciones_detalle, session.created_at, i)
      593 +
      594          steps_evaluation.append({
      595              "step_number": i + 1,
      596              "step_name": human_name,
     ...
      598              "status": "correcto" if is_correct else "incorrecto",
      599              "detected": score > 0.3,
      600              "feedback": "Paso realizado correctamente." if is_correct else f"Mejorar ejecución de {hum
           an_name.lower()}.",
      599 -            "time_start": 0.0,
      600 -            "time_end": 0.0,
      601 -            "duration": 0.0
      601 +            **times,
      602          })
      603
      604      errors = []

● Verifico que los cambios quedaron correctos leyendo las secciones clave:

  Read 1 file (ctrl+o to expand)

● Todo está correcto. Los cambios están bien aplicados en ambos lugares.

  ---
  Aquí está el resumen de lo que se hizo y cómo funciona:

  Causa raíz: En ambas funciones (evaluate_exercise y send_results_to_laravel) los campos temporales estaban
  hardcodeados en 0.0, aunque session.clasificaciones_detalle ya acumulaba el timestamp de cada clasificación durante el
   stream WebSocket.

  Lo que se agregó:

  Se añadió la función _compute_step_times(clasificaciones_detalle, created_at, step_id) que para cada paso:

  1. Filtra eventos del historial donde paso_id == step_id y confianza >= 0.75
  2. Sin eventos → devuelve todos los campos en None (paso no detectado)
  3. Con eventos → encuentra el peak_time (frame con mayor confianza), agrupa eventos contiguos en segmentos (gap
  máximo: 2s) y elige el segmento que contiene el pico
    - Si la duración del segmento < 0.5s → detection_type: "instant", duration: 0.0
    - Si no → detection_type: "segment", con time_start/time_end/duration reales

  Los tres parámetros están como constantes al inicio (_TIME_THRESHOLD = 0.75, _GAP_SECONDS = 2.0, _MIN_DURATION = 0.5)
  para que los puedas ajustar fácilmente si el comportamiento en producción lo requiere.