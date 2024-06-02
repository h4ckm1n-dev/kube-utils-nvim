-- kube-utils-nvim/k9s.lua

local K9s = {}

-- Helper function to set up terminal key mappings
local function set_terminal_keymaps(bufnr)
	local opts = { noremap = true, silent = true }
	local keymaps = {
		{ "t", "<C-w>q", "<C-\\><C-n>:q<CR>", opts },
		{ "t", "<C-w>c", "<C-\\><C-n>:q<CR>", opts },
		{ "t", "<C-c>", "<C-\\><C-n>", opts },
	}

	for _, keymap in ipairs(keymaps) do
		vim.api.nvim_buf_set_keymap(bufnr, keymap[1], keymap[2], keymap[3], keymap[4])
	end
end

-- Open K9s in a floating window
function K9s.open()
	local k9s_cmd = "k9s"

	-- Calculate window dimensions and position
	local width = 0.8
	local height = 0.8
	local x = (1 - width) / 2
	local y = (1 - height) / 2
	local opts = {
		relative = "editor",
		width = math.floor(vim.o.columns * width),
		height = math.floor(vim.o.lines * height),
		col = math.floor(vim.o.columns * x),
		row = math.floor(vim.o.lines * y),
		style = "minimal",
	}

	-- Create a new terminal buffer and open it in a floating window
	local bufnr = vim.api.nvim_create_buf(false, true)
	if not bufnr then
		print("Failed to create buffer")
		return
	end

	vim.api.nvim_open_win(bufnr, true, opts)

	-- Run K9s in the newly created terminal buffer
	vim.fn.termopen(k9s_cmd)

	-- Set key mappings for terminal buffer
	set_terminal_keymaps(bufnr)
end

-- Open K9s in a vertical split
function K9s.open_split()
	vim.cmd("vnew | terminal k9s")
	local bufnr = vim.api.nvim_get_current_buf()
	set_terminal_keymaps(bufnr)
end

return K9s
