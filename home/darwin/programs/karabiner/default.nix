# macOS向けKarabiner-Elements設定
{ pkgs, ... }:

let
  # Karabinerのjapanese_kana/eisuuではApple日本語入力への切り替えが安定しないため、
  # macismで現在の入力ソースを取得し、Apple日本語入力とABCを明示的に選択する。
  toggleInputSource = pkgs.writeShellScript "toggle-input-source" ''
    set -eu

    current_input_source="$(${pkgs.macism}/bin/macism)"

    if [ "$current_input_source" = "com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese" ]; then
      exec ${pkgs.macism}/bin/macism com.apple.keylayout.ABC
    fi

    exec ${pkgs.macism}/bin/macism com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese
  '';
in
{
  # Karabinerの設定をNixで一元管理し、GUIからの変更よりこの宣言を正本とする。
  home.file.".config/karabiner/karabiner.json" = {
    force = true;
    text = builtins.toJSON {
      # アップデート通知とメニューバー表示に関するアプリ全体の設定。
      global = {
        check_for_updates_on_startup = true;
        show_in_menu_bar = true;
        show_profile_name_in_menu_bar = false;
      };

      profiles = [
        {
          name = "Default";
          selected = true;

          # Rainy 75はANSI配列なので、Karabinerの仮想キーボードもANSIとして扱う。
          virtual_hid_keyboard = {
            keyboard_type_v2 = "ansi";
          };

          # Rainy 75はBluetooth接続時にキーボード兼ポインティングデバイスとして認識される。
          # Karabinerはポインティングデバイスを既定で無視するため、実機の識別子を完全に
          # 指定してignoreを解除し、キーボードイベントをComplex Modificationsへ渡す。
          devices = [
            {
              identifiers = {
                vendor_id = 9306;
                product_id = 33398;
                is_keyboard = true;
                is_pointing_device = true;
              };
              ignore = false;
            }
          ];

          # Caps LockをControlとして常時使用する基本的なキー置換。
          simple_modifications = [
            {
              from.key_code = "caps_lock";
              to = [
                {
                  key_code = "left_control";
                }
              ];
            }
          ];

          complex_modifications = {
            # 単押し、長押し、同時押しを判定するKarabinerの共通タイミング設定。
            parameters = {
              "basic.simultaneous_threshold_milliseconds" = 50;
              "basic.to_delayed_action_delay_milliseconds" = 500;
              "basic.to_if_alone_timeout_milliseconds" = 1000;
              "basic.to_if_held_down_threshold_milliseconds" = 500;
            };
            rules = [
              {
                description = "Right Shift alone switches between English and Japanese";
                manipulators = [
                  {
                    type = "basic";
                    from = {
                      key_code = "right_shift";
                      modifiers.optional = [ "any" ];
                    };
                    # 他のキーと組み合わせた場合は通常の右Shiftとして機能させる。
                    # lazyにより、単押しと確定する前に不要なShiftイベントを送らない。
                    to = [
                      {
                        key_code = "right_shift";
                        lazy = true;
                      }
                    ];
                    # 右Shiftだけを押して離した場合に限り、入力ソースを切り替える。
                    to_if_alone = [
                      {
                        shell_command = "${toggleInputSource}";
                      }
                    ];
                  }
                ];
              }
            ];
          };
        }
      ];
    };
  };
}
