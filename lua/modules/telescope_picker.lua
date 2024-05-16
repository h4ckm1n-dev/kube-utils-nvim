-- modules/telescope_picker.lua
local TelescopePicker = {}

function TelescopePicker.select_from_list(prompt_title, list, callback)
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
                        callback(selection.value)
                    end
                end)
                return true
            end,
        })
        :find()
end

function TelescopePicker.input(prompt_title, callback)
    local input = vim.fn.input(prompt_title .. ": ")
    if input ~= "" then
        callback(input)
    else
        print(prompt_title .. " cannot be empty.")
    end
end

return TelescopePicker
