part of nes.mapper;

class MMC3Mapper extends NROMMapper {
  /// write to PPU or CPU memory
  bool _write_to_ppu = false;

  int _size_to_write = 0;
  int _index_to_write = 0;

  int _irq_reload_value = 0;
  bool _irq_needs_reload = false;
  bool _irq_enabled = false;
  int _irq_counter = 0;

  // if ROM at $C000-$DFFF is fixed to second last bank or $8000-$DFFF if set to false
  bool _is_pgr_C000_fixed = true;
  bool _need_fixed_pgr_reload = false;

  static const List<int> _size_from_bank_select = const [
    1 << 11,
    1 << 11,
    1 << 10,
    1 << 10,
    1 << 10,
    1 << 10,
    1 << 13,
    1 << 13
  ];

  static const List<int> _index_from_bank_select = const [
    0x0000,
    0x0800,
    0x1000,
    0x1400,
    0x1800,
    0x1C00,
    0x8000,
    0xA000,
  ];

  void memory_write(int index, int value) {
    int id = ((index - 0x8000) >> 13) * 2 + (index & 1);

    switch (id) {
      case 0:
        // Bank select
        int select_loc = value & 7;
        _size_to_write = _size_from_bank_select[select_loc];
        _index_to_write = _index_from_bank_select[select_loc];
        if (select_loc == 6 && (value & (1 << 6)) != 0) {
          _index_to_write = 0xC000;
        } else if (select_loc <= 5 && (value & (1 << 7)) != 0) {
          _size_to_write ^= 0x1000;
        }
        _write_to_ppu = (select_loc <= 5);
        if (((value & (1 << 7)) != 0) != _is_pgr_C000_fixed) {
          _need_fixed_pgr_reload = true;
        }
        break;
      case 1:
        // bank change
        // value &= 0x3F
        if (_write_to_ppu) {
          _cpu.ppu.memory.copy_memory(_rom, _chr_start + value * (1 << 10),
              _size_to_write, _index_to_write);
        } else {
          _cpu.memory.copy_memory(_rom, _pgr_start + value * (1 << 13),
              _size_to_write, _index_to_write);
        }
        if (_need_fixed_pgr_reload) {
          _need_fixed_pgr_reload = false;
          _is_pgr_C000_fixed = !_is_pgr_C000_fixed;
          _cpu.memory.copy_memory(_rom, _pgr_start + (_nb_pgr - 1) * (1 << 14),
              1 << 13, _is_pgr_C000_fixed ? 0xC000 : 0x8000);
        }
        break;
      case 2:
        // Mirroring
        break;
      case 3:
        // RAM protect
        break;
      case 4:
        // IRQ latch
        _irq_reload_value = value;
        break;
      case 5:
        // IRQ relaod
        _irq_needs_reload = true;
        break;
      case 6:
        // IRQ disable
        _irq_enabled = false;
        break;
      case 7:
        // IRQ enable
        _irq_enabled = true;
        break;
    }
  }

  @override
  void count_scanline() {
    if (!_irq_enabled) return;
    if (_irq_needs_reload || _irq_counter <= 0) {
      _irq_needs_reload = false;
      _irq_counter = _irq_reload_value + 1;
    }
    _irq_counter--;
    if (_irq_counter == 0) {
      _cpu.interrupt(InterruptType.IRQ);
    }
  }
}
