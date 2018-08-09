part of nes.cpu;

class CPUMemory {
  /// The NES processor has a 16-bit address bus
  Uint8List _data = new Uint8List(0x10000);

  /// Access to the cpu
  CPU get cpu => _cpu;
  CPU _cpu;

  /// Quick access to the ppu memory
  PPUMemory get ppu_memory => _cpu._ppu.memory;

  /// 8-bit address of the sprite index
  int _sprite_memory_addr = 0;

  /// 16-bit address of the ppu ram
  int _ppu_memory_addr = 0;

  /// state of the stored address
  /// true -> 8 lower bits
  /// false -> 8 upper bits
  bool _ppu_addr_state_upper = true;

  /// current joypad button id to be read
  int _curr_button_id = 0;

  /// state of joypad reset
  bool _joypad_reset = false;

  /// current write state of PPUSCROLL (0x2005)
  bool _is_scroll_x = true;

  /// get the increase of [_ppu_memory_addr] after each read/write
  int get _ppu_addr_increase =>
      ((ppu_memory.control_register_1 >> 2) & 1) == 1 ? 32 : 1;

  /// load a 16-bit upper part of the PGR
  /// located at $C000-$CFFF
  void load_PGR_upper(Uint8List from, int start) {
    _copy_memory(from, start, 1 << 14, 0xC000);
  }

  /// load the 16-bit lower part of the PGR
  /// located at $8000-$8FFF
  void load_PGR_lower(Uint8List from, int start) {
    _copy_memory(from, start, 1 << 14, 0x8000);
  }

  /// load a 512-byte trainer
  /// located at $7000-$71FF
  void load_trainer(Uint8List from, int start) {
    _copy_memory(from, start, 512, 0x7000);
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
    } else if (index >= 0x6000) {
      // SRAM access, may disable it if no sram inserted
      return _data[index];
    }

    // RAM access
    if (index < 0x2000) {
      return _data[index];
    }

    if ((index >= 0x4000 && index <= 0x4013) || index == 0x4015) {
      // sound, not implemented yet
      return _data[index];
    }

    switch (index) {
      case 0x2000:
        return ppu_memory.control_register_1;

      case 0x2001:
        return ppu_memory.control_register_2;

      case 0x2002:
        int res = ppu_memory.status_register;
        // reading PPUSTATUS reset bit 7, PPUSCROLL and PPUADDRESS
        ppu_memory.status_register &= ~(1 << 7);
        _is_scroll_x = true;
        _ppu_addr_state_upper = true;
        return res;

      case 0x2004:
        int res = ppu_memory.spr_ram[_sprite_memory_addr];
        _sprite_memory_addr = (_sprite_memory_addr + 1) & 0xFF;
        return res;

      case 0x2007:
        int res = ppu_memory[_ppu_memory_addr];
        _ppu_memory_addr += _ppu_addr_increase;
        _ppu_memory_addr &= 0xFFFF;
        return res;

      case 0x4016:
        // joypad 1 state
        bool res = _cpu.gamepad.is_pressed(_curr_button_id);
        _curr_button_id++;
        _curr_button_id %= 25;
        _joypad_reset = false;
        return res ? 1 : 0;

      case 0x4017:
        // joypad 2 register
        print("Attempt to access player 2 gamepad");
        return 0;

      default:
        throw "Attempt to access memory location 0x${index.toRadixString(16)}";
    }
  }

  void operator []=(int index, int value) {
    if (index < 0x2000) {
      _data[index] = value;
      return;
    }

    if (index >= 0x6000 && index < 0x8000) {
      // sram, may disable it if no sram inserted
      _data[index] = value;
      return;
    }

    if ((index >= 0x4000 && index <= 0x4013) || index == 0x4015) {
      // sound, not implemented yet
      _data[index] = value;
      return;
    }

    switch (index) {
      case 0x2000:
        ppu_memory.control_register_1 = value;
        break;
      case 0x2001:
        ppu_memory.control_register_2 = value;
        break;
      case 0x2003:
        _sprite_memory_addr = value;
        break;
      case 0x2004:
        ppu_memory.spr_ram[_sprite_memory_addr] = value;
        _sprite_memory_addr++;
        _sprite_memory_addr &= 0xFF;
        break;
      case 0x2005:
        if (_is_scroll_x) {
          ppu_memory.x_scroll = value;
        } else {
          ppu_memory.y_scroll = value;
        }
        _is_scroll_x = !_is_scroll_x;
        break;
      case 0x2006:
        if (_ppu_addr_state_upper) {
          _ppu_memory_addr &= ~(0xFF00);
          _ppu_memory_addr |= value << 8;
          _ppu_addr_state_upper = false;
        } else {
          _ppu_memory_addr &= ~(0xFF);
          _ppu_memory_addr |= value;
          _ppu_addr_state_upper = true;
        }
        break;
      case 0x2007:
        ppu_memory[_ppu_memory_addr] = value;
        _ppu_memory_addr += _ppu_addr_increase;
        _ppu_memory_addr &= 0xFFFF;
        break;
      case 0x4014:
        // DMA
        for (int i = _sprite_memory_addr; i <= 0xFF; i++) {
          ppu_memory.spr_ram[i] = this[(value << 8) + i];
        }
        cpu._interpreter._cpu_cycles += 512;
        break;
      case 0x4016:
        if ((value & 1) == 1) {
          _joypad_reset = true;
        } else {
          if (_joypad_reset) _curr_button_id = 0;

          _joypad_reset = false;
        }
        break;
      case 0x4017:
        break;
      default:
        throw "Memory write at 0x${index.toRadixString(16)} not implemented";
    }
  }

  /// return the 16-bit address when an IRQ happens
  int get irq_address => _data[0xFFFE] + ((_data[0xFFFF]) << 8);
}
