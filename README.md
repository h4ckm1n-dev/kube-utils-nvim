# 🚀 Neovim Kubernetes Plugin 🚀
<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->
[![Go](https://github.com/h4ckm1n-dev/helm-utils-nvim/actions/workflows/lualint.yml/badge.svg)](https://github.com/h4ckm1n-dev/helm-utils-nvim/actions/workflows/lualint.yml)[![All Contributors](https://img.shields.io/badge/all_contributors-1-orange.svg?style=flat-square)](#contributors-)
<!-- ALL-CONTRIBUTORS-BADGE:END -->

This Neovim plugin provides seamless integration with Kubernetes and Helm, allowing you to deploy and manage Kubernetes resources directly from your editor.

## Features
- **Helm Deployment:** Use `:HelmDeployFromBuffer` to deploy the Helm chart from the current buffer. You'll be prompted for the release name context and namespace.
- **Helm Remove Deployment:** Use `Removedeployment`to remove a deployment, You'll be prompted for the release name and namespace
- **Helm Dry Run:** Use `:HelmDryRun` to simulate the Helm chart installation from the current buffer. You'll be prompted for the release name and namespace, and a new tab will open showing the simulated output.
- **Helm Dependency Update:** Use `:HelmDependencyUpdateFromBuffer` to update Helm dependencies from the current buffer.
- **Helm Dependency Build:** Use `:HelmDependencyBuildFromBuffer` to build Helm dependencies from the current buffer.
- **Kubectl Apply:** Use `:KubectlApplyFromBuffer` to apply Kubernetes manifests from the current buffer. You'll be prompted for the release name context and namespace.
- **Open K9s:** Use `:OpenK9s` to open the K9s Kubernetes CLI in a new terminal buffer.
- **Open K9s Split:** Use `:OpenK9sSplit` to open the K9s Kubernetes CLI in a new split terminal buffer.
### in both k9s mode ctl+c is remap to exit insert mode in k9s

![Capture d’écran du 2024-05-11 18-31-56](https://github.com/h4ckm1n-dev/kube-utils-nvim/assets/97511408/bbfe3a51-6117-413f-9d31-9f66517994c2)
![Capture d’écran du 2024-05-11 18-32-41](https://github.com/h4ckm1n-dev/kube-utils-nvim/assets/97511408/c6139ddf-e9af-4665-bd57-a829b236bac2)
![Capture d’écran du 2024-05-11 18-33-09](https://github.com/h4ckm1n-dev/kube-utils-nvim/assets/97511408/8c3cbaf8-d3c0-44a8-b487-4858e06b86f7)

## Installation
Install the plugin using your preferred package manager (below is an example using lazy.nvim):
```lua
return {
    {
        "h4ckm1n-dev/kube-utils-nvim",
        requires = { "nvim-telescope/telescope.nvim" },
        config = function()
            require("helm_utils").setup()
        end,
    },
}

```
Additionaly you can create a witch-key mapping to use the commands:
```lua
local helm_mappings = {
    k = {
        name = "Kubernetes", -- This sets a label for all helm-related keybindings
        c = { "<cmd>HelmDeployFromBuffer<CR>", "Helm Deploy Buffer to Context" },
        r = { "<cmd>RemoveDeployment<CR>", "Helm Remove Deployment From Buffer" },
        d = { "<cmd>HelmDryRun<CR>", "helm DryRun Buffer" },
        a = { "<cmd>KubectlApplyFromBuffer<CR>", "kubectl apply From buffer" },
        u = { "<cmd>HelmDependencyUpdateFromBuffer<CR>", "Helm Dependency Update from Buffer" },
        b = { "<cmd>HelmDependencyBuildFromBuffer<CR>", "Helm Dependency Build from Buffer" },
        K = { "<cmd>OpenK9sSplit<CR>", "Split View K9s" },
        k = { "<cmd>OpenK9s<CR>", "Open K9s" },
    },
}

-- Require the which-key plugin
local wk = require("which-key")

-- Register the Helm keybindings with a specific prefix
wk.register(helm_mappings, { prefix = "<leader>" })
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

Thanks goes to these wonderful people :

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/h4ckm1n-dev"><img src="https://avatars.githubusercontent.com/u/97511408?v=4?s=100" width="100px;" alt="h4ckm1n"/><br /><sub><b>h4ckm1n</b></sub></a><br /><a href="https://github.com/h4ckm1n-dev/kube-utils-nvim/commits?author=h4ckm1n-dev" title="Code">💻</a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!
