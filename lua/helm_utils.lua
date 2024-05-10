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

-- Function to perform a Helm dry-run deployment and display results in a new buffer
function M.helm_dry_run()
	local file_path = vim.api.nvim_buf_get_name(0)
	if file_path == "" then
		print("No file selected")
		return
	end
	local helm_cmd = "helm upgrade --install --dry-run " .. file_path .. " " .. file_path
	local result = run_shell_command(helm_cmd)
	if not result then -- Check if result is nil or empty
		print("Failed to execute helm command or no output returned.")
		return
	end
	vim.cmd("new") -- Open a new buffer
	vim.api.nvim_buf_set_lines(0, 0, -1, true, vim.split(result, "\n")) -- Display the result
end

function M.helm_deploy_from_buffer()
	-- Fetch the current file path from the buffer
	local file_path = vim.api.nvim_buf_get_name(0)
	if file_path == "" then
		print("No file selected")
		return
	end

	-- Prompt user for input regarding other deployment details
	local chart_name = vim.fn.input("Enter Chart Name (e.g., argo-cd): ")
	local chart_directory = vim.fn.input("Enter Chart Directory (e.g., argo-cd/): ")
	local namespace = vim.fn.input("Enter Namespace (e.g., argo-cd): ")

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
	vim.api.nvim_create_user_command("helm_deploy_from_buffer", M.helm_deploy_current_file, {})
	vim.api.nvim_create_user_command("KubeSwitchContext", M.switch_kubernetes_context, {})
	vim.api.nvim_create_user_command("HelmDryRun", M.helm_dry_run, {})
end

-- Helm keybindings
local helm_mappings = {
	h = {
		name = "Helm", -- This sets a label for all helm-related keybindings
		c = { "<cmd>helm_deploy_from_buffer<CR>", "Deploy Current Chart" },
		d = { "<cmd>HelmDryRun<CR>", "Select and Deploy Chart" },
		k = { "<cmd>KubeSwitchContext<CR>", "Switch Kubernetes Context" },
	},
}

-- Require the which-key plugin
local wk = require("which-key")

-- Register the Helm keybindings with a specific prefix
wk.register(helm_mappings, { prefix = "<leader>" })

return M
