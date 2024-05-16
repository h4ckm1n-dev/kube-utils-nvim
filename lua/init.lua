-- init.lua
local M = {}

local Helm = require("modules.helm")
local Kubectl = require("modules.kubectl")
local K9s = require("modules.k9s")

function M.setup()
    vim.api.nvim_create_user_command("HelmDeployFromBuffer", Helm.deploy_from_buffer, {})
    vim.api.nvim_create_user_command("RemoveDeployment", Kubectl.remove_deployment, {})
    vim.api.nvim_create_user_command("HelmDryRun", Helm.dryrun_from_buffer, {})
    vim.api.nvim_create_user_command("KubectlApplyFromBuffer", Kubectl.apply_from_buffer, {})
    vim.api.nvim_create_user_command("DeleteNamespace", Kubectl.delete_namespace, {})
    vim.api.nvim_create_user_command("HelmDependencyUpdateFromBuffer", Helm.dependency_update_from_buffer, {})
    vim.api.nvim_create_user_command("HelmDependencyBuildFromBuffer", Helm.dependency_build_from_buffer, {})
    vim.api.nvim_create_user_command("OpenK9s", K9s.open, {})
    vim.api.nvim_create_user_command("OpenK9sSplit", K9s.open_split, {})
end

return M
