

{ ... }:
{
    programs.tmux = {
      enable = true;

      shortcut = "a";
      baseIndex = 1;

      terminal = "screen-256color";

      mouse = true;

      extraConfig = ''
        # ───────────────
        # 見た目（ミニマル）
        # ───────────────
        set -g status on
        set -g status-interval 2
        set -g status-position bottom

        set -g status-style bg=default,fg=white

        # 左（セッション名だけ）
        set -g status-left "#S "

        # 右（時計だけ）
        set -g status-right "%Y-%m-%d %H:%M"

        # ウィンドウ表示
        setw -g window-status-format " #I:#W "
        setw -g window-status-current-format " #I:#W* "

        # ───────────────
        # 操作最小化
        # ───────────────
        bind | split-window -h
        bind - split-window -v

        bind h select-pane -L
        bind j select-pane -D
        bind k select-pane -U
        bind l select-pane -R

        # コピーモード（vim風）
        setw -g mode-keys vi
      '';
    };
}
