import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/evaluation_detail.dart';
import '../../data/repositories/aprendiz_stats_repository.dart';

/// FutureProvider.family — fetches a single evaluation detail by id.
/// Usage: ref.watch(evalDetailProvider(evalId))
final evalDetailProvider =
    FutureProvider.family<EvaluationDetail, int>((ref, id) =>
        ref.read(aprendizStatsRepoProvider).getEvaluationDetail(id));
