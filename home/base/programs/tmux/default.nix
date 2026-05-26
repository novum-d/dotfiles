{ ... }:
{
  programs.tmux = {
    enable = true;

    # Ctrl-a を prefix にする
    shortcut = "a";

    baseIndex = 1;
    keyMode = "vi";
    mouse = true;

    # true color 対応
    terminal = "tmux-256color";

    extraConfig = ''
      # ───────────────
      # 基本
      # ───────────────
      set -g renumber-windows on
      set -g history-limit 100000
      set -g escape-time 10
      set -g focus-events on

      # Neovim / Ghostty / modern terminal 向け
      set -ga terminal-overrides ",*:RGB"

      # ───────────────
      # ペイン分割
      # ───────────────
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # 新規ウィンドウも現在ディレクトリで開く
      bind c new-window -c "#{pane_current_path}"

      # Vim風ペイン移動
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # ペインサイズ変更
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      # 設定リロード
      bind r source-file ~/.config/tmux/tmux.conf \; display-message "tmux config reloaded"

      # ───────────────
      # コピーモード
      # ───────────────
      setw -g mode-keys vi

      bind-key -T copy-mode-vi v send -X begin-selection
      bind-key -T copy-mode-vi y send -X copy-selection-and-cancel

      # ───────────────
      # 見た目
      # ───────────────
      set -g status on
      set -g status-interval 2
      set -g status-position bottom
      set -g status-style bg=default,fg=white

      set -g status-left "#S "
      set -g status-right "%Y-%m-%d %H:%M"

      setw -g window-status-format " #I:#W "
      setw -g window-status-current-format " #I:#W* "
    '';
  };
}
