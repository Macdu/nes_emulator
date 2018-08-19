part of nes.ppu;

/// render the background
class Background {
  /// value 255 in this array means it has not been initialised yet
  Uint8List _result = new Uint8List(256 * 240 * 4);

  PPU _ppu;

  static const List<List<int>> _mirroring_tables = const [
    // Horizontal
    [0, 0, 0x800, 0x800],
    // Vertical
    [0, 0x400, 0, 0x400],
    // Four screens
    [0, 0x400, 0x800, 0xC00],
    // Single screen
    [0, 0, 0, 0],
  ];

  /// the background is rendered each frame
  void _render_tile_line(int start_x, int start_y) {
    int pattern_loc = _ppu.pattern_background_location * 0x1000;
    int table_offset; // offset from $2000
    int mirroring_offset;

    int cols_start = (start_x >> 3);
    // if y is not a multiple of 8, there are 2 tiles which are partially rendered
    int cols_end = cols_start + (((start_x & 7) == 0) ? 32 : 33);
    int old_line = (start_y >> 3);

    for (int old_col = cols_start; old_col < cols_end; old_col++) {
      table_offset = 0;
      mirroring_offset = 0;
      int col = old_col & 0x3F;
      int line = old_line;
      if (line >= 30) {
        line -= 30;
        mirroring_offset |= 2;
        ;
      }
      if (col >= 32) {
        col -= 32;
        mirroring_offset |= 1;
      }
      table_offset = _mirroring_tables[_ppu._mirroring.index][mirroring_offset];
      int real_tile = line * 32 + col;
      // get the high bit
      int square = ((col & 2) >> 1) + (line & 2);
      int number = (col >> 2) + ((line >> 2) << 3);
      int addr = 0x23C0 + table_offset + number;
      int high_bit = ((_ppu.memory._data[addr] >> (2 * square)) & 3) << 2;

      int pattern =
          (_ppu.memory._data[0x2000 + table_offset + real_tile] << 4) +
              pattern_loc;

      // Now we can render the pixels
      for (int x = 0; x < 8; x++) {
        for (int y = 0; y < 8; y++) {
          int color = high_bit |
              ((_ppu.memory._data[pattern + y] >> (7 - x)) & 1) |
              (((_ppu.memory._data[pattern + 8 + y] >> (7 - x)) & 1) << 1);
          _result[(old_line * 8 + y) * 256 * 2 + ((old_col & 0x3F) * 8 + x)] =
              color;
        }
      }
    }
  }
}
