local function get_script_location()
    -- Get the path of the current script
    local info = debug.getinfo(2, "S")
    local script_path = info.source:sub(2)         -- Remove leading '@' from the source path
    return vim.fn.fnamemodify(script_path, ":p:h") -- Return the directory of the script
end
local M = {}
M.setup = function()
    vim.api.nvim_create_autocmd("BufReadPost", {
        pattern = "pom.xml",
        callback = function()
            local file_path = get_script_location() .. "/../../sample/pom.xml"
            local file = io.open(file_path, "r")
            if not file then
                vim.api.nvim_err_writeln("Error: Could not open file " .. file_path)
                return
            end

            -- Read the file content
            local lines = {}
            for line in file:lines() do
                table.insert(lines, line)
            end
            file:close()
            -- Insert the lines into the current buffer
            local buf = vim.api.nvim_get_current_buf()
            local read_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
            local empty = true
            for _, line in ipairs(read_lines) do
                if line ~= "" then
                    empty = false
                end
            end
            if empty then
                vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
            end
        end
    })
end


return M
