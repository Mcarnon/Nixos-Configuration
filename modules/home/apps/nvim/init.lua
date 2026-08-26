-- Minimal init.lua — real dotfile deployed by HM (xdg.configFile."nvim".source).
-- Edit this file directly (plain Lua). After `nixos-rebuild switch --flake .#laptop` HM syncs it to ~/.config/nvim.
-- Temp IDE: LSP is configured below for nil/nix + lua_ls. Add servers per language as needed.

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Options (sensible defaults)
local o = vim.opt
o.number = true
o.relativenumber = true
o.termguicolors = true
o.signcolumn = "yes"
o.wrap = false
o.scrolloff = 8
o.sidescrolloff = 8
o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.smartindent = true
o.ignorecase = true
o.smartcase = true
o.undofile = true
o.clipboard = "unnamedplus"
o.splitbelow = true
o.splitright = true
o.timeoutlen = 300
o.updatetime = 250

-- Keymaps (minimal, no plugin manager yet)
vim.keymap.set("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
vim.keymap.set("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>")
vim.keymap.set("v", "J", ":m '>+1<cr>gv=gv", { desc = "Move line down" })
vim.keymap.set("v", "K", ":m '<-2<cr>gv=gv", { desc = "Move line up" })

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function() vim.highlight.on_yank() end,
})

-- LSP (temp IDE) — uses binaries from home.packages (nil, lua_ls).
-- For more languages, add server to home.packages + here.
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local map = function(keys, func, desc)
      vim.keymap.set("n", keys, func, { buffer = ev.buf, desc = "LSP: " .. desc })
    end
    map("gd", vim.lsp.buf.definition, "Go to definition")
    map("gr", vim.lsp.buf.references, "References")
    map("K", vim.lsp.buf.hover, "Hover")
    map("<leader>rn", vim.lsp.buf.rename, "Rename")
    map("<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("<leader>f", function() vim.lsp.buf.format({ async = true }) end, "Format")
  end,
})

-- Enable LSP servers if available (Neovim 0.11+ vim.lsp.enable)
local ok, lsp = pcall(function() return vim.lsp end)
if ok and lsp.enable then
  -- nil (Nix) — nil_ls binary name is `nil`
  lsp.enable("nil_ls")
  -- lua_ls
  lsp.enable("lua_ls")
end
