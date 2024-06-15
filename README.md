# Neovim Kubernetes Plugin

For the lazy, you can install my full config lazyvim with kube-utils-nvim installed [[template]](https://github.com/h4ckm1n-dev/h4ckm1n-lazyvim-template)

<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->

[![All Contributors](https://img.shields.io/badge/all_contributors-2-orange.svg?style=flat-square)](#contributors-)

<!-- ALL-CONTRIBUTORS-BADGE:END -->

This Neovim plugin provides seamless integration with Kubernetes and Helm, allowing you to deploy and manage Kubernetes resources directly from your editor.

### in both k9s mode ctl+c is remap to exit insert mode in k9s

![Capture d’écran du 2024-05-11 18-31-56](https://github.com/h4ckm1n-dev/kube-utils-nvim/assets/97511408/bbfe3a51-6117-413f-9d31-9f66517994c2)
![Capture d’écran du 2024-05-11 18-32-41](https://github.com/h4ckm1n-dev/kube-utils-nvim/assets/97511408/c6139ddf-e9af-4665-bd57-a829b236bac2)
![Capture d’écran du 2024-05-11 18-33-09](https://github.com/h4ckm1n-dev/kube-utils-nvim/assets/97511408/8c3cbaf8-d3c0-44a8-b487-4858e06b86f7)
![Capture d’écran du 2024-06-09 22-50-06](https://github.com/h4ckm1n-dev/kube-utils-nvim/assets/97511408/b5c1158e-5c93-41aa-b9ee-6fa5e2d0cb2b)

## Installation

Install the plugin using your preferred package manager (below is an example using lazy.nvim):

```lua
-- ~/.config/nvim/lua/plugins/kube-utils.lua
return {
  {
    "h4ckm1n-dev/kube-utils-nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    lazy = true,        -- Enable lazy loading for this plugin
    event = "VeryLazy", -- Load the plugin when Neovim starts
    opts = {},
  },
}
```

Additionaly you can create a witch-key mapping to use the commands (this is also the list of the feature) :

```lua
local helm_mappings = {
  k = {
    name = "Kubernetes",
    d = { "<cmd>HelmDeployFromBuffer<CR>", "Helm Deploy Buffer to Context" },
    r = { "<cmd>RemoveDeployment<CR>", "Helm Remove Deployment From Buffer" },
    T = { "<cmd>HelmDryRun<CR>", "Helm DryRun Buffer" },
    a = { "<cmd>KubectlApplyFromBuffer<CR>", "Kubectl Apply From Buffer" },
    D = { "<cmd>DeleteNamespace<CR>", "Kubectl Delete Namespace" },
    u = { "<cmd>HelmDependencyUpdateFromBuffer<CR>", "Helm Dependency Update" },
    b = { "<cmd>HelmDependencyBuildFromBuffer<CR>", "Helm Dependency Build" },
    t = { "<cmd>HelmTemplateFromBuffer<CR>", "Helm Template From Buffer" },
    K = { "<cmd>OpenK9sSplit<CR>", "Split View K9s" },
    k = { "<cmd>OpenK9s<CR>", "Open K9s" },
    l = { "<cmd>ToggleYamlHelm<CR>", "Toggle YAML/Helm" },
    c = { "<cmd>SelectCRD<CR>", "Download CRD" },
    C = { "<cmd>SelectSplitCRD<CR>", "Download CRD Split" },
    jl = { "<cmd>JsonFormatLogs<CR>", "Format JSON" },
  },
}

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
