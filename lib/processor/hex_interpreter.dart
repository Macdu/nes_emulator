part of nes.processor;

/// 6502 interpreter
class Interpreter {
  State _state;
  CPUMemory _memory;

  int _cpu_cycle = 0;
  int _opcodes_used;

  /// Create the interpreter with a state and a memory
  Interpreter(this._state, this._memory);

  /// evaluate the next instruction
  void eval_next_instruction() {
    // big switch, may use somthing better
    _cpu_cycle = 0;
    _opcodes_used = 1;
    int cond = _memory[_state.pc];
    switch (cond) {

      // 00 - BRK
      case 0x00:
        _cpu_cycle += 7;
        _state.pc++;
        _opcodes_used = 0;
        _state.break_command = true;
        _save_state();
        _state.interrupt_disable = true;
        _state.pc = _memory.irq_address;
        break;

      //01 - ORA - (Indirect,X)
      case 0x01:
        _cpu_cycle = 6;
        _state.a = _or(_state.a, _indirect_x());
        break;

      // 02 - 04 : Future Expansion

      // 05 - ORA - Zero Page
      case 0x05:
        _cpu_cycle = 3;
        _state.a = _or(_state.a, _zero_page());
        break;

      // 06 - ASL - Zero Page
      case 0x06:
        _cpu_cycle = 5;
        int addr = _memory[_state.pc + 1];
        _memory[addr] = _left_shift(_zero_page());
        break;

      // 07 - Future Expansion

      // 08 - PHP
      case 0x08:
        _cpu_cycle = 3;
        _stack_push(_state.export_processor_status());
        break;

      // 09 - ORA - Immediate
      case 0x09:
        _cpu_cycle = 2;
        _state.a = _or(_state.a, _immediate());
        break;

      // 0A - ASL - Accumulator
      case 0x0A:
        _cpu_cycle = 2;
        _state.a = _left_shift(_state.a);
        break;

      // 0B - 0C : Future Expansion

      // 0D - ORA - Absolute
      case 0x0D:
        _cpu_cycle = 4;
        _state.a = _or(_state.a, _absolute());
        break;

      // 0E - ASL - Absolute
      case 0x0E:
        _cpu_cycle = 6;
        int addr = _absolute_addr();
        _memory[addr] = _left_shift(_memory[addr]);
        break;

      // 0F - Future Expansion
      /*
        20 - JSR
        21 - AND - (Indirect,X)
        22 - Future Expansion
        23 - Future Expansion
        24 - BIT - Zero Page
        25 - AND - Zero Page
        26 - ROL - Zero Page
        27 - Future Expansion
        28 - PLP
        29 - AND - Immediate
        2A - ROL - Accumulator
        2B - Future Expansion
        2C - BIT - Absolute
        2D - AND - Absolute
        2E - ROL - Absolute
        2F - Future Expansion
        10 - BPL                        30 - BMI
        11 - ORA - (Indirect),Y         31 - AND - (Indirect),Y
        12 - Future Expansion           32 - Future Expansion
        13 - Future Expansion           33 - Future Expansion
        14 - Future Expansion           34 - Future Expansion
        15 - ORA - Zero Page,X          35 - AND - Zero Page,X
        16 - ASL - Zero Page,X          36 - ROL - Zero Page,X
        17 - Future Expansion           37 - Future Expansion
        18 - CLC                        38 - SEC
        19 - ORA - Absolute,Y           39 - AND - Absolute,Y
        1A - Future Expansion           3A - Future Expansion
        1B - Future Expansion           3B - Future Expansion
        1C - Future Expansion           3C - Future Expansion
        1D - ORA - Absolute,X           3D - AND - Absolute,X
        1E - ASL - Absolute,X           3E - ROL - Absolute,X
        1F - Future Expansion           3F - Future Expansion

        40 - RTI                        60 - RTS
        41 - EOR - (Indirect,X)         61 - ADC - (Indirect,X)
        42 - Future Expansion           62 - Future Expansion
        43 - Future Expansion           63 - Future Expansion
        44 - Future Expansion           64 - Future Expansion
        45 - EOR - Zero Page            65 - ADC - Zero Page
        46 - LSR - Zero Page            66 - ROR - Zero Page
        47 - Future Expansion           67 - Future Expansion
        48 - PHA                        68 - PLA
        49 - EOR - Immediate            69 - ADC - Immediate
        4A - LSR - Accumulator          6A - ROR - Accumulator
        4B - Future Expansion           6B - Future Expansion
        4C - JMP - Absolute             6C - JMP - Indirect
        4D - EOR - Absolute             6D - ADC - Absolute
        4E - LSR - Absolute             6E - ROR - Absolute
        4F - Future Expansion           6F - Future Expansion
        50 - BVC                        70 - BVS
        51 - EOR - (Indirect),Y         71 - ADC - (Indirect),Y
        52 - Future Expansion           72 - Future Expansion
        53 - Future Expansion           73 - Future Expansion
        54 - Future Expansion           74 - Future Expansion
        55 - EOR - Zero Page,X          75 - ADC - Zero Page,X
        56 - LSR - Zero Page,X          76 - ROR - Zero Page,X
        57 - Future Expansion           77 - Future Expansion
        58 - CLI                        78 - SEI
        59 - EOR - Absolute,Y           79 - ADC - Absolute,Y
        5A - Future Expansion           7A - Future Expansion
        5B - Future Expansion           7B - Future Expansion
        5C - Future Expansion           7C - Future Expansion
        50 - EOR - Absolute,X           70 - ADC - Absolute,X
        5E - LSR - Absolute,X           7E - ROR - Absolute,X
        5F - Future Expansion           7F - Future Expansion

        80 - Future Expansion           A0 - LDY - Immediate
        81 - STA - (Indirect,X)         A1 - LDA - (Indirect,X)
        82 - Future Expansion           A2 - LDX - Immediate
        83 - Future Expansion           A3 - Future Expansion
        84 - STY - Zero Page            A4 - LDY - Zero Page
        85 - STA - Zero Page            A5 - LDA - Zero Page
        86 - STX - Zero Page            A6 - LDX - Zero Page
        87 - Future Expansion           A7 - Future Expansion
        88 - DEY                        A8 - TAY
        89 - Future Expansion           A9 - LDA - Immediate
        8A - TXA                        AA - TAX
        8B - Future Expansion           AB - Future Expansion
        8C - STY - Absolute             AC - LDY - Absolute
        80 - STA - Absolute             AD - LDA - Absolute
        8E - STX - Absolute             AE - LDX - Absolute
        8F - Future Expansion           AF - Future Expansion
        90 - BCC                        B0 - BCS
        91 - STA - (Indirect),Y         B1 - LDA - (Indirect),Y
        92 - Future Expansion           B2 - Future Expansion
        93 - Future Expansion           B3 - Future Expansion
        94 - STY - Zero Page,X          B4 - LDY - Zero Page,X
        95 - STA - Zero Page,X          BS - LDA - Zero Page,X
        96 - STX - Zero Page,Y          B6 - LDX - Zero Page,Y
        97 - Future Expansion           B7 - Future Expansion
        98 - TYA                        B8 - CLV
        99 - STA - Absolute,Y           B9 - LDA - Absolute,Y
        9A - TXS                        BA - TSX
        9B - Future Expansion           BB - Future Expansion
        9C - Future Expansion           BC - LDY - Absolute,X
        90 - STA - Absolute,X           BD - LDA - Absolute,X
        9E - Future Expansion           BE - LDX - Absolute,Y
        9F - Future Expansion           BF - Future Expansion

        C0 - Cpy - Immediate            E0 - CPX - Immediate
        C1 - CMP - (Indirect,X)         E1 - SBC - (Indirect,X)
        C2 - Future Expansion           E2 - Future Expansion
        C3 - Future Expansion           E3 - Future Expansion
        C4 - CPY - Zero Page            E4 - CPX - Zero Page
        C5 - CMP - Zero Page            E5 - SBC - Zero Page
        C6 - DEC - Zero Page            E6 - INC - Zero Page
        C7 - Future Expansion           E7 - Future Expansion
        C8 - INY                        E8 - INX
        C9 - CMP - Immediate            E9 - SBC - Immediate
        CA - DEX                        EA - NOP
        CB - Future Expansion           EB - Future Expansion
        CC - CPY - Absolute             EC - CPX - Absolute
        CD - CMP - Absolute             ED - SBC - Absolute
        CE - DEC - Absolute             EE - INC - Absolute
        CF - Future Expansion           EF - Future Expansion
        D0 - BNE                        F0 - BEQ
        D1 - CMP   (Indirect@,Y         F1 - SBC - (Indirect),Y
        D2 - Future Expansion           F2 - Future Expansion
        D3 - Future Expansion           F3 - Future Expansion
        D4 - Future Expansion           F4 - Future Expansion
        D5 - CMP - Zero Page,X          F5 - SBC - Zero Page,X
        D6 - DEC - Zero Page,X          F6 - INC - Zero Page,X
        D7 - Future Expansion           F7 - Future Expansion
        D8 - CLD                        F8 - SED
        D9 - CMP - Absolute,Y           F9 - SBC - Absolute,Y
        DA - Future Expansion           FA - Future Expansion
        DB - Future Expansion           FB - Future Expansion
        DC - Future Expansion           FC - Future Expansion
        DD - CMP - Absolute,X           FD - SBC - Absolute,X
        DE - DEC - Absolute,X           FE - INC - Absolute,X
        DF - Future Expansion           FF - Future Expansion */
      default:
        throw "Opcode $cond Not Implemented";
    }
  }

  /// negative flag update
  void _negative_update(int nb) {
    _state.negative = (nb & (1 << 7)) != 0;
  }

  /// zero flag update
  void _zero_update(int nb) {
    _state.zero = (nb & 0xFF) == 0;
  }

  void _carry_update(int nb) {
    _state.carry = (nb > 0xFF);
  }

  /// return the 8-bit result of x + y and update the state flags
  int _add(int x, int y) {
    int res = x + y;
    _negative_update(res);
    _zero_update(res);
    _carry_update(res);
    return res;
  }

  /// return the 8-bit result of x | y and update the state flags
  int _or(int x, int y) {
    int res = x | y;
    _negative_update(res);
    _zero_update(res);
    return res & 0xFF;
  }

  /// left shift and updates flags
  int _left_shift(int x) {
    x <<= 1;
    _carry_update(x);
    _negative_update(x);
    _zero_update(x);
    return x & 0xFF;
  }

  /// push a byte onto the stack
  void _stack_push(int byte) {
    _memory[0x100 + _state.sp] = byte;
    _state.sp++;
    _state.sp &= 0xFF;
  }

  /// pull one byte from the stack
  int _stack_pull() {
    _state.sp--;
    _state.sp &= 0xFF;
    return _memory[0x100 + _state.sp];
  }

  /// save the current state in the stack
  void _save_state() {
    _stack_push((_state.pc >> 8) & 0xFF);
    _stack_push(_state.pc & 0xFF);
    _stack_push(_state.export_processor_status());
  }

  /// restore the state from the stack
  void _restore_state() {
    _state.load_processor_status(_stack_pull());
    _state.pc = _stack_pull() + (_stack_pull() << 8);
  }

  /// get an indirect_x value
  int _indirect_x() {
    _opcodes_used++;
    int addr = (_memory[_state.pc + 1] + _state.x) & 0xFF;
    int loc = _memory[addr] + (_memory[(addr + 1) & 0xFF] >> 8);
    return _memory[loc];
  }

  /// get a zero_page value
  int _zero_page() {
    _opcodes_used++;
    return _memory[_memory[_state.pc + 1]];
  }

  /// get an immediate value
  int _immediate() {
    _opcodes_used++;
    return _memory[_state.pc + 1];
  }

  /// get an absolute address
  int _absolute_addr() {
    _opcodes_used += 2;
    return _memory[_state.pc + 1] + (_memory[_state.pc + 2] << 8);
  }

  /// get an absolute value
  int _absolute() {
    return _memory[_absolute_addr()];
  }
}
