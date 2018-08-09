part of nes.cpu;

/// State of the 6502 processor
class State {
  /// 16 bit program counter
  int pc = 0;

  /// 8 bit stack pointer
  int sp = 0xFD;

  /// 8 bit accumulator
  int a = 0;

  /// 8 bit x index register
  int x = 0;

  /// 8 bit y index register
  int y = 0;

  /// Carry Flag (C) - The carry flag is set if the last instruction resulted in an overflow from bit
  /// 7 or an underflow from bit 0.
  bool carry = false;

  /// return the carry as an int
  int get carry_val => carry ? 1 : 0;

  /// Zero Flag (Z) - The zero flag is set if the result of the last instruction was zero
  bool zero = false;

  /// Interrupt Disable (I) - The interrupt disable flag can be used to prevent the system
  /// responding to IRQs
  bool interrupt_disable = true;

  /// The decimal mode flag is used to switch the 6502 into BCD mode.
  /// Not used by the NES, have no effect
  bool decimal_mode = false;

  /// Break Command (B) - The break command flag is used to indicate that a BRK (Break)
  /// instruction has been executed, causing an IRQ.
  // bool break_command = false;

  /// Overflow Flag (V) - The overflow flag is set if an invalid two’s complement result was
  /// obtained by the previous instruction.
  bool overflow = false;

  /// Negative Flag (N) - Bit 7 of a byte represents the sign of that byte, with 0 being positive
  /// and 1 being negative. The negative flag (also known as the sign flag) is set if this sign bit
  /// is 1.
  bool negative = false;

  /// load from the stack : NV BDIZC
  void load_processor_flags(int p) {
    carry = (p & 1) != 0;
    zero = (p & 0x02) != 0;
    interrupt_disable = (p & 0x04) != 0;
    decimal_mode = (p & 0x08) != 0;

    overflow = (p & 0x40) != 0;
    negative = (p & 0x80) != 0;
  }

  /// export to the stack : NV BDIZC
  int export_processor_flags(bool break_state) {
    int p = 0x20;
    if (carry) p |= 0x01;
    if (zero) p |= 0x02;
    if (interrupt_disable) p |= 0x04;
    if (decimal_mode) p |= 0x08;
    if (break_state) p |= 0x10;

    if (overflow) p |= 0x40;
    if (negative) p |= 0x80;
    return p;
  }
}
