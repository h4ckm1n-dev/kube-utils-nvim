-- /kube-utils-nvim/lua/init.lua

local M = {}

local Helm = require("kube-utils-nvim.helm")
local Kubectl = require("kube-utils-nvim.kubectl")
local K9s = require("kube-utils-nvim.k9s")
local toggle_lsp = require("kube-utils-nvim.toggle_lsp")

local default_opts = {
	toggle_lsp = {
		schemas = {
			-- ArgoCD ApplicationSet CRD
			["https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/crds/applicationset-crd.yaml"] = "",
			-- ArgoCD Application CRD
			["https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/crds/application-crd.yaml"] = "",
			-- Kubernetes strict schemas
			["https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.29.3-standalone-strict/all.json"] = "",
		},
	},
}

M.setup_commands = function()
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
	vim.api.nvim_create_user_command("StopYamlls", function()
		toggle_lsp.stop_yamlls()
	end, {})
	vim.api.nvim_create_user_command("StartYamlls", function()
		toggle_lsp.start_yamlls()
	end, {})
	vim.api.nvim_create_user_command("ToggleYamlHelm", function()
		toggle_lsp.toggle_yaml_helm()
	end, {})
	vim.api.nvim_create_user_command("SelectCRD", function()
		Kubectl.select_crd()
	end, {})
end

M.setup = function(config)
	local opts = config and vim.tbl_deep_extend("force", default_opts, config) or default_opts

	require("kube-utils-nvim.toggle_lsp").setup(opts)
	M.setup_commands()
end

return M
