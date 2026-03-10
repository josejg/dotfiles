# Neovim Config Reference

## Running

```bash
docker compose run --rm nvim
# then inside the container:
nvim
```

## Options

| Setting | Value | Notes |
|---------|-------|-------|
| Tabs | 4 spaces | expandtab |
| Line numbers | Relative | number + relativenumber |
| Scrolloff | 12 | Keeps cursor ~centered |
| Mouse | Enabled | `mouse=a` |
| Splits | Below + Right | splitbelow, splitright |
| Search | Case-insensitive | Unless uppercase typed (smartcase) |
| Search regex | Very-magic (`\v`) | `/` and `?` auto-prepend `\v`; `%s/` auto-prepends `\v` in pattern |
| Wildmenu | list:longest | List all matches, complete to longest common prefix |
| Diff | histogram + iwhite | Smarter algorithm, ignore whitespace, indent heuristic |
| Undo | Persistent | undofile across sessions |
| Folds | Indent-based | All open by default (foldlevelstart=99) |
| Clipboard | OSC52 | Works over SSH |
| Line wrap | linebreak + breakindent | Wraps at words, preserves indent |
| Smooth scroll | smoothscroll | Scrolls by screen line (nvim 0.10) |
| Substitute preview | inccommand=split | Live preview of `:s/foo/bar` |
| Hidden chars | `listchars` configured | Toggle with `Space ,` |
| Cursorline | Active window only | Auto on/off via WinEnter/WinLeave |
| Floating windows | Rounded borders | winborder=rounded |
| Diagnostics | virtual_lines (current line) | Full message under cursor line |

## Keymaps

| Category | Key | Action |
|----------|-----|--------|
| Movement | `H` / `L` | Start / End of line |
| Movement | `j` / `k` | Move by visual line (gj/gk) |
| Movement | `J` / `K` (normal) | Move current line down / up |
| Movement | `J` / `K` (visual) | Move selected block down / up |
| Movement | `n` / `N` / `*` / `#` | Search + 25% from top |
| Movement | `Ctrl-o` / `Ctrl-i` | Jump back/forward + 25% from top |
| Movement | Left / Right (normal) | Previous / Next buffer |
| Movement | Arrow keys (insert/visual) | Disabled |
| Movement | Up / Down (normal) | Disabled |
| Editing | `Tab` / `S-Tab` (visual) | Indent / Dedent selection |
| Editing | `gV` | Select last inserted text |
| Editing | `p` (visual) | Paste without clobbering register |
| Editing | `@` (visual) | Run macro over selected lines |
| Leader | `Space Space` | Toggle last buffer |
| Leader | `Space O` | Open file adjacent to current file |
| Leader | `Space w` / `Space q` | Save / Quit |
| Leader | `Space wq` / `Space Q` | Save+Quit / Force quit |
| Leader | `Space -` / `Space \|` | Horizontal / Vertical split |
| Leader | `Space y` / `Space d` | Yank / Delete to system clipboard |
| Leader | `Space p` / `Space P` | Paste from system clipboard |
| Leader | `Space z` | Toggle pane zoom |
| Toggle | `Space ,` | Hidden characters (tabs, trailing spaces, nbsp) |
| Toggle | `Space os` | Spell check |
| Toggle | `Space ol` | Color column (88) |
| Toggle | `Space on` | Relative numbers |
| Toggle | `Space oh` | Inlay hints |
| Toggle | `Space op` | Pyright diagnostics (off by default) |
| Toggle | `Space of` | Format-on-save |
| Toggle | `Space oa` | Linting |
| LSP (0.11 default) | `grn` | Rename symbol |
| LSP (0.11 default) | `grr` | References |
| LSP (0.11 default) | `gri` | Implementation |
| LSP (0.11 default) | `gra` | Code action |
| LSP (0.11 default) | `gO` | Document symbols |
| LSP (0.11 default) | `Ctrl-S` (insert) | Signature help |
| LSP (0.11 default) | `[d` / `]d` | Prev / Next diagnostic |
| LSP (custom) | `gd` | Go to definition (+ 25% scroll) |
| LSP (custom) | `gD` | Hover docs (K is taken by move-line) |
| LSP (custom) | `Space !` | All diagnostics in location list |
| Picker | `Ctrl-p` | Find files |
| Picker | `Space g` | Live grep |
| Picker | `Space ;` | Buffers |
| Picker (Space f) | `Space ff` / `fr` / `fg` / `fb` | Files / Recent / Grep / Buffers |
| Picker (Space f) | `Space fw` | Grep word under cursor |
| Picker (Space f) | `Space f/` | Search in current buffer |
| Picker (Space f) | `Space fd` / `fs` | Diagnostics / Document symbols |
| Picker (Space f) | `Space fh` / `fk` | Help pages / Keymaps |
| Picker (Space f) | `Space f:` / `fR` | Command history / Resume last |
| Completion | `Tab` / `S-Tab` | Navigate completion menu |
| Completion | `CR` | Confirm selection |
| Completion | `Ctrl-Space` | Trigger completion |
| Completion | `Ctrl-e` | Cancel completion |
| Completion | `Ctrl-d` / `Ctrl-f` | Scroll docs up / down |
| Treesitter | `Ctrl-Space` | Start/expand node selection |
| Treesitter | `BS` | Shrink node selection |
| Text object | `af` / `if` | Around / Inside function |
| Text object | `ac` / `ic` | Around / Inside class |
| Text object | `aa` / `ia` | Around / Inside argument |
| Text object | `ii` / `ai` | Inside / Around indent block |
| Text object | `ih` | Inside git hunk |
| Motion | `]f` / `[f` | Next / Prev function |
| Motion | `]c` / `[c` | Next / Prev class |
| Motion | `]a` / `[a` | Next / Prev argument |
| Motion | `]h` / `[h` | Next / Prev git hunk |
| Motion | `;` / `,` | Repeat last ]x/[x forward / backward |
| Motion | `%` | Jump between matching brackets (built-in) |
| Git (Space h) | `Space hs` | Stage hunk |
| Git (Space h) | `Space hr` | Reset hunk |
| Git (Space h) | `Space hu` | Undo stage hunk |
| Git (Space h) | `Space hp` | Preview hunk |
| Git (Space h) | `Space hd` | Diff against index |
| Git | `Space ob` | Toggle inline blame |
| Git | `Space G` | Open lazygit (floating terminal) |
| Flash | `s` | Sneak-style 2-char jump (labels appear) |
| Flash | `/` or `?` | Search with jump labels (automatic) |
| Surround | `ys{motion}{char}` | Add surround (e.g. `ysiw"`) |
| Surround | `cs{old}{new}` | Change surround (e.g. `cs"'`) |
| Surround | `ds{char}` | Delete surround (e.g. `ds"`) |
| Comment (built-in) | `gcc` / `gc{motion}` | Toggle line / block comment |
| Undo | `Space U` | Toggle undo tree |
| File explorer | `Space e` | Toggle neo-tree sidebar |
| Splits | `Ctrl-h/j/k/l` | Navigate splits (+ tmux/zellij/wezterm panes) |
| Splits | `Ctrl-Left/Down/Up/Right` | Resize splits |
| AI (Copilot) | `Ctrl-y` | Accept suggestion |
| AI (Copilot) | `Ctrl-Right` | Accept word |
| AI (Copilot) | `Ctrl-Down` / `Ctrl-Up` | Next / Prev suggestion |
| AI (Copilot) | `Ctrl-]` | Dismiss suggestion |
| AI (CodeCompanion) | `Space aa` | AI actions palette |
| AI (CodeCompanion) | `Space ac` | Toggle AI chat panel |
| AI (CodeCompanion) | `Space ai` | AI inline edit |
| AI (CodeCompanion) | `ga` (visual) | Add selection to AI chat |
| Harpoon | `Space m` | Mark current file |
| Harpoon | `Space M` | Toggle harpoon menu (reorder/remove) |
| Harpoon | `Space 1-9` | Jump to harpoon file 1-9 |
| Writing | `Space oz` | Toggle zen mode (distraction-free) |
| Trouble | `Space xx` | Toggle all diagnostics |
| Trouble | `Space xX` | Toggle buffer diagnostics |
| Trouble | `Space xl` | Toggle location list |
| Trouble | `Space xq` | Toggle quickfix list |
| Buffer | `Space x` | Close buffer (keep window layout) |
| Terminal | `Ctrl-\` | Toggle floating terminal |
| GitHub | `Space gh` | Open file/line in GitHub |
| GitHub | `Space fi` | Browse GitHub issues |
| GitHub | `Space fp` | Browse GitHub PRs |
| LSP (custom) | `Space cR` | Rename file (updates imports) |
| Other | `Q` | Disabled (was ex mode) |
| Other | `Ctrl-a` / `Ctrl-x` | Disabled (for tmux) |
| Other | `Esc` | Clear search highlight |

## LSP Servers

| Server | Language | Notes |
|--------|----------|-------|
| basedpyright | Python | Completions, go-to-def, hover, types (diagnostics off by default) |
| lua_ls | Lua | Configured with vim global |
| marksman | Markdown | Links, headings, references |
| typos_lsp | All | Typo detection |

## Formatting + Linting (all auto-installed via Mason)

| Tool | Type | Filetypes |
|------|------|-----------|
| ruff format | Formatter | Python |
| ruff check | Linter | Python |
| stylua | Formatter | Lua |
| shfmt | Formatter | sh, bash |
| shellcheck | Linter | sh, bash |
| jq | Formatter | JSON |
| yamllint | Linter | YAML |
| markdownlint-cli2 | Linter | Markdown (requires npm, auto-skipped if missing) |
| checkmake | Linter | Makefile (x86 only, auto-skipped on ARM) |
| actionlint | Linter | GitHub Actions (auto-detected by path) |
| just --fmt | Formatter | Justfile |

## Autocmds

- Reopen file → cursor jumps to last edit position
- Yank → briefly highlights yanked text
- `*.orig` / `*.bk` files open as readonly
- `*.yml.j2` detected as yaml
- Pressing `o` on a comment line does NOT auto-insert comment prefix
- Trailing whitespace trimmed on save (skips markdown, gitcommit, text, rst)
- `/` and `?` searches position at 25% from top
- Cursorline only shown in the active window
- 2-space indentation: YAML, Lua, JavaScript, TypeScript
- Hard tabs (width 8): Go, Makefile
- Markdown: spell check + textwidth=72 + colorcolumn=73
- Gitcommit: spell check + textwidth=72 + colorcolumn=73
- Dark background forced on any colorscheme change
- All autocmds grouped (`config`) — safe to reload without duplication

## Tmux Integration (smart-splits)

Add to `~/.tmux.conf` for seamless Ctrl-h/j/k/l navigation:

```
bind-key -n C-h if -F "#{@pane-is-vim}" 'send-keys C-h' 'select-pane -L'
bind-key -n C-j if -F "#{@pane-is-vim}" 'send-keys C-j' 'select-pane -D'
bind-key -n C-k if -F "#{@pane-is-vim}" 'send-keys C-k' 'select-pane -U'
bind-key -n C-l if -F "#{@pane-is-vim}" 'send-keys C-l' 'select-pane -R'
```

## Local Overrides

Place machine-specific config in `~/.config/nvim/local.lua` (not tracked in git).

## Treesitter Parsers

python, lua, bash, just, dockerfile, markdown, markdown_inline, json, yaml, toml, vim, vimdoc, regex

## Which-Key

Press `Space` and wait 400ms to see all available keymaps. Groups: `Space f` (find), `Space h` (git hunk), `Space o` (toggle), `Space a` (ai), `Space c` (code), `Space x` (trouble).

## Statusline (lualine)

`mode | filepath diff | searchcount diagnostics | filetype | location`

## Performance

- Built-in plugins disabled: gzip, netrw, rplugin, tar, tohtml, tutor, zip
- Snacks `quickfile` renders buffer before lazy plugins load
- Snacks `bigfile` auto-disables treesitter/LSP on large files
- All plugins lazy-loaded by default (explicit triggers via `event`/`keys`/`cmd`/`ft`)

## Useful Commands

| Command | Action |
|---------|--------|
| `:Mason` | Manage LSP servers + tools |
| `:ConformInfo` | Show active formatters for current buffer |
| `:InspectTree` | See AST for current file |
| `:Inspect` | See highlight groups for token under cursor |
| `:checkhealth` | Verify setup |
| `:Noice` | View message history (noice.nvim) |
| `:Trouble` | Open diagnostics panel |
| `:ZenMode` | Toggle distraction-free writing |

## Steps TODO

See PLAN.md for the full checklist.
