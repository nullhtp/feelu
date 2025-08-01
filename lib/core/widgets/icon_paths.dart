enum IconPaths {
  ear('assets/icons/ear.svg'),
  gemma3n('assets/icons/gemma-3n.png'),
  eye('assets/icons/eye.svg'),
  keyboard('assets/icons/keyboard.svg'),
  speak1('assets/icons/speak-1.svg'),
  speak2('assets/icons/speak-2.svg');

  const IconPaths(this.path);

  final String path;

  @override
  String toString() => path;
}
