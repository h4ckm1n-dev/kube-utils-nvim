-- kube-utils-nvim/utils.lua

local Utils = {}

-- Function log_error
Utils.log_error = function(message)
	vim.notify("Error: " .. message, vim.log.levels.ERROR)
end

return Utils
