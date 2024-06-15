-- kube-utils-nvim/formatjson.lua

local M = {}

local function FormatJsonLogs()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local formatted_lines = { "[" }

	for i, line in ipairs(lines) do
		local json_part = line:match("{.*}") -- Extract JSON if present
		local success, json_data = pcall(vim.fn.json_decode, json_part or "{}")
		json_data = success and json_data or {}

		-- Regular expressions to capture log metadata from unstructured parts
		local timestamp = line:match("^(%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d:%d%dZ)")
		local log_level = line:match("%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d:%d%dZ%s+([A-Z]+)%s+")
		local module = line:match("%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d:%d%dZ%s+[A-Z]+%s+([%w%.%-_]+)%s+")
		local message = line:match("%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d:%d%dZ%s+[A-Z]+%s+[%w%.%-_]+%s+(.*)")

		local log_entry = {
			timestamp = timestamp or "unknown",
			log_level = log_level or "INFO",
			module = module,
			message = message or line, -- Use the entire line as message if specific parsing fails
		}

		-- Merge structured JSON data with extracted data
		for key, value in pairs(json_data) do
			log_entry[key] = value
		end

		local json_text = vim.fn.json_encode(log_entry)
		table.insert(formatted_lines, "\t" .. json_text .. (i < #lines and "," or ""))
	end

	table.insert(formatted_lines, "]")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, formatted_lines)
end

M.format = FormatJsonLogs

return M