-- kube-utils-nvim/formatjson.lua

local M = {}

local function parseTimestamp(line)
    -- Extendable timestamp patterns
    local patterns = {
        "%d%d%d%d%-%d%d%-%d%d[%sT]%d%d:%d%d:%d%d[%.%d]*Z?", -- ISO 8601 with optional milliseconds and 'T'
        "%d%d%d%d/%d%d/%d%d %d%d:%d%d:%d%d",                -- Alternative format e.g., YYYY/MM/DD HH:MM:SS
    }
    for _, pattern in ipairs(patterns) do
        local timestamp = line:match("^" .. pattern)
        if timestamp then return timestamp end
    end
    return nil
end

local function parseLogMetadata(line, timestamp)
    local log_level, module, message
    if timestamp then
        local pattern = "^" .. timestamp:gsub("([%.%-:%/%s])", "%%%1") .. "%s+([A-Z]+)%s+([%w%.%-_]+)%s+(.*)"
        _, _, log_level, module, message = line:find(pattern)
    end
    return log_level, module, message
end

local function extractJsonPart(line)
    local json_part = line:match("{.*}") -- Extract JSON if present
    if json_part then
        local success, json_data = pcall(vim.fn.json_decode, json_part)
        if success then return json_data end
    end
    return {}
end

local function FormatJsonLogs()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local formatted_lines = {"["}

    for i, line in ipairs(lines) do
        local json_data = extractJsonPart(line)
        local timestamp = parseTimestamp(line) or "unknown"
        local log_level, module, message = parseLogMetadata(line, timestamp)

        local log_entry = {
            timestamp = timestamp,
            log_level = log_level or "INFO",
            module = module,
            message = message or line -- Use the entire line as message if specific parsing fails
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
