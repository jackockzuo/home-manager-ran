{ pkgs, ... }:

{
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font = "Maple Mono NF CN:size=12";
        prompt = "'❯ '";
        icon-theme = "Papirus-Dark";
        horizontal-pad = 20;
        vertical-pad = 12;
      };
      colors = {
        background = "1e1e2edd";
        text = "cdd6f4ff";
        match = "f38ba8ff";
        selection = "585b70ff";
        selection-text = "cdd6f4ff";
        border = "cba6f7ff";
      };
      border = { width = 2; radius = 12; };
    };
  };
}
