library nes;

import 'dart:html' show CanvasElement;
import 'dart:typed_data';

import 'cpu/cpu.dart';
import 'gamepad/gamepad.dart';

/// Emulates an NES to a given canvas
class NESEmulator {
  CPU _cpu = new CPU();
  GamePad gamepad = new GamePad();
  bool _playing = false;

  CPU get cpu => _cpu;

  NESEmulator(CanvasElement target) {
    _cpu.ppu.init(target, _cpu);
    _cpu.gamepad = gamepad;
  }

  /// run the emulator
  void run() {
    _playing = true;
    while (_playing) {
      //await window.animationFrame;
      tick();
    }
  }

  /// pauses the emulator (if it was running before)
  void pause() {
    _playing = false;
  }

  /// run one cpu cycle
  void tick() {
    _cpu.tick();
    _cpu.ppu.tick();
  }

  /// load rom from a ByteBuffer
  void loadRom(Uint8List rom) {
    // check file
    Uint8List infos = rom; // new Uint8List.view(rom, 0, 16);
    if (infos[0] != 0x4E || infos[1] != 0x45 || infos[2] != 0x53) {
      print("Bad NES file header");
      return;
    }

    int offset = 16;
    if ((infos[6] & (1 << 2)) != 0) {
      // contains a 512-byte trainer
      _cpu.memory.load_trainer(rom, offset);
      offset += 512;
    }

    int pgr_lower_start = offset;
    int pgr_higher_start = offset;
    if (rom.lengthInBytes >= 16 + (1 << 15)) {
      pgr_higher_start += (1 << 14);
    }
    _cpu.memory.load_PGR_lower(rom, pgr_lower_start);
    _cpu.memory.load_PGR_upper(rom, pgr_higher_start);
    reset();
  }

  /// reset the emulator
  void reset() {
    _cpu.interrupt(InterruptType.RESET);
    // ppu reset ?
  }
}
