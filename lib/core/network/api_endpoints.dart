class ApiEndpoints {
  ApiEndpoints._();

  // ── Auth (sin token) ──────────────────────────────────────────────────────
  static const String login          = '/auth/login';
  static const String register       = '/auth/register';
  static const String emailVerify    = '/auth/email/verify';
  static const String emailResend    = '/auth/email/resend';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword  = '/auth/reset-password';

  // ── Auth (con token) ──────────────────────────────────────────────────────
  static const String logout         = '/auth/logout';
  static const String me             = '/auth/me';

  // ── Perfil (con token) ───────────────────────────────────────────────────
  static const String profileUpdate   = '/profile';
  static const String profilePassword = '/profile/password';
  static const String profileAvatar   = '/profile/avatar';

  // ── Instructor (con token) ───────────────────────────────────────────────
  static const String registrationCodeGenerate = '/instructor/registration-code';
  static const String registrationCodeActive   = '/instructor/registration-code/active';
  static const String registrationCodeRevoke   = '/instructor/registration-code';
  // ── Estadísticas del aprendiz (con can_access_stats_module) ────────────────
  static const String evalStats     = '/evaluations/stats';
  static const String evalAnalytics = '/evaluations/analytics';
  static const String evaluations   = '/evaluations';

  // ── Estadísticas de aprendices (solo instructor con can_view_student_stats) ─
  static const String statsMyGroup     = '/instructor/stats/my-group';
  static const String statsRanking     = '/instructor/stats/ranking';
  static const String statsNeedHelp    = '/instructor/stats/need-help';
  static const String statsStepAnalysis = '/instructor/stats/step-analysis';

  // ── Evaluaciones del instructor ──────────────────────────────────────────
  static const String instructorEvaluations = '/instructor/evaluations';
  static String instructorEvalDetail(int id) => '/instructor/evaluations/$id';
  static String instructorEvalComments(int id) => '/instructor/evaluations/$id/comments';
  static String instructorDeleteComment(int evalId, int commentId) =>
      '/instructor/evaluations/$evalId/comments/$commentId';
  static String instructorEvalReview(int id) => '/instructor/evaluations/$id/review';

  // ── Notificaciones (con token) ────────────────────────────────────────────
  static const String notifications            = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static const String notificationsReadAll     = '/notifications/read-all';
  static String notificationRead(String id)    => '/notifications/$id/read';
}
