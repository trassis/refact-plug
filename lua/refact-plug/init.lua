local api = vim.api

api.nvim_create_augroup("MeuPopupGroup", { clear = true })

local M = {}
M.win_id = nil -- Variável para armazenar o ID da janela

function M.bye()
	if M.win_id and api.nvim_win_is_valid(M.win_id) then
		api.nvim_win_close(M.win_id, true)
		M.win_id = nil
		print("fechou")
	end
end

function M.hello()
	print("hi")

	-- -- 1. Cria um buffer temporário e sem nome
	-- local buf = api.nvim_create_buf(false, true)
	-- api.nvim_buf_set_lines(buf, 0, -1, false, { "Olá, Mundo!" })
	--
	-- -- 2. Define as opções da janela flutuante
	-- local opts = {
	-- 	relative = "editor", -- Posição relativa ao editor completo
	-- 	width = 15,
	-- 	height = 1,
	-- 	col = api.nvim_win_get_width(0) / 2 - 7, -- Centraliza horizontalmente
	-- 	row = api.nvim_win_get_height(0) / 2 - 1, -- Centraliza verticalmente
	-- 	style = "minimal",
	-- 	border = "single", -- Adiciona borda simples
	-- }
	--
	-- -- 3. Abre a janela e armazena o ID
	-- print("open floating window")
	-- M.win_id = api.nvim_open_win(buf, true, opts)
	--
	-- -- Fechando
	-- local closingKeys = { "<Esc>", "<CR>", "<Leader>" }

	-- CORREÇÃO: Usar 'ipairs' para iterar sobre a lista
	-- for _, key in ipairs(closingKeys) do
	-- 	vim.keymap.set("n", key, M.bye, { buffer = buf, silent = true, nowait = true })
	-- end
end

return M
