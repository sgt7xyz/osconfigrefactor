-- =============================================================================
-- Neovim Configuration with Catppuccin Macchiato Theme
-- =============================================================================

-- Install Catppuccin theme via vim.pack
vim.pack.add { { src = "https://github.com/catppuccin/nvim", name = "catppuccin" } }

-- Catppuccin Macchiato Theme
vim.cmd.colorscheme("catppuccin-macchiato")

-- Line numbers
vim.opt.number = true

-- Load editorconfig plugin if available
vim.g.editorconfig = true

-- Status line
vim.opt.laststatus = 2

-- Display whitespace characters
vim.opt.list = true
vim.opt.listchars = { tab = "→ ", space = "·", trail = "·" }
