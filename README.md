# Neovim Kubernetes Plugin

For the lazy, you can install my full config lazyvim with kube-utils-nvim installed [[template]](https://github.com/h4ckm1n-dev/h4ckm1n-lazyvim-template)

![All Contributors](https://img.shields.io/badge/all_contributors-2-orange.svg?style=flat-square)

This Neovim plugin provides seamless integration with Kubernetes and Helm, allowing you to deploy and manage Kubernetes resources directly from your editor.

## Features
- **Kubernetes Context and Namespace Management**: Easily switch between different Kubernetes contexts and namespaces.
- **CRD Viewer:** View Custom Resource Definitions directly in Neovim.
- **Helm Integration:** Manage Helm charts, update dependencies, and deploy directly from Neovim.
- **Log Viewer and Formatting:** Transform Kubernetes log files into a more readable JSON format.
- **Telescope Integration:** Utilize Telescope for picking Kubernetes contexts, namespaces, and viewing Helm releases.
- **LSP Integration:** Toggle YAML and Helm LSP settings based on the context within Neovim.
- **K9s Integration:** Open k9s from nvim

#### Screenshots
Here are some visual previews of the plugin in action

Telescope NS selector :
- ![Screenshot 1](https://github.com/h4ckm1n-dev/kube-utils-nvim/assets/97511408/bbfe3a51-6117-413f-9d31-9f66517994c2)
K9S module:
- ![Screenshot 2](https://github.com/h4ckm1n-dev/kube-utils-nvim/assets/97511408/c6139ddf-e9af-4665-bd57-a829b236bac2)
K9S in a vertical split view :
- ![Screenshot 3](https://github.com/h4ckm1n-dev/kube-utils-nvim/assets/97511408/8c3cbaf8-d3c0-44a8-b487-4858e06b86f7)
Get CRD function :
- ![Screenshot 4](https://github.com/h4ckm1n-dev/kube-utils-nvim/assets/97511408/b5c1158e-5c93-41aa-b9ee-6fa5e2d0cb2b)
Get Log and FormatJson :
- ![image](https://github.com/h4ckm1n-dev/kube-utils-nvim/assets/97511408/52c7ecc8-9bb7-4dc0-a0cb-8e886d4ce645)

![Capture Video Preview](https://github.com/h4ckm1n-dev/kube-utils-nvim/assets/97511408/d575048c-2f88-415a-a62f-90db935d6951)

## Installation

Install the plugin using your preferred Neovim package manager. Example for `lazy.nvim`:

```lua
-- ~/.config/nvim/lua/plugins/kube-utils.lua
return {
  {
    "h4ckm1n-dev/kube-utils-nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    lazy = true,
    event = "VeryLazy"
  },
}

```
## Key Bindings
Use the following mappings to access Kubernetes features efficiently:
```lua
local helm_mappings = {
  k = {
    name = "Kubernetes", -- Main title for all Kubernetes related commands

    -- Helm Commands
    h = {
      name = "+Helm",
      d = { "<cmd>HelmDeployFromBuffer<CR>", "Helm Deploy Buffer to Context" },
      r = { "<cmd>RemoveDeployment<CR>", "Helm Remove Deployment From Buffer" },
      T = { "<cmd>HelmDryRun<CR>", "Helm DryRun Buffer" },
      u = { "<cmd>HelmDependencyUpdateFromBuffer<CR>", "Helm Dependency Update" },
      b = { "<cmd>HelmDependencyBuildFromBuffer<CR>", "Helm Dependency Build" },
      t = { "<cmd>HelmTemplateFromBuffer<CR>", "Helm Template From Buffer" },
    },

    -- Kubectl Commands
    k = {
      name = "+Kubectl",
      a = { "<cmd>KubectlApplyFromBuffer<CR>", "Kubectl Apply From Buffer" },
      D = { "<cmd>DeleteNamespace<CR>", "Kubectl Delete Namespace" },
      K = { "<cmd>OpenK9s<CR>", "Open K9s" },
      k = { "<cmd>OpenK9sSplit<CR>", "Split View K9s" },
      l = { "<cmd>ToggleYamlHelm<CR>", "Toggle YAML/Helm" },
      c = { "<cmd>SelectCRD<CR>", "Download CRD" },
      C = { "<cmd>SelectSplitCRD<CR>", "Download CRD Split" },
    },

    -- Logs Commands
    l = {
      name = "+Logs",
      f = { "<cmd>JsonFormatLogs<CR>", "Format JSON" },
      v = { "<cmd>ViewPodLogs<CR>", "View Pod Logs" },
    },
  },
}

-- Register the Helm keybindings with a specific prefix
require('which-key').register(helm_mappings, { prefix = "<leader>" })
```
## Requirements

- Neovim 0.9.0 or higher
- Helm
- kubectl
- k9s

## Configuration

No additional configuration is required. Simply install the plugin and start using the commands.

## License

This plugin is licensed under the MIT License. See the LICENSE file for details., also feel free to submit a PR

## Contributors ✨

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/h4ckm1n-dev"><img src="https://avatars.githubusercontent.com/u/97511408?v=4?s=100" width="100px;" alt="h4ckm1n"/><br /><sub><b>h4ckm1n</b></sub></a><br /><a href="https://github.com/h4ckm1n-dev/kube-utils-nvim/commits?author=h4ckm1n-dev" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/ohdearaugustin"><img src="https://avatars.githubusercontent.com/u/14001491?v=4?s=100" width="100px;" alt="ohdearaugustin"/><br /><sub><b>ohdearaugustin</b></sub></a><br /><a href="https://github.com/h4ckm1n-dev/kube-utils-nvim/commits?author=ohdearaugustin" title="Code">💻</a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!
