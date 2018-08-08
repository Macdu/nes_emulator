import 'dart:html';

import 'package:nes_emulator/emulator.dart';

NESEmulator emu;

void tick(_) {
  emu.tick();
}

void play(_) {
  emu.run();
}

void pause(_) {
  emu.pause();
}

void reset(_) {
  emu.reset();
}

void loadRom(_) async {
  FileUploadInputElement fileInput = new FileUploadInputElement();
  fileInput.style.display = 'none';
  fileInput.accept = ".nes";
  document.body.children.add(fileInput);
  fileInput.click();

  await fileInput.onChange.first;
  FileReader reader = new FileReader();
  reader.readAsArrayBuffer(fileInput.files.first);
  await reader.onLoadEnd.first;

  emu.loadRom(reader.result);
}

void main() {
  emu = new NESEmulator(querySelector("#renderer"));

  querySelector("#play").onClick.listen(play);
  querySelector("#pause").onClick.listen(pause);
  querySelector("#tick").onClick.listen(tick);
  querySelector("#charge").onClick.listen(loadRom);
  querySelector("#reset").onClick.listen(reset);

  debug_info = querySelector("#debug");
  debug_toggle = querySelector("#do-debug");
  debug_toggle.onChange.listen((_) => debugging = debug_toggle.checked);
  debug();

  cpu_part = querySelector("#cpu-value");
  ppu_part = querySelector("#ppu-value");
  querySelector("#cpu-entry").onClick.listen(debug_cpu);
  querySelector("#ppu-entry").onClick.listen(debug_ppu);
}

ParagraphElement debug_info;
CheckboxInputElement debug_toggle;
bool debugging = false;
void debug() async {
  String res = debugging
      ? """PC: 0x${emu.cpu.state.pc.toRadixString(16)}
  <br /> A : 0x${emu.cpu.state.a.toRadixString(16)}
  <br /> X : 0x${emu.cpu.state.x.toRadixString(16)}
  <br /> Y : 0x${emu.cpu.state.y.toRadixString(16)}
  <br /> SP : 0x${emu.cpu.state.sp.toRadixString(16)}
  <br />"""
      : "";
  debug_info.innerHtml = res;
  await window.animationFrame;
  debug();
}

SpanElement cpu_part, ppu_part;
void debug_cpu(Event event) {
  int location = int.parse((event.target as TextInputElement).value, radix: 16);
  cpu_part.innerHtml = "0x${emu.cpu.memory[location].toRadixString(16)}";
}

void debug_ppu(Event event) {
  int location = int.parse((event.target as TextInputElement).value, radix: 16);
  ppu_part.innerHtml = "0x${emu.ppu.memory[location].toRadixString(16)}";
}
