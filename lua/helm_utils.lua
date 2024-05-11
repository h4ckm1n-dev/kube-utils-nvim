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
    -- Fetch available namespaces using kubectl
    local namespaces, err = run_shell_command("kubectl get namespaces --output=jsonpath={.items[*].metadata.name '\\n'}")
    if not namespaces then
        print("Failed to fetch namespaces: " .. (err or ""))
        return
    end

    -- Trim the last newline to prevent an empty entry
    namespaces = namespaces:gsub("%s+$", "")

    -- Split namespaces into a table
    local namespace_list = vim.split(namespaces, "\n", true)

    -- Create a table to hold individual namespace entries
    local formatted_namespaces = {}
    for _, namespace in ipairs(namespace_list) do
        table.insert(formatted_namespaces, { value = namespace, display = namespace })
    end

    -- Create a Telescope picker for selecting namespaces
    require("telescope.pickers").new({}, {
        prompt_title = "Select Namespace",
        finder = require("telescope.finders").new_table {
            results = formatted_namespaces,
        },
        sorter = require("telescope.config").values.generic_sorter({}),
        attach_mappings = function(_, map)
            map("i", "<CR>", function(prompt_bufnr)
                local selection = require("telescope.actions.state").get_selected_entry(prompt_bufnr)
                require("telescope.actions").close(prompt_bufnr)
                if selection then
                    local namespace = selection.value
                    -- Fetch the current file path from the buffer
                    local file_path = vim.api.nvim_buf_get_name(0)
                    if file_path == "" then
                        print("No file selected")
                        return
                    end

                    -- Parse file path to extract chart directory
                    local chart_directory = file_path:match("(.*/)") or ""

                    -- Prompt user for input regarding release name
                    local chart_name = vim.fn.input("Enter Release Name: ")

                    -- Construct the Helm command using the buffer's file as the values file
                    local helm_cmd = string.format(
                        "helm upgrade --install %s %s --values %s -n %s --create-namespace",
                        chart_name,
                        chart_directory,
                        file_path,
                        namespace
                    )

                    -- Execute the Helm command
                    local result, err = run_shell_command(helm_cmd)
                    if result and result ~= "" then
                        print("Deployment successful: \n" .. result)
                    else
                        print("Deployment failed: " .. (err or "Unknown error"))
                    end
                end
            end)
            return true
        end,
    }):find()
end


function M.helm_dryrun_from_buffer()
    -- Fetch available namespaces using kubectl
    local namespaces, err = run_shell_command("kubectl get namespaces --output=jsonpath={.items[*].metadata.name}")
    if not namespaces then
        print("Failed to fetch namespaces: " .. (err or ""))
        return
    end

    -- Split namespaces into a table
    local namespace_list = vim.split(namespaces, "\n", true)

    -- Format namespaces into a table with separate entries
    local formatted_namespaces = {}
    for _, namespace in ipairs(namespace_list) do
        table.insert(formatted_namespaces, { value = namespace, display = namespace, ordinal = namespace })
    end

    -- Define Telescope picker to select namespace
    vim.ui.select(formatted_namespaces, { prompt = "Select Namespace:" }, function(choice)
        if choice then
            local namespace = choice
            -- Fetch the current file path from the buffer
            local file_path = vim.api.nvim_buf_get_name(0)
            if file_path == "" then
                print("No file selected")
                return
            end

            -- Parse file path to extract chart directory
            local chart_directory = file_path:match("(.*/)") or ""

            -- Prompt user for input regarding release name
            local chart_name = vim.fn.input("Enter Release Name: ")

            -- Construct the Helm dry run command using the buffer's file as the values file
            local helm_cmd = string.format(
                "helm install --dry-run %s %s --values %s -n %s --create-namespace 2>&1 | grep -v '^debug'",
                chart_name,
                chart_directory,
                file_path,
                namespace
            )

            -- Execute the Helm dry run command
            local result = run_shell_command(helm_cmd)

            -- Open a new tab
            vim.cmd("tabnew")

            -- Create a new buffer
            local bufnr = vim.api.nvim_create_buf(false, true)

            -- Set the filetype to YAML
            vim.api.nvim_buf_set_option(bufnr, "filetype", "yaml")

            -- Print the output in the new buffer in Neovim
            if result and result ~= "" then
                vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, vim.split(result, "\n"))
            else
                print("Dry run failed or no output returned.")
            end

            -- Switch to the new buffer
            vim.api.nvim_set_current_buf(bufnr)
        else
            print("No namespace selected.")
        end
    end)
end

function M.kubectl_apply_from_buffer()
    -- Fetch available namespaces using kubectl
    local namespaces, err = run_shell_command("kubectl get namespaces --output=jsonpath={.items[*].metadata.name}")
    if not namespaces then
        print("Failed to fetch namespaces: " .. (err or ""))
        return
    end

    -- Split namespaces into a table
    local namespace_list = vim.split(namespaces, "\n", true)

    -- Format namespaces into a table with separate entries
    local formatted_namespaces = {}
    for _, namespace in ipairs(namespace_list) do
        table.insert(formatted_namespaces, { value = namespace, display = namespace, ordinal = namespace })
    end

    -- Define Telescope picker to select namespace
    vim.ui.select(formatted_namespaces, { prompt = "Select Namespace:" }, function(choice)
        if choice then
            local namespace = choice
            -- Fetch the current file path from the buffer
            local file_path = vim.api.nvim_buf_get_name(0)
            if file_path == "" then
                print("No file selected")
                return
            end

            -- Execute the kubectl apply command with specified namespace
            local result = run_shell_command("kubectl apply -f " .. file_path .. " -n " .. namespace)

            if result and result ~= "" then
                print("kubectl apply successful: \n" .. result)
            else
                print("kubectl apply failed or no output returned.")
            end
        else
            print("No namespace selected.")
        end
    end)
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
			local result, switch_error_message = run_shell_command("kubectl config use-context " .. choice)
			if result then
				print("Switched to context: " .. choice)
			else
				print(switch_error_message or "Failed to switch context.")
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
	vim.api.nvim_create_user_command("KubectlApplyFromBuffer", M.kubectl_apply_from_buffer, {})
end

return M
