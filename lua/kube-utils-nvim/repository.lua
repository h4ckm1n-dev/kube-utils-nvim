-- kube-utils-nvim/repository.lua

local Repository = {}

-- Function to read and parse the Chart.yaml file
Repository.get_repository_info = function(chart_yaml_path)
	local repo_name = ""
	local repo_url = ""

	-- Check if Chart.yaml exists
	if vim.fn.filereadable(chart_yaml_path) ~= 1 then
		print("Error: Chart.yaml not found at " .. chart_yaml_path)
		return nil, nil
	end

	-- Read the contents of Chart.yaml
	local chart_yaml_contents = vim.fn.readfile(chart_yaml_path)
	if not chart_yaml_contents then
		print("Error: Failed to read Chart.yaml")
		return nil, nil
	end

	-- Use a simple pattern matching approach to extract the required fields
	for _, line in ipairs(chart_yaml_contents) do
		local key, value = line:match("^%s*(%S+)%s*:%s*(.+)$")
		if key == "repository" then
			repo_url = value
		elseif key == "name" then
			repo_name = value
		end
	end

	if repo_name == "" then
		print("Error: Repository name not found in Chart.yaml")
	end
	if repo_url == "" then
		print("Error: Repository URL not found in Chart.yaml")
	end

	return repo_name, repo_url
end

return Repository
