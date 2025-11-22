local R = {}

-- Renames all instances of {source} to {target}
function R.rename_variable(opts)
	-- Parsing input
	local source = opts.fargs[1]
	local target = opts.fargs[2]
	if not source or not target then
		print("Usage: :RenameVar <source> <target>")
		return
	end

	-- This is the ast root associated with the file
	local tree = vim.treesitter.get_parser(0, "cpp"):parse()[1]

	-- TSQuery finds identifiers equal to "source"
	local query_string = string.format('((identifier) @target (#eq? @target "%s"))', source)
	local query = vim.treesitter.query.parse("cpp", query_string)

	-- Collect all matches
	-- iter_captures returns all nodes that match with the query
	-- node:range() is the position of the node in the buffer
	local changes = {}
	for _, node, _ in query:iter_captures(tree:root(), 0, 0, -1) do
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

-- Gets the row where the method that contains the cursor is defined.
local function get_insert_row(cursor_row)
	-- Cursor current node.
	local parent_node = vim.treesitter.get_node({ pos = { cursor_row, 0 } })

	-- Loops thorgh nodes untill it hits the exterior method definition.
	while parent_node do
		if parent_node:type() == "function_definition" then
			break
		end
		parent_node = parent_node:parent()
	end

	-- Cannot find exterior method definition.
	if not parent_node then
		return nil
	end

	-- Line where exterior method is defined.
	local start_row, _, _, _ = parent_node:range()
	return start_row
end

-- Extracts a selection {opts.line1..opts.line2} to a new method named {opts.fargs[1]}.
function R.extract_method(opts)
	local method_name = opts.fargs[1]
	local start_row = opts.line1 - 1
	local end_row = opts.line2

	-- Failed to recover args.
	if not method_name or not start_row or not end_row then
		print("Usage: :'<,'>ExtractMethod <method_name>")
		return
	end

	-- Gets the place where to insert the extracted method.
	local insert_row = get_insert_row(start_row)
	if not insert_row then
		print("Error: Failed to find a location where to extract.")
		return
	end

	-- Creates the new method.
	local method_definition = {
		string.format("void %s(){", method_name),
	}
	local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row, false)
	for _, line in ipairs(lines) do
		table.insert(method_definition, "    " .. line)
	end
	table.insert(method_definition, "}")
	table.insert(method_definition, "")

	-- Inserts a call to the extracted method.
	local method_call = string.format("%s();", method_name)
	vim.api.nvim_buf_set_lines(0, start_row, end_row, false, { method_call })
	vim.cmd(string.format("silent normal! %dG=%dG", start_row, end_row))

	-- Inserts the extracted method on the buffer.
	vim.api.nvim_buf_set_lines(0, insert_row, insert_row, false, method_definition)
	vim.cmd(string.format("silent normal! %dG=%dG", insert_row + 1, insert_row + #method_definition))
end

function R.inline_method(opts)
	local method_name = opts.fargs[1]

	if not method_name then
		print("Usage: :InlineMethod <method_name>")
		return
	end

	local view = vim.fn.winsaveview()

	-- Locates the function
	vim.cmd("normal! gg")
	local def_pattern = string.format("void\\s\\+%s\\s*()\\s*{", method_name)
	local def_row = vim.fn.search(def_pattern, "W")

	if def_row == 0 then
		print("Error: Definition for '" .. method_name .. "' not found.")
		return
	end

	vim.fn.search("{", "W", def_row + 1)
	local start_brace_row = vim.fn.line(".")
	vim.cmd("normal! %")
	local end_brace_row = vim.fn.line(".")

	-- Copy the internal lines
	local body_lines = vim.api.nvim_buf_get_lines(0, start_brace_row, end_brace_row - 1, false)

	-- Find the places where there is a function call
	vim.cmd("normal! gg")
	local call_pattern = string.format("\\<%s\\s*();", method_name)

	local calls = {}
	while true do
		local call_row = vim.fn.search(call_pattern, "W")
		if call_row == 0 then
			break
		end

		if call_row ~= def_row then
			table.insert(calls, call_row)
		end
	end

	if #calls == 0 then
		print("No calls found for '" .. method_name .. "'.")
		vim.fn.winrestview(view)
		return
	end

	-- Substitutes the method in the calls
	for i = #calls, 1, -1 do
		local row_idx = calls[i] - 1 -- API usa base-0

		vim.api.nvim_buf_set_lines(0, row_idx, row_idx + 1, false, body_lines)

		local end_insert = row_idx + #body_lines
		vim.cmd(string.format("silent normal! %dG=%dG", row_idx + 1, end_insert))
	end

	-- Deletes the original method
	vim.cmd("normal! gg")
	local final_def_row = vim.fn.search(def_pattern, "W")

	if final_def_row > 0 then
		vim.fn.search("{", "W", final_def_row + 1)
		vim.cmd("normal! %")
		local final_end_row = vim.fn.line(".")

		vim.api.nvim_buf_set_lines(0, final_def_row - 1, final_end_row, false, {})
		print("Inlined " .. #calls .. " occurrence(s) and removed definition.")
	else
		print("Warning: Could not find original definition to delete (lines shifted?).")
	end

	vim.fn.winrestview(view)
end

return R
