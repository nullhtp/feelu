abstract interface class Outputable {
  Future<void> initialize();
  Future<void> process(String data);
  Future<void> dispose();
}

abstract interface class Transformable {
  Future<void> initialize();
  Future<String> transform(String data);
  Future<void> dispose();
}

class Pipeline {
  Pipeline({required this.transformable, required this.outputable});

  final Transformable transformable;
  final Outputable outputable;

  Future<void> initialize() async {
    await transformable.initialize();
    await outputable.initialize();
  }

  Future<void> process(String data) async {
    final transformedData = await transformable.transform(data);
    await outputable.process(transformedData);
  }

  Future<void> dispose() async {
    await transformable.dispose();
    await outputable.dispose();
  }
}
