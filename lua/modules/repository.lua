-- modules/repository.lua
local Repository = {}

function Repository.get_repository_info(chart_yaml_path)
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

return Repository
