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
	require("telescope.pickers")
		.new({}, {
			prompt_title = "Select Kubernetes Context",
			finder = require("telescope.finders").new_table({
				results = context_list,
			}),
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
						require("telescope.pickers")
							.new({}, {
								prompt_title = "Select Namespace",
								finder = require("telescope.finders").new_table({
									results = namespace_list,
								}),
								sorter = require("telescope.config").values.generic_sorter({}),
								attach_mappings = function(_, map)
									map("i", "<CR>", function(ns_prompt_bufnr)
										local namespace_selection =
											require("telescope.actions.state").get_selected_entry(ns_prompt_bufnr)
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
							})
							:find()
					end
				end)
				return true
			end,
		})
		:find()
end

function M.remove_deployment()
    -- Identify the deployment to remove (e.g., by release name or some unique identifier)
    local release_name = vim.fn.input("Enter the release name to remove: ")

    -- Check if release name is provided
    if release_name == "" then
        print("Release name is required.")
        return
    end

    -- Construct the command to delete the deployment
    local delete_cmd = string.format("helm uninstall %s", release_name)

    -- Execute the command to delete the deployment
    local handle, err = io.popen(delete_cmd, "r")

    -- Check if command execution failed
    if not handle then
        print("Failed to remove deployment:", err)
        return
    end

    -- Read the output of the command
    local output = handle:read("*a")
    handle:close()

    -- Check if the command executed successfully
    if output and output ~= "" then
        print("Failed to remove deployment:", output)
    else
        print("Deployment successfully removed.")
    end
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
	require("telescope.pickers")
		.new({}, {
			prompt_title = "Select Kubernetes Context",
			finder = require("telescope.finders").new_table({
				results = context_list,
			}),
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
						require("telescope.pickers")
							.new({}, {
								prompt_title = "Select Namespace",
								finder = require("telescope.finders").new_table({
									results = namespace_list,
								}),
								sorter = require("telescope.config").values.generic_sorter({}),
								attach_mappings = function(_, map)
									map("i", "<CR>", function(ns_prompt_bufnr)
										local namespace_selection =
											require("telescope.actions.state").get_selected_entry(ns_prompt_bufnr)
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
							})
							:find()
					end
				end)
				return true
			end,
		})
		:find()
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
	require("telescope.pickers")
		.new({}, {
			prompt_title = "Select Kubernetes Context",
			finder = require("telescope.finders").new_table({
				results = context_list,
			}),
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
						require("telescope.pickers")
							.new({}, {
								prompt_title = "Select Namespace",
								finder = require("telescope.finders").new_table({
									results = namespace_list,
								}),
								sorter = require("telescope.config").values.generic_sorter({}),
								attach_mappings = function(ns_prompt_bufnr, map)
									map("i", "<CR>", function()
										local namespace_selection =
											require("telescope.actions.state").get_selected_entry(ns_prompt_bufnr)
										require("telescope.actions").close(ns_prompt_bufnr)
										if namespace_selection then
											local namespace = namespace_selection.value
											local file_path = vim.api.nvim_buf_get_name(0)
											if file_path == "" then
												print("No file selected")
												return
											end

											-- Execute the kubectl apply command with specified namespace
											local result, apply_err = run_shell_command(
												"kubectl apply -f " .. file_path .. " -n " .. namespace
											)
											if result and result ~= "" then
												print("kubectl apply successful: \n" .. result)
											else
												print("kubectl apply failed: " .. (apply_err or "Unknown error"))
											end
										end
									end)
									return true
								end,
							})
							:find()
					end
				end)
				return true
			end,
		})
		:find()
end

function M.open_k9s()
    -- Define the terminal command to run K9s
    local k9s_cmd = "k9s"

    -- Create a new floating window
    local width = 0.8  -- Width percentage of the screen
    local height = 0.8  -- Height percentage of the screen
    local x = (1 - width) / 2
    local y = (1 - height) / 2
    local opts = {
        relative = "editor",
        width = math.floor(vim.o.columns * width),
        height = math.floor(vim.o.lines * height),
        col = math.floor(vim.o.columns * x),
        row = math.floor(vim.o.lines * y),
        style = "minimal"
    }

    -- Create a new terminal buffer inside the floating window
    local bufnr = vim.api.nvim_create_buf(false, true)
    local win_id = vim.api.nvim_open_win(bufnr, true, opts)

    -- Run K9s in the terminal buffer
    vim.fn.termopen(k9s_cmd)

    -- Set key mappings to navigate the floating window
    vim.api.nvim_buf_set_keymap(bufnr, "t", "<C-w>q", "<C-\\><C-n>:q<CR>", {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(bufnr, "t", "<C-w>c", "<C-\\><C-n>:q<CR>", {noremap = true, silent = true})
end

function M.open_k9s_split()
    -- Open K9s in a new terminal buffer
    vim.cmd("vnew | terminal k9s")

    -- Set up key mapping to quit the terminal window gracefully
    vim.api.nvim_buf_set_keymap(0, "t", "<C-w>q", "<C-\\><C-n>:q<CR>", {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(0, "t", "<C-w>c", "<C-\\><C-n>:q<CR>", {noremap = true, silent = true})
end

-- Register Neovim commands
function M.setup()
	vim.api.nvim_create_user_command("HelmDeployFromBuffer", M.helm_deploy_from_buffer, {})
	vim.api.nvim_create_user_command("RemoveDeployment", M.remove_deployment, {})
	vim.api.nvim_create_user_command("HelmDryRun", M.helm_dryrun_from_buffer, {})
	vim.api.nvim_create_user_command("KubectlApplyFromBuffer", M.kubectl_apply_from_buffer, {})
	vim.api.nvim_create_user_command("OpenK9s", M.open_k9s, {})
    vim.api.nvim_create_user_command("OpenK9sSplit", M.open_k9s_split, {})
end

return M
