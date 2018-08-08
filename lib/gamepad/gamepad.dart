library nes.gamepad;

import 'dart:html';

/// Allow to access to the player gamepad
class GamePad {
  bool a_pressed = false;

  /// "A" by default
  int a_key = 65;
  bool b_pressed = false;

  /// "Z" by default
  int b_key = 90;

  bool select_pressed = false;

  /// "Q" by default
  int select_key = 81;
  bool start_pressed = false;

  /// "S" by default
  int start_key = 83;

  bool up_pressed = false;

  /// "Up arrow" by default
  int up_key = 38;
  bool down_pressed = false;

  /// "Down arrow" by default
  int down_key = 40;
  bool left_pressed = false;

  /// "Left arrow" by default
  int left_key = 37;
  bool right_pressed = false;

  /// "Right arrow" by default
  int right_key = 39;

  GamePad() {
    // add listener
    document.body.onKeyDown.listen(_key_change(true));
    document.body.onKeyUp.listen(_key_change(false));
  }

  Function _key_change(bool flag) => (KeyboardEvent event) {
        int key = event.keyCode;
        if (key == a_key)
          a_pressed = flag;
        else if (key == b_key)
          b_pressed = flag;
        else if (key == select_key)
          select_pressed = flag;
        else if (key == start_key)
          start_pressed = flag;
        else if (key == select_key)
          select_pressed = flag;
        else if (key == up_key)
          up_pressed = flag;
        else if (key == down_key)
          down_pressed = flag;
        else if (key == left_key)
          left_pressed = flag;
        else if (key == right_key) right_pressed = flag;
        return;
      };

  /// id correspond to the order the key states are given to the nes
  bool is_pressed(int id) {
    switch (id) {
      case 0:
        return a_pressed;
      case 1:
        return b_pressed;
      case 2:
        return select_pressed;
      case 3:
        return start_pressed;
      case 4:
        return up_pressed;
      case 5:
        return down_pressed;
      case 6:
        return left_pressed;
      case 7:
        return right_pressed;
      default:
        return false;
    }
  }
}
