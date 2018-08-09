part of nes.cpu;

/// 6502 interpreter
class Interpreter {
  State _state;
  CPUMemory _memory;

  int _cpu_cycles = 0;
  int _opcodes_used = 0;

  int _cycles_left = 0;

  /// make on CPU cycle
  void tick() {
    if (_cycles_left == 0) {
      _eval_next_instruction();
    }
    _cycles_left--;
  }

  /// Create the interpreter with a state and a memory
  Interpreter(this._state, this._memory);
  List<String> f = [];

  /// evaluate the next instruction
  void _eval_next_instruction() {
    // big switch, may use somthing better, performance ?
    _cpu_cycles = 0;
    _opcodes_used = 1;
    int cond = _memory[_state.pc];
    List g = f;
    //g.add(_state.pc.toRadixString(16));
    String a = _state.pc.toRadixString(16);
    //if (_state.pc == 0xA90C) debugger();
    switch (cond) {

      // 00 - BRK
      case 0x00:
        _cpu_cycles += 7;
        _state.pc += 2;
        _opcodes_used = 0;
        _save_state(true);
        _state.pc = _memory.irq_address;
        break;

      //01 - ORA - (Indirect,X)
      case 0x01:
        _cpu_cycles = 6;
        _state.a = _or(_state.a, _indirect_x());
        break;

      // 02 - 04 : Future Expansion

      // 05 - ORA - Zero Page
      case 0x05:
        _cpu_cycles = 3;
        _state.a = _or(_state.a, _zero_page());
        break;

      // 06 - ASL - Zero Page
      case 0x06:
        _cpu_cycles = 5;
        int addr = _memory[_state.pc + 1];
        _memory[addr] = _left_shift(_zero_page());
        break;

      // 07 - Future Expansion

      // 08 - PHP
      case 0x08:
        _cpu_cycles = 3;
        // PHP always includes the break flag
        _stack_push(_state.export_processor_flags(true));
        break;

      // 09 - ORA - Immediate
      case 0x09:
        _cpu_cycles = 2;
        _state.a = _or(_state.a, _immediate());
        break;

      // 0A - ASL - Accumulator
      case 0x0A:
        _cpu_cycles = 2;
        _state.a = _left_shift(_state.a);
        break;

      // 0B - 0C : Future Expansion

      // 0D - ORA - Absolute
      case 0x0D:
        _cpu_cycles = 4;
        _state.a = _or(_state.a, _absolute());
        break;

      // 0E - ASL - Absolute
      case 0x0E:
        _cpu_cycles = 6;
        int addr = _absolute_addr();
        _memory[addr] = _left_shift(_memory[addr]);
        break;

      // 0F - Future Expansion

      // 10 - BPL
      case 0x10:
        _cpu_cycles = 2;
        _branch(!_state.negative);
        break;

      // 11 - ORA - (Indirect),Y
      case 0x11:
        _cpu_cycles = 5;
        _state.a = _or(_state.a, _indirect_y());
        break;

      // 12 - 14 : Future Expansion

      // 15 - ORA - Zero Page,X
      case 0x15:
        _cpu_cycles = 4;
        _state.a = _or(_state.a, _zero_page_x());
        break;

      // 16 - ASL - Zero Page,X
      case 0x16:
        _cpu_cycles = 6;
        int addr = _zero_page_x_addr();
        _memory[addr] = _left_shift(_memory[addr]);
        break;

      // 17 - Future Expansion

      // 18 - CLC
      case 0x18:
        _cpu_cycles = 2;
        _state.carry = false;
        break;

      // 19 - ORA - Absolute,Y
      case 0x19:
        _cpu_cycles = 4;
        _state.a = _or(_state.a, _absolute_y());
        break;

      // 1A - 1C : Future Expansion

      // 1D - ORA - Absolute,X
      case 0x1D:
        _cpu_cycles = 4;
        _state.a = _or(_state.a, _absolute_x());
        break;

      // 1E - ASL - Absolute,X
      case 0x1E:
        _cpu_cycles = 7;
        int addr = _absolute_x_addr();
        _memory[addr] = _left_shift(_memory[addr]);
        break;

      // 1F: Future Expansion

      // 20 - JSR
      case 0x20:
        _cpu_cycles = 6;
        int addr = _absolute_addr();
        _state.pc += 2;
        _opcodes_used = 0;
        _save_pc();
        _state.pc = addr;
        break;

      // 21 - AND - (Indirect,X)
      case 0x21:
        _cpu_cycles = 6;
        _state.a = _and(_state.a, _indirect_x());
        break;

      // 22-23 - Future Expansion

      // 24 - BIT - Zero Page
      case 0x24:
        _cpu_cycles = 3;
        int val = _zero_page();
        _zero_update(val & _state.a);
        _negative_update(val);
        _state.overflow = (val & 0x40) != 0;
        break;

      // 25 - AND - Zero Page
      case 0x25:
        _cpu_cycles = 3;
        _state.a = _and(_state.a, _zero_page());
        break;

      // 26 - ROL - Zero Page
      case 0x26:
        _cpu_cycles = 5;
        int addr = _zero_page_addr();
        _memory[addr] = _left_rotate(_memory[addr]);
        break;

      // 27 - Future Expansion

      // 28 - PLP
      case 0x28:
        _cpu_cycles = 4;
        _state.load_processor_flags(_stack_pull());
        break;

      // 29 - AND - Immediate
      case 0x29:
        _cpu_cycles = 2;
        _state.a = _and(_state.a, _immediate());
        break;

      // 2A - ROL - Accumulator
      case 0x2A:
        _cpu_cycles = 2;
        _state.a = _left_rotate(_state.a);
        break;

      // 2B - Future Expansion

      // 2C - BIT - Absolute
      case 0x2C:
        _cpu_cycles = 4;
        int val = _absolute();
        _zero_update(val & _state.a);
        _negative_update(val);
        _state.overflow = (val & 0x40) != 0;
        break;

      // 2D - AND - Absolute
      case 0x2D:
        _cpu_cycles = 4;
        _state.a = _and(_state.a, _absolute());
        break;

      // 2E - ROL - Absolute
      case 0x2E:
        _cpu_cycles = 6;
        int addr = _absolute_addr();
        _memory[addr] = _left_rotate(_memory[addr]);
        break;

      // 2F - Future Expansion

      // 30 - BMI
      case 0x30:
        _cpu_cycles = 2;
        _branch(_state.negative);
        break;

      // 31 - AND - (Indirect),Y
      case 0x31:
        _cpu_cycles = 5;
        _state.a = _and(_state.a, _indirect_y());
        break;

      // 32 - 34 - Future Expansion

      // 35 - AND - Zero Page,X
      case 0x35:
        _cpu_cycles = 4;
        _state.a = _and(_state.a, _zero_page_x());
        break;

      // 36 - ROL - Zero Page,X
      case 0x36:
        _cpu_cycles = 6;
        int addr = _zero_page_x_addr();
        _memory[addr] = _left_rotate(_memory[addr]);
        break;

      // 37 - Future Expansion

      // 38 - SEC
      case 0x38:
        _cpu_cycles = 2;
        _state.carry = true;
        break;

      // 39 - AND - Absolute,Y
      case 0x39:
        _cpu_cycles = 4;
        _state.a = _and(_state.a, _absolute_y());
        break;

      // 3A - 3C - Future Expansion

      // 3D - AND - Absolute,X
      case 0x3D:
        _cpu_cycles = 4;
        _state.a = _and(_state.a, _absolute_x());
        break;

      // 3E - ROL - Absolute,X
      case 0x3E:
        _cpu_cycles = 7;
        int addr = _absolute_x_addr();
        _memory[addr] = _left_rotate(_memory[addr]);
        break;

      // 3F - Future Expansion

      // 40 - RTI
      case 0x40:
        _cpu_cycles = 6;
        _opcodes_used = 0;
        _restore_state();
        break;

      // 41 - EOR - (Indirect,X)
      case 0x41:
        _cpu_cycles = 6;
        _state.a = _xor(_state.a, _indirect_x());
        break;

      // 42 - 44 - Future Expansion

      // 45 - EOR - Zero Page
      case 0x45:
        _cpu_cycles = 3;
        _state.a = _xor(_state.a, _zero_page());
        break;

      //46 - LSR - Zero Page
      case 0x46:
        _cpu_cycles = 5;
        int addr = _zero_page_addr();
        _memory[addr] = _right_shift(_memory[addr]);
        break;

      // 47 - Future Expansion

      // 48 - PHA
      case 0x48:
        _cpu_cycles = 3;
        _stack_push(_state.a);
        break;

      // 49 - EOR - Immediate
      case 0x49:
        _cpu_cycles = 2;
        _state.a = _xor(_state.a, _immediate());
        break;

      // 4A - LSR - Accumulator
      case 0x4A:
        _cpu_cycles = 2;
        _state.a = _right_shift(_state.a);
        break;

      // 4B - Future Expansion

      // 4C - JMP - Absolute
      case 0x4C:
        _cpu_cycles = 3;
        _state.pc = _absolute_addr();
        _opcodes_used = 0;
        break;

      // 4D - EOR - Absolute
      case 0x4D:
        _cpu_cycles = 4;
        _state.a = _xor(_state.a, _absolute());
        break;

      // 4E - LSR - Absolute
      case 0x4E:
        _cpu_cycles = 6;
        int addr = _absolute_addr();
        _memory[addr] = _right_shift(_memory[addr]);
        break;

      // 4F - Future Expansion

      // 50 - BVC
      case 0x50:
        _cpu_cycles = 2;
        _branch(!_state.overflow);
        break;

      // 51 - EOR - (Indirect),Y
      case 0x51:
        _cpu_cycles = 5;
        _state.a = _xor(_state.a, _indirect_y());
        break;

      // 52 - 54 - Future Expansion

      // 55 - EOR - Zero Page,X
      case 0x55:
        _cpu_cycles = 4;
        _state.a = _xor(_state.a, _zero_page());
        break;

      // 56 - LSR - Zero Page,X
      case 0x56:
        _cpu_cycles = 6;
        int addr = _zero_page_x_addr();
        _memory[addr] = _right_shift(_memory[addr]);
        break;

      // 57 - Future Expansion

      // 58 - CLI
      case 0x58:
        _cpu_cycles = 2;
        _state.interrupt_disable = false;
        break;

      // 59 - EOR - Absolute,Y
      case 0x59:
        _cpu_cycles = 4;
        _state.a = _xor(_state.a, _absolute_y());
        break;

      // 5A - 5C - Future Expansion

      // 5D - EOR - Absolute,X
      case 0x5D:
        _cpu_cycles = 4;
        _state.a = _xor(_state.a, _absolute_x());
        break;

      // 5E - LSR - Absolute,X
      case 0x5E:
        _cpu_cycles = 7;
        int addr = _absolute_x_addr();
        _memory[addr] = _right_shift(_memory[addr]);
        break;

      // 5F - Future Expansion

      // 60 - RTS
      case 0x60:
        _cpu_cycles = 6;
        _restore_pc();
        break;

      // 61 - ADC - (Indirect,X)
      case 0x61:
        _cpu_cycles = 6;
        _state.a = _adc(_state.a, _indirect_x());
        break;

      // 62 - 64 - Future Expansion

      // 65 - ADC - Zero Page
      case 0x65:
        _cpu_cycles = 3;
        _state.a = _adc(_state.a, _zero_page());
        break;

      // 66 - ROR - Zero Page
      case 0x66:
        _cpu_cycles = 5;
        int addr = _zero_page_addr();
        _memory[addr] = _right_rotate(_memory[addr]);
        break;

      // 67 - Future Expansion

      // 68 - PLA
      case 0x68:
        _cpu_cycles = 4;
        _state.a = _stack_pull();
        _nz_update(_state.a);
        break;

      // 69 - ADC - Immediate
      case 0x69:
        _cpu_cycles = 2;
        _state.a = _adc(_state.a, _immediate());
        break;

      // 6A - ROR - Accumulator
      case 0x6A:
        _cpu_cycles = 2;
        _state.a = _right_rotate(_state.a);
        break;

      // 6B - Future Expansion

      // 6C - JMP - Indirect
      case 0x6C:
        _cpu_cycles = 5;
        _state.pc = _indirect();
        _opcodes_used = 0;
        break;

      // 6D - ADC - Absolute
      case 0x6D:
        _cpu_cycles = 4;
        _state.a = _adc(_state.a, _absolute());
        break;

      // 6E - ROR - Absolute
      case 0x6E:
        _cpu_cycles = 6;
        int addr = _absolute_addr();
        _memory[addr] = _right_rotate(_memory[addr]);
        break;

      // 6F - Future Expansion

      // 70 - BVS
      case 0x70:
        _cpu_cycles = 2;
        _branch(_state.overflow);
        break;

      // 71 - ADC - (Indirect),Y
      case 0x71:
        _cpu_cycles = 5;
        _state.a = _adc(_state.a, _indirect_y());
        break;

      // 72 - 74 - Future Expansion

      // 75 - ADC - Zero Page,X
      case 0x75:
        _cpu_cycles = 4;
        _state.a = _adc(_state.a, _zero_page_x());
        break;

      // 76 - ROR - Zero Page,X
      case 0x76:
        _cpu_cycles = 6;
        int addr = _zero_page_x_addr();
        _memory[addr] = _right_rotate(_memory[addr]);
        break;

      // 77 - Future Expansion

      // 78 - SEI
      case 0x78:
        _cpu_cycles = 2;
        _state.interrupt_disable = true;
        break;

      // 79 - ADC - Absolute,Y
      case 0x79:
        _cpu_cycles = 4;
        _state.a = _adc(_state.a, _absolute_y());
        break;

      // 7A - 7C - Future Expansion

      // 7D - ADC - Absolute,X
      case 0x7D:
        _cpu_cycles = 4;
        _state.a = _adc(_state.a, _absolute_x());
        break;

      // 7E - ROR - Absolute,X
      case 0x7E:
        _cpu_cycles = 7;
        int addr = _absolute_x_addr();
        _memory[addr] = _right_rotate(_memory[addr]);
        break;

      // 7F - 80 - Future Expansion

      // 81 - STA - (Indirect,X)
      case 0x81:
        _cpu_cycles = 6;
        _memory[_indirect_x_addr()] = _state.a;
        break;

      // 82 - 83 - Future Expansion

      // 84 - STY - Zero Page
      case 0x84:
        _cpu_cycles = 3;
        _memory[_zero_page_addr()] = _state.y;
        break;

      // 85 - STA - Zero Page
      case 0x85:
        _cpu_cycles = 3;
        _memory[_zero_page_addr()] = _state.a;
        break;

      // 86 - STX - Zero Page
      case 0x86:
        _cpu_cycles = 3;
        _memory[_zero_page_addr()] = _state.x;
        break;

      // 87 - Future Expansion

      // 88 - DEY
      case 0x88:
        _cpu_cycles = 2;
        _state.y = _add(_state.y, 0xFF /* -1 */);
        break;

      // 89 - Future Expansion

      // 8A - TXA
      case 0x8A:
        _cpu_cycles = 2;
        _state.a = _state.x;
        _nz_update(_state.a);
        break;

      // 8B - Future Expansion

      // 8C - STY - Absolute
      case 0x8C:
        _cpu_cycles = 4;
        _memory[_absolute_addr()] = _state.y;
        break;

      // 8D - STA - Absolute
      case 0x8D:
        _cpu_cycles = 4;
        _memory[_absolute_addr()] = _state.a;
        break;

      // 8E - STX - Absolute
      case 0x8E:
        _cpu_cycles = 4;
        _memory[_absolute_addr()] = _state.x;
        break;

      // 8F - Future Expansion

      // 90 - BCC
      case 0x90:
        _cpu_cycles = 2;
        _branch(!_state.carry);
        break;

      // 91 - STA - (Indirect),Y
      case 0x91:
        _cpu_cycles = 6;
        _memory[_indirect_y_addr()] = _state.a;
        break;

      // 92 - 93 - Future Expansion

      // 94 - STY - Zero Page,X
      case 0x94:
        _cpu_cycles = 4;
        _memory[_zero_page_x_addr()] = _state.y;
        break;

      // 95 - STA - Zero Page,X
      case 0x95:
        _cpu_cycles = 4;
        _memory[_zero_page_x_addr()] = _state.a;
        break;

      // 96 - STX - Zero Page,Y
      case 0x96:
        _cpu_cycles = 4;
        _memory[_zero_page_y_addr()] = _state.x;
        break;

      // 97 - Future Expansion

      // 98 - TYA
      case 0x98:
        _cpu_cycles = 2;
        _state.a = _state.y;
        _nz_update(_state.a);
        break;

      // 99 - STA - Absolute,Y
      case 0x99:
        _cpu_cycles = 5;
        _memory[_absolute_y_addr()] = _state.a;
        break;

      // 9A - TXS
      case 0x9A:
        _cpu_cycles = 2;
        _state.sp = _state.x;
        break;

      // 9B - 9C - Future Expansion

      // 9D - STA - Absolute,X
      case 0x9D:
        _cpu_cycles = 5;
        _memory[_absolute_x_addr()] = _state.a;
        break;

      // 9E - 9F - Future Expansion

      // A0 - LDY - Immediate
      case 0xA0:
        _cpu_cycles = 2;
        _state.y = _immediate();
        _nz_update(_state.y);
        break;

      // A1 - LDA - (Indirect,X)
      case 0xA1:
        _cpu_cycles = 6;
        _state.a = _indirect_x();
        _nz_update(_state.a);
        break;

      // A2 - LDX - Immediate
      case 0xA2:
        _cpu_cycles = 2;
        _state.x = _immediate();
        _nz_update(_state.x);
        break;

      // A3 - Future Expansion

      // A4 - LDY - Zero Page
      case 0xA4:
        _cpu_cycles = 3;
        _state.y = _zero_page();
        _nz_update(_state.y);
        break;

      // A5 - LDA - Zero Page
      case 0xA5:
        _cpu_cycles = 3;
        _state.a = _zero_page();
        _nz_update(_state.a);
        break;

      // A6 - LDX - Zero Page
      case 0xA6:
        _cpu_cycles = 3;
        _state.x = _zero_page();
        _nz_update(_state.x);
        break;

      // A7 - Future Expansion

      // A8 - TAY
      case 0xA8:
        _cpu_cycles = 2;
        _state.y = _state.a;
        _nz_update(_state.y);
        break;

      // A9 - LDA - Immediate
      case 0xA9:
        _cpu_cycles = 2;
        _state.a = _immediate();
        _nz_update(_state.a);
        break;

      // AA - TAX
      case 0xAA:
        _cpu_cycles = 2;
        _state.x = _state.a;
        _nz_update(_state.x);
        break;

      // AB - Future Expansion

      // AC - LDY - Absolute
      case 0xAC:
        _cpu_cycles = 4;
        _state.y = _absolute();
        _nz_update(_state.y);
        break;

      // AD - LDA - Absolute
      case 0xAD:
        _cpu_cycles = 4;
        _state.a = _absolute();
        _nz_update(_state.a);
        break;

      // AE - LDX - Absolute
      case 0xAE:
        _cpu_cycles = 4;
        _state.x = _absolute();
        _nz_update(_state.x);
        break;

      // AF - Future Expansion

      // B0 - BCS
      case 0xB0:
        _cpu_cycles = 2;
        _branch(_state.carry);
        break;

      // B1 - LDA - (Indirect),Y
      case 0xB1:
        _cpu_cycles = 5;
        _state.a = _indirect_y();
        _nz_update(_state.a);
        break;

      // B2 - B3 - Future Expansion

      // B4 - LDY - Zero Page,X
      case 0xB4:
        _cpu_cycles = 4;
        _state.y = _zero_page_x();
        _nz_update(_state.y);
        break;

      // B5 - LDA - Zero Page,X
      case 0xB5:
        _cpu_cycles = 4;
        _state.a = _zero_page_x();
        _nz_update(_state.a);
        break;

      // B6 - LDX - Zero Page,Y
      case 0xB6:
        _cpu_cycles = 4;
        _state.x = _zero_page_y();
        _nz_update(_state.x);
        break;

      // B7 - Future Expansion

      // B8 - CLV
      case 0xB8:
        _cpu_cycles = 2;
        _state.overflow = false;
        break;

      // B9 - LDA - Absolute,Y
      case 0xB9:
        _cpu_cycles = 4;
        _state.a = _absolute_y();
        _nz_update(_state.a);
        break;

      // BA - TSX
      case 0xBA:
        _cpu_cycles = 2;
        _state.x = _state.sp;
        _nz_update(_state.x);
        break;

      // BB - Future Expansion

      // BC - LDY - Absolute,X
      case 0xBC:
        _cpu_cycles = 4;
        _state.y = _absolute_x();
        _nz_update(_state.y);
        break;

      // BD - LDA - Absolute,X
      case 0xBD:
        _cpu_cycles = 4;
        _state.a = _absolute_x();
        _nz_update(_state.a);
        break;

      // BE - LDX - Absolute,Y
      case 0xBE:
        _cpu_cycles = 4;
        _state.x = _absolute_x();
        _nz_update(_state.x);
        break;

      // BF - Future Expansion

      // C0 - CPY - Immediate
      case 0xC0:
        _cpu_cycles = 2;
        _compare(_state.y, _immediate());
        break;

      // C1 - CMP - (Indirect,X)
      case 0xC1:
        _cpu_cycles = 6;
        _compare(_state.a, _indirect_x());
        break;

      // C2 - C3 - Future Expansion

      // C4 - CPY - Zero Page
      case 0xC4:
        _cpu_cycles = 3;
        _compare(_state.y, _zero_page());
        break;

      // C5 - CMP - Zero Page
      case 0xC5:
        _cpu_cycles = 3;
        _compare(_state.a, _zero_page());
        break;

      // C6 - DEC - Zero Page
      case 0xC6:
        _cpu_cycles = 5;
        int addr = _zero_page_addr();
        _memory[addr] = _add(_memory[addr], 0xFF);
        break;

      // C7 - Future Expansion

      // C8 - INY
      case 0xC8:
        _cpu_cycles = 2;
        _state.y = _add(_state.y, 1);
        break;

      // C9 - CMP - Immediate
      case 0xC9:
        _cpu_cycles = 2;
        _compare(_state.a, _immediate());
        break;

      // CA - DEX
      case 0xCA:
        _cpu_cycles = 2;
        _state.x = _add(_state.x, 0xFF);
        break;

      // CB - Future Expansion

      // CC - CPY - Absolute
      case 0xCC:
        _cpu_cycles = 4;
        _compare(_state.y, _absolute());
        break;

      // CD - CMP - Absolute
      case 0xCD:
        _cpu_cycles = 4;
        _compare(_state.a, _absolute());
        break;

      // CE - DEC - Absolute
      case 0xCE:
        _cpu_cycles = 6;
        int addr = _absolute_addr();
        _memory[addr] = _add(_memory[addr], 0xFF);
        break;

      // CF - Future Expansion

      // D0 - BNE
      case 0xD0:
        _cpu_cycles = 2;
        _branch(!_state.zero);
        break;

      // D1 - CMP   (Indirect),Y
      case 0xD1:
        _cpu_cycles = 5;
        _compare(_state.a, _indirect_y());
        break;

      // D2 - D4 - Future Expansion

      // D5 - CMP - Zero Page,X
      case 0xD0:
        _cpu_cycles = 4;
        _compare(_state.a, _zero_page_x());
        break;

      // D6 - DEC - Zero Page,X
      case 0xD6:
        _cpu_cycles = 6;
        int addr = _zero_page_x_addr();
        _memory[addr] = _add(_memory[addr], 0xFF);
        break;

      // D7 - Future Expansion

      // D8 - CLD
      case 0xD8:
        _cpu_cycles = 2;
        _state.decimal_mode = false;
        break;

      // D9 - CMP - Absolute,Y
      case 0xD9:
        _cpu_cycles = 4;
        _compare(_state.a, _absolute_y());
        break;

      // DA - DC - Future Expansion

      // DD - CMP - Absolute,X
      case 0xDD:
        _cpu_cycles = 4;
        _compare(_state.a, _absolute_y());
        break;

      // DE - DEC - Absolute,X
      case 0xDE:
        _cpu_cycles = 7;
        int addr = _absolute_x_addr();
        _memory[addr] = _add(_memory[addr], 0xFF);
        break;

      // DF - Future Expansion

      // E0 - CPX - Immediate
      case 0xE0:
        _cpu_cycles = 2;
        _compare(_state.x, _immediate());
        break;

      // E1 - SBC - (Indirect,X)
      case 0xE1:
        _cpu_cycles = 6;
        _state.a = _sbc(_state.a, _indirect_x());
        break;

      // E2 - E3 - Future Expansion

      // E4 - CPX - Zero Page
      case 0xE4:
        _cpu_cycles = 3;
        _compare(_state.x, _zero_page());
        break;

      // E5 - SBC - Zero Page
      case 0xE5:
        _cpu_cycles = 4;
        _state.a = _sbc(_state.a, _zero_page());
        break;

      // E6 - INC - Zero Page
      case 0xE6:
        _cpu_cycles = 5;
        int addr = _zero_page_addr();
        _memory[addr] = _add(_memory[addr], 1);
        break;

      // E7 - Future Expansion

      // E8 - INX
      case 0xE8:
        _cpu_cycles = 2;
        _state.x = _add(_state.x, 1);
        break;

      // E9 - SBC - Immediate
      case 0xE9:
        _cpu_cycles = 2;
        _state.a = _sbc(_state.a, _immediate());
        break;

      // EA - NOP
      case 0xEA:
        _cpu_cycles = 2;
        break;

      // EB - Future Expansion

      // EC - CPX - Absolute
      case 0xEC:
        _cpu_cycles = 4;
        _compare(_state.x, _absolute());
        break;

      // ED - SBC - Absolute
      case 0xED:
        _cpu_cycles = 4;
        _state.a = _sbc(_state.a, _absolute());
        break;

      // EE - INC - Absolute
      case 0xEE:
        _cpu_cycles = 6;
        int addr = _absolute_addr();
        _memory[addr] = _add(_memory[addr], 1);
        break;

      // EF - Future Expansion

      // F0 - BEQ
      case 0xF0:
        _cpu_cycles = 2;
        _branch(_state.zero);
        break;

      // F1 - SBC - (Indirect),Y
      case 0xF1:
        _cpu_cycles = 5;
        _state.a = _sbc(_state.a, _indirect_y());
        break;

      // F2 - F4 - Future Expansion

      // F5 - SBC - Zero Page,X
      case 0xF5:
        _cpu_cycles = 4;
        _state.a = _sbc(_state.a, _zero_page_x());
        break;

      // F6 - INC - Zero Page,X
      case 0xF6:
        _cpu_cycles = 5;
        int addr = _zero_page_x_addr();
        _memory[addr] = _add(_memory[addr], 1);
        break;

      // F7 - Future Expansion

      // F8 - SED
      case 0xF8:
        _cpu_cycles = 2;
        _state.decimal_mode = true;
        break;

      // F9 - SBC - Absolute,Y
      case 0xF9:
        _cpu_cycles = 4;
        _state.a = _sbc(_state.a, _absolute_y());
        break;

      // FA - FC - Future Expansion

      // FD - SBC - Absolute,X
      case 0xFD:
        _cpu_cycles = 4;
        _state.a = _sbc(_state.a, _absolute_x());
        break;

      // FE - INC - Absolute,X
      case 0xFE:
        _cpu_cycles = 7;
        int addr = _absolute_x_addr();
        _memory[addr] = _add(_memory[addr], 1);
        break;

      // FF - Future Expansion

      default:
        debugger();
        throw "Opcode ${cond.toRadixString(16)} Not Implemented";
    }
    _state.pc += _opcodes_used;
    _cycles_left += _cpu_cycles;
  }

  /// negative flag update
  void _negative_update(int nb) {
    _state.negative = (nb & (1 << 7)) != 0;
  }

  /// zero flag update
  void _zero_update(int nb) {
    _state.zero = (nb & 0xFF) == 0;
  }

  /// zero and negative flag update
  void _nz_update(int nb) {
    _negative_update(nb);
    _zero_update(nb);
  }

  /// carry flag update
  void _carry_update(int nb) {
    _state.carry = (nb > 0xFF);
  }

  /// return the 8-bit result of x + y and update the state flags
  int _add(int x, int y) {
    int res = (x + y);
    _nz_update(res);
    return res & 0xFF;
  }

  /// adc operation and update the flags
  int _adc(int x, int y) {
    int res = x + y + _state.carry_val;
    _nz_update(res);
    _carry_update(res);
    _state.overflow = (((x ^ y) & 0x80) == 0) && (((x ^ res) & 0x80) != 0);
    return res;
  }

  // sbc operation and update the flags
  int _sbc(int x, int y) {
    int res = x - y - (1 - _state.carry_val);
    _state.carry = res >= 0;
    if (res < 0) {
      res = ((-res) ^ (0x100 - 1)) + 1;
    }
    res &= 0xFF;
    _nz_update(res);
    _state.overflow = (((x ^ y) & 0x80) != 0) && (((x ^ res) & 0x80) != 0);
    return res;
  }

  /// return the 8-bit result of x | y and update the state flags
  int _or(int x, int y) {
    int res = x | y;
    _negative_update(res);
    _zero_update(res);
    return res;
  }

  /// return the 8-bit result of x ^ y and update the state flags
  int _xor(int x, int y) {
    int res = x ^ y;
    _negative_update(res);
    _zero_update(res);
    return res;
  }

  /// left shift and updates flags
  int _left_shift(int x) {
    x <<= 1;
    _carry_update(x);
    _negative_update(x);
    _zero_update(x);
    return x & 0xFF;
  }

  /// right shift and updates flags
  int _right_shift(int x) {
    _state.carry = (x & 1) == 1;
    x >>= 1;
    _state.negative = false;
    _zero_update(x);
    return x;
  }

  /// left rotate and update flags
  int _left_rotate(int x) {
    x <<= 1;
    x |= _state.carry_val;
    _zero_update(x);
    _negative_update(x);
    _carry_update(x);
    return x & 0xFF;
  }

  /// right rotate and update the flags
  int _right_rotate(int x) {
    x |= (_state.carry_val << 8);
    _state.carry = (x & 1) == 1;
    x >>= 1;
    _zero_update(x);
    _negative_update(x);
    return x;
  }

  /// return the 8-bit result of x & y and update sthe state flags
  int _and(int x, int y) {
    int res = x & y;
    _negative_update(res);
    _zero_update(res);
    return res;
  }

  /// compare x and y and update the flags
  void _compare(int x, int y) {
    int res = x - y;
    _state.carry = (x >= y);
    if (res < 0) {
      res = ((-res) ^ (0x100 - 1)) + 1;
    }
    _nz_update(res & 0xFF);
  }

  /// push a byte onto the stack
  void _stack_push(int byte) {
    _memory[0x100 + _state.sp] = byte;
    if (_state.sp == 0) {
      _state.sp = 0xFF;
    } else {
      _state.sp--;
    }
  }

  /// pull one byte from the stack
  int _stack_pull() {
    _state.sp++;
    _state.sp &= 0xFF;
    return _memory[0x100 + _state.sp];
  }

  // save the state PC in the stack
  void _save_pc() {
    _stack_push((_state.pc >> 8) & 0xFF);
    _stack_push(_state.pc & 0xFF);
  }

  /// save the current state in the stack
  void _save_state(bool break_state) {
    _save_pc();
    _stack_push(_state.export_processor_flags(break_state));
  }

  // get the PC from the stack
  void _restore_pc() {
    _state.pc = _stack_pull() + (_stack_pull() << 8);
  }

  /// restore the state from the stack
  void _restore_state() {
    _state.load_processor_flags(_stack_pull());
    _restore_pc();
  }

  /// get an indirect_x value
  int _indirect_x() {
    _opcodes_used++;
    int addr = (_memory[_state.pc + 1] + _state.x) & 0xFF;
    int loc = _memory[addr] | (_memory[(addr + 1) & 0xFF] << 8);
    return _memory[loc];
  }

  /// get an indirect y value
  int _indirect_y() {
    _opcodes_used++;
    int addr = _memory[_state.pc + 1];
    addr = _memory[addr] | (_memory[(addr + 1) & 0xFF] << 8);
    int loc = (addr + _state.y) & 0xFFFF;
    if ((addr & 0xFF00) != (loc & 0xFF00)) _cpu_cycles++;
    return _memory[loc];
  }

  /// get an indirect_x address
  int _indirect_x_addr() {
    _opcodes_used++;
    int addr = (_memory[_state.pc + 1] + _state.x) & 0xFF;
    return _memory[addr] + (_memory[(addr + 1) & 0xFF] << 8);
  }

  /// get an indirect y address
  int _indirect_y_addr() {
    _opcodes_used++;
    int addr = _memory[_state.pc + 1];
    return (_memory[addr] + (_memory[(addr + 1) & 0xFF] << 8) + _state.y) &
        0xFFFF;
  }

  /// get an indirect address
  int _indirect() {
    _opcodes_used += 2;
    int addr = _memory[_state.pc + 1] | (_memory[_state.pc + 2] << 8);
    return _memory[addr] |
        (_memory[(addr & 0xFF00) | ((addr + 1) & 0x00FF)] << 8);
  }

  /// get a zero_page value
  int _zero_page() {
    _opcodes_used++;
    return _memory[_memory[_state.pc + 1]];
  }

  /// get a zero_page address
  int _zero_page_addr() {
    _opcodes_used++;
    return _memory[_state.pc + 1];
  }

  /// get a zero_page x value
  int _zero_page_x() {
    _opcodes_used++;
    return _memory[(_memory[_state.pc + 1] + _state.x) & 0xFF];
  }

  /// get a zero_page x address
  int _zero_page_x_addr() {
    _opcodes_used++;
    return (_memory[_state.pc + 1] + _state.x) & 0xFF;
  }

  /// get a zero_page y value
  int _zero_page_y() {
    _opcodes_used++;
    return _memory[(_memory[_state.pc + 1] + _state.y) & 0xFF];
  }

  /// get a zero_page y address
  int _zero_page_y_addr() {
    _opcodes_used++;
    return (_memory[_state.pc + 1] + _state.y) & 0xFF;
  }

  /// get an immediate value
  int _immediate() {
    _opcodes_used++;
    return _memory[_state.pc + 1];
  }

  /// get an absolute address
  int _absolute_addr() {
    _opcodes_used += 2;
    return _memory[_state.pc + 1] | (_memory[_state.pc + 2] << 8);
  }

  /// return absolute y address
  /// Page boundary cross doesn't imply a new cpu cycle here
  int _absolute_y_addr() => _absolute_addr() + _state.y;

  /// return absolute x address
  /// Page boundary cross doesn't imply a new cpu cycle here
  int _absolute_x_addr() => _absolute_addr() + _state.x;

  /// get an absolute value
  int _absolute() {
    return _memory[_absolute_addr()];
  }

  /// return absolute y value
  int _absolute_y() => _absolute_(_state.y);

  /// return absolute x value
  int _absolute_x() => _absolute_(_state.x);

  /// return absolute value + delta
  int _absolute_(int delta) {
    int addr = _absolute_addr();
    int nouv = (addr + delta) & 0xFFFF;
    if ((addr & 0xFF00) != (nouv & 0XFF00)) _cpu_cycles++;
    return _memory[nouv];
  }

  /// return a relative address
  int _get_relative(int rel) {
    if (rel & 0x80 != 0) {
      rel = -(rel ^ (0x100 - 1)) - 1;
    }
    int relative = _state.pc + rel;
    // if page boundary crossed : one more cycle
    if ((relative & 0xFF00) != (_state.pc & 0xFF00)) {
      _cpu_cycles += 2;
    } else {
      _cpu_cycles++;
    }
    return relative;
  }

  /// branch on address (if condition is true)
  void _branch(bool cond) {
    _opcodes_used++;
    if (cond) {
      _state.pc = _get_relative(_memory[_state.pc + 1]);
    }
  }

  /// read a 16-bit address with little endian located at addr and addr+1
  int _read_16bit_addr(int addr) {
    return _memory[addr] | (_memory[addr + 1] << 8);
  }
}
