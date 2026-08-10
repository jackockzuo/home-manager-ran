{ pkgs, ... }:

{
  # 1. Fish Shell 基础配置
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
      v = "nvim";
      };
  };
  # 🔴 100% 兼容的方式：直接生成 Fish 自动加载函数文件 ~/.config/fish/functions/clean-system.fish
  xdg.configFile."fish/functions/clean-system.fish".text = ''
    function clean-system
        echo "🧹 正在清理 Nix 废弃历史版本..."
        nix-collect-garbage -d

        echo "🧹 正在清理 Pacman 软件包缓存..."
        sudo pacman -Sc --noconfirm

        echo "🧹 正在清理系统孤立无用包..."
        sudo pacman -Qtdq | sudo pacman -Rns

        echo "✨ 系统保洁完成，恢复极致清爽！"
    end
  '';

  # 迁移自 minimal-niri-dotfiles：y (yazi 退出后 cd 回目录) / lt (eza 树状) / la (eza 长格式)
  xdg.configFile."fish/functions/y.fish".text = ''
    function y
    	set tmp (mktemp -t "yazi-cwd.XXXXXX")
    	yazi $argv --cwd-file="$tmp"
    	if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
    		builtin cd -- "$cwd"
    	end
    	rm -f -- "$tmp"
    end
  '';
  xdg.configFile."fish/functions/lt.fish".text = ''
    function lt
    	command eza --icons=auto --tree -- $argv
    end
  '';
  xdg.configFile."fish/functions/la.fish".text = ''
    function la
    	command eza -l --icons=auto -- $argv
    end
  '';
  # Wine 程序安装（推荐独立 prefix，卸载零残留）
  # 用法: wine-install <安装程序路径> [prefix名]
  #   例: wine-install setup.exe              → 用默认 ~/.wine 安装
  #   例: wine-install setup.exe sgs           → 用独立 prefix ~/.wine-sgs 安装
  xdg.configFile."fish/functions/wine-install.fish".text = ''
    function wine-install
        set -l installer $argv[1]
        set -l prefix_name $argv[2]
        if test -z "$installer"
            echo "用法: wine-install <安装程序> [prefix名]"
            echo "  例: wine-install setup.exe          # 默认 ~/.wine"
            echo "  例: wine-install setup.exe sgs       # 独立 prefix ~/.wine-sgs"
            return 1
        end
        if not test -f "$installer"
            echo "❌ 找不到安装程序: $installer"
            return 1
        end
        if test -n "$prefix_name"
            set -l prefix_dir ~/.wine-$prefix_name
            if not test -d "$prefix_dir"
                echo "📦 创建独立 prefix: $prefix_dir"
                WINEPREFIX="$prefix_dir" wineboot -u
            end
            echo "🚀 正在用 prefix $prefix_dir 安装 $installer ..."
            WINEPREFIX="$prefix_dir" wine "$installer"
        else
            echo "🚀 正在用默认 prefix 安装 $installer ..."
            wine "$installer"
        end
        echo "✅ 安装完成。卸载时用: wine-uninstall $prefix_name"
    end
  '';
  # Wine 程序卸载（打开官方卸载器 + 清理快捷方式/空目录残留）
  # 用法: wine-uninstall [prefix名]
  #   例: wine-uninstall        → 打开默认 prefix 的卸载器
  #   例: wine-uninstall sgs    → 打开 ~/.wine-sgs 的卸载器，卸载后清理该 prefix 的入口
  xdg.configFile."fish/functions/wine-uninstall.fish".text = ''
    function wine-uninstall
        set -l prefix_name $argv[1]
        set -l prefix_dir ~/.wine
        if test -n "$prefix_name"
            set prefix_dir ~/.wine-$prefix_name
        end
        if not test -d "$prefix_dir"
            echo "❌ prefix 不存在: $prefix_dir"
            return 1
        end
        echo "🧹 打开 Wine 卸载器 ($prefix_dir) —— 在列表里选目标程序卸载..."
        WINEPREFIX="$prefix_dir" wine uninstaller
        echo "🧹 正在清理快捷方式残留..."
        # 删除该 prefix 对应的开始菜单入口（如果 wine 用的是默认菜单目录）
        set -l prog_dir ~/.local/share/applications/wine/Programs
        if test -d "$prog_dir"
            # 清理空目录残留（.desktop 已删但目录还在的）
            for d in $prog_dir/*
                if test -d "$d"
                    set -l has_entry (find "$d" -name '*.desktop' 2>/dev/null | count)
                    if test "$has_entry" -eq 0
                        rmdir "$d" 2>/dev/null; and echo "🗑️  移除空目录: $d"
                    end
                end
            end
        end
        # 若指定了独立 prefix 且用户确认，可整体删除 prefix
        if test -n "$prefix_name"
            echo ""
            echo "💡 如果想彻底删除整个 prefix (含程序本体+注册表):"
            echo "   rm -rf $prefix_dir"
            echo "   确认无误后可执行: wine-uninstall --purge $prefix_name"
        end
    end
    # 子命令: --purge 彻底删除独立 prefix
    function __wine_purge
        set -l prefix_name $argv[1]
        if test -z "$prefix_name"; or test "$prefix_name" = "--purge"
            echo "用法: wine-uninstall --purge <prefix名>"
            return 1
        end
        set -l prefix_dir ~/.wine-$prefix_name
        if not test -d "$prefix_dir"
            echo "❌ prefix 不存在: $prefix_dir"
            return 1
        end
        echo "⚠️  即将彻底删除 $prefix_dir (程序+注册表+一切)..."
        read -l -P '确认输入 yes 继续: ' confirm
        if test "$confirm" = "yes"
            rm -rf "$prefix_dir"
            echo "✅ 已彻底删除 $prefix_dir"
            # 清理该 prefix 残留的快捷方式
            set -l prog_dir ~/.local/share/applications/wine/Programs
            if test -d "$prog_dir"
                for d in $prog_dir/*
                    if test -d "$d"
                        set -l has_entry (find "$d" -name '*.desktop' 2>/dev/null | count)
                        if test "$has_entry" -eq 0
                            rmdir "$d" 2>/dev/null
                        end
                    end
                end
            end
        else
            echo "已取消"
        end
    end
    # 路由: --purge 子命令
    if test "$argv[1]" = "--purge"
        __wine_purge $argv[2]
    end
  '';
  # 2. 🔴 由 Nix 声明式构建你的专属 Powerline Starship 主题
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;

    settings = {
      "$schema" = "https://starship.rs/config-schema.json";

      format = "[](red)$os$username[](bg:peach fg:red)$directory[](bg:yellow fg:peach)$git_branch$git_status[](fg:yellow bg:green)$c$cpp$fortran$rust$java$haskell$python[](fg:green bg:sapphire)$cmake$pixi[](fg:sapphire bg:lavender)$time[ ](fg:lavender)$cmd_duration$line_break$character";

      palette = "catppuccin_mocha";

      os = {
        disabled = false;
        style = "bg:red fg:crust";
        symbols = {
          Windows = ""; Ubuntu = "󰕈"; SUSE = ""; Raspbian = "󰐿";
          Mint = "󰣭"; Macos = "󰀵"; Manjaro = ""; Linux = "󰌽";
          Gentoo = "󰣨"; Fedora = "󰣛"; Alpine = ""; Amazon = "";
          Android = ""; AOSC = ""; Arch = "󰣇"; Artix = "󰣇";
          CentOS = ""; Debian = "󰣚"; Redhat = "󱄛"; RedHatEnterprise = "󱄛";
        };
      };

      username = {
        show_always = true;
        style_user = "bg:red fg:crust";
        style_root = "bg:red fg:crust";
        format = "[ $user]($style)";
      };

      directory = {
        style = "bg:peach fg:crust";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = "…/";
        substitutions = {
          "Documents" = "󰈙 "; "Downloads" = " "; "Music" = "󰝚 ";
          "Pictures" = " "; "Developer" = "󰲋 ";
        };
      };

      git_branch = { symbol = ""; style = "bg:yellow"; format = "[[ $symbol $branch ](fg:crust bg:yellow)]($style)"; };
      git_status = { style = "bg:yellow"; format = "[[($all_status$ahead_behind )](fg:crust bg:yellow)]($style)"; };
      cmake = { symbol = " "; style = "bg:blue"; format = "[[ $symbol$version ](fg:crust bg:sapphire)]($style)"; };
      c = { symbol = " "; style = "bg:green"; format = "[[ $symbol $name $version ](fg:crust bg:green)]($style)"; };
      cpp = { symbol = " "; style = "bg:green fg:crust"; format = "[ $symbol($name $version) ]($style)"; disabled = false; };
      fortran = { symbol = "󱈚 "; style = "bg:green"; format = "[[ $symbol $name $version ](fg:crust bg:green)]($style)"; };
      rust = { symbol = ""; style = "bg:green"; format = "[[ $symbol$version ](fg:crust bg:green)]($style)"; };
      pixi = { symbol = "󱄵 "; style = "bg:blue"; format = "[[ $symbol $environment ](fg:crust bg:sapphire)]($style)"; };
      java = { symbol = " "; style = "bg:green"; format = "[[ $symbol $version ](fg:crust bg:green)]($style)"; };
      haskell = { symbol = ""; style = "bg:green"; format = "[[ $symbol$version ](fg:crust bg:green)]($style)"; };
      python = { symbol = ""; style = "bg:green"; format = "[[ $symbol $version ](fg:crust bg:green)]($style)"; };
      time = { disabled = false; time_format = "%R"; style = "bg:lavender"; format = "[[  $time ](fg:crust bg:lavender)]($style)"; };
      cmd_duration = { show_milliseconds = true; format = " in $duration "; style = "fg:text"; disabled = false; };
      line_break = { disabled = false; };
      character = { disabled = false; success_symbol = "[❯](bold fg:green)"; error_symbol = "[❯](bold fg:red)"; vimcmd_symbol = "[❮](bold fg:green)"; };

      palettes.catppuccin_mocha = {
        rosewater = "#f5e0dc"; flamingo = "#f2cdcd"; pink = "#f5c2e7"; mauve = "#cba6f7";
        red = "#f38ba8"; maroon = "#eba0ac"; peach = "#fab387"; yellow = "#f9e2af";
        green = "#a6e3a1"; teal = "#94e2d5"; sky = "#89dceb"; sapphire = "#74c7ec";
        blue = "#89b4fa"; lavender = "#b4befe"; text = "#cdd6f4"; subtext1 = "#bac2de";
        subtext0 = "#a6adc8"; overlay2 = "#9399b2"; overlay1 = "#7f849c"; overlay0 = "#6c7086";
        surface2 = "#585b70"; surface1 = "#45475a"; surface0 = "#313244"; base = "#1e1e2e";
        mantle = "#181825"; crust = "#11111b";
      };
    };
  };

  programs.zoxide = { enable = true; enableFishIntegration = true; };
  programs.fzf = { enable = true; enableFishIntegration = true; };
  programs.bat = { enable = true; };
}
