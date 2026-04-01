import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/entities/eval_stats.dart';
import '../../domain/entities/analytics.dart';
import '../../domain/entities/evaluation_summary.dart';

/// Tipo de reporte PDF que el usuario puede solicitar.
enum PdfReportType {
  resumen,
  analisis,
  historial,
}

/// Genera documentos PDF con las estadísticas del aprendiz.
class StatsPdfService {
  StatsPdfService._();

  static const _brandColor = PdfColor.fromInt(0xFFAA241D); // primary5

  // ─────────────────────────────────────────────────────────────────────────
  // 1) Reporte de Resumen (Dashboard — A1)
  // ─────────────────────────────────────────────────────────────────────────

  static Future<Uint8List> generateResumen({
    required EvalStats stats,
    required String userName,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _header('Reporte de Resumen', userName),
        footer: (ctx) => _footer(ctx),
        build: (ctx) => [
          // ── Resumen general ─────────────────────────────
          _sectionTitle('Resumen General'),
          pw.SizedBox(height: 8),
          _statsTable([
            ['Promedio general', '${stats.averageScore.toStringAsFixed(1)}%'],
            ['Mejor puntaje', '${stats.bestScore.toStringAsFixed(1)}%'],
            ['Total de intentos', stats.totalAttempts.toString()],
            ['Aprobados', '${stats.approved}'],
            ['Reprobados', '${stats.failed}'],
            ['Tasa de aprobación', '${stats.passRate.toStringAsFixed(0)}%'],
          ]),
          pw.SizedBox(height: 16),

          // ── Consistencia ────────────────────────────────
          _sectionTitle('Consistencia'),
          pw.SizedBox(height: 8),
          _statsTable([
            ['Nivel', stats.nivelConsistencia],
            ['Resultado más común', stats.resultadoMasComun.toStringAsFixed(1)],
            ['Rango típico', stats.rangoTipico],
          ]),
          pw.SizedBox(height: 4),
          _bodyText(stats.interpretacionConsistencia),
          pw.SizedBox(height: 16),

          // ── Comparación con el grupo ───────────────────
          _sectionTitle('Comparación con el Grupo'),
          pw.SizedBox(height: 8),
          _statsTable([
            ['Mi promedio', '${stats.comparacionGrupo.miPromedio.toStringAsFixed(1)}%'],
            ['Promedio del grupo', '${stats.comparacionGrupo.promedioGrupo.toStringAsFixed(1)}%'],
            ['Diferencia', '${stats.comparacionGrupo.diferencia >= 0 ? "+" : ""}${stats.comparacionGrupo.diferencia.toStringAsFixed(1)}%'],
          ]),
          pw.SizedBox(height: 4),
          _bodyText(stats.comparacionGrupo.interpretacion),
          pw.SizedBox(height: 16),

          // ── Punto débil ────────────────────────────────
          if (stats.hardestStep != null) ...[
            _sectionTitle('Punto Débil'),
            pw.SizedBox(height: 8),
            _statsTable([
              ['Paso', '${stats.hardestStep!.stepNumber}: ${stats.hardestStep!.stepName}'],
              ['Promedio en este paso', '${stats.hardestStep!.avgScore.toStringAsFixed(1)}%'],
              ['Intentos registrados', '${stats.hardestStep!.attempts}'],
            ]),
            pw.SizedBox(height: 16),
          ],

          // ── Último intento ─────────────────────────────
          if (stats.lastEvaluation != null) ...[
            _sectionTitle('Último Intento'),
            pw.SizedBox(height: 8),
            _statsTable([
              ['ID', '#${stats.lastEvaluation!.id}'],
              ['Puntaje', '${stats.lastEvaluation!.generalScore.toStringAsFixed(1)}%'],
              ['Estado', stats.lastEvaluation!.status],
              ['Pasos completados', '${stats.lastEvaluation!.stepsCompleted}'],
              ['Fecha', _fmtDate(stats.lastEvaluation!.createdAt)],
            ]),
            pw.SizedBox(height: 16),
          ],

          // ── Progreso ───────────────────────────────────
          if (stats.progress.isNotEmpty) ...[
            _sectionTitle('Historial de Progreso'),
            pw.SizedBox(height: 8),
            _progressTable(stats.progress),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2) Reporte de Análisis (A2)
  // ─────────────────────────────────────────────────────────────────────────

  static Future<Uint8List> generateAnalisis({
    required Analytics analytics,
    required String userName,
  }) async {
    final pdf = pw.Document();
    final ps = analytics.personalStats;
    final cg = analytics.comparacionGrupo;
    final t  = analytics.tendencia;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _header('Reporte de Análisis', userName),
        footer: (ctx) => _footer(ctx),
        build: (ctx) => [
          // ── Estadísticas personales ─────────────────────
          _sectionTitle('Estadísticas Personales'),
          pw.SizedBox(height: 8),
          _statsTable([
            ['Promedio', '${ps.promedio.toStringAsFixed(1)}%'],
            ['Mejor puntaje', '${ps.mejorPuntaje.toStringAsFixed(1)}%'],
            ['Total intentos', ps.totalIntentos.toString()],
            ['Resultado más común', ps.resultadoMasComun.toStringAsFixed(1)],
            ['Rango típico', ps.rangoTipico],
            ['Consistencia', ps.nivelConsistencia],
          ]),
          pw.SizedBox(height: 4),
          _bodyText(ps.interpretacion),
          pw.SizedBox(height: 16),

          // ── Posición en el grupo ────────────────────────
          _sectionTitle('Posición en el Grupo'),
          pw.SizedBox(height: 8),
          _statsTable([
            ['Mi promedio', '${cg.miPromedio.toStringAsFixed(1)}%'],
            ['Promedio del grupo', '${cg.promedioGrupo.toStringAsFixed(1)}%'],
            ['Diferencia', '${cg.diferencia >= 0 ? "+" : ""}${cg.diferencia.toStringAsFixed(1)}%'],
            ['Posición estimada', cg.posicionEstimada],
            ['Mejor del grupo', '${cg.mejorDelGrupo.toStringAsFixed(1)}%'],
            ['Para top 10%', '${cg.paraTop10.toStringAsFixed(1)}%'],
          ]),
          pw.SizedBox(height: 16),

          // ── Tendencia ───────────────────────────────────
          _sectionTitle('Tendencia'),
          pw.SizedBox(height: 8),
          _statsTable([
            ['Tipo', t.tipo],
            ['Mejora acumulada', '+${t.mejorTotal.toStringAsFixed(1)} pts'],
            ['Velocidad de mejora', '${t.velocidadMejora.toStringAsFixed(1)} pts/intento'],
          ]),
          pw.SizedBox(height: 4),
          _bodyText(t.interpretacion),
          pw.SizedBox(height: 16),

          // ── Fortalezas ──────────────────────────────────
          if (analytics.fortalezas.isNotEmpty) ...[
            _sectionTitle('Fortalezas'),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEBF5FB)),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellAlignment: pw.Alignment.centerLeft,
              headers: ['Paso', 'Nombre', 'Promedio', 'Estrellas'],
              data: analytics.fortalezas
                  .map((s) => [
                        '${s.paso}',
                        s.nombre,
                        '${s.promedio.toStringAsFixed(1)}%',
                        '${'★' * s.estrellas}${'☆' * (5 - s.estrellas)}',
                      ])
                  .toList(),
            ),
            pw.SizedBox(height: 16),
          ],

          // ── Debilidades ─────────────────────────────────
          if (analytics.debilidades.isNotEmpty) ...[
            _sectionTitle('Áreas a Mejorar'),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFFDE8E8)),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellAlignment: pw.Alignment.centerLeft,
              headers: ['Paso', 'Nombre', 'Promedio', 'vs Grupo', 'Dif.'],
              data: analytics.debilidades
                  .map((w) => [
                        '${w.paso}',
                        w.nombre,
                        '${w.promedio.toStringAsFixed(1)}%',
                        '${w.promedioGrupo.toStringAsFixed(1)}%',
                        '${w.diferencia >= 0 ? "+" : ""}${w.diferencia.toStringAsFixed(1)}%',
                      ])
                  .toList(),
            ),
            pw.SizedBox(height: 8),
            ...analytics.debilidades.map((w) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: _bodyText('• ${w.nombre}: ${w.recomendacion}'),
                )),
            pw.SizedBox(height: 16),
          ],

          // ── Progreso temporal ───────────────────────────
          if (analytics.progresoTemporal.isNotEmpty) ...[
            _sectionTitle('Progreso Temporal'),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF0F4FF)),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellAlignment: pw.Alignment.center,
              headers: ['Intento', 'Puntaje', 'Fecha'],
              data: analytics.progresoTemporal
                  .map((p) => ['${p.intento}', '${p.puntaje.toStringAsFixed(1)}%', p.fecha])
                  .toList(),
            ),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3) Reporte de Historial (A3)
  // ─────────────────────────────────────────────────────────────────────────

  static Future<Uint8List> generateHistorial({
    required List<EvaluationSummary> evaluations,
    required String userName,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _header('Reporte de Historial', userName),
        footer: (ctx) => _footer(ctx),
        build: (ctx) => [
          _bodyText('Total de evaluaciones: ${evaluations.length}'),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEBF5FB)),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.center,
            columnWidths: {
              0: const pw.FixedColumnWidth(40),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(1),
            },
            headers: ['#', 'Fecha', 'Puntaje', 'Estado', 'Pasos'],
            data: evaluations
                .map((e) => [
                      '${e.id}',
                      _fmtDate(e.createdAt),
                      '${e.generalScore.toStringAsFixed(1)}%',
                      e.status,
                      '${e.stepsCompleted}/${e.totalSteps}',
                    ])
                .toList(),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  static pw.Widget _header(String title, String userName) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: _brandColor,
              ),
            ),
            pw.Text(
              'Bomberos — Entrenamiento EPP',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Aprendiz: $userName',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
            ),
            pw.Text(
              'Generado: ${_fmtDate(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: _brandColor, thickness: 1.5),
        pw.SizedBox(height: 12),
      ],
    );
  }

  static pw.Widget _footer(pw.Context ctx) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
      ),
    );
  }

  static pw.Widget _sectionTitle(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        color: _brandColor,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _bodyText(String text) {
    return pw.Text(
      text,
      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
    );
  }

  static pw.Widget _statsTable(List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
      },
      children: rows.map(
        (row) => pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                row[0],
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(row[1], style: const pw.TextStyle(fontSize: 10)),
            ),
          ],
        ),
      ).toList(),
    );
  }

  static pw.Widget _progressTable(List<ProgressPoint> points) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF0F4FF)),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignment: pw.Alignment.center,
      headers: ['#', 'Puntaje', 'Estado', 'Pasos', 'Fecha'],
      data: points
          .map((p) => [
                '${p.id}',
                '${p.generalScore.toStringAsFixed(1)}%',
                p.status,
                '${p.stepsCompleted}',
                _fmtDate(p.createdAt),
              ])
          .toList(),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
