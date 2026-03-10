# Neovim Config Build Plan

## Incremental Steps

- [x] **Step 1: Foundation** — options, keymaps, autocmds, lazy.nvim bootstrap
- [x] **Step 2: Colorscheme** — monokai-nightasty

- [x] **Step 3: Treesitter**
  - Plugin: nvim-treesitter
  - Parsers: python, lua, markdown, markdown_inline, json, yaml, toml, bash, vim, vimdoc, regex, just, dockerfile
  - Enable: `highlight`, `indent`, `incremental_selection`
  - Keymaps: `Ctrl-Space` start/expand selection, `BS` shrink selection
  - Verify: `:InspectTree` to see AST, `:Inspect` on any token, compare highlighting vs no treesitter
  - Learn: treesitter parses real ASTs, not regex. `:InspectTree` shows you the parse tree.

- [x] **Step 4: LSP + Completion**
  - Plugins: mason.nvim, mason-lspconfig.nvim, nvim-lspconfig, nvim-cmp, cmp-nvim-lsp, cmp-buffer, cmp-path, LuaSnip, cmp_luasnip
  - Servers: basedpyright, lua_ls, marksman, typos_lsp (no npm-dependent servers)
  - Uses neovim 0.11 default keymaps (grn/grr/gri/gra/gO/Ctrl-S) + custom gd, gD
  - basedpyright diagnostics silenced by default (Space op to toggle)
  - virtual_lines on current line, severity_sort, rounded borders, inlay hints toggle
  - Future: consider `lsp_signature.nvim` for persistent signature help while typing

- [x] **Step 5: Formatting + Linting**
  - Plugins: conform.nvim, nvim-lint, mason-tool-installer
  - Formatters: ruff_format (Python), stylua (Lua), shfmt (sh/bash), jq (JSON), just --fmt (Justfile)
  - Linters: ruff (Python), shellcheck (sh/bash), yamllint (YAML), markdownlint-cli2 (Markdown), checkmake (Makefile), actionlint (GitHub Actions, auto-detected by path)
  - All tools auto-installed via Mason
  - Keymaps: `Space of` toggle format-on-save, `Space oa` toggle linting

- [x] **Step 6: Picker (snacks.nvim)**
  - Plugin: snacks.nvim (by Folke, lazy.nvim author — replaces telescope)
  - Personal shortcuts: `Ctrl-p`/`Space e` files, `Space g` grep, `Space ;` buffers
  - Full `Space f` prefix: ff files, fr recent, fg grep, fw grep word, fb buffers, f/ buffer lines, fd diagnostics, fs symbols, fh help, fk keymaps, f: command history, fR resume
  - Also replaces vim.ui.select, excludes venv/__pycache__/node_modules from file picker

- [x] **Step 7: Git (gitsigns)**
  - Plugin: gitsigns.nvim
  - Hunk nav: `]h`/`[h` (not `]c`/`[c` — those are class navigation)
  - Actions: `Space h` prefix — hs stage, hr reset, hu undo stage, hp preview, hd diff
  - Toggle: `Space ob` inline blame
  - Text object: `ih` (inside hunk)
  - Also added: treesitter textobjects, repeatable moves (;/,), vim-matchup (%), mini.indentscope (ii/ai)

- [x] **Step 8: Flash + Statusline**
  - Plugins: flash.nvim, lualine.nvim
  - flash.nvim: augments `/` and `?` with jump labels automatically, `s` for sneak-style 2-char jump
  - lualine.nvim: mode | filepath + diff | searchcount + diagnostics | filetype | location
  - Verify: type `/foo`, see labels appear on matches, press label to jump. `s` + 2 chars for sneak.
  - Learn: flash enhances your existing search with labels. No new muscle memory needed — your `/` search just gets superpowers. Replaces easymotion + sneak + hop + incsearch.

- [x] **Step 9: Text editing**
  - Plugin: nvim-surround (others skipped — neovim 0.10 has built-in gc/gcc commenting, autopairs skipped by preference, vim-repeat not needed)
  - nvim-surround: `ys{motion}{char}` add, `cs{old}{new}` change, `ds{char}` delete
  - Verify: `ysiw"` to surround word with quotes, `cs"'` to change quotes, `ds"` to remove them

- [x] **Step 10: UI polish**
  - Plugins: which-key.nvim, lazydev.nvim, todo-comments.nvim, rainbow-delimiters.nvim
  - which-key: press `Space` and wait, see all available keymaps (replaces vim-which-key)
  - lazydev: full neovim API completions for lua_ls when editing config
  - todo-comments: highlight TODO/FIXME/HACK/NOTE in code
  - rainbow-delimiters: colored matching brackets via treesitter
  - Skipped: indent-blankline (mini.indentscope sufficient), dressing (snacks handles vim.ui.select)
  - lualine + undotree already added in earlier steps

- [x] **Step 11: File management + Tmux**
  - Plugins: neo-tree.nvim, smart-splits.nvim, mini.cursorword, hardtime.nvim, snacks dashboard
  - neo-tree: `Space e` toggles file sidebar, follows current file, hides __pycache__/venv
  - smart-splits: `Ctrl-h/j/k/l` navigate splits + tmux/zellij panes, `Ctrl-arrows` resize
  - mini.cursorword: auto-highlights all instances of word under cursor
  - hardtime: blocks repeated hjkl, suggests better motions
  - snacks dashboard: start screen with recent files + quick actions

- [x] **Step 12: AI**
  - Plugins: copilot.lua (autocomplete), codecompanion.nvim (chat + inline edits)
  - copilot.lua: ghost text suggestions, gated behind `node` availability, Alt-l to accept
  - codecompanion: `Space aa` actions, `Space ac` chat, `Space ai` inline, `ga` (visual) add to chat
  - Default adapter: anthropic (Claude), requires `ANTHROPIC_API_KEY` env var
  - Verify: open a Python file, see copilot ghost text. `Space ac` to open chat, ask about code.

- [x] **Step 13: Writing + UI extras**
  - zen-mode.nvim + twilight.nvim: `Space oz` toggles distraction-free writing
  - trouble.nvim: `Space xx/xX/xl/xq` for better diagnostics/quickfix UI
  - noice.nvim: commented out (polarizing), uncomment to try fancy cmdline/messages

## Process per step
1. Add plugin(s) to `lua/plugins/init.lua`
2. Test in Docker: `docker compose run --rm nvim`
3. Verify with `:checkhealth`, try keybindings
4. Update REFERENCE.md
5. Check off here, move to next

## Revisit later
- persistence.nvim (session restore — reopen nvim and get buffers back)
- trouble.nvim — installed, `Space x` prefix
- noice.nvim — installed but commented out, uncomment to try
- bufferline.nvim (tab bar with icons)
- mini.pairs (auto-close brackets — skipped by preference, reconsider if missed)

## Deliberately skipped from old config
- vim-easy-align (never used)
- vim-argwrap (never used)
- tabular (never used)
- vim-unimpaired (]q/[q — rarely needed)
- vim-startify (no start screen needed)
- vim-fugitive (lazygit replaces it)
- vim-repeat (nvim-surround has built-in dot-repeat)
- nvim-autopairs (skipped by preference)
- Comment.nvim (neovim 0.10 built-in gc/gcc)
- Tab navigation Leader+1-9 (using buffers instead)
- JSON pretty-print keymap (jq via conform handles it)
- vim-eunuch (oil/neo-tree + native commands cover it)
- vim-bbye, vim-symlink, vim-signature, tagbar/vista (not needed)

## Decisions made
- No node/npm — dropped npm-dependent LSP servers (jsonls, yamlls, bashls) for simplicity
- Neovim 0.11.6 in Docker (Ubuntu 24.04 ships 0.7.x, too old)
- Plugin data persisted via `nvim-data` Docker volume
- Single `init.lua` + `lua/plugins/init.lua` (no file sprawl)
- `linebreak` wraps at word boundaries; `breakindent` keeps indent on wrapped lines
- snacks.nvim picker over telescope (by Folke, zero deps, future LazyVim default)
- basedpyright diagnostics disabled at server level (typeCheckingMode=off), not namespace filtering
- Architecture-gated Mason tools (markdownlint-cli2 needs npm, checkmake needs x86)
