part of nes.ppu;

/// simulate the PPU memory
/// Uses a 16-bit address, 64k memory although only 16k is physical
class PPUMemory {
  /// the last 48k mirrors the first 16k
  Uint8List _memory = new Uint8List(0x4000);

  Uint8List _spr_ram = new Uint8List(256);

  int operator [](int index) {
    index %= 0x4000;

    // to be improved latter
    return _memory[index];
  }

  void operator []=(int index, int value) {
    index %= 0x4000;

    // to be improved latter
    _memory[index] = value;
  }
}
