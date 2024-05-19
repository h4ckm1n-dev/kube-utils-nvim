-- modules/helm.lua
local Command = require("modules.command")
local Repository = require("modules.repository")
local TelescopePicker = require("modules.telescope_picker")

local Helm = {}

local function log_error(message)
	print("Error: " .. message)
end

local function fetch_contexts()
	local contexts, err = Command.run_shell_command("kubectl config get-contexts -o name")
	if not contexts then
		log_error(err or "Failed to fetch Kubernetes contexts.")
		return nil
	end
	local context_list = vim.split(contexts, "\n", true)
	if #context_list == 0 then
		log_error("No Kubernetes contexts available.")
		return nil
	end
	return context_list
end

local function fetch_namespaces()
	local namespaces, err = Command.run_shell_command("kubectl get namespaces | awk 'NR>1 {print $1}'")
	if not namespaces then
		log_error("Failed to fetch namespaces: " .. (err or "No namespaces found."))
		return nil
	end
	local namespace_list = vim.split(namespaces, "\n", true)
	if #namespace_list == 0 then
		log_error("No namespaces available.")
		return nil
	end
	return namespace_list
end

local function select_context(callback)
	local context_list = fetch_contexts()
	if not context_list then
		return
	end
	TelescopePicker.select_from_list("Select Kubernetes Context", context_list, function(selected_context)
		Command.run_shell_command("kubectl config use-context " .. selected_context)
		callback(selected_context)
	end)
end

local function select_namespace(callback)
	local namespace_list = fetch_namespaces()
	if not namespace_list then
		return
	end
	table.insert(namespace_list, 1, "[Create New Namespace]")
	TelescopePicker.select_from_list("Select Namespace", namespace_list, function(selected_namespace)
		if selected_namespace == "[Create New Namespace]" then
			TelescopePicker.input("Enter Namespace Name", function(new_ns_name)
				local create_ns_cmd = string.format("kubectl create namespace %s", new_ns_name)
				local create_ns_result, create_ns_err = Command.run_shell_command(create_ns_cmd)
				if create_ns_result then
					print(string.format("Namespace %s created successfully.", new_ns_name))
					callback(new_ns_name)
				else
					log_error("Failed to create namespace: " .. (create_ns_err or "Unknown error"))
				end
			end)
		else
			callback(selected_namespace)
		end
	end)
end

local function fetch_releases(namespace)
	local releases_cmd = string.format("helm list -n %s -q", namespace)
	local releases, err = Command.run_shell_command(releases_cmd)
	if not releases then
		log_error(err or "Failed to fetch Helm releases.")
		return nil
	end
	local release_list = vim.split(releases, "\n", true)
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
	local helm_cmd = string.format("helm dependency update %s", chart_directory)

	-- Extract repository information from Chart.yaml
	local chart_yaml_path = chart_directory .. "Chart.yaml"
	local repo_name, repo_url = Repository.get_repository_info(chart_yaml_path)

	-- Check if the repository is missing and add it
	local repo_check_cmd =
		string.format("helm repo list | grep -q %s || helm repo add %s %s", repo_name, repo_name, repo_url)
	local _, repo_check_err = Command.run_shell_command(repo_check_cmd)

	if repo_check_err then
		print("Adding missing repository: " .. repo_check_err)
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
	local helm_cmd = string.format("helm dependency build %s", chart_directory)
	local result, err = Command.run_shell_command(helm_cmd)
	if result then
		print("Helm dependency build successful: \n" .. result)
	else
		log_error("Helm dependency build failed: " .. (err or "Unknown error"))
	end
end

function Helm.deploy_from_buffer()
	select_context(function()
		select_namespace(function(namespace)
			local file_path = vim.api.nvim_buf_get_name(0)
			if file_path == "" then
				log_error("No file selected")
				return
			end
			local chart_directory = file_path:match("(.*/)")
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
	select_context(function()
		select_namespace(function(namespace)
			local file_path = vim.api.nvim_buf_get_name(0)
			if file_path == "" then
				log_error("No file selected")
				return
			end
			local chart_directory = file_path:match("(.*/)")
			TelescopePicker.input("Enter Release Name", function(chart_name)
				local helm_cmd = string.format(
					"helm install --dry-run %s %s --values %s -n %s --create-namespace",
					chart_name,
					chart_directory,
					file_path,
					namespace
				)
				local result, ns_err = Command.run_shell_command(helm_cmd)

				-- Open a new tab and create a buffer
				vim.cmd("tabnew")
				local bufnr = vim.api.nvim_create_buf(false, true)
				vim.bo[bufnr].filetype = "yaml"
				if result and result ~= "" then
					vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, vim.split(result, "\n"))
				else
					log_error("Dry run failed: " .. (ns_err or "Unknown error"))
				end
				-- Switch to the new buffer
				vim.api.nvim_set_current_buf(bufnr)
			end)
		end)
	end)
end

function Helm.remove_deployment()
	select_context(function()
		select_namespace(function(namespace)
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
