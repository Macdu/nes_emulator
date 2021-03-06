part of nes.mapper;

class MMC1Mapper extends NROMMapper {
  int _curr_buffer = 0;
  int _buffer_step = 0;

  bool _copy_pgr_lower = false;

  /// false: copy size of 16k, true: copy size of 32k
  bool _copy_pgr_32k = false;

  /// switch 4k or 8k of chr rom at a time
  bool _copy_chr_8k = false;

  /// if the first and second pgr are set to their default location
  /// (first and last bank)
  bool _first_pgr_to_default;
  bool _second_pgr_to_default;

  /// if PGR rom is larger than 512k, MMC1 behavior is different
  bool _is_pgr_large;

  bool _pgr_rom_bank_high = false;

  Uint8List _register_values = new Uint8List(4);

  @override
  void init(CPU cpu, Uint8List rom) {
    super.init(cpu, rom);
    _first_pgr_to_default = true;
    _second_pgr_to_default = true;

    // if there are more than 32 16-bit PGR
    _is_pgr_large = _nb_pgr >= 32;

    if (_is_pgr_large) {
      // last memory bank is not the right one
      _cpu.memory.load_PGR_upper(_rom, _pgr_start + (1 << 14) * 0xF);
    }
  }

  void memory_write(int index, int value) {
    int id = (index - 0x8000) >> 13;
    if ((value >> 7) == 1) {
      _reset_register();
      int old_control = _register_values[0];
      _register_values[0] |= 0xC;
      _load_register(0);
      if (old_control != _register_values[0]) {
        // update PGR rom
        _load_register(3);
      }
    } else {
      _curr_buffer |= (value << _buffer_step);
      _buffer_step++;
      if (_buffer_step == 5) {
        _register_values[id] = _curr_buffer;
        _load_register(id);
        _reset_register();
      }
    }
  }

  void _reset_register() {
    _curr_buffer = 0;
    _buffer_step = 0;
  }

  /// only used in SUROM type mapper
  void _handle_high_pgr_switch(int value) {
    bool switch_up = (value & (1 << 4)) != 0;
    value &= 0xF;
    if (switch_up != _pgr_rom_bank_high) {
      _pgr_rom_bank_high = switch_up;
      // update PGR
      _first_pgr_to_default = false;
      _second_pgr_to_default = false;
      _load_register(3);
    }
  }

  /// called when 5 bits have been written to a register
  void _load_register(int id) {
    int value = _register_values[id];
    switch (id) {
      case 0:
        // control register
        if ((value & 2) == 0)
          _cpu.ppu.memory.mirroring = MirroringType.SingleScreen;
        else
          _cpu.ppu.memory.mirroring = ((value & 1) == 0)
              ? MirroringType.Vertical
              : MirroringType.Horizontal;
        bool old_copy_32k = _copy_pgr_32k;
        if (((value >> 3) & 1) == 0) {
          _copy_pgr_32k = true;
        } else {
          _copy_pgr_32k = false;
          _copy_pgr_lower = (((value >> 2) & 1) == 1);
        }
        if (old_copy_32k != _copy_pgr_32k) {
          // we need to update the memory loaded in
          _load_register(3);
        }
        _copy_chr_8k = (((value >> 4) & 1) == 0);
        break;
      case 1:
        // chr bank 0
        if (_is_pgr_large) {
          _handle_high_pgr_switch(value);
          value &= 0xF;
        }
        if (_nb_chr == 0) break;
        if (_copy_chr_8k) {
          int addr = _chr_start + (1 << 13) * (value >> 1);
          _cpu.ppu.memory.load_chr_rom(_rom, addr);
        } else {
          int addr = _chr_start + (1 << 12) * (value);
          _cpu.ppu.memory.load_chr_rom_low(_rom, addr);
        }
        break;
      case 2:
        // chr bank 1
        // if copy size is 8k, ignore this register I believe
        if (!_copy_chr_8k) {
          if (_is_pgr_large) {
            _handle_high_pgr_switch(value);
            value &= 0xF;
          }
          if (_nb_chr == 0) break;
          int addr = _chr_start + (1 << 12) * (value);
          _cpu.ppu.memory.load_chr_rom_high(_rom, addr);
        }
        break;
      case 3:
        // pgr bank
        //value &= ((1 << 4) - 1);
        if (_pgr_rom_bank_high) value += 16;
        if (_copy_pgr_32k) {
          _first_pgr_to_default = false;
          _second_pgr_to_default = false;
          int addr = _pgr_start + (1 << 15) * (value >> 1);
          _cpu.memory.load_PGR(_rom, addr);
        } else {
          int addr = _pgr_start + (1 << 14) * (value);
          if (_copy_pgr_lower) {
            _first_pgr_to_default = false;
            _cpu.memory.load_PGR_lower(_rom, addr);
            if (!_second_pgr_to_default) {
              _cpu.memory.load_PGR_upper(
                  _rom,
                  _pgr_start +
                      (1 << 14) * (_pgr_rom_bank_high ? 0xF : (_nb_pgr - 1)));
              _second_pgr_to_default = true;
            }
          } else {
            _second_pgr_to_default = false;
            _cpu.memory.load_PGR_upper(_rom, addr);
            if (!_first_pgr_to_default) {
              _cpu.memory.load_PGR_lower(_rom,
                  _pgr_start + (_pgr_rom_bank_high ? (1 << 14) * 0xF : 0));
              _first_pgr_to_default = true;
            }
          }
        }
        break;
    }
  }
}
