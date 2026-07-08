/// Filtro de Kalman simples de uma dimensão para suavizar medições ruidosas.
///
/// Adequado para suavizar velocidade GPS que pode variar bastante entre
/// leituras em embarcações, especialmente em trechos com sinal fraco ou
/// durante manobras lentas.
///
/// Equações:
///   Predição:   P⁻ = P + Q
///   Ganho:      K  = P⁻ / (P⁻ + R)
///   Correção:   x  = x + K·(z - x)
///               P  = (1 - K)·P⁻
///
/// onde x é a estimativa atual, P a covariância do erro, Q o ruído de
/// processo e R o ruído de medição.
class KalmanFilter {
  /// Covariância do ruído de processo (Q).
  ///
  /// Controla quão rápido o filtro reage a mudanças reais de estado.
  /// Valor menor → mais suavização, resposta mais lenta.
  final double processNoise;

  /// Covariância do ruído de medição (R).
  ///
  /// Reflete a confiança nas leituras do GPS.
  /// Valor maior → menos confiança no GPS, mais peso na estimativa interna.
  final double measurementNoise;

  double estimate;       // estimativa atual (x)
  double errorCovariance; // covariância do erro (P)

  KalmanFilter({
    required double initialValue,
    this.processNoise = 0.1,
    this.measurementNoise = 2.0,
    double initialErrorCovariance = 1.0,
  })  : estimate = initialValue,
        errorCovariance = initialErrorCovariance;

  /// Processa uma nova medição [z] e retorna a estimativa suavizada.
  double update(double z) {
    // Passo de predição: aumenta incerteza com o ruído de processo
    errorCovariance += processNoise;

    // Ganho de Kalman: ponderação entre estimativa anterior e nova medição
    final gain = errorCovariance / (errorCovariance + measurementNoise);

    // Passo de atualização: incorpora nova medição
    estimate = estimate + gain * (z - estimate);
    errorCovariance = (1.0 - gain) * errorCovariance;

    return estimate;
  }

  /// Valor atual (sem aplicar nova medição).
  double get value => estimate;

  /// Reseta o filtro para o início de uma nova viagem.
  void reset({double? initialValue}) {
    if (initialValue != null) estimate = initialValue;
    errorCovariance = 1.0;
  }
}
