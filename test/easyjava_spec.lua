local path = require("plenary.path")
describe("plugin", function()
    it("should load fine", function()
        local sut = require "easyjava"
        assert.are_table(sut)
    end)
    it("should provide setup function", function()
        local sut = require("easyjava")
        assert.are_function(sut.setup)
    end)
    describe("context menu", function()
        local sut = require("easyjava")
        sut.setup()
        local select_called = false
        vim.ui.select = function(_, _, _)
            select_called = true
        end
        it("command can be invoked", function()
            vim.cmd("EasyJava")
        end)
        it("opens select menu", function()
            vim.cmd("EasyJava")
            select_called = true
        end)
    end)
    describe("scaffolding autocomplete", function()
        local sut = require("easyjava")
        sut.setup()
        it("should return main packages for classes", function()
            local actual = sut._find_java_packages(path:new(vim.loop.cwd(), "fixture"))
            assert.are_same("com", actual[1])
            assert.are_same("com.example", actual[2])
            assert.are_same("com.other", actual[3])
        end)
        it("should return test packages for tests", function()
            local actual = sut._find_java_packages(path:new(vim.loop.cwd(), "fixture"), true)
            assert.are_same("com", actual[1])
            assert.are_same("com.testing", actual[2])
        end)
    end)
    describe("visiting pom.xml", function()
        describe("default configuration", function()
            local sut = require("easyjava")
            sut.setup()
            local temp_file_path = path:new("pom.xml")
            before_each(function()
                temp_file_path:write("", "w")
            end)
            after_each(function()
                temp_file_path:rm()
            end)
            it("should fill it with basics if empty", function()
                -- arrange
                -- act
                vim.cmd("edit" .. temp_file_path:absolute())
                assert.are_same(vim.fn.expand("%:p"), temp_file_path:absolute())

                -- assert
                local buffer_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
                local actual = buffer_content[1] or ""
                assert.are_same('<project xmlns="http://maven.apache.org/POM/4.0.0"', actual)
            end)
            it("should not fill if not empty", function()
                -- arrange
                temp_file_path:write("something", "w")
                -- act
                vim.cmd("edit" .. temp_file_path:absolute())
                assert.are_same(vim.fn.expand("%:p"), temp_file_path:absolute())

                -- assert
                local buffer_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
                local actual = buffer_content[1] or ""
                assert.are_same('something', actual)
            end)
        end)
        describe("turned off autofill", function()
            local sut = require("easyjava")
            sut.setup({ autofill = false })
            local temp_file_path = path:new("pom.xml")
            before_each(function()
                temp_file_path:write("", "w")
            end)
            after_each(function()
                temp_file_path:rm()
            end)
            it("should not fill it with basics if empty", function()
                -- arrange
                -- act
                vim.cmd("edit" .. temp_file_path:absolute())
                assert.are_same(vim.fn.expand("%:p"), temp_file_path:absolute())

                -- assert
                local buffer_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
                local actual = buffer_content[1] or ""
                assert.are_same('', actual)
            end)
            it("should not fill if not empty", function()
                -- arrange
                temp_file_path:write("something", "w")
                -- act
                vim.cmd("edit" .. temp_file_path:absolute())
                assert.are_same(vim.fn.expand("%:p"), temp_file_path:absolute())

                -- assert
                local buffer_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
                local actual = buffer_content[1] or ""
                assert.are_same('', actual)
            end)
        end)
    end)
    describe("visiting other file", function()
        local sut = require("easyjava")
        sut.setup()
        local temp_file_path = path:new("other.xml")
        before_each(function()
            temp_file_path:write("", "w")
        end)
        after_each(function()
            temp_file_path:rm()
        end)
        it("should not fill", function()
            -- arrange
            -- act
            vim.cmd("edit" .. temp_file_path:absolute())
            assert.are_same(vim.fn.expand("%:p"), temp_file_path:absolute())

            -- assert
            local buffer_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
            local actual = buffer_content[1] or ""
            assert.are_same('', actual)
        end)
    end)
end)
