import 'dart:async';

abstract interface class Outputable {
  Future<void> initialize();
  Future<void> process(String data);
  Future<void> dispose();
}

abstract interface class Transformable {
  Future<void> initialize();
  Future<String> transform(dynamic data);
  Future<void> dispose();
}

class Pipeline {
  Pipeline({required this.transformable, required this.outputable});

  final Transformable transformable;
  final Outputable outputable;

  // Stream controller for transformed data
  final StreamController<String> _transformedDataController =
      StreamController<String>.broadcast();

  // Getter for the stream
  Stream<String> get transformedDataStream => _transformedDataController.stream;

  Future<void> initialize() async {
    await transformable.initialize();
    await outputable.initialize();
  }

  Future<void> process(String data) async {
    final transformedData = await transformable.transform(data);

    // Emit the transformed data to subscribers
    _transformedDataController.add(transformedData);

    await outputable.process(transformedData);
  }

  Future<void> dispose() async {
    await _transformedDataController.close();
    await transformable.dispose();
    await outputable.dispose();
  }
}
