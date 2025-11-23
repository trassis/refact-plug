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

-- Get identifiers defined outside a selection {start_row...end_row}
local function get_external_params(start_row, end_row)
	local root = vim.treesitter.get_parser(0, "cpp"):parse()[1]:root()
	local params = {}
	local seen = {}

	-- Query to find identifiers used in the selection
	local usage_query = vim.treesitter.query.parse("cpp", "(identifier) @id")

	-- Loop trough all identifiers in the selection
	for _, node in usage_query:iter_captures(root, 0, start_row, end_row) do
		local name = vim.treesitter.get_node_text(node, 0)
		local parent = node:parent()

		-- Ignore if already seen, or if its a function call/field access
		if not seen[name] and parent:type() ~= "call_expression" and parent:type() ~= "field_expression" then
			-- Check if is defined inside the selection
			local is_local = false
			local local_def_query = vim.treesitter.query.parse(
				"cpp",
				string.format('(declaration declarator: (_ declarator: (identifier) @name (#eq? @name "%s")))', name)
			)
			for _ in local_def_query:iter_captures(root, 0, start_row, end_row) do
				is_local = true
			end

			if not is_local then
				seen[name] = true
				-- Search above the selection for the type definition
				local type_val = "auto"
				local type_query = vim.treesitter.query.parse(
					"cpp",
					string.format(
						'(declaration type: (_) @type declarator: (_ declarator: (identifier) @name (#eq? @name "%s")))',
						name
					)
				)
				for id, t_node in type_query:iter_captures(root, 0, 0, start_row) do
					if type_query.captures[id] == "type" then
						type_val = vim.treesitter.get_node_text(t_node, 0)
					end
				end

				table.insert(params, { type = type_val, name = name })
			end
		end
	end
	return params
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
	-- local method_definition = {
	-- 	string.format("void %s(){", method_name),
	-- }
	-- local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row, false)
	-- for _, line in ipairs(lines) do
	-- 	-- table.insert(method_definition, "    " .. line)
	-- 	table.insert(method_definition, line)
	-- end
	-- table.insert(method_definition, "}")
	-- table.insert(method_definition, "")

	local params_list = get_external_params(start_row, end_row)
	local param_definitions = {}
	local param_args = {}
	for _, p in ipairs(params_list) do
		table.insert(param_definitions, string.format("%s& %s", p.type, p.name))
		table.insert(param_args, p.name)
	end
	local params_str = table.concat(param_definitions, ", ")
	local args_str = table.concat(param_args, ", ")

	local method_definition = {
		string.format("void %s(%s) {", method_name, params_str),
	}
	local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row, false)
	for _, line in ipairs(lines) do
		table.insert(method_definition, line)
	end
	table.insert(method_definition, "}")
	table.insert(method_definition, "")

	local method_call = string.format("%s(%s);", method_name, args_str)
	vim.api.nvim_buf_set_lines(0, start_row, end_row, false, { method_call })
	vim.cmd(string.format("silent normal! %dG=%dG", start_row, end_row))

	-- Inserts a call to the extracted method.
	vim.api.nvim_buf_set_lines(0, insert_row, insert_row, false, method_definition)
	vim.cmd(string.format("silent normal! %dG=%dG", insert_row + 1, insert_row + #method_definition))
end

-- Extracts the name of function parameters
local function parse_params(param_str)
	local params = {}
	if not param_str or param_str:match("^%s*$") then
		return params
	end

	for part in string.gmatch(param_str, "([^,]+)") do
		part = part:match("^%s*(.-)%s*$")
		local name = part:match("[%w_]+$")
		if name then
			table.insert(params, name)
		end
	end
	return params
end

-- Extracts the name of variables on function call
local function parse_args(arg_str)
	local args = {}
	if not arg_str or arg_str:match("^%s*$") then
		return args
	end

	for part in string.gmatch(arg_str, "([^,]+)") do
		table.insert(args, part:match("^%s*(.-)%s*$"))
	end
	return args
end

function R.inline_method(opts)
	local method_name = opts.fargs[1]
	if not method_name then
		print("Usage: :InlineMethod <method_name>")
		return
	end

	local view = vim.fn.winsaveview()

	-- Locates function and parameters
	vim.cmd("normal! gg")
	local def_pattern = string.format("void\\s\\+%s\\s*(\\zs.*\\ze)\\s*{", method_name)
	local def_row = vim.fn.search(def_pattern, "W")

	if def_row == 0 then
		local fallback_pattern = string.format("void\\s\\+%s\\s*().*{", method_name)
		def_row = vim.fn.search(fallback_pattern, "W")
		if def_row == 0 then
			print("Error: Definition for '" .. method_name .. "' not found.")
			return
		end
	end

	local def_line_text = vim.api.nvim_buf_get_lines(0, def_row - 1, def_row, false)[1]
	local raw_params = def_line_text:match("void%s+" .. method_name .. "%s*%((.*)%)")
	local param_names = parse_params(raw_params)

	-- Copy function body
	vim.fn.search("{", "W", def_row + 1)
	local start_brace_row = vim.fn.line(".")
	vim.cmd("normal! %")
	local end_brace_row = vim.fn.line(".")

	local original_body_lines = vim.api.nvim_buf_get_lines(0, start_brace_row, end_brace_row - 1, false)

	-- Find function call
	vim.cmd("normal! gg")
	local call_pattern = string.format("\\<%s\\s*(", method_name)

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

	-- Substitutes the variables
	for i = #calls, 1, -1 do
		local row_idx = calls[i] - 1
		local call_line_text = vim.api.nvim_buf_get_lines(0, row_idx, row_idx + 1, false)[1]

		local raw_args = call_line_text:match(method_name .. "%s*%((.*)%);")
		local call_args = parse_args(raw_args)

		local new_body_lines = {}

		for _, line in ipairs(original_body_lines) do
			local modified_line = line

			if #param_names == #call_args then
				for k, param in ipairs(param_names) do
					local arg = call_args[k]
					modified_line = modified_line:gsub("%f[%w_]" .. param .. "%f[^%w_]", arg)
				end
			end
			table.insert(new_body_lines, modified_line)
		end

		vim.api.nvim_buf_set_lines(0, row_idx, row_idx + 1, false, new_body_lines)
		local end_insert = row_idx + #new_body_lines
		vim.cmd(string.format("silent normal! %dG=%dG", row_idx + 1, end_insert))
	end

	vim.cmd("normal! gg")

	local def_clean_pattern = string.format("void\\s\\+%s\\s*(.*{", method_name)
	local final_def_row = vim.fn.search(def_clean_pattern, "W")

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

-- Helper to captilalize the first letter (ant -> Ant)
local function capitalize(str)
	return (str:gsub("^%l", string.upper))
end

function R.encapsulate_field()
	local current_row = vim.api.nvim_win_get_cursor(0)[1] - 1
	local line = vim.api.nvim_get_current_line()
	local view = vim.fn.winsaveview()

	-- 1. ANALISAR A VARIÁVEL
	local indent, type, name = line:match("^(%s*)([%w_:*&]+)%s+([%w_]+)%s*;")
	if not type or not name then
		print("Erro: Cursor não está sobre uma declaração válida 'Tipo nome;'")
		return
	end
	local cap_name = (name:gsub("^%l", string.upper))

	-- 2. ENCONTRAR O INÍCIO DA CLASSE
	local class_start_row = vim.fn.search("\\(class\\|struct\\).*{", "bnW")
	if class_start_row == 0 then
		print("Erro: Classe não encontrada.")
		return
	end

	-- 3. DESCOBRIR O ESCOPO ATUAL (Onde a variável está?)
	-- Busca para trás o modificador mais próximo (public: ou private:)
	local modifier_row = vim.fn.search("\\(public\\|private\\):", "bnW", class_start_row)
	local is_already_private = false

	if modifier_row > 0 then
		local modifier_line = vim.api.nvim_buf_get_lines(0, modifier_row - 1, modifier_row, false)[1]
		if modifier_line:match("private:") then
			is_already_private = true
		end
	else
		-- Se não achou modificador, classes são private por default, structs são public.
		-- Vamos assumir 'false' (public) para forçar a criação explicita das seções,
		-- a menos que seja class, mas para segurança, tratamos como se precisasse mover.
		local class_line = vim.api.nvim_buf_get_lines(0, class_start_row - 1, class_start_row, false)[1]
		if class_line:match("class") then
			-- Em class, se não tem modificador no topo, é private.
			is_already_private = true
		end
	end

	-- 4. LOCALIZAR OU CRIAR SEÇÕES (PUBLIC / PRIVATE)
	-- Vamos buscar onde elas estão. Se não existirem, inserimos no topo da classe.

	-- Busca posição do 'private:'
	vim.api.nvim_win_set_cursor(0, { class_start_row, 0 })
	local private_section_row = vim.fn.search("private:", "W")

	-- Busca posição do 'public:'
	vim.api.nvim_win_set_cursor(0, { class_start_row, 0 })
	local public_section_row = vim.fn.search("public:", "W")

	-- Lógica de Criação de Seções Faltantes (Inserir logo após { da classe)
	local insert_offset = 0 -- Controle de linhas adicionadas
	local effective_class_start = class_start_row -- Base 1 do Vim

	-- Se não tem public, cria
	if public_section_row == 0 then
		vim.api.nvim_buf_set_lines(0, effective_class_start, effective_class_start, false, { indent .. "public:" })
		public_section_row = effective_class_start + 1
		insert_offset = insert_offset + 1
		-- Se o private existia, ele foi empurrado pra baixo
		if private_section_row > 0 then
			private_section_row = private_section_row + 1
		end
		-- Se a variável estava abaixo, ela também desceu
		current_row = current_row + 1
	end

	-- Se não tem private, cria
	if private_section_row == 0 then
		-- Insere ANTES do public recém criado ou existente, ou no topo
		-- Estratégia: Colocar private logo no início da classe é mais seguro para atributos
		vim.api.nvim_buf_set_lines(0, effective_class_start, effective_class_start, false, { indent .. "private:" })
		private_section_row = effective_class_start + 1
		insert_offset = insert_offset + 1
		-- O public foi empurrado pra baixo
		public_section_row = public_section_row + 1
		current_row = current_row + 1
	end

	-- 5. MOVIMENTAÇÃO DO CAMPO (Se necessário)
	if is_already_private then
		print("Atributo já é privado. Mantendo no lugar.")
		-- Se já é privado, não deletamos a linha original.
		-- Mas precisamos garantir que não estamos inserindo os métodos no meio do atributo
	else
		print("Movendo atributo para private...")
		-- 1. Cria a linha no private (logo abaixo da tag private:)
		local field_line = string.format("%s%s %s;", indent, type, name)
		vim.api.nvim_buf_set_lines(0, private_section_row, private_section_row, false, { field_line })

		-- 2. Ajusta índices porque inserimos linha
		if public_section_row > private_section_row then
			public_section_row = public_section_row + 1
		end
		current_row = current_row + 1 -- A linha original desceu 1

		-- 3. Deleta a linha original (que era pública)
		vim.api.nvim_buf_set_lines(0, current_row, current_row + 1, false, {})

		-- Como deletamos, o que estava abaixo sobe. Se o public estava abaixo, sobe 1.
		-- Mas geralmente o public está acima ou em outro lugar.
	end

	-- 6. INSERÇÃO DOS MÉTODOS (Sempre no Public)
	local methods_lines = {
		string.format("%s%s get%s() { return %s; }", indent, type, cap_name, name),
		string.format("%svoid set%s(%s %s) { this->%s = %s; }", indent, cap_name, type, name, name, name),
		"",
	}

	-- Insere logo abaixo da tag 'public:'
	vim.api.nvim_buf_set_lines(0, public_section_row, public_section_row, false, methods_lines)

	-- Formatação final
	vim.cmd("silent normal! gg=G")
	-- Tenta restaurar cursor (pode não ser perfeito devido a inserções)
	pcall(vim.fn.winrestview, view)
end

return R
