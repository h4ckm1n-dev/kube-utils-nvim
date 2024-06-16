-- kube-utils-nvim/formatjson.lua

local M = {}

local function parseTimestamp(line)
	local patterns = {
		"%d%d%d%d%-%d%d%-%d%d[T ]%d%d:%d%d:%d%d[%.%d]*[+-]%d%d:?%d%d", -- ISO 8601 with milliseconds and timezone
		"%d%d%d%d%-%d%d%-%d%d[T ]%d%d:%d%d:%d%d[%.%d]*Z?", -- ISO 8601 with optional milliseconds and 'T'
		"%d%d%d%d%-%d%d%-%d%d[T ]%d%d:%d%d:%d%d[+-]%d%d:?%d%d", -- ISO 8601 with time zone
		"%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d,%d%d%d", -- YYYY-MM-DD HH:MM:SS,SSS
		"%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d", -- YYYY-MM-DD HH:MM:SS
		"%d+%.%d+", -- Unix timestamp with milliseconds
		"%d+", -- Unix timestamp (seconds since Unix epoch)
		"%d%d/%d%d/%d%d%d%d %d%d:%d%d:%d%d", -- MM/DD/YYYY HH:MM:SS
		"%d%d%-%d%d%-%d%d%d%d %d%d:%d%d:%d%d", -- MM-DD-YYYY HH:MM:SS
		"%a%a%a %d%d %d%d:%d%d:%d%d %d%d%d%d", -- RFC 2822 with day of the week
		"%a%a%a %a%a%a %d%d %d%d:%d%d:%d%d %d%d%d%d", -- Full RFC 2822
		"%d%d%a%a%a%d%d%d%d %d%d:%d%d:%d%d", -- Custom Kubernetes format
	}
	for _, pattern in ipairs(patterns) do
		local timestamp = line:match(pattern)
		if timestamp then
			return timestamp
		end
	end
	return "unknown"
end

local function parseLogLevel(line)
	local log_level_patterns = {
		{ level = "CRITICAL", pattern = "%[%s*critical%s*%]" },
		{ level = "ERROR", pattern = "%[%s*error%s*%]" },
		{ level = "WARNING", pattern = "%[%s*warning%s*%]" },
		{ level = "INFO", pattern = "%[%s*info%s*%]" },
		{ level = "DEBUG", pattern = "%[%s*debug%s*%]" },
		{ level = "LEVEL(-2)", pattern = "level%(%-2%)" }, -- Adjusted pattern for LEVEL(-2)
	}
	local lower_line = line:lower()
	for _, log_level in ipairs(log_level_patterns) do
		if lower_line:find(log_level.pattern) then
			return log_level.level
		end
	end
	return "INFO"
end

local function parseLogMetadata(line)
	local log_level = parseLogLevel(line)
	local message = line
	local module = "unknown"
	local json_start = line:find("{")
	local structured_data = nil

	-- Attempt to parse structured JSON data if present
	if json_start then
		local json_possible = line:sub(json_start)
		local status, json_data = pcall(vim.fn.json_decode, json_possible)
		if status then
			structured_data = json_data
			message = "Structured JSON data present"
		end
	end

	-- Regex to capture Kubernetes specific identifiers like module paths
	local module_patterns = {
		"%a[%a%d._/-]+%[%d+%]", -- Matches module patterns like "CRON[329707]", "systemd-logind[1227]"
		"%S+/%S+", -- Matches module paths like "setup.version/version/version.go"
		"%w+%.py%[%a+%]", -- Matches patterns like "main.py[DEBUG]"
		"%S+", -- Match any non-space sequence
	}

	for _, pattern in ipairs(module_patterns) do
		local matched_module = line:match(pattern)
		if matched_module and not matched_module:match("%d%d%d%d%-%d%d%-%d%d") then -- Avoid matching timestamps
			module = matched_module
			break
		end
	end

	return log_level, module, message, structured_data
end

local function FormatJsonLogs()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local formatted_lines = { "[" }
	for i, line in ipairs(lines) do
		local timestamp = parseTimestamp(line) or "unknown"
		local log_level, module, message, structured_data = parseLogMetadata(line)
		local log_entry = {
			timestamp = timestamp,
			log_level = log_level,
			module = module or "unknown",
			message = message,
			structured_data = structured_data,
		}
		local json_text = vim.fn.json_encode(log_entry)
		table.insert(formatted_lines, "\t" .. json_text .. (i < #lines and "," or ""))
	end
	table.insert(formatted_lines, "]")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, formatted_lines)
end

M.format = FormatJsonLogs

return M
