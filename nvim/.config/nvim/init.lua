local opt = vim.opt
local map = vim.keymap.set
local autocmd = vim.api.nvim_create_autocmd

-- Mason bin on PATH so nvim-lint/conform can find mason-installed tools
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH

-- =============================================================================
--   OPTIONS
-- =============================================================================

vim.g.mapleader = " "
vim.g.maplocalleader = " "
opt.background = "dark"              -- force dark mode (container doesn't advertise)

-- Tabs & indentation
opt.tabstop = 4             -- visual width of a TAB character
opt.softtabstop = 4         -- spaces inserted when pressing Tab
opt.shiftwidth = 4          -- spaces used for auto-indent
opt.expandtab = true        -- convert tabs to spaces (mainly for Python)

-- Line numbers
opt.number = true           -- show absolute line number on current line
opt.relativenumber = true   -- relative numbers on all other lines

-- UI
opt.mouse = "a"             -- a necessary evil
opt.errorbells = false
opt.splitbelow = true       -- new horizontal splits open below
opt.splitright = true       -- new vertical splits open right
opt.linebreak = true        -- wrap long lines at word boundaries, not mid-word
opt.breakindent = true      -- wrapped lines preserve their indentation
opt.smoothscroll = true     -- scroll by screen line, not text line (nvim 0.10)
opt.scrolloff = 12          -- keep cursor roughly centered on screen
opt.inccommand = "split"    -- live preview of :s substitutions in a split
opt.updatetime = 100        -- faster CursorHold events (some plugins need this)
opt.timeoutlen = 400        -- ms to wait for key sequence completion (default 1000 is sluggish)
opt.showmode = false        -- redundant once we have a statusline
opt.signcolumn = "yes"      -- always show sign column (avoids layout shift)
opt.confirm = true          -- ask to save on :q instead of erroring
opt.pumheight = 10          -- limit completion popup to 10 items
opt.virtualedit = "block"   -- allow cursor past end of line in visual block
opt.fillchars = { eob = " " } -- hide ~ tildes on empty lines
-- Hidden character display (toggle with <Leader>,)
opt.listchars = { tab = "» ", nbsp = "␣", extends = "»", precedes = "«", trail = "·" }
opt.shortmess:append("I")  -- suppress intro message on startup
opt.isfname:remove({ "=" }) -- don't treat = as part of filenames (better gf)

-- Searching
opt.ignorecase = true       -- case-insensitive by default
opt.smartcase = true        -- ...unless an uppercase letter is typed
opt.grepprg = "rg --vimgrep" -- use ripgrep for :grep (fast, respects .gitignore)
opt.grepformat = "%f:%l:%c:%m"
opt.wildmode = "list:longest" -- list all matches, complete to longest common prefix
opt.wildignore:append({ "*/.git/*", "*/tmp/*", "*.swp" })

-- Diff: smarter algorithm, ignore whitespace, better hunk boundaries
-- (improves nvim -d, gitsigns, diffview output)
opt.diffopt:append("iwhite")              -- ignore whitespace changes
opt.diffopt:append("algorithm:histogram") -- smarter than default Myers
opt.diffopt:append("indent-heuristic")    -- align hunks to indentation

-- Undo
opt.undofile = true         -- persist undo history across sessions

-- Folding
opt.foldenable = true       -- enable folding
opt.foldlevelstart = 99     -- start with all folds open
opt.foldnestmax = 10        -- 10 nested folds max
opt.foldmethod = "indent"   -- fold based on indent level (great for Python)

-- Custom filetype detection
vim.filetype.add({ pattern = { [".*%.yml%.j2"] = "yaml" } })

-- OSC52 clipboard for SSH/remote (neovim 0.10+)
vim.g.clipboard = {
    name = "OSC 52",
    copy = {
        ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
        ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
    },
    paste = {
        ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
        ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
    },
}

local augroup = vim.api.nvim_create_augroup("config", { clear = true })

-- =============================================================================
--   KEYMAPS
-- =============================================================================

-- Disable Q (ex mode) and unbind C-a/C-x for tmux
map("n", "Q", "<Nop>")
map("", "<C-a>", "<Nop>")
map("", "<C-x>", "<Nop>")

-- Move vertically by visual line
map("n", "j", "gj")
map("n", "k", "gk")

-- Jump to start and end of line using home row
map("", "H", "^")
map("", "L", "$")

-- Move lines up/down with J/K
map("n", "J", ":move+<CR>==", { silent = true })
map("n", "K", ":move-2<CR>==", { silent = true })
map("x", "J", ":move'>+<CR>gv=gv", { silent = true })
map("x", "K", ":move-2<CR>gv=gv", { silent = true })

-- Tab/S-Tab indent in visual mode
map("v", "<Tab>", ">gv")
map("v", "<S-Tab>", "<gv")

-- After jumps/searches, position cursor ~25% from top (more context below than above)
-- Exposed as global for use in plugin configs
function _G.quarter_top()
    local offset = math.floor(vim.api.nvim_win_get_height(0) * 0.25)
    vim.cmd("normal! zt")
    if offset > 0 then
        local keys = vim.api.nvim_replace_termcodes(offset .. "<C-y>", true, false, true)
        vim.api.nvim_feedkeys(keys, "nx", false)
    end
end
map("n", "n", function() vim.cmd("normal! n") quarter_top() end, { silent = true })
map("n", "N", function() vim.cmd("normal! N") quarter_top() end, { silent = true })
map("n", "*", function() vim.cmd("normal! *") quarter_top() end, { silent = true })
map("n", "#", function() vim.cmd("normal! #") quarter_top() end, { silent = true })
map("n", "g*", function() vim.cmd("normal! g*") quarter_top() end, { silent = true })
map("n", "<C-o>", function()
    vim.cmd("execute \"normal! \\<C-o>\"")
    quarter_top()
end)
map("n", "<C-i>", function()
    local keys = vim.api.nvim_replace_termcodes("<C-i>", true, false, true)
    vim.api.nvim_feedkeys(keys, "nx", false)
    quarter_top()
end)

-- Position after / and ? searches too
autocmd("CmdlineLeave", {
    group = augroup,
    pattern = { "/", "?" },
    callback = function()
        vim.schedule(quarter_top)
    end,
})

-- Clear search highlight
map("n", "<Esc>", ":nohlsearch<CR>", { silent = true })

-- Very-magic mode: PCRE-like regex (less escaping for (, +, {, etc.)
map("n", "/", "/\\v")
map("n", "?", "?\\v")
map("c", "%s/", "%s/\\v")

-- Disable arrow keys (hard mode); left/right switch buffers in normal mode
for _, mode in ipairs({ "i", "v" }) do
    map(mode, "<Up>", "<Nop>")
    map(mode, "<Down>", "<Nop>")
    map(mode, "<Left>", "<Nop>")
    map(mode, "<Right>", "<Nop>")
end
map("n", "<Up>", "<Nop>")
map("n", "<Down>", "<Nop>")
map("n", "<Left>", ":bp<CR>", { silent = true })
map("n", "<Right>", ":bn<CR>", { silent = true })

-- Toggle between buffers
map("n", "<Leader><Leader>", "<C-^>")

-- Splits
map("n", "<Leader>-", ":sp<CR>", { silent = true })
map("n", "<Leader>|", ":vsp<CR>", { silent = true })

-- Quick save/quit
map("n", "<Leader>w", ":w<CR>")
map("n", "<Leader>q", ":q<CR>")
map("n", "<Leader>wq", ":wq<CR>")
map("n", "<Leader>Q", ":q!<CR>")

-- Open new file in current file's directory (quick sibling file creation)
map("n", "<Leader>O", ':e <C-R>=expand("%:p:h") . "/" <CR>', { desc = "Open adjacent file" })

-- System clipboard
map({ "n", "v" }, "<Leader>y", '"+y')
map({ "n", "v" }, "<Leader>d", '"+d')
map({ "n", "v" }, "<Leader>p", '"+p')
map({ "n", "v" }, "<Leader>P", '"+P')

-- Highlight last inserted text
map("n", "gV", "`[v`]")

-- Paste over selection without clobbering register
map("v", "p", '"_dP')

-- Toggles (leader+o prefix)
map("n", "<Leader>,", ":set invlist<CR>", { desc = "Toggle hidden chars", silent = true })
map("n", "<Leader>os", ":setlocal spell! spelllang=en_us<CR>", { desc = "Toggle spell check" })
map("n", "<Leader>ol", function()
    if vim.wo.colorcolumn == "" then
        vim.wo.colorcolumn = "88"
    else
        vim.wo.colorcolumn = ""
    end
end, { desc = "Toggle color column" })
map("n", "<Leader>on", function()
    if vim.wo.relativenumber then
        vim.wo.relativenumber = false
        vim.wo.number = true
    else
        vim.wo.relativenumber = true
    end
end, { desc = "Toggle relative numbers" })

-- Pane zoom toggle (opens current split in a new tab, :tabclose to unzoom)
map("n", "<Leader>z", function()
    if vim.fn.tabpagenr("$") > 1 and vim.t.zoomed then
        vim.cmd("tabclose")
    else
        vim.cmd("tab split")
        vim.t.zoomed = true
    end
end, { desc = "Toggle pane zoom" })

-- Execute macro over visual range
map("x", "@", function()
    return ":'<,'>normal @" .. vim.fn.nr2char(vim.fn.getchar()) .. "<CR>"
end, { expr = true })

-- =============================================================================
--   AUTOCOMMANDS
-- =============================================================================

-- Cursorline only in active window (visual cue for focused split)
autocmd({ "VimEnter", "WinEnter", "BufWinEnter" }, {
    group = augroup,
    callback = function() vim.wo.cursorline = true end,
})
autocmd("WinLeave", {
    group = augroup,
    callback = function() vim.wo.cursorline = false end,
})

-- Jump to last edit position on opening file
autocmd("BufReadPost", {
    group = augroup,
    callback = function(args)
        local buf = args.buf
        if vim.bo[buf].filetype == "gitcommit" or vim.b[buf].last_pos_set then
            return
        end
        vim.b[buf].last_pos_set = true
        local mark = vim.api.nvim_buf_get_mark(buf, '"')
        local lcount = vim.api.nvim_buf_line_count(buf)
        if mark[1] > 0 and mark[1] <= lcount then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})

-- Highlight on yank
autocmd("TextYankPost", {
    group = augroup,
    callback = function()
        vim.hl.on_yank({ timeout = 200 })
    end,
})

-- Prevent accidental writes to backup files
autocmd("BufRead", {
    group = augroup,
    pattern = { "*.orig", "*.bk" },
    callback = function()
        vim.bo.readonly = true
    end,
})

-- Disable auto-commenting on new lines
autocmd("FileType", {
    group = augroup,
    callback = function()
        vim.schedule(function()
            vim.opt_local.formatoptions:remove({ "o" })
        end)
    end,
})

-- Trim trailing whitespace on save (skip prose-like filetypes where spaces can be meaningful)
autocmd("BufWritePre", {
    group = augroup,
    callback = function()
        local ft = vim.bo.filetype
        if ft == "markdown" or ft == "gitcommit" or ft == "text" or ft == "rst" then
            return
        end
        local view = vim.fn.winsaveview()
        vim.cmd([[keeppatterns %s/\s\+$//e]])
        vim.fn.winrestview(view)
    end,
})

-- Per-filetype indentation
autocmd("FileType", {
    group = augroup,
    pattern = { "yaml", "lua", "javascript", "typescript", "typescriptreact", "javascriptreact" },
    callback = function()
        vim.bo.tabstop = 2
        vim.bo.softtabstop = 2
        vim.bo.shiftwidth = 2
    end,
})
autocmd("FileType", {
    group = augroup,
    pattern = { "go", "make" },
    callback = function()
        vim.bo.expandtab = false
        vim.bo.tabstop = 8
        vim.bo.softtabstop = 8
        vim.bo.shiftwidth = 8
    end,
})

autocmd("FileType", {
    group = augroup,
    pattern = "markdown",
    callback = function()
        vim.wo.spell = true
        vim.bo.spelllang = "en_us"
        vim.bo.textwidth = 72
        vim.wo.colorcolumn = "73"
    end,
})

autocmd("FileType", {
    group = augroup,
    pattern = "gitcommit",
    callback = function()
        vim.wo.spell = true
        vim.bo.spelllang = "en_us"
        vim.bo.textwidth = 72
        vim.wo.colorcolumn = "73"
    end,
})

-- Force dark mode on any colorscheme change (some plugins trigger reloads)
autocmd("ColorScheme", {
    group = augroup,
    callback = function()
        vim.opt.background = "dark"
    end,
})

-- =============================================================================
--   LAZY.NVIM BOOTSTRAP
-- =============================================================================

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
    vim.fn.system({
        "git", "clone", "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", lazypath,
    })
end
opt.rtp:prepend(lazypath)

require("lazy").setup("plugins", {
    defaults = { lazy = true },
    install = { colorscheme = { "monokai-nightasty", "habamax" } },
    rocks = { enabled = false },
    checker = { enabled = false },
    change_detection = { notify = false },
    performance = {
        rtp = {
            disabled_plugins = {
                "gzip", "netrwPlugin", "rplugin",
                "tarPlugin", "tohtml", "tutor", "zipPlugin",
            },
        },
    },
})

-- =============================================================================
--   LOCAL OVERRIDES (optional, not tracked in git)
-- =============================================================================
local local_config = vim.fn.stdpath("config") .. "/local.lua"
if vim.uv.fs_stat(local_config) then
    dofile(local_config)
end
