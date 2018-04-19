part of nes.processor;

/// State of the 6502 processor
class State {
  /// 16 bit program counter
  int pc;

  /// 8 bit stack pointer
  int sp;

  /// 8 bit accumulator
  int a;

  /// 8 bit x index register
  int x;

  /// 8 bit y index register
  int y;

  /// Carry Flag (C) - The carry flag is set if the last instruction resulted in an overflow from bit
  /// 7 or an underflow from bit 0.
  bool carry;

  /// Zero Flag (Z) - The zero flag is set if the result of the last instruction was zero
  bool zero;

  /// Interrupt Disable (I) - The interrupt disable flag can be used to prevent the system
  /// responding to IRQs
  bool interrupt_disable;

  /// The decimal mode flag is used to switch the 6502 into BCD mode.
  /// Not used by the NES, have no effect
  bool decimal_mode;

  /// Break Command (B) - The break command flag is used to indicate that a BRK (Break)
  /// instruction has been executed, causing an IRQ.
  bool break_command;

  /// Overflow Flag (V) - The overflow flag is set if an invalid two’s complement result was
  /// obtained by the previous instruction.
  bool overflow;

  /// Negative Flag (N) - Bit 7 of a byte represents the sign of that byte, with 0 being positive
  /// and 1 being negative. The negative flag (also known as the sign flag) is set if this sign bit
  /// is 1.
  bool negative;

  /// load from the stack : NV BDIZC
  void load_processor_status(int p) {
    carry = (p & 1) != 0;
    zero = (p & 0x02) != 0;
    interrupt_disable = (p & 0x04) != 0;
    decimal_mode = (p & 0x08) != 0;
    break_command = (p & 0x10) != 0;

    negative = (p & 0x40) != 0;
    overflow = (p & 0x80) != 0;
  }

  /// export to the stack : NV BDIZC
  int export_processor_status() {
    int p = 0;
    if (carry) p &= 0x01;
    if (zero) p &= 0x02;
    if (interrupt_disable) p &= 0x04;
    if (decimal_mode) p &= 0x08;
    if (break_command) p &= 0x10;

    if (negative) p &= 0x40;
    if (overflow) p &= 0x80;
    return p;
  }
}
