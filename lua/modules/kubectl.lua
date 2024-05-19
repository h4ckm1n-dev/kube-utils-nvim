-- modules/kubectl.lua

local Command = require("modules.command")
local TelescopePicker = require("modules.telescope_picker")

local Kubectl = {}

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

function Kubectl.select_context(callback)
	local context_list = fetch_contexts()
	if not context_list then
		return
	end
	TelescopePicker.select_from_list("Select Kubernetes Context", context_list, function(selected_context)
		Command.run_shell_command("kubectl config use-context " .. selected_context)
		callback(selected_context)
	end)
end

function Kubectl.select_namespace(callback)
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

function Kubectl.apply_from_buffer()
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
				log_error("No file selected")
				return
			end

			local result, apply_err =
				Command.run_shell_command("kubectl apply -f " .. file_path .. " -n " .. selected_namespace)
			if result and result ~= "" then
				print("kubectl apply successful: \n" .. result)
			else
				log_error("kubectl apply failed: " .. (apply_err or "Unknown error"))
			end
		end)
	end)
end

function Kubectl.delete_namespace()
	local context_list = fetch_contexts()
	if not context_list then
		return
	end

	TelescopePicker.select_from_list("Select Kubernetes Context", context_list, function(selected_context)
		Command.run_shell_command("kubectl config use-context " .. selected_context)
		Kubectl.select_and_delete_namespace()
	end)
end

function Kubectl.select_and_delete_namespace()
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
				log_error("Failed to delete namespace " .. selected_namespace .. ": " .. (err or "Unknown error"))
			end
		else
			print("Deletion cancelled.")
		end
	end)
end

return Kubectl
