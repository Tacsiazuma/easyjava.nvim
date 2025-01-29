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

    local current_dir = vim.fn.fnamemodify(file_path, ":p:h")

    -- Helper function to check if a file exists
    local function file_exists(path)
        local f = io.open(path, "r")
        if f then
            f:close()
            return true
        end
        return false
    end

    -- Traverse up the directory tree
    while current_dir ~= "/" do
        print(current_dir)
        local pom_path = current_dir .. "/pom.xml"
        if file_exists(pom_path) then
            return current_dir
        end
        -- Move up one directory
        current_dir = vim.fn.fnamemodify(current_dir, ":h")
    end

    -- If no pom.xml is found, return nil
    return nil
end
M._create_file = function(root, package, file, type)
    local package_folder = string.gsub(package, "%.", "/")
    local prefix
    if type == "test" then
        prefix = "/src/test/java/"
    else
        prefix = "/src/main/java/"
    end
    local path = root .. prefix .. package_folder .. '/' .. file .. '.java'

    -- Create the directory if it doesn't exist
    local dir = root .. prefix .. package_folder
    os.execute('mkdir -p ' .. dir)

    -- Open the file for writing
    local f = io.open(path, 'w')
    if f then
        -- Write an initial header or content to the file
        f:write('package ' .. package .. ";\n\n")
        if type == 'interface' then
            f:write('public interface ' .. file .. ' {}')
        elseif type == 'record' then
            f:write('public record ' .. file .. '() {}')
        else
            f:write('public class ' .. file .. ' {}')
        end
        -- Close the file after writing
        f:close()
        print('File created: ' .. path)
        vim.cmd("edit " .. path)
    else
        print('Error creating file: ' .. path)
    end
end

local function on_create(type)
    local file_path = vim.fn.expand("%:p") -- Absolute path of the current file
    local root = M._find_pom_directory(file_path)
    if root == nil then
        return print("Not in a maven project")
    end
    local test = false
    if type == test then
        test = true
    end
    local items = M._find_java_packages(root, test)
    if items == nil then
        return print("Can't find any packages")
    end
    vim.ui.select(items, {}, function(package)
        vim.ui.input({}, function(file)
            M._create_file(root, package, file, type)
        end)
    end)
end


local function populate_with_content(lines)
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

local function get_package_name(abs_path)
    -- Find "src/main/java/" or "src/test/java/" in the path
    local match = abs_path:match("src/[^/]+/java/")
    if not match then
        return nil -- Return nil if neither is found
    end

    -- Extract the package path after "src/main/java/" or "src/test/java/"
    local package_path = abs_path:match(match .. "(.*)")

    -- Remove filename from the path
    package_path = package_path:gsub("/[^/]+$", "")

    -- Convert `/` to `.`
    local package_name = package_path:gsub("/", ".")

    return package_name
end

local function get_class_name(abs_path)
    local filename = abs_path:match("([^/]+)%.java$")
    return filename
end
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
            populate_with_content(lines)
        end
    })
    vim.api.nvim_create_autocmd("BufReadPost", {
        pattern = "*.java",
        callback = function()
            local path = vim.api.nvim_buf_get_name(0)
            local class_name = get_class_name(path)
            local package_name = get_package_name(path)
            local lines = {
                "package " .. package_name .. ";",
                "",
                "public class "..class_name.." {}",
            }
            populate_with_content(lines)
        end
    })
    vim.api.nvim_create_user_command("EasyJava", function()
        local items = { "Create class", "Create test", "Create interface" }
        local options = { prompt = "Please select:" }
        local on_choice = function(choice)
            if choice == "Create class" then
                on_create("class")
            elseif choice == "Create test" then
                on_create("test")
            elseif choice == "Create interface" then
                on_create("interface")
            else
                on_create("record")
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
