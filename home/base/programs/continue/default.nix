# Continue設定
{ ... }:
{
  home.file.".continue/config.yaml".text = ''
    name: Local Config
    version: 0.0.1
    schema: v1

    models:
      - name: Qwen3 Coder 30B
        provider: ollama
        model: qwen3-coder:30b
        apiBase: http://localhost:11434
        defaultCompletionOptions:
          contextLength: 32768
        capabilities:
          - tool_use
        roles:
          - chat
          - edit
          - apply

    context:
      - provider: file
      - provider: currentFile
      - provider: open
      - provider: code
      - provider: codebase
      - provider: repo-map
      - provider: tree
      - provider: search
        params:
          maxResults: 100
      - provider: diff
      - provider: terminal
      - provider: problems
      - provider: url
      - provider: web
        params:
          n: 5
      - provider: os

    rules:
      - Always inspect the relevant project files before answering project-specific questions.
      - Use the codebase, repo-map, tree, file, search, and diff context providers when the task depends on repository contents.
      - Use web or url context when the task depends on current external information, documentation, package behavior, or internet sources.
      - When fetching a URL, use the fetch_url_content tool if it is available. Never call a tool named fetch unless it is explicitly listed in the available tools.
      - When reading local files, use the available ls and read_file tools. Never call a tool named shell unless it is explicitly listed in the available tools.
      - If the available context is insufficient, ask for or retrieve the missing files or web context instead of guessing.

    mcpServers:
      - name: filesystem
        command: /etc/profiles/per-user/novumd/bin/npx
        args:
          - "-y"
          - "@modelcontextprotocol/server-filesystem"
          - /Users/novumd/repos
          # - /Users/novumd/repos/dotfiles/knowledge

      - name: git
        command: /etc/profiles/per-user/novumd/bin/uvx
        args:
          - mcp-server-git
          - --repository
          - /Users/novumd/repos/dotfiles

     # - name: sqlite
     #   command: uvx
     #   args:
     #     - mcp-server-sqlite
     #     - --db-path
     #     - /Users/novumd/.continue/mcp.sqlite

     # mcp-server-fetch exposes a prompt that Continue tries to load at
     # startup without a URL, which produces:
     # [MCP Prompt - failed to load content during startup]
     # - name: fetch
     #   command: /etc/profiles/per-user/novumd/bin/uvx
     #   args:
     #     - mcp-server-fetch
  '';
}
