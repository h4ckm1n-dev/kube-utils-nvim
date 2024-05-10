local M = {}

-- Utility function to run shell commands and capture output
local function run_shell_command(cmd)
	local handle = io.popen(cmd, "r")
	local output = handle:read("*a")
	handle:close()
	return output
end

-- Function to deploy the Helm chart of the current file
function M.helm_deploy_current_file()
	-- Get the full path of the current buffer
	local file_path = vim.api.nvim_buf_get_name(0)

	-- Ensure Minikube is the target context
	run_shell_command("kubectl config use-context minikube")

	-- Deploy Helm chart
	local helm_cmd = "helm upgrade --install " .. file_path .. " " .. file_path
	local result = run_shell_command(helm_cmd)
	print(result)
end

-- Function to allow user to select a Helm chart from a list
function M.select_and_deploy_chart()
	local charts = vim.fn.globpath("path/to/charts", "*", 0, 1)
	if #charts == 0 then
		print("No charts found.")
		return
	end
	vim.ui.select(charts, { prompt = "Select a chart to deploy:" }, function(choice)
		if choice then
			M.helm_deploy({ choice })
		end
	end)
end

-- Function to switch Kubernetes contexts
function M.switch_kubernetes_context()
	local contexts = run_shell_command("kubectl config get-contexts -o name")
	local context_list = vim.split(contexts, "\n", true)
	vim.ui.select(context_list, { prompt = "Select Kubernetes context:" }, function(choice)
		if choice then
			run_shell_command("kubectl config use-context " .. choice)
			print("Switched to context: " .. choice)
		end
	end)
end

-- Register Neovim commands
function M.setup()
	vim.api.nvim_create_user_command("HelmDeployCurrent", M.helm_deploy_current_file, {})

	vim.api.nvim_create_user_command("HelmSelectAndDeploy", M.select_and_deploy_chart, {})

	vim.api.nvim_create_user_command("KubeSwitchContext", M.switch_kubernetes_context, {})
end

return M
