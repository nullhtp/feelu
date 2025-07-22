abstract interface class Inputable {
  String getData();
}

abstract interface class Outputable {
  void process(String data);
}

abstract interface class Transformable {
  String transform(String data);
}
