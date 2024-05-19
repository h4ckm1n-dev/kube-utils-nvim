-- /home/h4ckm1n/Documents/Divers/kube-utils-nvim/init.lua

local M = {}

local Helm = require("modules.helm")
local Kubectl = require("modules.kubectl")
local K9s = require("modules.k9s")
local toggle_lsp = require("modules.toggle_lsp") -- Include the toggle LSP module

function M.setup()
	-- Define a command to call the Helm.template_from_buffer function
	vim.api.nvim_create_user_command("HelmTemplateFromBuffer", function()
		Helm.template_from_buffer()
	end, {})
	vim.api.nvim_create_user_command("HelmDeployFromBuffer", function()
		Helm.deploy_from_buffer()
	end, {})
	vim.api.nvim_create_user_command("RemoveDeployment", function()
		Helm.remove_deployment()
	end, {})
	vim.api.nvim_create_user_command("HelmDryRun", function()
		Helm.dryrun_from_buffer()
	end, {})
	vim.api.nvim_create_user_command("KubectlApplyFromBuffer", function()
		Kubectl.apply_from_buffer()
	end, {})
	vim.api.nvim_create_user_command("DeleteNamespace", function()
		Kubectl.delete_namespace()
	end, {})
	vim.api.nvim_create_user_command("HelmDependencyUpdateFromBuffer", function()
		Helm.dependency_update_from_buffer()
	end, {})
	vim.api.nvim_create_user_command("HelmDependencyBuildFromBuffer", function()
		Helm.dependency_build_from_buffer()
	end, {})
	vim.api.nvim_create_user_command("OpenK9s", function()
		K9s.open()
	end, {})
	vim.api.nvim_create_user_command("OpenK9sSplit", function()
		K9s.open_split()
	end, {})

	-- Define commands for toggling LSP
	vim.api.nvim_create_user_command("StopYamlls", function()
		toggle_lsp.stop_yamlls()
	end, {})
	vim.api.nvim_create_user_command("StartYamlls", function()
		toggle_lsp.start_yamlls()
	end, {})
	vim.api.nvim_create_user_command("ToggleYamlHelm", function()
		toggle_lsp.toggle_yaml_helm()
	end, {})
end

return M
