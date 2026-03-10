local picker_exclude = { "venv", ".venv", "__pycache__", "node_modules", ".git" }

return {
    -- =========================================================================
    --   COLORSCHEME
    -- =========================================================================
    {
        "polirritmico/monokai-nightasty.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("monokai-nightasty").setup({
                dark_style_background = "default",
            })
            vim.cmd.colorscheme("monokai-nightasty")
        end,
    },
    -- =========================================================================
    --   TREESITTER — syntax highlighting via real parsing, not regex
    -- =========================================================================
    {
        "nvim-treesitter/nvim-treesitter",
        -- TODO: switch to branch="main" after upgrading to nvim 0.12+
        -- main branch drops ensure_installed/highlight/indent/incremental_selection
        -- and uses vim.treesitter.start() + FileType autocmds instead
        branch = "master", -- pin to legacy branch (main requires nvim 0.12+)
        build = ":TSUpdate",
        lazy = false,      -- treesitter does not support lazy-loading
        config = function()
            require("nvim-treesitter.configs").setup({
                ensure_installed = {
                    "python", "lua", "bash", "just", "dockerfile",
                    "markdown", "markdown_inline",
                    "json", "yaml", "toml",
                    "vim", "vimdoc", "regex",
                },
                auto_install = true,
                highlight = { enable = true },
                indent = { enable = true },
                incremental_selection = {
                    enable = true,
                    keymaps = {
                        init_selection = "<C-space>",  -- start selecting AST node
                        node_incremental = "<C-space>", -- expand to parent node
                        node_decremental = "<BS>",      -- shrink selection
                    },
                },
            })
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter-textobjects",
        branch = "main",
        lazy = false,
        dependencies = { "nvim-treesitter" },
        config = function()
            require("nvim-treesitter-textobjects").setup({
                select = {
                    lookahead = true, -- jump forward to matching text object
                },
                move = {
                    set_jumps = true, -- add to jumplist
                },
            })

            local map = vim.keymap.set
            -- Text objects: af/if (function), ac/ic (class), aa/ia (argument)
            map({ "x", "o" }, "af", function() require("nvim-treesitter-textobjects.select").select_textobject("@function.outer") end, { desc = "Around function" })
            map({ "x", "o" }, "if", function() require("nvim-treesitter-textobjects.select").select_textobject("@function.inner") end, { desc = "Inside function" })
            map({ "x", "o" }, "ac", function() require("nvim-treesitter-textobjects.select").select_textobject("@class.outer") end, { desc = "Around class" })
            map({ "x", "o" }, "ic", function() require("nvim-treesitter-textobjects.select").select_textobject("@class.inner") end, { desc = "Inside class" })
            map({ "x", "o" }, "aa", function() require("nvim-treesitter-textobjects.select").select_textobject("@parameter.outer") end, { desc = "Around argument" })
            map({ "x", "o" }, "ia", function() require("nvim-treesitter-textobjects.select").select_textobject("@parameter.inner") end, { desc = "Inside argument" })

            -- Motions: ]f/[f (function), ]c/[c (class), ]a/[a (argument)
            -- Made repeatable with ;/, via repeatable_move
            local move = require("nvim-treesitter-textobjects.move")
            local rep = require("nvim-treesitter-textobjects.repeatable_move")

            map({ "n", "x", "o" }, "]f", function() move.goto_next_start("@function.outer") end, { desc = "Next function" })
            map({ "n", "x", "o" }, "[f", function() move.goto_previous_start("@function.outer") end, { desc = "Prev function" })
            map({ "n", "x", "o" }, "]C", function() move.goto_next_start("@class.outer") end, { desc = "Next class" })
            map({ "n", "x", "o" }, "[C", function() move.goto_previous_start("@class.outer") end, { desc = "Prev class" })
            map({ "n", "x", "o" }, "]a", function() move.goto_next_start("@parameter.inner") end, { desc = "Next argument" })
            map({ "n", "x", "o" }, "[a", function() move.goto_previous_start("@parameter.inner") end, { desc = "Prev argument" })

            -- ; and , repeat the last ]x/[x motion AND f/t/F/T
            map({ "n", "x", "o" }, ";", rep.repeat_last_move_next)
            map({ "n", "x", "o" }, ",", rep.repeat_last_move_previous)
            map({ "n", "x", "o" }, "f", rep.builtin_f_expr, { expr = true })
            map({ "n", "x", "o" }, "F", rep.builtin_F_expr, { expr = true })
            map({ "n", "x", "o" }, "t", rep.builtin_t_expr, { expr = true })
            map({ "n", "x", "o" }, "T", rep.builtin_T_expr, { expr = true })
        end,
    },

    -- =========================================================================
    --   TREESITTER CONTEXT — pin function/class header at top of screen
    -- =========================================================================
    {
        "nvim-treesitter/nvim-treesitter-context",
        event = "VeryLazy",
        opts = {
            max_lines = 3,        -- show at most 3 context lines
            min_window_height = 20, -- disable in short windows
        },
        keys = {
            { "<Leader>oc", "<cmd>TSContextToggle<CR>", desc = "Toggle treesitter context" },
            { "[o", function() require("treesitter-context").go_to_context() end, desc = "Jump to context" },
        },
    },

    -- =========================================================================
    --   INDENT TEXT OBJECT — ii/ai for indentation blocks (great for Python)
    -- =========================================================================
    {
        "echasnovski/mini.indentscope",
        event = "VeryLazy",
        opts = {
            symbol = "│",
            options = { try_as_border = true },
        },
    },

    -- =========================================================================
    --   FLASH — jump labels on search, sneak-style 2-char jump, treesitter select
    --   Replaces easymotion + vim-sneak + hop
    -- =========================================================================
    {
        "folke/flash.nvim",
        event = "VeryLazy",
        opts = {
            modes = {
                search = { enabled = true },  -- add labels to / and ? searches
                char = { enabled = false },   -- don't override f/t/F/T (keep default)
            },
        },
        keys = {
            { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash jump" },
        },
    },

    -- =========================================================================
    --   STATUSLINE — minimal, like lightline (replaces lightline)
    -- =========================================================================
    {
        "nvim-lualine/lualine.nvim",
        event = "UIEnter",
        opts = {
            options = {
                theme = "auto",
                section_separators = "",
                component_separators = "|",
            },
            sections = {
                lualine_a = { "mode" },
                lualine_b = {},
                lualine_c = { { "filename", path = 1 }, "diff" },
                lualine_x = { "searchcount", "diagnostics" },
                lualine_y = { "filetype" },
                lualine_z = { "location" },
            },
            inactive_sections = {
                lualine_c = { { "filename", path = 1 } },
                lualine_x = { "location" },
            },
        },
    },

    -- =========================================================================
    --   UNDO TREE — visual undo history (replaces vim-mundo)
    -- =========================================================================
    {
        "mbbill/undotree",
        keys = {
            { "<Leader>U", vim.cmd.UndotreeToggle, desc = "Toggle undo tree" },
        },
    },

    -- =========================================================================
    --   GIT — gutter signs, hunk navigation, blame, stage/undo
    -- =========================================================================
    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPost", "BufNewFile" },
        opts = {
            on_attach = function(bufnr)
                local gs = require("gitsigns")
                local map = function(mode, keys, func, desc)
                    vim.keymap.set(mode, keys, func, { buffer = bufnr, desc = desc })
                end

                -- Hunk navigation (]h/[h for hunks, ]c/[c reserved for diff mode)
                vim.keymap.set("n", "]h", function()
                    if vim.wo.diff then return "]c" end
                    vim.schedule(function() gs.nav_hunk("next") end)
                    return "<Ignore>"
                end, { buffer = bufnr, expr = true, desc = "Next hunk" })
                vim.keymap.set("n", "[h", function()
                    if vim.wo.diff then return "[c" end
                    vim.schedule(function() gs.nav_hunk("prev") end)
                    return "<Ignore>"
                end, { buffer = bufnr, expr = true, desc = "Prev hunk" })

                -- Actions
                map("n", "<Leader>hs", gs.stage_hunk, "Stage hunk")
                map("n", "<Leader>hr", gs.reset_hunk, "Reset hunk")
                map("v", "<Leader>hs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Stage selection")
                map("v", "<Leader>hr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Reset selection")
                map("n", "<Leader>hu", gs.undo_stage_hunk, "Undo stage hunk")
                map("n", "<Leader>hp", gs.preview_hunk, "Preview hunk")
                map("n", "<Leader>hd", gs.diffthis, "Diff against index")

                -- Toggle blame
                map("n", "<Leader>ob", gs.toggle_current_line_blame, "Toggle git blame")

                -- Hunk text object (e.g., vih = select inside hunk)
                map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Inside hunk")
            end,
        },
    },

    -- =========================================================================
    --   DIFFVIEW — tabpage diff UI for multi-file diffs and merge conflicts
    -- =========================================================================
    {
        "sindrets/diffview.nvim",
        cmd = { "DiffviewOpen", "DiffviewFileHistory" },
        keys = {
            { "<Leader>hD", "<cmd>DiffviewOpen<CR>", desc = "Diff against index (all files)" },
            { "<Leader>hf", "<cmd>DiffviewFileHistory %<CR>", desc = "File history (current)" },
            { "<Leader>hF", "<cmd>DiffviewFileHistory<CR>", desc = "File history (repo)" },
        },
        opts = {
            enhanced_diff_hl = true,
        },
    },

    -- =========================================================================
    --   LSP — language servers for navigation, completions, diagnostics
    -- =========================================================================
    {
        "mason-org/mason.nvim",
        cmd = { "Mason", "MasonInstall" },
        build = ":MasonUpdate",
        opts = {},
    },
    {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        event = "VeryLazy",
        dependencies = { "mason.nvim" },
        opts = function()
            local tools = {
                "ruff",              -- Python linter + formatter
                "stylua",            -- Lua formatter
                "shellcheck",        -- Shell linter
                "shfmt",             -- Shell formatter
                "actionlint",        -- GitHub Actions workflow linter
                "yamllint",          -- YAML linter
                "jq",                -- JSON formatter
            }
            -- These need npm or lack ARM64 binaries
            local has_npm = vim.fn.executable("npm") == 1
            local is_x86 = vim.uv.os_uname().machine:match("x86_64")
            if has_npm then table.insert(tools, "markdownlint-cli2") end
            if is_x86 then table.insert(tools, "checkmake") end
            return { ensure_installed = tools }
        end,
    },
    {
        "mason-org/mason-lspconfig.nvim",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = { "mason.nvim", "neovim/nvim-lspconfig" },
        opts = {
            ensure_installed = {
                "basedpyright",  -- Python LSP (completions, go-to-def, hover, types)
                "lua_ls",        -- Lua
                "marksman",      -- Markdown (links, headings, references)
                "typos_lsp",     -- Typo detection across all filetypes
            },
            automatic_enable = true, -- auto-start servers for matching filetypes
        },
    },
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            -- basedpyright: disable diagnostics by default (ruff handles linting)
            -- Toggle with <Space>op which changes typeCheckingMode at runtime
            vim.lsp.config("basedpyright", {
                settings = {
                    basedpyright = {
                        analysis = {
                            typeCheckingMode = vim.g.pyright_diagnostics and "standard" or "off",
                        },
                    },
                },
            })

            -- Lua LSP: lazydev handles vim global + workspace, just disable telemetry
            vim.lsp.config("lua_ls", {
                settings = {
                    Lua = {
                        telemetry = { enable = false },
                    },
                },
            })

            -- Diagnostic display
            vim.diagnostic.config({
                virtual_lines = { current_line = true }, -- show full diagnostic under cursor line
                severity_sort = true,                    -- errors above warnings when stacked
                float = { border = "rounded" },          -- rounded borders on diagnostic floats
                -- TODO: uncomment nerd font signs when confirmed working in container
                -- signs = {
                --     text = {
                --         [vim.diagnostic.severity.ERROR] = "",
                --         [vim.diagnostic.severity.WARN]  = "",
                --         [vim.diagnostic.severity.INFO]  = "",
                --         [vim.diagnostic.severity.HINT]  = "󰌵",
                --     },
                -- },
            })

            -- Rounded borders on all floating windows (hover, signature help, etc.)
            vim.o.winborder = "rounded"

            -- Keymaps applied when any LSP server attaches to a buffer
            -- Neovim 0.11 defaults: grn=rename, grr=references, gri=implementation,
            --   gra=code action, gO=document symbols, Ctrl-S=signature help, [d/]d=diagnostics
            -- We only add keymaps that aren't covered by defaults:
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("lsp_keymaps", { clear = true }),
                callback = function(args)
                    local map = function(keys, func, desc)
                        vim.keymap.set("n", keys, func, { buffer = args.buf, desc = desc })
                    end
                    map("gd", function()
                        vim.lsp.buf.definition({
                            on_list = function(options)
                                vim.fn.setqflist({}, " ", options)
                                vim.cmd("cfirst")
                                quarter_top()
                            end,
                        })
                    end, "Go to definition")
                    map("gD", vim.lsp.buf.hover, "Hover docs (K is taken by move-line)")
                    map("<Leader>!", vim.diagnostic.setloclist, "All diagnostics in location list")
                    map("<Leader>oh", function()
                        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
                    end, "Toggle inlay hints")

                    -- Toggle basedpyright diagnostics (off by default, ruff handles linting)
                    map("<Leader>op", function()
                        vim.g.pyright_diagnostics = not vim.g.pyright_diagnostics
                        local mode = vim.g.pyright_diagnostics and "standard" or "off"
                        -- Update setting and restart basedpyright
                        for _, c in ipairs(vim.lsp.get_clients({ name = "basedpyright" })) do
                            c.settings = vim.tbl_deep_extend("force", c.settings or {}, {
                                basedpyright = { analysis = { typeCheckingMode = mode } },
                            })
                            c.notify("workspace/didChangeConfiguration", { settings = c.settings })
                        end
                        vim.notify(
                            "Pyright diagnostics: " .. (vim.g.pyright_diagnostics and "ON" or "OFF"),
                            vim.log.levels.INFO
                        )
                    end, "Toggle pyright diagnostics")
                end,
            })
        end,
    },

    -- =========================================================================
    --   COMPLETION — suggestions as you type (blink.cmp)
    -- =========================================================================
    {
        "saghen/blink.cmp",
        version = "1.*",
        event = "InsertEnter",
        config = function(_, opts)
            require("blink.cmp").setup(opts)
            vim.lsp.config("*", {
                capabilities = require("blink.cmp").get_lsp_capabilities(),
            })
        end,
        opts = {
            keymap = {
                preset = "default",
                ["<Tab>"] = { "select_next", "fallback" },
                ["<S-Tab>"] = { "select_prev", "fallback" },
                ["<CR>"] = { "accept", "fallback" },
                ["<C-space>"] = { "show" },
                ["<C-e>"] = { "cancel" },
                ["<C-d>"] = { "scroll_documentation_up" },
                ["<C-f>"] = { "scroll_documentation_down" },
            },
            completion = {
                documentation = { auto_show = true, auto_show_delay_ms = 200 },
            },
            sources = {
                default = { "lsp", "path", "snippets", "buffer" },
            },
            fuzzy = { implementation = "prefer_rust_with_warning" },
        },
    },

    -- =========================================================================
    --   SURROUND — ys/cs/ds for quotes, brackets, tags
    -- =========================================================================
    {
        "kylechui/nvim-surround",
        version = "2.*",
        event = "VeryLazy",
        opts = {},
    },

    -- =========================================================================
    --   FORMATTING — auto-format on save
    -- =========================================================================
    {
        "stevearc/conform.nvim",
        event = "BufWritePre",
        cmd = "ConformInfo",
        dependencies = { "mason.nvim" },
        config = function()
            require("conform").setup({
                formatters_by_ft = {
                    python = { "ruff_format" },
                    lua = { "stylua" },
                    sh = { "shfmt" },
                    bash = { "shfmt" },
                    json = { "jq" },
                    just = { "just_fmt" },
                },
                formatters = {
                    just_fmt = {
                        command = "just",
                        args = { "--fmt", "--unstable", "-f", "$FILENAME" },
                        stdin = false,
                    },
                },
                format_on_save = function()
                    if vim.g.disable_autoformat then return end
                    return { timeout_ms = 3000, lsp_format = "fallback" }
                end,
            })

            vim.keymap.set("n", "<Leader>of", function()
                vim.g.disable_autoformat = not vim.g.disable_autoformat
                vim.notify(
                    "Format-on-save: " .. (vim.g.disable_autoformat and "OFF" or "ON"),
                    vim.log.levels.INFO
                )
            end, { desc = "Toggle format-on-save" })
        end,
    },

    -- =========================================================================
    --   LINTING — diagnostics from external linters
    -- =========================================================================
    {
        "mfussenegger/nvim-lint",
        event = { "BufReadPre", "BufNewFile" }, -- load before read/new buffer lint events
        dependencies = { "mason.nvim" },
        config = function()
            local lint = require("lint")
            lint.linters_by_ft = {
                python = { "ruff" },
                sh = { "shellcheck" },
                bash = { "shellcheck" },
                yaml = { "yamllint" },
            }
            -- Conditionally add linters that need npm or x86
            if vim.fn.executable("markdownlint-cli2") == 1 then
                lint.linters_by_ft.markdown = { "markdownlint-cli2" }
            end
            if vim.fn.executable("checkmake") == 1 then
                lint.linters_by_ft.make = { "checkmake" }
            end

            -- Run linters on these events
            vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
                group = vim.api.nvim_create_augroup("lint_on_save", { clear = true }),
                callback = function()
                    if vim.g.disable_lint then return end
                    lint.try_lint()
                    -- actionlint only for GitHub Actions workflows
                    local path = vim.fn.expand("%:p")
                    if path:match("%.github/workflows/") then
                        lint.try_lint("actionlint")
                    end
                end,
            })

            vim.keymap.set("n", "<Leader>oa", function()
                vim.g.disable_lint = not vim.g.disable_lint
                if vim.g.disable_lint then
                    -- Clear only nvim-lint diagnostics (preserve LSP diagnostics)
                    local seen = {}
                    for _, linters in pairs(lint.linters_by_ft) do
                        for _, linter_name in ipairs(linters) do
                            if not seen[linter_name] then
                                seen[linter_name] = true
                                vim.diagnostic.reset(lint.get_namespace(linter_name))
                            end
                        end
                    end
                else
                    lint.try_lint()
                end
                vim.notify(
                    "Linting: " .. (vim.g.disable_lint and "OFF" or "ON"),
                    vim.log.levels.INFO
                )
            end, { desc = "Toggle linting" })
        end,
    },

    -- =========================================================================
    --   PICKER — fuzzy find files, grep, buffers, diagnostics, LSP symbols
    -- =========================================================================
    {
        "folke/snacks.nvim",
        lazy = false,
        priority = 1000,
        opts = {
            bigfile = { enabled = true },
            lazygit = { enabled = true },
            gh = { enabled = true },
            quickfile = { enabled = true },
            input = { enabled = true },
            words = { enabled = true },
            terminal = { enabled = true },
            dashboard = {
                enabled = true,
                preset = {
                    header = "", -- no ASCII art
                    keys = {}, -- no action buttons
                },
                sections = {
                    { section = "header" },
                    { section = "recent_files", limit = 10, padding = 1 },
                    { section = "startup" },
                },
            },
            picker = {
                ui_select = true, -- replace vim.ui.select with snacks picker
                win = {
                    input = {
                        keys = {
                            ["<Esc>"] = { "close", mode = "n" },
                        },
                    },
                },
                sources = {
                    files = { exclude = picker_exclude },
                    grep = { exclude = picker_exclude },
                    gh_issue = {},
                    gh_pr = {},
                },
            },
        },
        config = function(_, opts)
            require("snacks").setup(opts)
            local map = vim.keymap.set
            -- Personal shortcuts (muscle memory)
            map("n", "<C-p>",      function() Snacks.picker.files() end,              { desc = "Find files" })
            map("n", "<Leader>g",   function() Snacks.picker.grep() end,               { desc = "Live grep" })
            map("n", "<Leader>;",   function() Snacks.picker.buffers() end,            { desc = "Buffers" })
            -- Find (Space f prefix)
            map("n", "<Leader>ff",  function() Snacks.picker.files() end,              { desc = "Files" })
            map("n", "<Leader>fr",  function() Snacks.picker.recent() end,             { desc = "Recent files" })
            map("n", "<Leader>fg",  function() Snacks.picker.grep() end,               { desc = "Grep" })
            map({ "n", "x" }, "<Leader>fw",  function() Snacks.picker.grep_word() end, { desc = "Grep word under cursor" })
            map("n", "<Leader>fb",  function() Snacks.picker.buffers() end,            { desc = "Buffers" })
            map("n", "<Leader>f/",  function() Snacks.picker.lines() end,              { desc = "Buffer lines" })
            map("n", "<Leader>fd",  function() Snacks.picker.diagnostics() end,        { desc = "Diagnostics" })
            map("n", "<Leader>fs",  function() Snacks.picker.lsp_symbols() end,        { desc = "Document symbols" })
            map("n", "<Leader>fh",  function() Snacks.picker.help() end,               { desc = "Help pages" })
            map("n", "<Leader>fk",  function() Snacks.picker.keymaps() end,            { desc = "Keymaps" })
            map("n", "<Leader>f:",  function() Snacks.picker.command_history() end,     { desc = "Command history" })
            map("n", "<Leader>fR",  function() Snacks.picker.resume() end,             { desc = "Resume last picker" })
            -- GitHub (requires `gh` CLI authenticated)
            map("n", "<Leader>fi",  function() Snacks.picker.gh_issue() end,          { desc = "GitHub issues" })
            map("n", "<Leader>fp",  function() Snacks.picker.gh_pr() end,             { desc = "GitHub PRs" })
            -- Terminal
            map({ "n", "t" }, "<C-\\>", function() Snacks.terminal() end, { desc = "Toggle terminal" })
            -- Buffer management
            map("n", "<Leader>x", function() Snacks.bufdelete() end, { desc = "Close buffer" })
            -- Git browse
            map("n", "<Leader>gh", function() Snacks.gitbrowse() end, { desc = "Open in GitHub" })
            -- LSP file rename
            map("n", "<Leader>cR", function() Snacks.rename.rename_file() end, { desc = "Rename file" })
            -- Git
            map("n", "<Leader>G", function()
                if vim.fn.executable("lazygit") == 1 then
                    Snacks.lazygit()
                else
                    vim.notify("lazygit not installed: https://github.com/jesseduffield/lazygit", vim.log.levels.WARN)
                end
            end, { desc = "Lazygit" })
        end,
    },

    -- =========================================================================
    --   WHICH-KEY — show available keymaps after pressing a prefix
    -- =========================================================================
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {
            delay = 400,
            icons = { mappings = false },
            spec = {
                { "<Leader>a", group = "ai" },
                { "<Leader>f", group = "find" },
                { "<Leader>h", group = "git hunk" },
                { "<Leader>o", group = "toggle" },
                { "<Leader>x", group = "trouble" },
            },
        },
    },

    -- =========================================================================
    --   LAZYDEV — full neovim API completions for lua_ls
    -- =========================================================================
    {
        "folke/lazydev.nvim",
        ft = "lua",
        opts = {},
    },

    -- =========================================================================
    --   TODO COMMENTS — highlight and search TODO/FIXME/HACK/NOTE
    -- =========================================================================
    {
        "folke/todo-comments.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        event = "VeryLazy",
        opts = {},
    },

    -- =========================================================================
    --   RAINBOW DELIMITERS — colored matching brackets via treesitter
    -- =========================================================================
    {
        "HiPhish/rainbow-delimiters.nvim",
        event = "VeryLazy",
    },

    -- =========================================================================
    --   NEO-TREE — toggleable file sidebar
    -- =========================================================================
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
        },
        keys = {
            { "<Leader>e", "<cmd>Neotree toggle<CR>", desc = "Toggle file explorer" },
        },
        opts = {
            filesystem = {
                follow_current_file = { enabled = true },
                filtered_items = {
                    visible = true,
                    hide_dotfiles = false,
                    hide_gitignored = false,
                    hide_by_name = { "__pycache__", ".venv", "venv", "node_modules" },
                },
            },
            window = {
                width = 35,
                mappings = {
                    ["<Space>"] = "none", -- don't steal leader
                },
            },
        },
    },

    -- =========================================================================
    --   SMART SPLITS — navigate + resize splits, works across tmux/zellij/wezterm
    -- =========================================================================
    {
        "mrjones2014/smart-splits.nvim",
        lazy = false, -- needed for tmux integration (@pane-is-vim variable)
        opts = {},
        keys = {
            -- Navigate splits (and tmux panes)
            { "<C-h>", function() require("smart-splits").move_cursor_left() end,  desc = "Move to left split" },
            { "<C-j>", function() require("smart-splits").move_cursor_down() end,  desc = "Move to below split" },
            { "<C-k>", function() require("smart-splits").move_cursor_up() end,    desc = "Move to above split" },
            { "<C-l>", function() require("smart-splits").move_cursor_right() end, desc = "Move to right split" },
            -- Resize splits
            { "<C-Left>",  function() require("smart-splits").resize_left() end,  desc = "Resize left" },
            { "<C-Down>",  function() require("smart-splits").resize_down() end,  desc = "Resize down" },
            { "<C-Up>",    function() require("smart-splits").resize_up() end,    desc = "Resize up" },
            { "<C-Right>", function() require("smart-splits").resize_right() end, desc = "Resize right" },
        },
    },

    -- =========================================================================
    --   CURSORWORD — highlight all instances of word under cursor
    -- =========================================================================
    {
        "echasnovski/mini.cursorword",
        event = "VeryLazy",
        opts = {},
    },

    -- =========================================================================
    --   HARPOON — bookmark files, jump with Leader+1-9
    -- =========================================================================
    {
        "ThePrimeagen/harpoon",
        branch = "harpoon2",
        dependencies = { "nvim-lua/plenary.nvim" },
        keys = (function()
            local keys = {
                { "<Leader>m", function() require("harpoon"):list():add() end, desc = "Harpoon mark file" },
                { "<Leader>M", function() require("harpoon").ui:toggle_quick_menu(require("harpoon"):list()) end, desc = "Harpoon menu" },
            }
            for i = 1, 9 do
                keys[#keys + 1] = { "<Leader>" .. i, function() require("harpoon"):list():select(i) end, desc = "Harpoon file " .. i }
            end
            return keys
        end)(),
        config = function()
            require("harpoon"):setup()
        end,
    },

    -- =========================================================================
    --   HARDTIME — break bad habits, suggest better motions
    --   Uncomment when ready to train better vim motions
    -- =========================================================================
    -- {
    --     "m4xshen/hardtime.nvim",
    --     dependencies = { "MunifTanjim/nui.nvim" },
    --     event = "VeryLazy",
    --     opts = {
    --         max_count = 3, -- block after 3 repeated presses
    --     },
    -- },

    -- =========================================================================
    --   AI: COPILOT — ghost text autocomplete (requires Node.js)
    -- =========================================================================
    {
        "zbirenbaum/copilot.lua",
        cond = function()
            if vim.fn.executable("node") == 0 then
                vim.api.nvim_create_user_command("Copilot", function()
                    vim.notify("Copilot requires Node.js v22+. Install it and restart nvim.", vim.log.levels.WARN)
                end, {})
                return false
            end
            return true
        end,
        cmd = "Copilot",
        event = "InsertEnter",
        opts = {
            suggestion = {
                auto_trigger = true,
                keymap = {
                    accept = "<C-y>",       -- Ctrl-y to accept (like confirm in old completion)
                    accept_word = "<C-Right>", -- Ctrl-Right to accept word
                    next = "<C-Down>",      -- Ctrl-Down next suggestion
                    prev = "<C-Up>",        -- Ctrl-Up prev suggestion
                    dismiss = "<C-]>",      -- Ctrl-] dismiss
                },
            },
            filetypes = {
                markdown = true,
                yaml = true,
            },
        },
    },

    -- =========================================================================
    --   AI: CODECOMPANION — chat + inline edits (multi-provider)
    -- =========================================================================
    {
        "olimorris/codecompanion.nvim",
        version = "^19",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter",
        },
        cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions", "CodeCompanionCmd" },
        keys = {
            { "<Leader>aa", "<cmd>CodeCompanionActions<CR>",      mode = { "n", "v" }, desc = "AI actions" },
            { "<Leader>ac", "<cmd>CodeCompanionChat Toggle<CR>",  mode = { "n", "v" }, desc = "AI chat toggle" },
            { "<Leader>ai", "<cmd>CodeCompanion<CR>",             mode = { "n", "v" }, desc = "AI inline" },
            { "ga",         "<cmd>CodeCompanionChat Add<CR>",     mode = "v",          desc = "Add to AI chat" },
        },
        opts = {
            strategies = {
                chat = { adapter = "anthropic" },
                inline = { adapter = "anthropic" },
                cmd = { adapter = "anthropic" },
            },
            adapters = {
                anthropic = function()
                    return require("codecompanion.adapters").extend("anthropic", {
                        env = { api_key = "ANTHROPIC_API_KEY" },
                    })
                end,
            },
        },
    },

    -- =========================================================================
    --   WRITING: ZEN MODE + TWILIGHT — distraction-free editing
    -- =========================================================================
    {
        "folke/zen-mode.nvim",
        dependencies = { "folke/twilight.nvim" },
        keys = {
            { "<Leader>oz", "<cmd>ZenMode<CR>", desc = "Toggle zen mode" },
        },
        opts = {
            window = {
                width = 90,
                options = {
                    signcolumn = "no",
                    number = false,
                    relativenumber = false,
                    cursorline = false,
                },
            },
            plugins = {
                twilight = { enabled = true },
                tmux = { enabled = true },
            },
        },
    },
    {
        "folke/twilight.nvim",
        lazy = true,
        opts = {
            context = 10,
        },
    },

    -- =========================================================================
    --   TROUBLE: better diagnostics / quickfix UI
    -- =========================================================================
    {
        "folke/trouble.nvim",
        cmd = "Trouble",
        keys = {
            { "<Leader>xx", "<cmd>Trouble diagnostics toggle<CR>",              desc = "Diagnostics (Trouble)" },
            { "<Leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Buffer diagnostics (Trouble)" },
            { "<Leader>xl", "<cmd>Trouble loclist toggle<CR>",                  desc = "Location list (Trouble)" },
            { "<Leader>xq", "<cmd>Trouble qflist toggle<CR>",                   desc = "Quickfix list (Trouble)" },
        },
        opts = {},
    },

    -- =========================================================================
    --   NOICE: enhanced cmdline, messages, notifications
    -- =========================================================================
    {
        "folke/noice.nvim",
        event = "VeryLazy",
        dependencies = { "MunifTanjim/nui.nvim" },
        opts = {
            lsp = {
                override = {
                    ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                    ["vim.lsp.util.stylize_markdown"] = true,
                },
            },
            presets = {
                bottom_search = true,
                command_palette = true,
                long_message_to_split = true,
            },
        },
    },
}
