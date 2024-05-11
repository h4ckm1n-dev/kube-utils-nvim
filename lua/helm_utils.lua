local M = {}

-- Importing telescope module
local telescope = require("telescope.builtin")

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
    -- First, fetch available contexts
    local contexts, context_err = run_shell_command("kubectl config get-contexts -o name")
    if not contexts then
        print(context_err or "Failed to fetch Kubernetes contexts.")
        return
    end

    local context_list = vim.split(contexts, "\n", true)
    if #context_list == 0 then
        print("No Kubernetes contexts available.")
        return
    end

    -- Create a Telescope picker for selecting Kubernetes context
    require("telescope.pickers").new({}, {
        prompt_title = "Select Kubernetes Context",
        finder = require("telescope.finders").new_table {
            results = context_list,
        },
        sorter = require("telescope.config").values.generic_sorter({}),
        attach_mappings = function(_, map)
            map("i", "<CR>", function(prompt_bufnr)
                local context_selection = require("telescope.actions.state").get_selected_entry(prompt_bufnr)
                require("telescope.actions").close(prompt_bufnr)
                if context_selection then
                    -- Use the selected context
                    run_shell_command("kubectl config use-context " .. context_selection.value)
                    -- Now fetch namespaces after context is selected
                    local namespaces, err = run_shell_command("kubectl get namespaces | awk 'NR>1 {print $1}'")
                    if not namespaces then
                        print("Failed to fetch namespaces: " .. (err or "No namespaces found."))
                        return
                    end

                    local namespace_list = vim.split(namespaces, "\n", true)
                    if #namespace_list == 0 then
                        print("No namespaces available.")
                        return
                    end

                    -- Create a Telescope picker for selecting namespaces
                    require("telescope.pickers").new({}, {
                        prompt_title = "Select Namespace",
                        finder = require("telescope.finders").new_table {
                            results = namespace_list,
                        },
                        sorter = require("telescope.config").values.generic_sorter({}),
                        attach_mappings = function(_, map)
                            map("i", "<CR>", function(ns_prompt_bufnr)
                                local namespace_selection = require("telescope.actions.state").get_selected_entry(ns_prompt_bufnr)
                                require("telescope.actions").close(ns_prompt_bufnr)
                                if namespace_selection then
                                    local namespace = namespace_selection.value
                                    local file_path = vim.api.nvim_buf_get_name(0)
                                    if file_path == "" then
                                        print("No file selected")
                                        return
                                    end
                                    local chart_directory = file_path:match("(.*/)")
                                    local chart_name = vim.fn.input("Enter Release Name: ")
                                    local helm_cmd = string.format(
                                        "helm upgrade --install %s %s --values %s -n %s --create-namespace",
                                        chart_name,
                                        chart_directory,
                                        file_path,
                                        namespace
                                    )
                                    local result, helm_err = run_shell_command(helm_cmd)
                                    if result and result ~= "" then
                                        print("Deployment successful: \n" .. result)
                                    else
                                        print("Deployment failed: " .. (helm_err or "Unknown error"))
                                    end
                                end
                            end)
                            return true
                        end,
                    }):find()
                end
            end)
            return true
        end,
    }):find()
end

function M.helm_dryrun_from_buffer()
    -- First, fetch available contexts
    local contexts, context_err = run_shell_command("kubectl config get-contexts -o name")
    if not contexts then
        print(context_err or "Failed to fetch Kubernetes contexts.")
        return
    end

    local context_list = vim.split(contexts, "\n", true)
    if #context_list == 0 then
        print("No Kubernetes contexts available.")
        return
    end

    -- Create a Telescope picker for selecting Kubernetes context
    require("telescope.pickers").new({}, {
        prompt_title = "Select Kubernetes Context",
        finder = require("telescope.finders").new_table {
            results = context_list,
        },
        sorter = require("telescope.config").values.generic_sorter({}),
        attach_mappings = function(_, map)
            map("i", "<CR>", function(prompt_bufnr)
                local context_selection = require("telescope.actions.state").get_selected_entry(prompt_bufnr)
                require("telescope.actions").close(prompt_bufnr)
                if context_selection then
                    -- Use the selected context
                    run_shell_command("kubectl config use-context " .. context_selection.value)

                    -- Now fetch namespaces after context is selected
                    local namespaces, err = run_shell_command("kubectl get namespaces | awk 'NR>1 {print $1}'")
                    if not namespaces then
                        print("Failed to fetch namespaces: " .. (err or "No namespaces found."))
                        return
                    end

                    local namespace_list = vim.split(namespaces, "\n", true)
                    if #namespace_list == 0 then
                        print("No namespaces available.")
                        return
                    end

                    -- Create a Telescope picker for selecting namespaces
                    require("telescope.pickers").new({}, {
                        prompt_title = "Select Namespace",
                        finder = require("telescope.finders").new_table {
                            results = namespace_list,
                        },
                        sorter = require("telescope.config").values.generic_sorter({}),
                        attach_mappings = function(_, map)
                            map("i", "<CR>", function(ns_prompt_bufnr)
                                local namespace_selection = require("telescope.actions.state").get_selected_entry(ns_prompt_bufnr)
                                require("telescope.actions").close(ns_prompt_bufnr)
                                if namespace_selection then
                                    local namespace = namespace_selection.value
                                    local file_path = vim.api.nvim_buf_get_name(0)
                                    if file_path == "" then
                                        print("No file selected")
                                        return
                                    end
                                    local chart_directory = file_path:match("(.*/)")
                                    local chart_name = vim.fn.input("Enter Release Name: ")
                                    local helm_cmd = string.format(
                                        "helm install --dry-run %s %s --values %s -n %s --create-namespace",
                                        chart_name,
                                        chart_directory,
                                        file_path,
                                        namespace
                                    )
                                    local result = run_shell_command(helm_cmd)
                                    
                                    -- Open a new tab and create a buffer
                                    vim.cmd("tabnew")
                                    local bufnr = vim.api.nvim_create_buf(false, true)
                                    vim.api.nvim_buf_set_option(bufnr, "filetype", "yaml")
                                    if result and result ~= "" then
                                        vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, vim.split(result, "\n"))
                                    else
                                        print("Dry run failed: " .. (err or "Unknown error"))
                                    end
                                    -- Switch to the new buffer
                                    vim.api.nvim_set_current_buf(bufnr)
                                end
                            end)
                            return true
                        end,
                    }):find()
                end
            end)
            return true
        end,
    }):find()
end


function M.kubectl_apply_from_buffer()
    -- First, fetch available contexts
    local contexts, context_err = run_shell_command("kubectl config get-contexts -o name")
    if not contexts then
        print(context_err or "Failed to fetch Kubernetes contexts.")
        return
    end

    local context_list = vim.split(contexts, "\n", true)
    if #context_list == 0 then
        print("No Kubernetes contexts available.")
        return
    end

    -- Create a Telescope picker for selecting Kubernetes context
    require("telescope.pickers").new({}, {
        prompt_title = "Select Kubernetes Context",
        finder = require("telescope.finders").new_table {
            results = context_list,
        },
        sorter = require("telescope.config").values.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
            map("i", "<CR>", function()
                local context_selection = require("telescope.actions.state").get_selected_entry(prompt_bufnr)
                require("telescope.actions").close(prompt_bufnr)
                if context_selection then
                    -- Use the selected context
                    run_shell_command("kubectl config use-context " .. context_selection.value)

                    -- Now fetch namespaces after context is selected
                    local namespaces, err = run_shell_command("kubectl get namespaces | awk 'NR>1 {print $1}'")
                    if not namespaces then
                        print("Failed to fetch namespaces: " .. (err or "No namespaces found."))
                        return
                    end

                    local namespace_list = vim.split(namespaces, "\n", true)
                    if #namespace_list == 0 then
                        print("No namespaces available.")
                        return
                    end

                    -- Create a Telescope picker for selecting namespaces
                    require("telescope.pickers").new({}, {
                        prompt_title = "Select Namespace",
                        finder = require("telescope.finders").new_table {
                            results = namespace_list,
                        },
                        sorter = require("telescope.config").values.generic_sorter({}),
                        attach_mappings = function(ns_prompt_bufnr, map)
                            map("i", "<CR>", function()
                                local namespace_selection = require("telescope.actions.state").get_selected_entry(ns_prompt_bufnr)
                                require("telescope.actions").close(ns_prompt_bufnr)
                                if namespace_selection then
                                    local namespace = namespace_selection.value
                                    local file_path = vim.api.nvim_buf_get_name(0)
                                    if file_path == "" then
                                        print("No file selected")
                                        return
                                    end

                                    -- Execute the kubectl apply command with specified namespace
                                    local result, apply_err = run_shell_command("kubectl apply -f " .. file_path .. " -n " .. namespace)
                                    if result and result ~= "" then
                                        print("kubectl apply successful: \n" .. result)
                                    else
                                        print("kubectl apply failed: " .. (apply_err or "Unknown error"))
                                    end
                                end
                            end)
                            return true
                        end,
                    }):find()
                end
            end)
            return true
        end,
    }):find()
end

function M.open_k9s()
    -- Calculate 80% of the current screen height
    local height = math.floor(vim.o.lines * 0.8)

    -- Create a floating window with a new terminal running K9s
    vim.cmd('botright ' .. height .. 'new | setlocal nobuflisted | setlocal buftype=terminal | setlocal nonumber | setlocal norelativenumber | start term://k9s')
    -- Resize the floating window to a suitable size
    vim.cmd('resize ' .. height)
    -- Set some additional options for a better appearance
    vim.cmd('setlocal winblend=10') -- Adds transparency to the floating window
    vim.cmd('setlocal winhighlight=Normal:Float') -- Applies a different highlight group for the window
end

-- Register Neovim commands
function M.setup()
	vim.api.nvim_create_user_command("HelmDeployFromBuffer", M.helm_deploy_from_buffer, {})
	vim.api.nvim_create_user_command("HelmDryRun", M.helm_dryrun_from_buffer, {})
	vim.api.nvim_create_user_command("KubectlApplyFromBuffer", M.kubectl_apply_from_buffer, {})
    vim.api.nvim_create_user_command("OpenK9s", M.open_k9s, {})
end

return M