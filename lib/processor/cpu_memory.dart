part of nes.processor;

class CPUMemory {
  /// The NES processor has a 16-bit address bus
  Uint8List _data = new Uint8List(0x10000);

  /// load a 16-bit upper part of the PGR
  /// located at $C000-$CFFF
  void load_PGR_upper(Uint8List from, int start) {
    _copy_memory(from, start, 1 << 16, 0xC000);
  }

  /// load the 16-bit lower part of the PGR
  /// located at $8000-$8FFF
  void load_PGR_lower(Uint8List from, int start) {
    _copy_memory(from, start, 1 << 16, 0x8000);
  }

  void _copy_memory(Uint8List from, int start, int length, int to) {
    // Add some code to check validity ?
    for (int i = 0; i < length; i++) {
      _data[to + i] = from[start + i];
    }
  }

  int operator [](int index) {
    // If access is done in the PGR zone
    if (index >= 0x8000) {
      return _data[index];
    }
    throw "Not Implemented yet";
  }
}
