library nes;

import 'dart:html' show CanvasElement, window;
import 'dart:typed_data';

import 'cpu/cpu.dart';
import 'gamepad/gamepad.dart';
import 'ppu/ppu.dart';

/// Emulates an NES to a given canvas
class NESEmulator {
  CPU _cpu = new CPU();
  GamePad gamepad = new GamePad();
  bool _playing = false;

  int _nb_pgr_rom;
  int _nb_chr_rom;

  CPU get cpu => _cpu;
  PPU get ppu => _cpu.ppu;

  NESEmulator(CanvasElement target) {
    _cpu.ppu.init(target, _cpu);
    _cpu.gamepad = gamepad;
  }

  /// run the emulator
  void run() async {
    _playing = true;
    while (_playing) {
      await window.animationFrame;
      // render about one frame
      for (int i = 0; i < 22272; i++) tick();
    }
  }

  /// pauses the emulator (if it was running before)
  void pause() {
    _playing = false;
  }

  int _total_ticks = 0;

  /// run one cpu cycle
  void tick() {
    _total_ticks++;
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

    _nb_pgr_rom = rom[4];
    _nb_chr_rom = rom[5];

    int offset = 16;
    if ((infos[6] & (1 << 2)) != 0) {
      // contains a 512-byte trainer
      _cpu.memory.load_trainer(rom, offset);
      offset += 512;
    }

    int pgr_lower_start = offset;
    int pgr_higher_start = offset;
    offset += 1 << 14;
    if (_nb_pgr_rom > 1) {
      pgr_higher_start += (1 << 14);
      offset += 1 << 14;
    }
    _cpu.memory.load_PGR_lower(rom, pgr_lower_start);
    _cpu.memory.load_PGR_upper(rom, pgr_higher_start);

    if (_nb_chr_rom >= 1) {
      ppu.memory.load_chr_rom(rom, offset);
    }
    reset();
    _cpu.state.sp = 0xFD;
  }

  /// reset the emulator
  void reset() {
    _cpu.interrupt(InterruptType.RESET);
    // ppu reset ?
  }
}
