library nes;

import 'dart:html' show CanvasElement, window;
import 'dart:typed_data';

import 'cpu/cpu.dart';
import 'gamepad/gamepad.dart';
import 'ppu/ppu.dart';
import 'mapper/mapper.dart';

/// Emulates an NES to a given canvas
class NESEmulator {
  CPU _cpu = new CPU();
  GamePad gamepad = new GamePad();
  bool _playing = false;

  /// Keep access to the rom
  Uint8List _curr_rom;

  Mapper _mapper;
  Mapper get mapper => _mapper;

  CPU get cpu => _cpu;
  PPU get ppu => _cpu.ppu;

  NESEmulator(CanvasElement target) {
    _cpu.ppu.init(target, _cpu);
    _cpu.gamepad = gamepad;
  }

  /// run the emulator
  void run() async {
    _playing = true;
    if (_curr_rom == null) return;
    while (_playing) {
      await window.animationFrame;
      // render about one frame
      for (int i = 0; i < 29781; i++) tick();
    }
  }

  /// pauses the emulator (if it was running before)
  void pause() {
    _playing = false;
  }

  int _total_ticks = 0;

  /// run one cpu cycle
  void tick() {
    if (_curr_rom == null) return;

    _total_ticks++;
    _cpu.tick();
    _cpu.ppu.tick();
  }

  /// load rom from a ByteBuffer
  void loadRom(Uint8List rom) {
    // check file

    int mapper_id = rom[7] >> 4;
    this._mapper = mappers[mapper_id];
    _curr_rom = rom;

    reset();
    _cpu.state.sp = 0xFD;
  }

  /// reset the emulator
  void reset() {
    if (_curr_rom == null) return;

    _mapper.init(cpu, _curr_rom);
    _cpu.interrupt(InterruptType.RESET);
    // ppu reset ?
  }
}
