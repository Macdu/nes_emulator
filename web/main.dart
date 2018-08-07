import 'dart:html';
import 'dart:typed_data';

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
  // skips the first 18 bytes of the iNES file
  emu.loadRom(reader.result);
}

void main() {
  emu = new NESEmulator(querySelector("#renderer"));

  querySelector("#play").onClick.listen(tick);
  querySelector("#pause").onClick.listen(pause);
  querySelector("#tick").onClick.listen(tick);
  querySelector("#charge").onClick.listen(loadRom);
}
