part of nes.mapper;

/// NROM mapper, basic mapper for NES cartridge
class NROMMapper extends Mapper {
  void init(CPU cpu, Uint8List rom) {
    super.init(cpu, rom);

    // load first and last pgr roms
    _cpu.memory.load_PGR_lower(_rom, _pgr_start);
    _cpu.memory.load_PGR_upper(_rom, _pgr_start + (1 << 14) * (_nb_pgr - 1));

    // not sure if I have to load this part
    if (_nb_chr >= 1) {
      _cpu.ppu.memory.load_chr_rom(_rom, _chr_start);
    }
  }
}
