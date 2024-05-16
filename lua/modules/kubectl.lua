-- modules/kubectl.lua
local Command = require("modules.command")
local TelescopePicker = require("modules.telescope_picker")

local Kubectl = {}

function Kubectl.apply_from_buffer()
    -- First, fetch available contexts
    local contexts, context_err = Command.run_shell_command("kubectl config get-contexts -o name")
    if not contexts then
        print(context_err or "Failed to fetch Kubernetes contexts.")
        return
    end

    local context_list = vim.split(contexts, "\n", true)
    if #context_list == 0 then
        print("No Kubernetes contexts available.")
        return
    end

    -- Select Kubernetes context
    TelescopePicker.select_from_list("Select Kubernetes Context", context_list, function(selected_context)
        Command.run_shell_command("kubectl config use-context " .. selected_context)

        -- Fetch namespaces after context is selected
        local namespaces, err = Command.run_shell_command("kubectl get namespaces | awk 'NR>1 {print $1}'")
        if not namespaces then
            print("Failed to fetch namespaces: " .. (err or "No namespaces found."))
            return
        end

        local namespace_list = vim.split(namespaces, "\n", true)
        if #namespace_list == 0 then
            print("No namespaces available.")
            return
        end

        -- Select namespace
        TelescopePicker.select_from_list("Select Namespace", namespace_list, function(selected_namespace)
            local file_path = vim.api.nvim_buf_get_name(0)
            if file_path == "" then
                print("No file selected")
                return
            end

            -- Execute the kubectl apply command with specified namespace
            local result, apply_err = Command.run_shell_command(
                "kubectl apply -f " .. file_path .. " -n " .. selected_namespace
            )
            if result and result ~= "" then
                print("kubectl apply successful: \n" .. result)
            else
                print("kubectl apply failed: " .. (apply_err or "Unknown error"))
            end
        end)
    end)
end

function Kubectl.delete_namespace()
    -- Fetch available contexts
    local contexts, context_err = Command.run_shell_command("kubectl config get-contexts -o name")
    if not contexts then
        print(context_err or "Failed to fetch Kubernetes contexts.")
        return
    end

    local context_list = vim.split(contexts, "\n", true)
    if #context_list == 0 then
        print("No Kubernetes contexts available.")
        return
    end

    -- Select Kubernetes context
    TelescopePicker.select_from_list("Select Kubernetes Context", context_list, function(selected_context)
        Command.run_shell_command("kubectl config use-context " .. selected_context)
        -- Proceed to namespace selection
        Kubectl.select_and_delete_namespace()
    end)
end

function Kubectl.select_and_delete_namespace()
    -- Fetch available namespaces
    local namespaces, ns_err = Command.run_shell_command(
    "kubectl get namespaces -o jsonpath='{.items[*].metadata.name}'")
    if not namespaces then
        print(ns_err or "Failed to fetch namespaces.")
        return
    end

    local namespace_list = vim.split(namespaces, " ", true)
    if #namespace_list == 0 then
        print("No namespaces available.")
        return
    end

    -- Select namespace
    TelescopePicker.select_from_list("Select Namespace to Delete", namespace_list, function(selected_namespace)
        -- Confirm deletion with user
        local confirm_delete = vim.fn.input("Delete namespace " .. selected_namespace .. "? [y/N]: ")
        if confirm_delete == "y" or confirm_delete == "Y" then
            -- Construct the command to delete the namespace
            local delete_cmd = string.format("kubectl delete namespace %s", selected_namespace)

            -- Execute the command to delete the namespace
            local result, err = Command.run_shell_command(delete_cmd)

            -- Check if deletion was successful
            if result then
                print("Namespace " .. selected_namespace .. " successfully deleted.")
            else
                print("Failed to delete namespace " .. selected_namespace .. ":", err)
            end
        else
            print("Deletion cancelled.")
        end
    end)
end

return Kubectl
