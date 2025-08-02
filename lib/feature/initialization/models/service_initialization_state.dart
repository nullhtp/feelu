enum ServiceStatus { pending, checking, success, error, retrying }

class ServiceInitializationState {
  final String name;
  String description;
  ServiceStatus status;
  String? errorMessage;
  String? fixInstructions;
  double? progress;
  Future<bool> Function(int index)? initiator;

  ServiceInitializationState({
    required this.name,
    required this.description,
    this.status = ServiceStatus.pending,
    this.errorMessage,
    this.fixInstructions,
    this.progress,
    this.initiator,
  });

  ServiceInitializationState copyWith({
    String? name,
    String? description,
    ServiceStatus? status,
    String? errorMessage,
    String? fixInstructions,
    double? progress,
    Future<bool> Function(int index)? initiator,
  }) {
    return ServiceInitializationState(
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      fixInstructions: fixInstructions ?? this.fixInstructions,
      progress: progress ?? this.progress,
      initiator: initiator ?? this.initiator,
    );
  }

  bool get isSuccess => status == ServiceStatus.success;
  bool get isError => status == ServiceStatus.error;
  bool get isChecking => status == ServiceStatus.checking;
  bool get isPending => status == ServiceStatus.pending;
  bool get isRetrying => status == ServiceStatus.retrying;
}
