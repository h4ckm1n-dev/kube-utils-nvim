-- /home/h4ckm1n/Documents/Divers/kube-utils-nvim/init.lua
local M = {}

local Helm = require("modules.helm")
local Kubectl = require("modules.kubectl")
local K9s = require("modules.k9s")

function M.setup()
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
end

return M
