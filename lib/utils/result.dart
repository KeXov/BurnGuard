class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  const Result.success(this.data) : error = null, isSuccess = true;

  const Result.failure(this.error) : data = null, isSuccess = false;

  bool get isFailure => !isSuccess;

  R when<R>({
    required R Function(T data) success,
    required R Function(String error) failure,
  }) {
    if (isSuccess) {
      return success(data as T);
    }
    return failure(error!);
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'Result.success($data)';
    }
    return 'Result.failure($error)';
  }
}
