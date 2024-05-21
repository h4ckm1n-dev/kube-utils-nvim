-- modules/helm.lua

local Command = require("modules.command")
local Repository = require("modules.repository")
local TelescopePicker = require("modules.telescope_picker")
local Kubectl = require("modules.kubectl")

local Helm = {}

local function log_error(message)
	print("Error: " .. message)
end

local function fetch_releases(namespace)
	-- Construct the helm list command with the provided namespace
	local releases_cmd = string.format("helm list -n %s -q", namespace)
	local releases, err = Command.run_shell_command(releases_cmd)

	-- Check if the command was successful
	if not releases or releases == "" then
		log_error(err or "Failed to fetch Helm releases.")
		return nil
	end

	-- Split the releases into a list
	local release_list = vim.split(releases, "\n", { trimempty = true })

	-- Check if the list is empty
	if #release_list == 0 then
		log_error("No Helm releases available.")
		return nil
	end

	return release_list
end

function Helm.dependency_update_from_buffer()
	local file_path = vim.api.nvim_buf_get_name(0)
	if file_path == "" then
		log_error("No file selected")
		return
	end

	local chart_directory = file_path:match("(.*/)")
	if not chart_directory then
		log_error("Failed to determine chart directory from file path")
		return
	end

	local helm_cmd = string.format("helm dependency update %s", chart_directory)

	-- Extract repository information from Chart.yaml
	local chart_yaml_path = chart_directory .. "Chart.yaml"
	local repo_name, repo_url = Repository.get_repository_info(chart_yaml_path)

	if repo_name and repo_url then
		-- Check if the repository is missing and add it
		local repo_check_cmd =
			string.format("helm repo list | grep -q %s || helm repo add %s %s", repo_name, repo_name, repo_url)
		local _, repo_check_err = Command.run_shell_command(repo_check_cmd)

		if repo_check_err then
			print("Adding missing repository: " .. repo_check_err)
		end
	else
		log_error("Repository information is missing in Chart.yaml")
	end

	-- Execute the dependency update command
	local result, err = Command.run_shell_command(helm_cmd)
	if result then
		print("Helm dependency update successful: \n" .. result)
	else
		log_error("Helm dependency update failed: " .. (err or "Unknown error"))
	end
end

function Helm.dependency_build_from_buffer()
	local file_path = vim.api.nvim_buf_get_name(0)
	if file_path == "" then
		log_error("No file selected")
		return
	end

	local chart_directory = file_path:match("(.*/)")
	if not chart_directory then
		log_error("Failed to determine chart directory from file path")
		return
	end

	local helm_cmd = string.format("helm dependency build %s", chart_directory)
	local result, err = Command.run_shell_command(helm_cmd)
	if result then
		print("Helm dependency build successful: \n" .. result)
	else
		log_error("Helm dependency build failed: " .. (err or "Unknown error"))
	end
end

local function generate_helm_template(chart_directory)
	-- Change the current working directory to the chart directory
	local original_directory = vim.loop.cwd() or ""

	-- Handle the case where original_directory is nil
	if original_directory == "" then
		log_error("Failed to get the current working directory")
		return "Error: Failed to get the current working directory"
	end

	vim.loop.chdir(chart_directory)

	local helm_cmd = "helm template ."
	local result, err = Command.run_shell_command(helm_cmd)

	-- Change back to the original directory
	vim.loop.chdir(original_directory)

	if result and result ~= "" then
		return result
	else
		local error_message = "Helm template generation failed: " .. (err or "Unknown error")
		log_error(error_message)
		return error_message
	end
end

function Helm.template_from_buffer()
	local file_path = vim.api.nvim_buf_get_name(0)
	if file_path == "" then
		log_error("No file selected")
		return
	end

	local chart_directory = file_path:match("(.*/)")
	if not chart_directory then
		log_error("Failed to determine chart directory from file path")
		return
	end

	local template = generate_helm_template(chart_directory)
	if template then
		-- Open a new tab and create a buffer
		vim.cmd("tabnew")
		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.bo[bufnr].filetype = "yaml"
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, vim.split(template, "\n"))
		-- Switch to the new buffer
		vim.api.nvim_set_current_buf(bufnr)
	end
end

function Helm.deploy_from_buffer()
	Kubectl.select_context(function()
		Kubectl.select_namespace(function(namespace)
			local file_path = vim.api.nvim_buf_get_name(0)
			if file_path == "" then
				log_error("No file selected")
				return
			end
			local chart_directory = file_path:match("(.*/)")
			if not chart_directory then
				log_error("Failed to determine chart directory from file path")
				return
			end

			TelescopePicker.input("Enter Release Name", function(chart_name)
				local helm_cmd = string.format(
					"helm upgrade --install %s %s --values %s -n %s --create-namespace",
					chart_name,
					chart_directory,
					file_path,
					namespace
				)
				local result, helm_err = Command.run_shell_command(helm_cmd)
				if result and result ~= "" then
					print("Deployment successful: \n" .. result)
				else
					log_error("Deployment failed: " .. (helm_err or "Unknown error"))
				end
			end)
		end)
	end)
end

function Helm.dryrun_from_buffer()
	Kubectl.select_context(function()
		Kubectl.select_namespace(function(namespace)
			local file_path = vim.api.nvim_buf_get_name(0)
			if file_path == "" then
				log_error("No file selected")
				return
			end
			local chart_directory = file_path:match("(.*/)")
			if not chart_directory then
				log_error("Failed to determine chart directory from file path")
				return
			end

			TelescopePicker.input("Enter Release Name", function(chart_name)
				local helm_cmd = string.format(
					"helm upgrade --install --dry-run %s %s --values %s -n %s",
					chart_name,
					chart_directory,
					file_path,
					namespace
				)

				-- Run the helm command and capture its output
				local handle = io.popen(helm_cmd)
				if not handle then
					log_error("Failed to run Helm command")
					return
				end
				local result = handle:read("*a")
				local success, _, exit_code = handle:close()

				-- Check if the command was successful
				if not success or exit_code ~= 0 or not result or result == "" then
					log_error("Dry run failed")
					return
				end

				-- Extract console output (lines that indicate Helm messages)
				local console_output = {}
				for _, line in ipairs(vim.split(result, "\n")) do
					if
						line:match("^Release")
						or line:match("^NAME")
						or line:match("^LAST DEPLOYED")
						or line:match("^NAMESPACE")
						or line:match("^STATUS")
						or line:match("^REVISION")
						or line:match("^HOOKS:")
					then
						table.insert(console_output, line)
					end
				end

				-- Open a new tab and create a buffer
				vim.cmd("tabnew")
				local bufnr = vim.api.nvim_create_buf(false, true)
				vim.bo[bufnr].filetype = "yaml"

				-- Prepare the lines to set in the buffer
				local buffer_lines = vim.split(result, "\n")

				-- Add console output as comments at the beginning of the buffer lines
				if #console_output > 0 then
					local commented_output = {}
					for _, line in ipairs(console_output) do
						table.insert(commented_output, "# " .. line)
					end
					table.insert(commented_output, "") -- Add an empty line after comments
					buffer_lines = vim.list_extend(commented_output, buffer_lines)
				end

				vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, buffer_lines)

				-- Switch to the new buffer
				vim.api.nvim_set_current_buf(bufnr)
			end)
		end)
	end)
end

-- Example of running a shell command and returning the output (mocked)
Command = {}
function Command.run_shell_command(cmd)
	local handle = io.popen(cmd)
	local result = handle:read("*a")
	local _, _, exit_code = handle:close()
	if exit_code ~= 0 then
		return result, "Command failed"
	end
	return result, nil
end

function Helm.remove_deployment()
	Kubectl.select_context(function()
		Kubectl.select_namespace(function(namespace)
			local release_list = fetch_releases(namespace)
			if not release_list then
				return
			end
			TelescopePicker.select_from_list("Select Release to Remove", release_list, function(release_name)
				local helm_cmd = string.format("helm uninstall %s -n %s", release_name, namespace)
				local result, helm_err = Command.run_shell_command(helm_cmd)
				if result and result ~= "" then
					print("Deployment removal successful: \n" .. result)
				else
					log_error("Deployment removal failed: " .. (helm_err or "Unknown error"))
				end
			end)
		end)
	end)
end

return Helm
