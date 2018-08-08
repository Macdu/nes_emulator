part of nes.ppu;

/// A simple RGB color
class Color {
  final int r, v, b;

  const Color(int hex)
      : r = (hex >> 16) & 0xFF,
        v = (hex >> 8) & 0xFF,
        b = hex & 0xFF;
}

// the current transparent color
Color _transparent;

/// nes color palette from http://nesdev.com/nespal.txt
const List<Color> nes_palette = [
  Color(0x808080),
  Color(0x0000BB),
  Color(0x3700BF),
  Color(0x8400A6),
  Color(0xBB006A),
  Color(0xB7001E),
  Color(0xB30000),
  Color(0x912600),
  Color(0x7B2B00),
  Color(0x003E00),
  Color(0x00480D),
  Color(0x003C22),
  Color(0x002F66),
  Color(0x000000),
  Color(0x050505),
  Color(0x050505),
  Color(0xC8C8C8),
  Color(0x0059FF),
  Color(0x443CFF),
  Color(0xB733CC),
  Color(0xFF33AA),
  Color(0xFF375E),
  Color(0xFF371A),
  Color(0xD54B00),
  Color(0xC46200),
  Color(0x3C7B00),
  Color(0x1E8415),
  Color(0x009566),
  Color(0x0084C4),
  Color(0x111111),
  Color(0x090909),
  Color(0x090909),
  Color(0xFFFFFF),
  Color(0x0095FF),
  Color(0x6F84FF),
  Color(0xD56FFF),
  Color(0xFF77CC),
  Color(0xFF6F99),
  Color(0xFF7B59),
  Color(0xFF915F),
  Color(0xFFA233),
  Color(0xA6BF00),
  Color(0x51D96A),
  Color(0x4DD5AE),
  Color(0x00D9FF),
  Color(0x666666),
  Color(0x0D0D0D),
  Color(0x0D0D0D),
  Color(0xFFFFFF),
  Color(0x84BFFF),
  Color(0xBBBBFF),
  Color(0xD0BBFF),
  Color(0xFFBFEA),
  Color(0xFFBFCC),
  Color(0xFFC4B7),
  Color(0xFFCCAE),
  Color(0xFFD9A2),
  Color(0xCCE199),
  Color(0xAEEEB7),
  Color(0xAAF7EE),
  Color(0xB3EEFF),
  Color(0xDDDDDD),
  Color(0x111111),
  Color(0x111111),
];
