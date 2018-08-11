part of nes.mapper;

/// NROM mapper, basic mapper for NES cartridge
class NROMMapper extends Mapper {
  void init(CPU cpu, Uint8List rom) {
    super.init(cpu, rom);

    _cpu.memory.load_PGR_lower(_rom, _pgr_start);

    // if the game has only one PGR slot, copy it to lower and upper part of memory
    _cpu.memory
        .load_PGR_upper(_rom, _pgr_start + ((_nb_pgr > 1) ? (1 << 14) : 0));

    if (_nb_chr >= 1) {
      _cpu.ppu.memory.load_chr_rom(_rom, _chr_start);
    }
  }
}