-- kube-utils-nvim/formatjson.lua

local M = {}

-- TODO: Add more patterns for various log formats
local module_patterns = {
	"%w+%.py%[%a+%]", -- Python modules with log level in square brackets
	"%a[%a%d._/-]+%[%d+%]", -- Generic module with numbers (e.g., CRON jobs, systemd, etc.)
	"pam_unix%([^:]+%):", -- pam_unix specific pattern
	"[%a_]+%.[%a_]+%[%a+%]", -- General modules with log level in square brackets
	"%S+/%S+", -- Generic paths and modules with various separators
	"[%w_.-]+:[%w_.-]+:[%w_.-]+", -- Modules with multiple components separated by colons
	"[%a_][%a%d._-]*%[%a+%]", -- More general module patterns with log level
	"%w+%.%w+%[%w+%]", -- PostgreSQL logs: include database and function names
	"[%w_/]+%.go:%d+", -- Go modules with file paths
	"[%w$.]+%.java:%d+", -- Java logs with package and class names
	"[%w_/%.]+%.%a+:%d+", -- Generic modules with file extensions and line numbers
}

local timestamp_patterns = {
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

local function parseTimestamp(line)
	for _, pattern in ipairs(timestamp_patterns) do
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
		{ level = "LEVEL", pattern = "level%((%-?%d+)%)" },
	}
	local lower_line = line:lower()
	for _, log_level in ipairs(log_level_patterns) do
		if lower_line:find(log_level.pattern) then
			return log_level.level
		end
	end
	return "INFO" -- Default log level
end

local function parseLogMetadata(line)
	local log_level = parseLogLevel(line)
	local module = "unknown"
	local timestamp = parseTimestamp(line)

	-- Assume JSON starts with '{' character
	local json_start = line:find("{")
	local structured_data, message

	if json_start then
		local json_possible = line:sub(json_start)
		local status, json_data = pcall(vim.fn.json_decode, json_possible)
		if status then
			structured_data = json_data
			message = "Structured JSON data present"
		else
			message = line:sub(1, json_start - 1) -- Fallback to plain text up to JSON start
		end
	else
		message = line -- Use the whole line as message if no JSON is found
	end

	return timestamp, log_level, module, message, structured_data
end

local function FormatJsonLogs()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local formatted_lines = { "[" }
	for i, line in ipairs(lines) do
		local timestamp, log_level, module, message, structured_data = parseLogMetadata(line)
		local log_entry = {
			timestamp = timestamp,
			log_level = log_level,
			module = module,
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
