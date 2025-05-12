local M = {}

function M.fetch_rules_from_url(url, callback)
	if not url or url == "" then
		return callback(nil, "URL is empty")
	end

	local stdout_lines, stderr_lines = {}, {}

	vim.fn.jobstart({ "curl", "-sSfL", url }, {
		stdout_buffered = false,
		stderr_buffered = false,

		on_stdout = function(_, data, _)
			for _, ln in ipairs(data) do
				stdout_lines[#stdout_lines + 1] = ln
			end
		end,

		on_stderr = function(_, data, _)
			for _, ln in ipairs(data) do
				stderr_lines[#stderr_lines + 1] = ln
			end
		end,

		on_exit = function(_, code, _)
			if code ~= 0 then
				local err_msg = table.concat(stderr_lines, "\n")
				return callback(nil, err_msg ~= "" and err_msg or ("curl exited with code " .. code))
			end

			local full = table.concat(stdout_lines, "\n")
			local ok, rules = pcall(vim.json.decode, full)
			if not ok then
				return callback(nil, "JSON parse error: " .. rules)
			end
			return callback(rules, nil)
		end,
	})
end

return M
