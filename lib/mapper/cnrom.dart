part of nes.mapper;

class CNROMMapper extends NROMMapper {
  void memory_write(int index, int value) {
    _cpu.ppu.memory.load_chr_rom(_rom, _chr_start + (1 << 13) * (value & 3));
  }
}
