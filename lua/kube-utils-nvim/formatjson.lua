-- kube-utils-nvim/formatjson.lua

local M = {}
-- TODO: Add more patterns for modules
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
			if log_level.level == "LEVEL" then
				local number = lower_line:match("level%((%-?%d+)%)")
				return "LEVEL(" .. number .. ")"
			else
				return log_level.level
			end
		end
	end
	return "INFO"
end

-- Function to parse log metadata, ensuring modules are not mistaken for timestamps
local function parseLogMetadata(line)
	local log_level = parseLogLevel(line)
	local module = "unknown"
	local json_start = line:find("{")
	local structured_data = nil
	local message = line
	local plain_text_message = line

	-- Parse structured JSON data if present
	if json_start then
		local json_possible = line:sub(json_start)
		local status, json_data = pcall(vim.fn.json_decode, json_possible)
		if status then
			structured_data = json_data
			message = "Structured JSON data present"
			plain_text_message = line:sub(1, json_start - 1)
		end
	end

	-- Extract the timestamp first
	local timestamp = parseTimestamp(line)

	-- Remove the timestamp from the line to prevent it from being matched as a module
	if timestamp ~= "unknown" then
		line = line:gsub(timestamp, "")
	end

	-- Match module patterns, ensuring no common timestamp formats are matched
	local parsed = false
	for _, pattern in ipairs(module_patterns) do
		local matched_module = line:match(pattern)
		if matched_module and not matched_module:match("%d%d:%d%d:%d%d") then -- Avoid matching timestamps
			module = matched_module
			parsed = true
			break
		end
	end

	-- If nothing could be parsed, keep the full message
	if not parsed then
		message = line
	end

	return log_level, module, message, structured_data, plain_text_message
end

local function FormatJsonLogs()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local formatted_lines = { "[" }
	for i, line in ipairs(lines) do
		local timestamp = parseTimestamp(line) or "unknown"
		local log_level, module, message, structured_data, plain_text_message = parseLogMetadata(line)
		local log_entry = {
			timestamp = timestamp,
			log_level = log_level,
			module = module or "unknown",
			message = message,
			plain_text_message = plain_text_message,
		}
		if structured_data then
			log_entry.structured_data = structured_data
		end
		-- Remove plain_text_message if it is the same as message
		if log_entry.message == log_entry.plain_text_message then
			log_entry.plain_text_message = nil
		end
		local json_text = vim.fn.json_encode(log_entry)
		table.insert(formatted_lines, "\t" .. json_text .. (i < #lines and "," or ""))
	end
	table.insert(formatted_lines, "]")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, formatted_lines)
end

M.format = FormatJsonLogs

return M
