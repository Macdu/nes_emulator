part of nes.ppu;

/// simulate the PPU memory
/// Uses a 16-bit address, 64k memory although only 16k is physical
class PPUMemory {
  /// the last 48k mirrors the first 16k
  final Uint8List _data = new Uint8List(0x4000);

  final Uint8List _spr_ram = new Uint8List(256);

  /// access to the spr_ram
  Uint8List get spr_ram => _spr_ram;

  /// 8-bit PPU control register address 1
  int control_register_1 = 0;

  /// 8-bit PPU control register address 2
  int control_register_2 = 0;

  /// vram address register 1 first value
  int x_scroll = 0;
  // vram address register 1 second value
  int y_scroll = 0;

  /// PPU status register
  int status_register = 0;

  int operator [](int index) {
    index %= 0x4000;

    // to be improved latter
    return _data[index];
  }

  void operator []=(int index, int value) {
    index %= 0x4000;

    // to be improved latter
    _data[index] = value;
  }
}
