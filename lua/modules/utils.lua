-- modules/utils.lua

local Utils = {}

-- Function log_error
function Utils.log_error(message)
	vim.notify("Error: " .. message, vim.log.levels.ERROR)
end

return Utils
