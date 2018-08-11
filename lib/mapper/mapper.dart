library nes.mapper;

import 'dart:typed_data';
import 'dart:developer';

import '../cpu/cpu.dart';

part 'nrom.dart';
part 'mmc1.dart';
part 'unrom.dart';
part 'cnrom.dart';

final Map<int, Mapper> mappers = {
  0: new NROMMapper(),
  1: new MMC1Mapper(),
  2: new UNROMMapper(),
  3: new CNROMMapper(),
};

abstract class Mapper {
  CPU _cpu;

  Uint8List _rom;
  int _nb_pgr;
  int _nb_chr;
  bool _has_sram;

  /// Start address of the PGR ROM
  int _pgr_start;

  /// Start address of the CHR ROM
  int _chr_start;

  /// if SRAM is present in this game
  bool get has_sram => _has_sram;

  /// Called upon reset and power up
  void init(CPU cpu, Uint8List rom) {
    this._cpu = cpu;
    this._rom = rom;

    _nb_pgr = _rom[4];
    _nb_chr = _rom[5];

    // basic iNES file init
    if (_rom[0] != 0x4E ||
        _rom[1] != 0x45 ||
        _rom[2] != 0x53 ||
        _rom[3] != 0x1A) {
      print("Bad NES file header");
      return;
    }

    _pgr_start = 16;
    if ((_rom[6] & (1 << 2)) != 0) {
      // contains a 512-byte trainer
      _cpu.memory.load_trainer(_rom, 16);
      _pgr_start += 512;
    }

    _chr_start = _pgr_start + (1 << 14) * (_nb_pgr);
  }

  /// Called when a memory writes happens in the PGR rom
  void memory_write(int index, int value) {
    throw "Attempt to write at memory location 0x${index.toRadixString(16)}";
  }
}
