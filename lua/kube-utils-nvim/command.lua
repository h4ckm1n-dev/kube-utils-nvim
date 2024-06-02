-- kube-utils-nvim/command.lua

local Utils = require("kube-utils-nvim.utils")

local Command = {}

function Command.run_shell_command(cmd)
	-- Attempt to open a pipe to run the command and capture both stdout and stderr
	local handle, err = io.popen(cmd .. " 2>&1", "r")
	if not handle then
		-- Log the error and return nil along with the error message
		Utils.log_error("Failed to run command: " .. cmd .. "\n" .. tostring(err))
		return nil, "Error running command: " .. tostring(err)
	end

	-- Read the output of the command
	local output = handle:read("*a")
	-- Always ensure the handle is closed to avoid resource leaks
	local success, close_err = handle:close()
	if not success then
		-- Log the error and return nil along with the error message
		Utils.log_error("Failed to close command handle for: " .. cmd .. "\n" .. tostring(close_err))
		return nil, "Error closing command handle: " .. tostring(close_err)
	end

	-- Check if the output is nil or empty
	if not output or output == "" then
		return nil, "Command returned no output"
	end

	-- Return the output normally
	return output, nil
end

return Command
