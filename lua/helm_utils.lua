local M = {}

local function run_shell_command(cmd)
	-- Attempt to open a pipe to run the command
	local handle, err = io.popen(cmd, "r")
	if not handle then
		-- If the handle is nil, print the error and return a default message
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

function M.helm_deploy_from_buffer()
	-- Fetch the current file path from the buffer
	local file_path = vim.api.nvim_buf_get_name(0)
	if file_path == "" then
		print("No file selected")
		return
	end

	-- Parse file path to extract chart directory
	local chart_directory = file_path:match("(.*/)") or ""

	-- Prompt user for input regarding release name and namespace
	local chart_name = vim.fn.input("Enter Realese Name: ")
	local namespace = vim.fn.input("Enter Namespace: ")

	-- Construct the Helm command using the buffer's file as the values file
	local helm_cmd = string.format(
		"helm upgrade --install %s %s --values %s -n %s --create-namespace",
		chart_name,
		chart_directory,
		file_path,
		namespace
	)

	-- Execute the Helm command
	local result = run_shell_command(helm_cmd)
	if result and result ~= "" then
		print("Deployment successful: \n" .. result)
	else
		print("Deployment failed or no output returned.")
	end
end

function M.helm_dryrun_from_buffer()
	-- Fetch the current file path from the buffer
	local file_path = vim.api.nvim_buf_get_name(0)
	if file_path == "" then
		print("No file selected")
		return
	end

	-- Parse file path to extract chart directory
	local chart_directory = file_path:match("(.*/)") or ""

	-- Prompt user for input regarding release name and namespace
	local chart_name = vim.fn.input("Enter Release Name: ")
	local namespace = vim.fn.input("Enter Namespace: ")

	-- Construct the Helm dry run command using the buffer's file as the values file
	local helm_cmd = string.format(
		"helm install --debug --dry-run %s %s --values %s -n %s --create-namespace",
		chart_name,
		chart_directory,
		file_path,
		namespace
	)

	-- Execute the Helm dry run command
	local result = run_shell_command(helm_cmd)

	-- Open a new buffer
	local bufnr = vim.api.nvim_create_buf(false, true)

	-- Set the filetype to YAML
	vim.api.nvim_buf_set_option(bufnr, "filetype", "yaml")

	-- Print the output in the new buffer in Neovim
	if result and result ~= "" then
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, vim.split(result, "\n"))
		vim.api.nvim_set_current_buf(bufnr)
	else
		print("Dry run failed or no output returned.")
	end
end

-- Function to switch Kubernetes contexts
function M.switch_kubernetes_context()
	local contexts, error_message = run_shell_command("kubectl config get-contexts -o name")
	if not contexts then
		print(error_message or "Failed to fetch Kubernetes contexts.")
		return
	end

	local context_list = vim.split(contexts, "\n", true)
	if #context_list == 0 then
		print("No Kubernetes contexts available.")
		return
	end

	vim.ui.select(context_list, { prompt = "Select Kubernetes context:" }, function(choice)
		if choice then
			local result, error_message = run_shell_command("kubectl config use-context " .. choice)
			if result then
				print("Switched to context: " .. choice)
			else
				print(error_message or "Failed to switch context.")
			end
		else
			print("No context selected.")
		end
	end)
end

-- Register Neovim commands
function M.setup()
	vim.api.nvim_create_user_command("HelmDeployFromBuffer", M.helm_deploy_from_buffer, {})
	vim.api.nvim_create_user_command("HelmDryRun", M.helm_dryrun_from_buffer, {})
	vim.api.nvim_create_user_command("KubeSwitchContext", M.switch_kubernetes_context, {})
end

return M
