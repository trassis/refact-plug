local M = {}

-- HACK: apagar isso aqui dps
function M.hello()
	print("Hi from the plugin!")
end

local CodeSmells = require("refact-plug.codeSmells")
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
		callback = function()
            CodeSmells.detect_smells()
        end,
	})

	CodeSmells.detect_smells()
end

return M
