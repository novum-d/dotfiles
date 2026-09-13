set -eu

# macOS、WSL、Wayland、X11の順に利用可能なクリップボードCLIを選ぶ。
if command -v pbcopy >/dev/null 2>&1; then
  exec pbcopy
fi

if command -v powershell.exe >/dev/null 2>&1; then
  # PowerShellへUTF-8として渡し、日本語を含む標準入力の文字化けを防ぐ。
  exec powershell.exe -NoProfile -Command "[Console]::InputEncoding=[System.Text.UTF8Encoding]::new(); Set-Clipboard -Value ([Console]::In.ReadToEnd())"
fi

if command -v clip.exe >/dev/null 2>&1; then
  exec clip.exe
fi

if command -v wl-copy >/dev/null 2>&1; then
  exec wl-copy
fi

if command -v xclip >/dev/null 2>&1; then
  exec xclip -selection clipboard
fi

if command -v xsel >/dev/null 2>&1; then
  exec xsel --clipboard --input
fi

echo "copy: no clipboard command found" >&2
exit 127
