library nes.processor;

import 'dart:typed_data';

part "cpu_memory.dart";
part "state.dart";
part "hex_interpreter.dart";

/// Simulate a 6502 processor
class NESProcessor {
  final CPUMemory memory = new CPUMemory();
  final State state = new State();
  Interpreter _interpreter;

  NESProcessor() {
    state.load_processor_status(0);
    // the program start at address $8000
    state.pc = 0x8000;
    _interpreter = new Interpreter(state, memory);
  }
}
