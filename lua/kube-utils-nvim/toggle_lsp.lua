-- module/toggle_lsp.lua
local M = {}

local lspconfig = require("lspconfig")
local lsp = vim.lsp
local config

M.setup = function(opts)
	config = opts
end

-- Function to stop yamlls client
M.stop_yamlls = function()
	for _, client in pairs(lsp.get_clients()) do
		if client.name == "yamlls" then
			client.stop()
		end
	end
end

-- Function to stop helm_ls client
M.stop_helm_ls = function()
	for _, client in pairs(lsp.get_clients()) do
		if client.name == "helm_ls" then
			client.stop()
		end
	end
end

-- Function to start yamlls client
M.start_yamlls = function()
	M.stop_helm_ls() -- Ensure helm_ls is stopped before starting yamlls

	local yamlls_config = {
		on_attach = function()
			-- Add any custom on_attach behavior here if needed
		end,
		settings = {
			yaml = {
				schemaStore = {
					enable = true,
					url = "https://www.schemastore.org/api/json/catalog.json",
				},
				schemas = config.toggle_lsp.schemas,
				validate = true,
				completion = true,
				hover = true,
				format = {
					enable = true,
					bracketSpacing = true,
					printWidth = 80,
					proseWrap = "preserve",
					singleQuote = true,
				},
				customTags = {
					"!Ref",
					"!Sub sequence",
					"!Sub mapping",
					"!GetAtt",
				},
				disableAdditionalProperties = false,
				maxItemsComputed = 5000,
				trace = {
					server = "verbose",
				},
			},
			redhat = {
				telemetry = {
					enabled = false,
				},
			},
		},
	}

	lspconfig.yamlls.setup(yamlls_config)
	lsp.buf.add_workspace_folder(vim.fn.getcwd())

	-- Attach the new yamlls client to the current buffer
	local client_id = lsp.start_client(yamlls_config)
	if client_id then
		lsp.buf_attach_client(0, client_id)
	end
end

-- Function to start helm_ls client
M.start_helm_ls = function()
	M.stop_yamlls() -- Ensure yamlls is stopped before starting helm_ls

	local helm_ls_config = {
		cmd = { "helm_ls" },
		filetypes = { "helm" },
		on_attach = function()
			-- Add any custom on_attach behavior here if needed
		end,
	}

	lspconfig.helm_ls.setup(helm_ls_config)
	lsp.buf.add_workspace_folder(vim.fn.getcwd())

	-- Attach the new helm_ls client to the current buffer
	local client_id = lsp.start_client(helm_ls_config)
	if client_id then
		lsp.buf_attach_client(0, client_id)
	else
	end
end

-- Function to toggle between yaml and helm filetypes
M.toggle_yaml_helm = function()
	if vim.bo.filetype == "yaml" then
		vim.bo.filetype = "helm"
		M.stop_yamlls()
		M.start_helm_ls()
	elseif vim.bo.filetype == "helm" then
		vim.bo.filetype = "yaml"
		M.stop_helm_ls()
		M.start_yamlls()
	end
end

return M
