class RouteNames {
  // ── Públicas ──────────────────────────────────────────────────────────────
  static const welcome        = '/';
  static const login          = '/login';
  static const register       = '/register';
  static const otp            = '/otp';
  static const forgotPassword = '/forgot-password';
  static const resetPassword  = '/reset-password';

  // ── Protegidas ────────────────────────────────────────────────────────────
  static const homeInstructor          = '/home/instructor';
  static const homeAprendiz            = '/home/aprendiz';
  static const profile                 = '/profile';
  static const registrationCode        = '/instructor/registration-code';
  static const aiModule                = '/ai-module';
  static const studentStats            = '/instructor/student-stats';
  static const trainingInstructions    = '/training/instructions';
  static const cameraPermission         = '/training/camera-permission';
  static const cameraSession            = '/training/camera-session';
  static const eppTraining              = '/training/epp';
  static const eppEvaluationResult      = '/training/epp/result';
  static const instructorTrainingSetup  = '/training/instructor-setup';
  static const aprendizStats            = '/aprendiz/stats';
  static const aprendizEvalDetail       = '/aprendiz/stats/evaluation';
  static const instructorEvaluations    = '/instructor/evaluations';
  static const instructorStudentEvals   = '/instructor/evaluations/student';
  static const instructorEvalDetail     = '/instructor/evaluations/detail';
  static const instructorEvalReview     = '/instructor/evaluations/review';
  static const security                 = '/profile/security';
  static const notifications            = '/notifications';

  /// Rutas accesibles sin sesión (se redirige a home si ya hay sesión).
  static const publicRoutes = [welcome, login, register, forgotPassword];

  /// Rutas siempre accesibles (no fuerzan redirección si no hay sesión).
  static const alwaysPublicRoutes = [welcome, otp, resetPassword];
}
