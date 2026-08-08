{ pkgs, ... }:

{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting ""
      fastfetch
    '';
    shellAliases = {
      ls = "eza --icons";
      cat = "bat";
      lg = "lazygit";
    };
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.zoxide = { enable = true; enableFishIntegration = true; };
  programs.fzf = { enable = true; enableFishIntegration = true; };
  programs.bat = { enable = true; };
}
