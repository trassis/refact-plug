local M = {}

-- HACK: apagar isso aqui dps
function M.hello()
	print("Hi from the plugin!")
end

local ns = vim.api.nvim_create_namespace("RefactorPlugin")

function M.detect_smells()
	local diagnostics = {}

	-- Long lines code smell
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	for i, line in ipairs(lines) do
		if #line > 80 then
			table.insert(diagnostics, {
				lnum = i - 1,
				col = 80,
				end_lnum = i - 1,
				end_col = #line,
				severity = vim.diagnostic.severity.WARN,
				message = "Code Smell - Line exceeds 80 characters",
				source = "RefactorPlug",
			})
		end
	end

	-- Publish the diagnostics to the buffer
	vim.diagnostic.set(ns, 0, diagnostics)
end

local Refactorings = require("refact-plug.refactorings")

function M.setup()
	-- TODO: If lang is not cpp, do not continue...

	-- Creates user commands for each refactoring.
	vim.api.nvim_create_user_command("RenameVar", Refactorings.rename_variable, {
		nargs = "+",
		desc = "Renames <source> variable to <target>.",
	})
	vim.api.nvim_create_user_command("ExtractMethod", Refactorings.extract_method, {
		nargs = "+",
		range = true,
		desc = "Extracts a selection into a new method name <method_name>.",
	})

	vim.api.nvim_create_user_command("InlineMethod", Refactorings.inline_method, {
		nargs = "+",
		desc = "Inline ",
	})

	vim.api.nvim_create_user_command("EncapsulateField", Refactorings.encapsulate_field, {})

	-- Detects code smells whenever the buffer is modified or saved.
	vim.api.nvim_create_autocmd({ "TextChanged", "BufWritePost" }, {
		callback = M.detect_smells,
	})
	M.detect_smells()
end

return M
