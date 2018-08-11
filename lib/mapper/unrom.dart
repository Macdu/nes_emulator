part of nes.mapper;

class UNROMMapper extends NROMMapper {
  void memory_write(int index, int value) {
    _cpu.memory.load_PGR_lower(_rom, _pgr_start + (1 << 14) * value);
  }
}
