-- modules/k9s.lua
local K9s = {}

function K9s.open()
	-- Define the terminal command to run K9s
	local k9s_cmd = "k9s"

	-- Calculate window dimensions and position based on the editor's size
	local width = 0.8 -- Width percentage of the screen
	local height = 0.8 -- Height percentage of the screen
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
	vim.api.nvim_open_win(bufnr, true, opts)

	-- Run K9s in the newly created terminal buffer
	vim.fn.termopen(k9s_cmd)

	-- Set key mappings to manage the floating window and interactions
	vim.api.nvim_buf_set_keymap(bufnr, "t", "<C-w>q", "<C-\\><C-n>:q<CR>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(bufnr, "t", "<C-w>c", "<C-\\><C-n>:q<CR>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(bufnr, "t", "<C-c>", "<C-\\><C-n>", { noremap = true, silent = true })
end

function K9s.open_split()
	-- Open K9s in a new terminal buffer
	vim.cmd("vnew | terminal k9s")

	-- Set up key mapping to quit the terminal window gracefully
	vim.api.nvim_buf_set_keymap(0, "t", "<C-w>q", "<C-\\><C-n>:q<CR>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(0, "t", "<C-w>c", "<C-\\><C-n>:q<CR>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(0, "t", "<C-c>", "<C-\\><C-n>", { noremap = true, silent = true })
end

return K9s
