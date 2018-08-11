part of nes.mapper;

class MMC1Mapper extends Mapper {
  int _curr_buffer = 0;
  int _buffer_step = 0;

  bool _copy_pgr_lower = false;

  /// false: copy size of 16k, true: copy size of 32k
  bool _copy_pgr_32k = false;

  /// switch 4k or 8k of chr rom at a time
  bool _copy_chr_8k = false;

  void init(CPU cpu, Uint8List rom) {
    super.init(cpu, rom);

    // load first and last pgr roms
    _cpu.memory.load_PGR_lower(_rom, _pgr_start);
    _cpu.memory.load_PGR_upper(_rom, _pgr_start + (1 << 14) * (_nb_pgr - 1));

    // not sure if I have to load this part
    if (_nb_chr > 1) {
      _cpu.ppu.memory.load_chr_rom(_rom, _chr_start);
    }
  }

  void memory_write(int index, int value) {
    int id = (index - 0x8000) >> 13;
    if ((value >> 7) == 1) {
      _reset_register();
    } else {
      _curr_buffer |= (value << _buffer_step);
      _buffer_step++;
      if (_buffer_step == 5) {
        _load_register(id);
        _reset_register();
      }
    }
  }

  void _reset_register() {
    _curr_buffer = 0;
    _buffer_step = 0;
  }

  /// called when 5 bits have been written to a register
  void _load_register(int id) {
    if (_nb_chr == 0 && (id == 1 || id == 2)) return;
    switch (id) {
      case 0:
        // control register
        // need to handle mirroring
        if (((_curr_buffer >> 3) & 1) == 0) {
          _copy_pgr_32k = true;
        } else {
          _copy_pgr_32k = false;
          _copy_pgr_lower = (((_curr_buffer >> 2) & 1) == 1);
        }
        _copy_chr_8k = (((_curr_buffer >> 4) & 1) == 0);
        break;
      case 1:
        // chr bank 0
        if (_copy_chr_8k) {
          int addr = _chr_start + (1 << 13) * (_curr_buffer >> 1);
          _cpu.ppu.memory.load_chr_rom(_rom, addr);
        } else {
          int addr = _chr_start + (1 << 12) * (_curr_buffer);
          _cpu.ppu.memory.load_chr_rom_low(_rom, addr);
        }
        break;
      case 2:
        // chr bank 1
        // if copy size is 8k, ignore this register I believe
        if (!_copy_chr_8k) {
          int addr = _chr_start + (1 << 12) * (_curr_buffer);
          _cpu.ppu.memory.load_chr_rom_high(_rom, addr);
        }
        break;
      case 3:
        // pgr bank
        _curr_buffer &= ((1 << 4) - 1);
        if (_copy_pgr_32k) {
          int addr = _pgr_start + (1 << 15) * (_curr_buffer >> 1);
          _cpu.memory.load_PGR(_rom, addr);
        } else {
          int addr = _pgr_start + (1 << 14) * (_curr_buffer);
          if (_copy_pgr_lower)
            _cpu.memory.load_PGR_lower(_rom, addr);
          else
            _cpu.memory.load_PGR_upper(_rom, addr);
        }
        break;
    }
  }
}