# Karabiner-Elements設定
{ ... }:
{
  home.file.".config/karabiner/karabiner.json" = {
    force = true;
    text = builtins.toJSON {
      global = {
        check_for_updates_on_startup = true;
        show_in_menu_bar = true;
        show_profile_name_in_menu_bar = false;
      };

      profiles = [
        {
          name = "Default";
          selected = true;
          virtual_hid_keyboard = {
            keyboard_type_v2 = "ansi";
          };
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
            parameters = {
              "basic.simultaneous_threshold_milliseconds" = 50;
              "basic.to_delayed_action_delay_milliseconds" = 500;
              "basic.to_if_alone_timeout_milliseconds" = 1000;
              "basic.to_if_held_down_threshold_milliseconds" = 500;
            };
            rules = [
              {
                description = "Right Shift alone switches input source";
                manipulators = [
                  {
                    type = "basic";
                    from = {
                      key_code = "right_shift";
                      modifiers.optional = [ "any" ];
                    };
                    to = [
                      {
                        key_code = "right_shift";
                        lazy = true;
                      }
                    ];
                    to_if_alone = [
                      {
                        key_code = "spacebar";
                        modifiers = [ "left_control" ];
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
