local M = {}

local default_rules = require("discipline.default_rules")
local fetch = require("discipline.fetch")

local function log_error(msg)
	vim.notify(msg, vim.log.levels.ERROR, { title = "Discipline plugin error" })
end

function M.create_rule(config)
	assert(config.keys, "config.keys is required")
	if type(config.keys) ~= "table" then
		log_error("config.keys must be a table. Rule: " .. vim.inspect(config))
		return
	end

	local keys = config.keys
	local threshold = config.threshold or 10
	local message = config.message or "Hold on!!"
	local level = config.level or vim.log.levels.WARN
	local icon = config.icon or "😅"
	local timeout = config.timeout or 2000
	local mode = config.mode or "n"

	local notification_id = nil
	local ok = true

	for _, key in ipairs(keys) do
		local count = 0
		local timer = assert(vim.uv.new_timer())
		if not timer then
			log_error("Failed to create timer for key: " .. key)
			return
		end

		local map = key

		vim.keymap.set(mode, key, function()
			if vim.v.count > 0 then
				count = 0
			end

			if count >= threshold then
				ok, notification_id = pcall(vim.notify, message, level, {
					icon = icon,
					replace = notification_id,
					keep = function()
						return count >= threshold
					end,
				})

				if not ok then
					notification_id = nil
					log_error("failed to send notification:" .. vim.inspect(notification_id))
					return map
				end
			else
				count = count + 1
				timer:start(timeout, 0, function()
					count = 0
				end)
				return map
			end
		end, { expr = true, silent = true })
	end
end

function M.apply_rules(rules_list)
	if type(rules_list) ~= "table" then
		log_error("Rules_list must be a table.")
		return
	end
	for _, rule_config in ipairs(rules_list) do
		if type(rule_config) == "table" and rule_config.keys then
			local status, err = pcall(M.create_rule, rule_config)
			if not status then
				log_error("Error creating rule: " .. err .. "\nRule config: " .. vim.inspect(rule_config))
			end
		else
			log_error("Invalid rule format skipped: " .. vim.inspect(rule_config))
		end
	end
end

function M.setup(config)
	config = config or {}

	local function load_and_apply_rules(rules_to_apply)
		if rules_to_apply and type(rules_to_apply) == "table" and #rules_to_apply > 0 then
			M.apply_rules(rules_to_apply)
			vim.notify(
				"Cowboy rules applied (" .. #rules_to_apply .. " rule sets).",
				vim.log.levels.INFO,
				{ title = "Cowboy Plugin" }
			)
		elseif config.use_default_rules ~= false then
			vim.notify("Using default Discipline rules.", vim.log.levels.INFO, { title = "Discipline Plugin" })
			M.apply_rules(default_rules)
		else
			vim.notify("No Discipline rules loaded.", vim.log.levels.WARN, { title = "Discipline Plugin" })
		end
	end

	if config.rules_url then
		vim.notify(
			"Fetching Discipline rules from: " .. config.rules_url,
			vim.log.levels.INFO,
			{ title = "Discipline Plugin" }
		)
		fetch.fetch_rules_from_url(config.rules_url, function(fetched_rules, err)
			vim.schedule(function()
				if err then
					log_error("Failed to fetch custom rules: " .. err)
					if config.rules then
						log_error("Falling back to explicitly provided local rules.")
						load_and_apply_rules(config.rules)
					elseif config.use_default_rules ~= false then
						log_error("Falling back to default rules.")
						load_and_apply_rules(default_rules)
					else
						log_error("No fallback rules provided.")
					end
				else
					load_and_apply_rules(fetched_rules)
				end
			end)
		end)
	elseif config.rules then
		load_and_apply_rules(config.rules)
	elseif config.use_default_rules ~= false then
		load_and_apply_rules(default_rules)
	else
		vim.notify(
			"Discipline plugin setup, but no rules specified to load.",
			vim.log.levels.INFO,
			{ title = "Discipline Plugin" }
		)
	end
end

function M.default_rules()
	M.setup({ use_default_rules = true })
end

return M
