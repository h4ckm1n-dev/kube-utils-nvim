local M = {}

local function run_shell_command(cmd)
	-- Attempt to open a pipe to run the command and capture both stdout and stderr
	local handle, err = io.popen(cmd .. " 2>&1", "r")
	if not handle then
		-- If the handle is nil, log the error using print (replace with a logging function if available)
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

function M.get_repository_info(chart_yaml_path)
	local repo_name = ""
	local repo_url = ""

	-- Check if Chart.yaml exists
	if vim.fn.filereadable(chart_yaml_path) == 1 then
		-- Read the contents of Chart.yaml
		local chart_yaml_contents = vim.fn.readfile(chart_yaml_path)

		-- Parse the contents to extract repository information
		for _, line in ipairs(chart_yaml_contents) do
			local key, value = line:match("(%S+)%s*:%s*(.+)")
			if key == "repository" then
				repo_url = value
			elseif key == "name" then
				repo_name = value
			end
		end
	end

	return repo_name, repo_url
end

function M.helm_dependency_update_from_buffer()
	local file_path = vim.api.nvim_buf_get_name(0)
	if file_path == "" then
		print("No file selected")
		return
	end

	local chart_directory = file_path:match("(.*/)")
	local helm_cmd = string.format("helm dependency update %s", chart_directory)

	-- Extract repository information from Chart.yaml
	local chart_yaml_path = chart_directory .. "Chart.yaml"
	local repo_name, repo_url = M.get_repository_info(chart_yaml_path) -- Notice the use of M.

	-- Check if the repository is missing
	local repo_check_cmd =
		string.format("helm repo list | grep -q %s || helm repo add %s %s", repo_name, repo_name, repo_url)
	local _, repo_check_err = run_shell_command(repo_check_cmd)

	-- If the repository is missing, add it before updating dependencies
	if repo_check_err then
		print("Adding missing repository:", repo_check_err)
	end

	-- Execute the dependency update command
	local result, err = run_shell_command(helm_cmd)
	if result then
		print("Helm dependency update successful: \n" .. result)
	else
		print("Helm dependency update failed: " .. (err or "Unknown error"))
	end
end

function M.helm_dependency_build_from_buffer()
	local file_path = vim.api.nvim_buf_get_name(0)
	if file_path == "" then
		print("No file selected")
		return
	end

	local chart_directory = file_path:match("(.*/)")
	local helm_cmd = string.format("helm dependency build %s", chart_directory)
	local result, err = run_shell_command(helm_cmd)
	if result then
		print("Helm dependency build successful: \n" .. result)
	else
		print("Helm dependency build failed: " .. (err or "Unknown error"))
	end
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
			finder = require("telescope.finders").new_table({ results = context_list }),
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

						-- Add the option to create a new namespace
						table.insert(namespace_list, 1, "[Create New Namespace]")

						-- Create a Telescope picker for selecting namespaces
						require("telescope.pickers")
							.new({}, {
								prompt_title = "Select Namespace",
								finder = require("telescope.finders").new_table({ results = namespace_list }),
								sorter = require("telescope.config").values.generic_sorter({}),
								attach_mappings = function(_, ns_map)
									ns_map("i", "<CR>", function(ns_prompt_bufnr)
										local namespace_selection =
											require("telescope.actions.state").get_selected_entry(ns_prompt_bufnr)
										require("telescope.actions").close(ns_prompt_bufnr)
										if namespace_selection then
											if namespace_selection.index == 1 then
												local new_ns_name = vim.fn.input("Enter Namespace Name: ")
												if new_ns_name ~= "" then
													local create_ns_cmd =
														string.format("kubectl create namespace %s", new_ns_name)
													local create_ns_result, create_ns_err =
														run_shell_command(create_ns_cmd)
													if create_ns_result then
														print(
															string.format(
																"Namespace %s created successfully.",
																new_ns_name
															)
														)
														-- Deploy after creating namespace
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
															new_ns_name
														)
														local result, helm_err = run_shell_command(helm_cmd)
														if result and result ~= "" then
															print("Deployment successful: \n" .. result)
														else
															print(
																"Deployment failed: " .. (helm_err or "Unknown error")
															)
														end
													else
														print(
															"Failed to create namespace: "
																.. (create_ns_err or "Unknown error")
														)
													end
												else
													print("Namespace name cannot be empty.")
												end
											else
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
    -- Fetch available contexts
    local contexts, ctx_err = run_shell_command("kubectl config get-contexts -o name")
    if not contexts then
        print(ctx_err or "Failed to fetch Kubernetes contexts.")
        return
    end

    local context_list = vim.split(contexts, "\n", true)
    if #context_list == 0 then
        print("No Kubernetes contexts available.")
        return
    end

    -- Create a Telescope picker for selecting the context
    require("telescope.pickers")
        .new({}, {
            prompt_title = "Select Kubernetes Context",
            finder = require("telescope.finders").new_table({ results = context_list }),
            sorter = require("telescope.config").values.generic_sorter({}),
            attach_mappings = function(_, map)
                map("i", "<CR>", function(ctx_prompt_bufnr)
                    local ctx_selection = require("telescope.actions.state").get_selected_entry(ctx_prompt_bufnr)
                    require("telescope.actions").close(ctx_prompt_bufnr)
                    if ctx_selection then
                        local context = ctx_selection.value

                        -- Set the selected context
                        local set_ctx_cmd = string.format("kubectl config use-context %s", context)
                        local _, set_ctx_err = run_shell_command(set_ctx_cmd)
                        if set_ctx_err then
                            print("Failed to set context:", set_ctx_err)
                            return
                        end

                        -- Fetch available namespaces
                        local namespaces, ns_err =
                            run_shell_command("kubectl get namespaces -o jsonpath='{.items[*].metadata.name}'")
                        if not namespaces then
                            print(ns_err or "Failed to fetch namespaces.")
                            return
                        end

                        local namespace_list = vim.split(namespaces, " ", true)
                        if #namespace_list == 0 then
                            print("No namespaces available.")
                            return
                        end

                        -- Create a table to store namespaces and their associated releases
                        local namespace_release_map = {}

                        -- Iterate over each namespace to fetch release names
                        for _, namespace in ipairs(namespace_list) do
                            local releases = run_shell_command(string.format("helm list -n %s --short", namespace))
                            if releases then
                                local release_list = vim.split(releases, "\n", true)
                                if #release_list > 0 then
                                    namespace_release_map[namespace] = release_list
                                end
                            else
                                print("No releases found in namespace:", namespace)
                            end
                        end

                        -- Check if any releases were found
                        if vim.tbl_isempty(namespace_release_map) then
                            print("No releases found in any namespace.")
                            return
                        end

                        -- Create a Telescope picker for selecting the namespace and release
                        require("telescope.pickers")
                            .new({}, {
                                prompt_title = "Select Namespace and Release to Remove",
                                finder = require("telescope.finders").new_table({ results = namespace_list }),
                                sorter = require("telescope.config").values.generic_sorter({}),
                                attach_mappings = function(_, ns_map)
                                    ns_map("i", "<CR>", function(namespace_prompt_bufnr)
                                        local namespace_selection =
                                            require("telescope.actions.state").get_selected_entry(namespace_prompt_bufnr)
                                        require("telescope.actions").close(namespace_prompt_bufnr)
                                        if namespace_selection then
                                            local namespace = namespace_selection.value
                                            local release_list = namespace_release_map[namespace]
                                            if release_list then
                                                -- Create a Telescope picker for selecting the release
                                                require("telescope.pickers")
                                                    .new({}, {
                                                        prompt_title = "Select Release to Remove",
                                                        finder = require("telescope.finders").new_table({
                                                            results = release_list,
                                                        }),
                                                        sorter = require("telescope.config").values.generic_sorter({}),
                                                        attach_mappings = function(_, rs_map)
                                                            rs_map("i", "<CR>", function(release_prompt_bufnr)
                                                                local release_selection = require(
                                                                    "telescope.actions.state"
                                                                ).get_selected_entry(
                                                                    release_prompt_bufnr
                                                                )
                                                                require("telescope.actions").close(release_prompt_bufnr)
                                                                if release_selection then
                                                                    local release_name = release_selection.value
                                                                    local delete_cmd = string.format(
                                                                        "helm uninstall %s -n %s",
                                                                        release_name,
                                                                        namespace
                                                                    )
                                                                    local result, err = run_shell_command(delete_cmd)
                                                                    if result then
                                                                        print(
                                                                            "Deployment "
                                                                                .. release_name
                                                                                .. " successfully removed."
                                                                        )
                                                                    else
                                                                        print(
                                                                            "Failed to remove deployment "
                                                                                .. release_name
                                                                                .. ":",
                                                                            err
                                                                        )
                                                                    end
                                                                end
                                                            end)
                                                            return true
                                                        end,
                                                    })
                                                    .find()
                                            else
                                                print("No releases found in namespace " .. namespace)
                                            end
                                        end
                                    end)
                                    return true
                                end,
                            })
                            .find()
                    end
                end)
                return true
            end,
        })
        .find()
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
								attach_mappings = function(ns_prompt_bufnr, ns_map)
									ns_map("i", "<CR>", function()
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
											local result, ns_err = run_shell_command(helm_cmd) -- change from err to ns_err

											-- Open a new tab and create a buffer
											vim.cmd("tabnew")
											local bufnr = vim.api.nvim_create_buf(false, true)
											vim.api.nvim_buf_set_option(bufnr, "filetype", "yaml")
											if result and result ~= "" then
												vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, vim.split(result, "\n"))
											else
												print("Dry run failed: " .. (ns_err or "Unknown error")) -- change from err to ns_err
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
								attach_mappings = function(ns_prompt_bufnr, ns_map)
									ns_map("i", "<CR>", function()
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

function M.delete_namespace()
	-- Fetch available contexts
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

	-- Create a Telescope picker for selecting the Kubernetes context
	require("telescope.pickers")
		.new({}, {
			prompt_title = "Select Kubernetes Context",
			finder = require("telescope.finders").new_table({ results = context_list }),
			sorter = require("telescope.config").values.generic_sorter({}),
			attach_mappings = function(_, map)
				map("i", "<CR>", function(prompt_bufnr)
					local context_selection = require("telescope.actions.state").get_selected_entry(prompt_bufnr)
					require("telescope.actions").close(prompt_bufnr)
					if context_selection then
						-- Use the selected context
						run_shell_command("kubectl config use-context " .. context_selection.value)
						-- Proceed to namespace selection
						M.select_and_delete_namespace()
					end
				end)
				return true
			end,
		})
		:find()
end

function M.select_and_delete_namespace()
	-- Fetch available namespaces
	local namespaces, ns_err = run_shell_command("kubectl get namespaces -o jsonpath='{.items[*].metadata.name}'")
	if not namespaces then
		print(ns_err or "Failed to fetch namespaces.")
		return
	end

	local namespace_list = vim.split(namespaces, " ", true)
	if #namespace_list == 0 then
		print("No namespaces available.")
		return
	end

	-- Create a Telescope picker for selecting the namespace
	require("telescope.pickers")
		.new({}, {
			prompt_title = "Select Namespace to Delete",
			finder = require("telescope.finders").new_table({ results = namespace_list }),
			sorter = require("telescope.config").values.generic_sorter({}),
			attach_mappings = function(_, map)
				map("i", "<CR>", function(prompt_bufnr)
					local namespace_selection = require("telescope.actions.state").get_selected_entry(prompt_bufnr)
					require("telescope.actions").close(prompt_bufnr)
					if namespace_selection then
						local namespace = namespace_selection.value

						-- Confirm deletion with user
						local confirm_delete = vim.fn.input("Delete namespace " .. namespace .. "? [y/N]: ")
						if confirm_delete == "y" or confirm_delete == "Y" then
							-- Construct the command to delete the namespace
							local delete_cmd = string.format("kubectl delete namespace %s", namespace)

							-- Execute the command to delete the namespace
							local result, err = run_shell_command(delete_cmd)

							-- Check if deletion was successful
							if result then
								print("Namespace " .. namespace .. " successfully deleted.")
							else
								print("Failed to delete namespace " .. namespace .. ":", err)
							end
						else
							print("Deletion cancelled.")
						end
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

	-- Calculate window dimensions and position based on the editor's size
	local width = 0.8 -- Width percentage of the screen
	local height = 0.8 -- Height percentage of the screen
	local x = (1 - width) / 2
	local y = (1 - height) / 2
	local opts = {
		relative = "editor",
		width = math.floor(vim.o.columns * width),
		height = math.floor(vim.o.lines * height),
		col = math.floor(vim.o.columns * x),
		row = math.floor(vim.o.lines * y),
		style = "minimal",
	}

	-- Create a new terminal buffer and open it in a floating window
	local bufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_open_win(bufnr, true, opts)

	-- Run K9s in the newly created terminal buffer
	vim.fn.termopen(k9s_cmd)

	-- Set key mappings to manage the floating window and interactions
	vim.api.nvim_buf_set_keymap(bufnr, "t", "<C-w>q", "<C-\\><C-n>:q<CR>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(bufnr, "t", "<C-w>c", "<C-\\><C-n>:q<CR>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(bufnr, "t", "<C-c>", "<C-\\><C-n>", { noremap = true, silent = true })
end

function M.open_k9s_split()
	-- Open K9s in a new terminal buffer
	vim.cmd("vnew | terminal k9s")

	-- Set up key mapping to quit the terminal window gracefully
	vim.api.nvim_buf_set_keymap(0, "t", "<C-w>q", "<C-\\><C-n>:q<CR>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(0, "t", "<C-w>c", "<C-\\><C-n>:q<CR>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(0, "t", "<C-c>", "<C-\\><C-n>", { noremap = true, silent = true })
end

-- Register Neovim commands
function M.setup()
	vim.api.nvim_create_user_command("HelmDeployFromBuffer", M.helm_deploy_from_buffer, {})
	vim.api.nvim_create_user_command("RemoveDeployment", M.remove_deployment, {})
	vim.api.nvim_create_user_command("HelmDryRun", M.helm_dryrun_from_buffer, {})
	vim.api.nvim_create_user_command("KubectlApplyFromBuffer", M.kubectl_apply_from_buffer, {})
	vim.api.nvim_create_user_command("DeleteNamespace", M.delete_namespace, {})
	vim.api.nvim_create_user_command("HelmDependencyUpdateFromBuffer", M.helm_dependency_update_from_buffer, {})
	vim.api.nvim_create_user_command("HelmDependencyBuildFromBuffer", M.helm_dependency_build_from_buffer, {})
	vim.api.nvim_create_user_command("OpenK9s", M.open_k9s, {})
	vim.api.nvim_create_user_command("OpenK9sSplit", M.open_k9s_split, {})
end

return M
