library nes.processor;

import 'dart:typed_data';

part "cpu_memory.dart";
part "state.dart";

/// Simulate a 6502 processor
class NESProcessor {
  final CPUMemory memory = new CPUMemory();

  NESProcessor() {}
}
