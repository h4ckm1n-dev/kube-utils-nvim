-- modules/helm.lua
local Command = require("modules.command")
local Repository = require("modules.repository")
local TelescopePicker = require("modules.telescope_picker")

local Helm = {}

function Helm.dependency_update_from_buffer()
    local file_path = vim.api.nvim_buf_get_name(0)
    if file_path == "" then
        print("No file selected")
        return
    end

    local chart_directory = file_path:match("(.*/)")
    local helm_cmd = string.format("helm dependency update %s", chart_directory)

    -- Extract repository information from Chart.yaml
    local chart_yaml_path = chart_directory .. "Chart.yaml"
    local repo_name, repo_url = Repository.get_repository_info(chart_yaml_path)

    -- Check if the repository is missing
    local repo_check_cmd =
        string.format("helm repo list | grep -q %s || helm repo add %s %s", repo_name, repo_name, repo_url)
    local _, repo_check_err = Command.run_shell_command(repo_check_cmd)

    -- If the repository is missing, add it before updating dependencies
    if repo_check_err then
        print("Adding missing repository:", repo_check_err)
    end

    -- Execute the dependency update command
    local result, err = Command.run_shell_command(helm_cmd)
    if result then
        print("Helm dependency update successful: \n" .. result)
    else
        print("Helm dependency update failed: " .. (err or "Unknown error"))
    end
end

function Helm.dependency_build_from_buffer()
    local file_path = vim.api.nvim_buf_get_name(0)
    if file_path == "" then
        print("No file selected")
        return
    end

    local chart_directory = file_path:match("(.*/)")
    local helm_cmd = string.format("helm dependency build %s", chart_directory)
    local result, err = Command.run_shell_command(helm_cmd)
    if result then
        print("Helm dependency build successful: \n" .. result)
    else
        print("Helm dependency build failed: " .. (err or "Unknown error"))
    end
end

function Helm.deploy_from_buffer()
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

        -- Add the option to create a new namespace
        table.insert(namespace_list, 1, "[Create New Namespace]")

        -- Select namespace
        TelescopePicker.select_from_list("Select Namespace", namespace_list, function(selected_namespace)
            if selected_namespace == "[Create New Namespace]" then
                TelescopePicker.input("Enter Namespace Name", function(new_ns_name)
                    local create_ns_cmd = string.format("kubectl create namespace %s", new_ns_name)
                    local create_ns_result, create_ns_err = Command.run_shell_command(create_ns_cmd)
                    if create_ns_result then
                        print(string.format("Namespace %s created successfully.", new_ns_name))
                        Helm.perform_deploy(new_ns_name)
                    else
                        print("Failed to create namespace: " .. (create_ns_err or "Unknown error"))
                    end
                end)
            else
                Helm.perform_deploy(selected_namespace)
            end
        end)
    end)
end

function Helm.perform_deploy(namespace)
    local file_path = vim.api.nvim_buf_get_name(0)
    if file_path == "" then
        print("No file selected")
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
            print("Deployment failed: " .. (helm_err or "Unknown error"))
        end
    end)
end

function Helm.dryrun_from_buffer()
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
            local chart_directory = file_path:match("(.*/)")
            TelescopePicker.input("Enter Release Name", function(chart_name)
                local helm_cmd = string.format(
                    "helm install --dry-run %s %s --values %s -n %s --create-namespace",
                    chart_name,
                    chart_directory,
                    file_path,
                    selected_namespace
                )
                local result, ns_err = Command.run_shell_command(helm_cmd)

                -- Open a new tab and create a buffer
                vim.cmd("tabnew")
                local bufnr = vim.api.nvim_create_buf(false, true)
                vim.api.nvim_buf_set_option(bufnr, "filetype", "yaml")
                if result and result ~= "" then
                    vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, vim.split(result, "\n"))
                else
                    print("Dry run failed: " .. (ns_err or "Unknown error"))
                end
                -- Switch to the new buffer
                vim.api.nvim_set_current_buf(bufnr)
            end)
        end)
    end)
end

return Helm
