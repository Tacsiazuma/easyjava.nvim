local plenary = require("plenary")
local Path = require("plenary.path")
local function get_script_location()
    -- Get the path of the current script
    local info = debug.getinfo(2, "S")
    local script_path = info.source:sub(2)         -- Remove leading '@' from the source path
    return vim.fn.fnamemodify(script_path, ":p:h") -- Return the directory of the script
end
local M = {}

-- Function to find the directory containing pom.xml
M._find_pom_directory = function(file_path)
    -- Get the current buffer's file path
    if file_path == "" then
        return print("No file in the current buffer")
    end

    -- Start searching from the current file's directory
    local current_dir = Path:new(file_path):parent()

    local i = 0
    while i < 10 do
        -- Check if pom.xml exists in the current directory
        local pom_path = current_dir:joinpath("pom.xml")
        if pom_path:exists() then
            return current_dir:absolute() -- Return the absolute path of the directory
        end

        -- Move to the parent directory
        current_dir = current_dir:parent()
        print("'" .. current_dir .. "'")
        -- If we've reached the root directory, stop
        if current_dir == "/" or current_dir == Path:new("C:\\") then
            return print("pom.xml not found")
        end
        i = i + 1
    end
end
local function create_file(root, package, file, type)
    local path = root .. 'src/main/java/' .. package .. '/' .. file .. '.java'

    -- Create the directory if it doesn't exist
    local dir = root .. '/src/main/java/' .. package
    os.execute('mkdir -p ' .. dir)

    -- Open the file for writing
    local f = io.open(path, 'w')
    if f then
        -- Write an initial header or content to the file
        f:write('package ' .. package .. ";")

        -- Close the file after writing
        f:close()
        print('File created: ' .. path)
    else
        print('Error creating file: ' .. path)
    end
end

local function on_create_class()
    local file_path = vim.fn.expand("%:p") -- Absolute path of the current file
    local root = M._find_pom_directory(file_path)
    if root == nil then
        return print("Not in a maven project")
    end
    local items = M._find_java_packages(root, false)
    if items == nil then
        return print("Can't find any packages")
    end
    vim.ui.select(items, {}, function(package)
        vim.ui.input({}, function(file)
            create_file(root, package, file, "class")
        end)
    end)
end



local function on_create_test()
end

local function on_create_interface()
end

local default_options = {
    autofill = true
}
local autocmd_id = -1
M.setup = function(opts)
    opts = opts or default_options
    if opts.autofill then
        autocmd_id = vim.api.nvim_create_autocmd("BufReadPost", {
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
    elseif not opts.autofill and autocmd_id ~= -1 then
        vim.api.nvim_del_autocmd(autocmd_id)
    end
    vim.api.nvim_create_user_command("EasyJava", function()
        local items = { "Create class", "Create test", "Create interface" }
        local options = { prompt = "Please select:" }
        local on_choice = function(choice)
            if choice == "Create class" then
                on_create_class()
            elseif choice == "Create test" then
                on_create_test()
            else
                on_create_interface()
            end
        end
        vim.ui.select(items, options, on_choice)
    end, { bang = false })
end


M._find_java_packages = function(root, testing)
    testing = testing or false
    local java_src_dir
    if testing then
        java_src_dir = Path:new(root, "src/test/java")
    else
        java_src_dir = Path:new(root, "src/main/java")
    end
    if not java_src_dir:exists() then
        print("Directory '" .. java_src_dir .. "' not found!")
        return {}
    end

    local packages = {}

    -- Recursively find directories
    local dirs = plenary.scandir.scan_dir(java_src_dir:absolute(), { hidden = false, only_dirs = true })
    for _, dir in ipairs(dirs) do
        print(dir)
        -- Convert directory path to Java package name
        local relative_path = Path:new(dir):make_relative(java_src_dir:absolute())
        local package_name = relative_path:gsub("/", ".") -- Replace `/` with `.`
        table.insert(packages, package_name)
    end

    return packages
end

return M
