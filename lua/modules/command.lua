-- modules/command.lua
local Command = {}

function Command.run_shell_command(cmd)
	-- Attempt to open a pipe to run the command and capture both stdout and stderr
	local handle, err = io.popen(cmd .. " 2>&1", "r")
	if not handle then
		-- If the handle is nil, log the error using print (replace with a logging function if available)
		print("Failed to run command: " .. cmd .. "\nError: " .. tostring(err))
		return nil, "Error running command: " .. tostring(err)
	end

	-- Read the output of the command
	local output = handle:read("*a")
	-- Always ensure the handle is closed to avoid resource leaks
	handle:close()

	-- Check if the output is nil or empty
	if not output or output == "" then
		return nil, "Command returned no output"
	end

	-- Return the output normally
	return output
end

return Command
