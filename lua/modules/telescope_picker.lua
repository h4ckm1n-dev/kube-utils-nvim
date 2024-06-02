-- modules/telescope_picker.lua

local TelescopePicker = {}

local function invoke_callback(callback, value)
	if type(callback) == "function" then
		callback(value)
	else
		Utils.log_error("Callback is not a function.")
	end
end

function TelescopePicker.select_from_list(prompt_title, list, callback)
	if type(list) ~= "table" or #list == 0 then
		Utils.log_error("List must be a non-empty table.")
		return
	end

	if type(callback) ~= "function" then
		Utils.log_error("Callback must be a function.")
		return
	end

	require("telescope.pickers")
		.new({}, {
			prompt_title = prompt_title,
			finder = require("telescope.finders").new_table({ results = list }),
			sorter = require("telescope.config").values.generic_sorter({}),
			attach_mappings = function(_, map)
				map("i", "<CR>", function(prompt_bufnr)
					local selection = require("telescope.actions.state").get_selected_entry(prompt_bufnr)
					require("telescope.actions").close(prompt_bufnr)
					if selection then
						invoke_callback(callback, selection.value)
					end
				end)
				return true
			end,
		})
		:find()
end

function TelescopePicker.input(prompt_title, callback)
	if type(callback) ~= "function" then
		Utils.log_error("Callback must be a function.")
		return
	end

	local input = vim.fn.input(prompt_title .. ": ")
	if input ~= "" then
		invoke_callback(callback, input)
	else
		Utils.log_error("" .. prompt_title .. " cannot be empty.")
	end
end

return TelescopePicker
