local M = {}

-- HACK: apagar isso aqui dps
function M.hello()
	print("Hi from the plugin!")
end

local ns = vim.api.nvim_create_namespace("RefactorPlugin")

function M.detect_smells()
	local diagnostics = {}

	-- Long lines smell
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	for i, line in ipairs(lines) do
		if #line > 80 then
			table.insert(diagnostics, {
				lnum = i - 1,
				col = 80,
				end_lnum = i - 1,
				end_col = #line,
				severity = vim.diagnostic.severity.WARN,
				message = "Code Smell: Line exceeds 80 characters",
				source = "RefactorPlug",
			})
		end
	end

	-- Publish the diagnostics to the buffer
	vim.diagnostic.set(ns, 0, diagnostics)
end

-- Renames source variable to target
function M.rename_variable(opts)
	-- Parsing input
	local source = opts.fargs[1]
	local target = opts.fargs[2]
	if not source or not target then
		print("Usage: :RenameVar <source> <target>")
		return
	end

	-- This is the ast root associated with the file
	local tree = vim.treesitter.get_parser():parse()[1]

	-- TSQuery finds identifiers equal to "source"
	local query_string = string.format('((identifier) @target (#eq? @target "%s"))', source)
	local query = vim.treesitter.query.parse("cpp", query_string)

	-- Collect all matches
	-- iter_captures returns all nodes that match with the query
	-- node:range() is the position of the node in the buffer
	local changes = {}
	for id, node, metadata in query:iter_captures(tree:root(), 0, 0, -1) do
		local start_row, start_col, end_row, end_col = node:range()
		table.insert(changes, { start_row, start_col, end_row, end_col })
	end

	-- Apply changes in reverse order
	-- We must go backwards so changing line 1 doesn't shift the coordinates for line 10
	for i = #changes, 1, -1 do
		local r = changes[i]
		vim.api.nvim_buf_set_text(0, r[1], r[2], r[3], r[4], { target })
	end
end

function M.setup()
	-- TODO: Assert lang is cpp?

	vim.api.nvim_create_user_command("RenameVar", M.rename_variable, {
		nargs = "+",
		desc = "Renames <source> variable to <target>.",
	})

	vim.api.nvim_create_autocmd({ "TextChanged", "BufWritePost" }, {
		callback = M.detect_smells,
	})
	M.detect_smells()
end

return M
