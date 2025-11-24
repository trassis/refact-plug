local M = {}
local ns = vim.api.nvim_create_namespace("RefactorPlugin")

local function setup_diagnostics()
    vim.diagnostic.config(
        { underline = { severity = { min = vim.diagnostic.severity.WARN } }, virtual_text = true, signs = false, }, ns)
    vim.api.nvim_set_hl(0, "RefactorUnderline", { underline = true, sp = "#ffaa00", })
end

local function detect_long_lines(lines)
    local diagnostics = {}

    if type(lines) == "string" then
        lines = vim.split(lines, "\n")
    end

    for i, line in ipairs(lines) do
        local line_content = line:gsub("^%s+", "")
        if #line_content > 80 then
            table.insert(diagnostics, {
                lnum = i - 1,
                col = 0,
                end_lnum = i - 1,
                end_col = #line,
                hl_group = "RefactorUnderline",
                severity = vim.diagnostic.severity.WARN,
                message = "Code Smell — Line exceeds 80 characters",
                source = "RefactorPlug",
            })
        end
    end
    return diagnostics
end

local function normalize(str)
    return str:gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
end

local function detect_duplicate_code(lines, min_block_size)
    local diagnostics = {}
    local norm_lines = {}

    min_block_size = min_block_size or 5  

    for i, line in ipairs(lines) do
        norm_lines[i] = normalize(line)
    end

    local seen = {}

    for start = 1, #norm_lines - min_block_size + 1 do
        local max_size = #norm_lines - start + 1
        for size = min_block_size, max_size do
            local block = table.concat(norm_lines, "\n", start, start + size - 1)
            local hash = vim.fn.sha256(block)

            if seen[hash] then
                local prev = seen[hash]
                table.insert(diagnostics, {
                    lnum = start - 1,
                    col = 0,
                    end_lnum = start + size - 2,
                    hl_group = "RefactorUnderline",
                    severity = vim.diagnostic.severity.WARN,
                    message = string.format(
                        "Duplicate code detected (%d lines). First occurrence at lines %d–%d.",
                        size,
                        prev.start,
                        prev.start + prev.size - 1
                    ),
                    source = "RefactorPlug",
                })
            else
                seen[hash] = { start = start, size = size }
            end
        end
    end

    return diagnostics
end

local function detect_large_classes(lines, max_class_size)
    local diagnostics = {}
    local open_classes = {}

    for i, line in ipairs(lines) do
        local clean_line = line:gsub("//.*", "")

        local class_name = clean_line:match("class%s+([%w_]+)")
        local is_forward_decl = clean_line:find(";") and not clean_line:find("{")

        if class_name and not is_forward_decl then
            table.insert(open_classes, {
                name = class_name,
                start_lnum = i,
                depth = 0,
                started_scope = false
            })
        end

        local _, open_count = clean_line:gsub("{", "")
        local _, close_count = clean_line:gsub("}", "")

        for j = #open_classes, 1, -1 do
            local cls = open_classes[j]

            if not cls.started_scope then
                if open_count > 0 then
                    cls.started_scope = true
                    cls.depth = cls.depth + open_count - close_count
                end
            else
                cls.depth = cls.depth + open_count - close_count
            end

            if cls.started_scope and cls.depth <= 0 then
                local class_size = i - cls.start_lnum + 1

                if class_size > max_class_size then
                    table.insert(diagnostics, {
                        lnum = cls.start_lnum - 1,
                        col = 0,
                        end_lnum = cls.start_lnum - 1,
                        end_col = #lines[cls.start_lnum],
                        hl_group = "RefactorUnderline",
                        severity = vim.diagnostic.severity.WARN,
                        message = string.format("Code Smell — Class '%s' is too large (%d lines).", cls.name,
                            class_size),
                        source = "RefactorPlug",
                    })
                end

                table.remove(open_classes, j)
            end
        end
    end

    return diagnostics
end

local function detect_methods_with_many_params(lines, max_params)
    local diagnostics = {}
    local i = 1
    while i <= #lines do
        local line = lines[i]
        local open_paren_col = line:find("%(")

        if open_paren_col then
            local pre_paren = line:sub(1, open_paren_col - 1)

            local is_method_call = pre_paren:find("%.") or pre_paren:find("%-%>")

            local is_control_flow = pre_paren:match("%f[%w]if%s*$") or
                pre_paren:match("%f[%w]for%s*$") or
                pre_paren:match("%f[%w]while%s*$") or
                pre_paren:match("%f[%w]switch%s*$") or
                pre_paren:match("%f[%w]catch%s*$")

            local is_keyword_call = pre_paren:match("%f[%w]new%s+") or
                pre_paren:match("%f[%w]return%s+")

            if not is_method_call and not is_control_flow and not is_keyword_call then
                local func_start_line = i
                local func_text = line:sub(open_paren_col)
                local close_paren_line = i

                while not func_text:find("%)") and close_paren_line < #lines do
                    close_paren_line = close_paren_line + 1
                    func_text = func_text .. " " .. lines[close_paren_line]
                end

                local params_str = func_text:match("%b()")
                if params_str then
                    params_str = params_str:sub(2, -2)
                    local params = {}

                    for param in params_str:gmatch("[^,]+") do
                        table.insert(params, param)
                    end

                    if #params > max_params then
                        local curr_line = func_start_line
                        for _, param in ipairs(params) do
                            local param_trim = param:gsub("^%s*", ""):gsub("%s*$", "")

                            local start_col, end_col = nil, nil

                            for search_line_idx = curr_line, close_paren_line do
                                local search_line = lines[search_line_idx]
                                start_col, end_col = search_line:find(param_trim, 1, true)
                                if start_col then
                                    curr_line = search_line_idx
                                    table.insert(diagnostics, {
                                        lnum = search_line_idx - 1,
                                        col = start_col - 1,
                                        end_lnum = search_line_idx - 1,
                                        end_col = end_col,
                                        severity = vim.diagnostic.severity.WARN,
                                        message = "Code Smell — Too many parameters (" .. #params .. ")",
                                        source = "RefactorPlug",
                                    })
                                    break
                                end
                            end
                        end
                    end
                end
                i = close_paren_line
            end
        end
        i = i + 1
    end

    return diagnostics
end

local function detect_long_methods(lines, max_lines)
    local diagnostics = {}
    local open_blocks = {} 

    max_lines = max_lines or 20 

    for i, line in ipairs(lines) do
        local clean_line = line:gsub('".-"', ""):gsub("//.*", "")
        
        local is_control = clean_line:match("%f[%w]if%s*%(") or 
                           clean_line:match("%f[%w]for%s*%(") or 
                           clean_line:match("%f[%w]while%s*%(") or 
                           clean_line:match("%f[%w]switch%s*%(") or 
                           clean_line:match("%f[%w]catch%s*%(")

        local is_structure = clean_line:match("%f[%w]class%s+") or 
                             clean_line:match("%f[%w]struct%s+") or 
                             clean_line:match("%f[%w]namespace%s+")

        local has_params = clean_line:match("%b()")
        local is_method_candidate = has_params and not is_control and not is_structure

        for char in clean_line:gmatch(".") do
            if char == "{" then
                table.insert(open_blocks, { 
                    start_lnum = i, 
                    is_method = is_method_candidate 
                })
                is_method_candidate = false

            elseif char == "}" then
                local block = table.remove(open_blocks)
                
                if block and block.is_method then
                    local method_size = i - block.start_lnum + 1
                    
                    if method_size > max_lines then
                        table.insert(diagnostics, {
                            lnum = block.start_lnum - 1,
                            col = 0,
                            end_lnum = i - 1,  
                            end_col = #lines[i],
                            hl_group = "RefactorUnderline",
                            severity = vim.diagnostic.severity.WARN,
                            message = string.format(
                                "Code Smell: Long Method (%d lines). Recommended: max %d.",
                                method_size, max_lines
                            ),
                            source = "RefactorPlug",
                        })
                    end
                end
            end
        end
    end

    return diagnostics
end


function M.detect_smells()
    setup_diagnostics()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local diagnostics = {}
    vim.list_extend(diagnostics, detect_long_lines(lines))
    vim.list_extend(diagnostics, detect_duplicate_code(lines, 5))
    vim.list_extend(diagnostics, detect_large_classes(lines, 50))
    vim.list_extend(diagnostics, detect_methods_with_many_params(lines, 5))
    vim.list_extend(diagnostics, detect_long_methods(lines, 40))
    vim.diagnostic.set(ns, 0, diagnostics)
end

return M
