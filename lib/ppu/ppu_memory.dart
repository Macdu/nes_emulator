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
  int control_register = 0;

  /// 8-bit PPU control register address 2
  int mask_register = 0;

  /// vram address register 1 first value
  int x_scroll = 0;
  // vram address register 1 second value
  int y_scroll = 0;

  /// PPU status register
  int status_register = 0;

  /// 16-bit address of the ppu ram, register v
  int memory_addr = 0;

  /// register t, PPU temporary address
  int temp_addr = 0;

  /// current write state of PPUSCROLL (0x2005) / PPUADDR (0x2006), register w
  bool toggle_second_w = false;

  /// current nametable
  int nametable = 0;

  /// happens during second write to $2006 and horizontal blank
  /// update scrolling data and memory address
  void transfer_temp_addr() {
    memory_addr = temp_addr;
    x_scroll &= 7;
    x_scroll |= ((memory_addr & 0x1F) << 3);
    y_scroll = ((memory_addr >> 2) & 0xF8) | ((memory_addr >> 12) /* & 7*/);
    nametable = (memory_addr >> 10) & 3;
  }

  /// upadte only horizontal scrolling
  /// should also update memory_addr
  void _update_horizontal_scrolling() {
    x_scroll &= 7;
    x_scroll |= ((temp_addr & 0x1F) << 3);

    nametable &= 2;
    nametable |= (temp_addr >> 10) & 1;
  }

  // get real index through memory mirroring
  int _get_addr(int index) {
    index &= (0x4000 - 1);

    if (index >= 0x3000 && index < 0x3F00) {
      index -= 0x1000;
    } else if (index >= 0x3F00 && index < 0x4000) {
      index = 0x3F00 | (index & 0x1F);
      if ((index & 3) == 0) {
        index = 0x3F00 | (index & 0xF);
      }
    }

    return index;
  }

  int operator [](int index) {
    index = _get_addr(index);

    // to be improved latter
    return _data[index];
  }

  void operator []=(int index, int value) {
    index = _get_addr(index);

    // to be improved latter
    _data[index] = value;
  }

  /// Used by mappers
  void copy_memory(Uint8List from, int start, int length, int to) {
    // Add some code to check validity ?
    for (int i = 0; i < length; i++) {
      _data[to + i] = from[start + i];
    }
  }

  /// load a 8k bit CHR ROM at location $0000
  void load_chr_rom(Uint8List from, int start) {
    copy_memory(from, start, 0x2000, 0);
  }

  /// load a 4k bit CHR ROM at location $0000
  void load_chr_rom_low(Uint8List from, int start) {
    copy_memory(from, start, 0x1000, 0);
  }

  /// load a 4k bit CHR ROM at location $1000
  void load_chr_rom_high(Uint8List from, int start) {
    copy_memory(from, start, 0x1000, 0x1000);
  }
}
