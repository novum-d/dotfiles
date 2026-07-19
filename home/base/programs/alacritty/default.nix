{ ... }:
{
  programs.alacritty.settings = {
    window = {
      opacity = 1.0;
      padding = {
        x = 6;
        y = 6;
      };
      decorations = "None";
    };

    font = {
      normal.family = "Hack Nerd Font";
      size = 13.5;
    };

    scrolling.history = 10000;
  };
}
