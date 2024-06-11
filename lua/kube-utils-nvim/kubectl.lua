-- kube-utils-nvim/kubectl.lua

local Utils = require("kube-utils-nvim.utils")
local Command = require("kube-utils-nvim.command")
local TelescopePicker = require("kube-utils-nvim.telescope_picker")

local Kubectl = {}

local function fetch_contexts()
	-- Run the shell command to get Kubernetes contexts
	local contexts, err = Command.run_shell_command("kubectl config get-contexts -o name")

	-- Check if the command was successful
	if not contexts or contexts == "" then
		Utils.log_error(err or "Failed to fetch Kubernetes contexts.")
		return nil
	end

	-- Split the contexts into a list
	local context_list = vim.split(contexts, "\n", { trimempty = true })

	-- Check if the list is empty
	if #context_list == 0 then
		Utils.log_error("No Kubernetes contexts available.")
		return nil
	end

	return context_list
end

local function fetch_namespaces()
	-- Run the shell command to get namespaces
	local namespaces, err = Command.run_shell_command("kubectl get namespaces | awk 'NR>1 {print $1}'")

	-- Check if the command was successful
	if not namespaces or namespaces == "" then
		Utils.log_error("Failed to fetch namespaces: " .. (err or "No namespaces found."))
		return nil
	end

	-- Split the namespaces into a list
	local namespace_list = vim.split(namespaces, "\n", { trimempty = true })

	-- Check if the list is empty
	if #namespace_list == 0 then
		Utils.log_error("No namespaces available.")
		return nil
	end

	return namespace_list
end

local function fetch_crds()
	-- Run the shell command to get CRDs
	local crds, err = Command.run_shell_command("kubectl get crd -o name")

	-- Check if the command was successful
	if not crds or crds == "" then
		Utils.log_error(err or "Failed to fetch CRDs: Command returned no output.")
		return nil
	end

	-- Split the CRDs into a list
	local crd_list = vim.split(crds, "\n", { trimempty = true })

	-- Check if the list is empty
	if #crd_list == 0 then
		Utils.log_error("No CRDs available.")
		return nil
	end

	return crd_list
end

local function fetch_crd_details(crd_name)
	-- Run the shell command to get CRD details
	local crd_details, err = Command.run_shell_command("kubectl get " .. crd_name .. " -o yaml")

	-- Check if the command was successful
	if not crd_details or crd_details == "" then
		Utils.log_error(err or "Failed to fetch CRD details: Command returned no output.")
		return nil
	end

	return crd_details
end

Kubectl.select_crd = function()
	-- Step 1: Select a context
	local context_list = fetch_contexts()
	if not context_list then
		return
	end
	TelescopePicker.select_from_list("Select Kubernetes Context", context_list, function(selected_context)
		Command.run_shell_command("kubectl config use-context " .. selected_context)
		-- Step 3: Select a CRD
		local crd_list = fetch_crds()
		if not crd_list then
			return
		end
		TelescopePicker.select_from_list("Select CRD", crd_list, function(selected_crd)
			-- Step 4: Fetch the selected CRD details
			local crd_details = fetch_crd_details(selected_crd)
			if not crd_details then
				return
			end

			-- Function to safely rename buffer
			local function safe_set_buf_name(buf, name)
				local ok, err = pcall(vim.api.nvim_buf_set_name, buf, name)
				if not ok then
					print("Failed to rename buffer: " .. err)
				end
			end

			-- Step 5: Open the CRD details in a new buffer with a vertical split and save it
			vim.api.nvim_command("new")
			local buf = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_set_current_buf(buf)
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(crd_details, "\n"))
			safe_set_buf_name(buf, selected_crd .. ".yaml")
			vim.bo[buf].filetype = "yaml"
		end)
	end)
end

Kubectl.select_crd_split = function()
	-- Step 1: Select a context
	local context_list = fetch_contexts()
	if not context_list then
		return
	end
	TelescopePicker.select_from_list("Select Kubernetes Context", context_list, function(selected_context)
		Command.run_shell_command("kubectl config use-context " .. selected_context)
		-- Step 3: Select a CRD
		local crd_list = fetch_crds()
		if not crd_list then
			return
		end
		TelescopePicker.select_from_list("Select CRD", crd_list, function(selected_crd)
			-- Step 4: Fetch the selected CRD details
			local crd_details = fetch_crd_details(selected_crd)
			if not crd_details then
				return
			end

			-- Function to safely rename buffer
			local function safe_set_buf_name(buf, name)
				local ok, err = pcall(vim.api.nvim_buf_set_name, buf, name)
				if not ok then
					print("Failed to rename buffer: " .. err)
				end
			end

			-- Step 5: Open the CRD details in a new buffer with a vertical split and save it
			vim.api.nvim_command("vsplit")
			local buf = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_set_current_buf(buf)
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(crd_details, "\n"))
			safe_set_buf_name(buf, selected_crd .. ".yaml")
			vim.bo[buf].filetype = "yaml"
		end)
	end)
end

Kubectl.select_context = function(callback)
	local context_list = fetch_contexts()
	if not context_list then
		return
	end
	TelescopePicker.select_from_list("Select Kubernetes Context", context_list, function(selected_context)
		Command.run_shell_command("kubectl config use-context " .. selected_context)
		callback(selected_context)
	end)
end

Kubectl.select_namespace = function(callback)
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
					Utils.log_error("Failed to create namespace: " .. (create_ns_err or "Unknown error"))
				end
			end)
		else
			callback(selected_namespace)
		end
	end)
end

Kubectl.apply_from_buffer = function()
	local context_list = fetch_contexts()
	if not context_list then
		return
	end

	TelescopePicker.select_from_list("Select Kubernetes Context", context_list, function(selected_context)
		Command.run_shell_command("kubectl config use-context " .. selected_context)

		local namespace_list = fetch_namespaces()
		if not namespace_list then
			return
		end

		TelescopePicker.select_from_list("Select Namespace", namespace_list, function(selected_namespace)
			local file_path = vim.api.nvim_buf_get_name(0)
			if file_path == "" then
				Utils.log_error("No file selected")
				return
			end

			local result, apply_err =
				Command.run_shell_command("kubectl apply -f " .. file_path .. " -n " .. selected_namespace)
			if result and result ~= "" then
				print("kubectl apply successful: \n" .. result)
			else
				Utils.log_error("kubectl apply failed: " .. (apply_err or "Unknown error"))
			end
		end)
	end)
end

Kubectl.delete_namespace = function()
	local context_list = fetch_contexts()
	if not context_list then
		return
	end

	TelescopePicker.select_from_list("Select Kubernetes Context", context_list, function(selected_context)
		Command.run_shell_command("kubectl config use-context " .. selected_context)
		Kubectl.select_and_delete_namespace()
	end)
end

Kubectl.select_and_delete_namespace = function()
	local namespace_list = fetch_namespaces()
	if not namespace_list then
		return
	end

	TelescopePicker.select_from_list("Select Namespace to Delete", namespace_list, function(selected_namespace)
		local confirm_delete = vim.fn.input("Delete namespace " .. selected_namespace .. "? [y/N]: ")
		if confirm_delete == "y" or confirm_delete == "Y" then
			local delete_cmd = "kubectl delete namespace " .. selected_namespace
			local result, err = Command.run_shell_command(delete_cmd)
			if result then
				print("Namespace " .. selected_namespace .. " successfully deleted.")
			else
				Utils.log_error("Failed to delete namespace " .. selected_namespace .. ": " .. (err or "Unknown error"))
			end
		else
			print("Deletion cancelled.")
		end
	end)
end

return Kubectl
