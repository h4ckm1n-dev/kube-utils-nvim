-- kube-utils-nvim/formatjson.lua

local M = {}

local function FormatJsonLogs()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local formatted_lines = { "[" }

	for i, line in ipairs(lines) do
		local json_part = line:match("{.*}")
		local timestamp = line:match("^(%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d:%d%dZ)")
		local log_level = line:match("%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d:%d%dZ%s+([A-Z]+)%s+")
		local module = line:match("%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d:%d%dZ%s+[A-Z]+%s+([%w%.%-_]+)%s+")

		local success, json_data = pcall(vim.fn.json_decode, json_part)
		json_data = success and json_data or {} -- Ensure json_data is always a table

		local ordered_json_data = { timestamp = timestamp }
		if log_level then
			ordered_json_data.log_level = log_level
		end
		if module then
			ordered_json_data.module = module
		end

		for key, value in pairs(json_data) do
			if key ~= "timestamp" and key ~= "log_level" and key ~= "module" then
				ordered_json_data[key] = value
			end
		end

		local json_text = vim.fn.json_encode(ordered_json_data)
		table.insert(formatted_lines, "\t" .. json_text .. (i < #lines and "," or ""))
	end

	table.insert(formatted_lines, "]")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, formatted_lines)
end

M.format = FormatJsonLogs

return M
