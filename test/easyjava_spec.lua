local path = require("plenary.path")
local function active_buffer()
	-- Get the current buffer ID
	local current_buf = vim.api.nvim_get_current_buf()
	-- Get the file name of the current buffer
	local current_buf_path = vim.api.nvim_buf_get_name(current_buf)

	-- Compare paths
	return current_buf_path
end

local function split_lines(content)
	-- Split the file content into lines
	local lines = {}
	for line in string.gmatch(content, "([^\n]*)\n?") do
		table.insert(lines, line)
	end
	return lines
end
describe("plugin", function()
	it("should load fine", function()
		local sut = require("easyjava")
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
			assert.are_same(select_called, true)
		end)
	end)
	describe("finding project root", function()
		local sut = require("easyjava")
		it("should find proper root if present", function()
			local actual = sut._find_pom_directory(vim.loop.cwd() .. "/fixture/src/main/java/com/example")
			assert.are_same(vim.loop.cwd() .. "/fixture", actual)
		end)
		it("should find proper root", function()
			local actual = sut._find_pom_directory(vim.loop.cwd() .. "/fixture")
			assert.are_same(vim.loop.cwd() .. "/fixture", actual)
		end)
		it("should return nil if no root can be found", function()
			local actual = sut._find_pom_directory(vim.loop.cwd())
			assert.are_nil(actual)
		end)
	end)
	describe("getting package list", function()
		local sut = require("easyjava")
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
	describe("creating file", function()
		local sut = require("easyjava")
		after_each(function()
			path:new(vim.loop.cwd() .. "/fixture/src/main/java/com/example/Created.java"):rm()
			path:new(vim.loop.cwd() .. "/fixture/src/test/java/com/testing/CreatedTest.java"):rm()
			path:new(vim.loop.cwd() .. "/fixture/src/test/java/com/testing/test/CreatedTest.java"):rm()
		end)
		it("should create classes in the proper folder", function()
			sut._create_file(vim.loop.cwd() .. "/fixture", "com.example", "Created", "class")
			assert.are_true(path:new(vim.loop.cwd() .. "/fixture/src/main/java/com/example/Created.java"):exists())
		end)
		it("should create tests in the proper folder", function()
			sut._create_file(vim.loop.cwd() .. "/fixture", "com.testing", "CreatedTest", "test")
			assert.are_true(path:new(vim.loop.cwd() .. "/fixture/src/test/java/com/testing/CreatedTest.java"):exists())
		end)
		it("should create non-existing packages in the proper folder", function()
			sut._create_file(vim.loop.cwd() .. "/fixture", "com.testing.test", "CreatedTest", "test")
			assert.are_true(
				path:new(vim.loop.cwd() .. "/fixture/src/test/java/com/testing/test/CreatedTest.java"):exists()
			)
		end)
		it("should create classes with proper package name", function()
			sut._create_file(vim.loop.cwd() .. "/fixture", "com.example", "Created", "class")
			local content =
				split_lines(path:new(vim.loop.cwd() .. "/fixture/src/main/java/com/example/Created.java"):read())
			assert.are_same("package com.example;", content[1])
		end)
		it("should create classes with proper type", function()
			sut._create_file(vim.loop.cwd() .. "/fixture", "com.example", "Created", "class")
			local content =
				split_lines(path:new(vim.loop.cwd() .. "/fixture/src/main/java/com/example/Created.java"):read())
			assert.are_same("public class Created {}", content[3])
		end)
		it("should create interfaces with proper type", function()
			sut._create_file(vim.loop.cwd() .. "/fixture", "com.example", "Created", "interface")
			local content =
				split_lines(path:new(vim.loop.cwd() .. "/fixture/src/main/java/com/example/Created.java"):read())
			assert.are_same("public interface Created {}", content[3])
		end)
		it("should create records with proper type", function()
			sut._create_file(vim.loop.cwd() .. "/fixture", "com.example", "Created", "record")
			local content =
				split_lines(path:new(vim.loop.cwd() .. "/fixture/src/main/java/com/example/Created.java"):read())
			assert.are_same("public record Created() {}", content[3])
		end)
		it("should create tests with proper type", function()
			sut._create_file(vim.loop.cwd() .. "/fixture", "com.testing", "CreatedTest", "test")
			local content =
				split_lines(path:new(vim.loop.cwd() .. "/fixture/src/test/java/com/testing/CreatedTest.java"):read())
			assert.are_same("public class CreatedTest {}", content[3])
		end)

		it("should open the file as a buffer", function()
			sut._create_file(vim.loop.cwd() .. "/fixture", "com.example", "Created", "class")
			local filename = vim.loop.cwd() .. "/fixture/src/main/java/com/example/Created.java"
			assert.are_same(filename, active_buffer())
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
				assert.are_same("something", actual)
			end)
		end)
	end)
	describe("visiting java file", function()
		local sut = require("easyjava")
		sut.setup()
		local temp_file_path = path:new("fixture/src/main/java/com/example/ClassName.java")
		before_each(function()
			temp_file_path:write("", "w")
		end)
		after_each(function()
			temp_file_path:rm()
		end)
		it("should fill it based on its assumed package", function()
			vim.cmd("edit" .. temp_file_path:absolute())
			assert.are_same(vim.fn.expand("%:p"), temp_file_path:absolute())

			-- assert
			local buffer_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
			local actual = buffer_content[1] or ""
			assert.are_same("package com.example;", actual)
		end)
		it("should fill the class declaration", function()
			vim.cmd("edit" .. temp_file_path:absolute())
			assert.are_same(vim.fn.expand("%:p"), temp_file_path:absolute())

			-- assert
			local buffer_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
			assert.are_same("", buffer_content[2])
			assert.are_same("public class ClassName {}", buffer_content[3])
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
			assert.are_same("", actual)
		end)
	end)
end)
