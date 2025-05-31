#!/usr/bin/env lua

--- @alias BatteryStatus "Discharging" | "Charging" | "Not charging" | "Full" | "Unknown"
--- @alias NotificationUrgency "NORMAL" | "LOW" | "CRITICAL"

--- @class BatteryConfig
local config = {
	battery_full_threshold = 100,
	battery_critical_threshold = 5,
	unplug_charger_threshold = 80,
	battery_low_threshold = 20,
	timer = 120,
	notify = 1140,
	interval = 5,
	execute_critical = "systemctl suspend",
	execute_low = "",
	execute_unplug = "",
	execute_charging = "",
	execute_discharging = "",
	verbose = false,
}

--- @class BatteryState
local state = {
	battery_status = "Unknown",
	battery_percentage = 0,
	last_battery_status = nil,
	last_battery_percentage = nil,
	last_notified_percentage = 0,
	prev_status = nil,
	lt = 0,
	undock = false,
}

local io = require("io")
local os = require("os")

--- Execute a shell command and return its output
--- @param cmd string
--- @return string?
local function execute_command(cmd)
	local handle = io.popen(cmd)
	if not handle then
		return nil
	end
	local result = handle:read("*a")
	handle:close()
	return result and result:gsub("%s+$", "") or nil
end

--- Execute a command without waiting for output
--- @param cmd string
local function execute_async(cmd)
	if cmd and cmd ~= "" then
		if config.verbose then
			print("Executing: " .. cmd)
		end
		os.execute("nohup " .. cmd .. " >/dev/null 2>&1 &")
	end
end

--- Check if the system is a laptop by detecting battery
--- @return boolean
local function is_laptop()
	local result = execute_command("find /sys/class/power_supply -name 'BAT*' | wc -l")
	local battery_count = tonumber(result) or 0

	if battery_count > 0 then
		return true
	else
		print("No battery detected. If you think this is an error please post a report to the repo")
		os.exit(0)
	end
end

--- Display verbose information about battery status
local function fn_verbose()
	if config.verbose then
		print("=============================================")
		print(string.format("        Battery Status: %s", state.battery_status))
		print(string.format("        Battery Percentage: %d", state.battery_percentage))
		print("=============================================")
	end
end

--- Send a notification using notify-send
--- @param flags string
--- @param urgency NotificationUrgency
--- @param title string
--- @param message string
local function fn_notify(flags, urgency, title, message)
	-- Check if notify-send is available
	local notify_available = execute_command("command -v notify-send")
	if not notify_available then
		print(string.format("[%s] %s: %s", urgency, title, message))
		return
	end

	local cmd = string.format("notify-send -a 'Power' %s -u %s '%s' '%s'", flags, urgency, title, message)
	if config.verbose then
		print("Notification: " .. cmd)
	end
	execute_command(cmd)
end

--- Handle battery percentage thresholds and notifications
local function fn_percentage()
	-- Unplug notification
	if
		state.battery_percentage >= config.unplug_charger_threshold
		and state.battery_status ~= "Discharging"
		and state.battery_status ~= "Full"
		and (state.battery_percentage - state.last_notified_percentage) >= config.interval
	then
		if config.verbose then
			print(
				string.format(
					"Prompt:UNPLUG: %d %s %d",
					config.unplug_charger_threshold,
					state.battery_status,
					state.battery_percentage
				)
			)
		end
		fn_notify(
			"-t 5000",
			"CRITICAL",
			"Battery Charged",
			string.format("Battery is at %d%%. You can unplug the charger!", state.battery_percentage)
		)
		state.last_notified_percentage = state.battery_percentage

	-- Critical battery notification with countdown
	elseif state.battery_percentage <= config.battery_critical_threshold and state.battery_status == "Discharging" then
		local count = config.timer
		while count > 0 do
			-- Recheck battery status
			get_battery_info()

			if state.battery_status ~= "Discharging" then
				break
			end

			local minutes = math.floor(count / 60)
			local seconds = count % 60
			fn_notify(
				"-t 5000 -r 69",
				"CRITICAL",
				"Battery Critically Low",
				string.format(
					"%d%% is critically low. Device will execute %s in %d:%02d.",
					state.battery_percentage,
					config.execute_critical,
					minutes,
					seconds
				)
			)
			count = count - 1
			os.execute("sleep 1")
		end

		if count == 0 and state.battery_status == "Discharging" then
			execute_async(config.execute_critical)
		end

	-- Low battery notification
	elseif
		state.battery_percentage <= config.battery_low_threshold
		and state.battery_status == "Discharging"
		and (state.last_notified_percentage - state.battery_percentage) >= config.interval
	then
		if config.verbose then
			print(
				string.format(
					"Prompt:LOW: %d %s %d",
					config.battery_low_threshold,
					state.battery_status,
					state.battery_percentage
				)
			)
		end
		fn_notify(
			"-t 5000",
			"CRITICAL",
			"Battery Low",
			string.format("Battery is at %d%%. Connect the charger.", state.battery_percentage)
		)
		state.last_notified_percentage = state.battery_percentage
		execute_async(config.execute_low)
	end
end

--- Handle battery status changes and notifications
local function fn_status()
	if state.battery_percentage >= config.battery_full_threshold and state.battery_status ~= "Discharging" then
		if config.verbose then
			print(string.format("Full and %s", state.battery_status))
		end
		state.battery_status = "Full"
	end

	if state.battery_status == "Discharging" then
		if config.verbose then
			print(string.format("Case:%s Level: %d", state.battery_status, state.battery_percentage))
		end

		if state.prev_status ~= "Discharging" then
			state.prev_status = state.battery_status
			local urgency = state.battery_percentage <= config.battery_low_threshold and "CRITICAL" or "NORMAL"
			fn_notify(
				"-t 5000 -r 54321",
				urgency,
				"Charger Plug OUT",
				string.format("Battery is at %d%%.", state.battery_percentage)
			)
			execute_async(config.execute_discharging)
		end
		fn_percentage()

	elseif state.battery_status == "Charging" then
		if config.verbose then
			print(string.format("Case:%s Level: %d", state.battery_status, state.battery_percentage))
		end

		if state.prev_status == "Discharging" then
			state.prev_status = state.battery_status
			local urgency = state.battery_percentage >= config.unplug_charger_threshold and "CRITICAL" or "NORMAL"
			fn_notify(
				"-t 5000 -r 54321",
				urgency,
				"Charger Plug In",
				string.format("Battery is at %d%%.", state.battery_percentage)
			)
			execute_async(config.execute_charging)
		end
		fn_percentage()

	elseif state.battery_status == "Full" then
		if config.verbose then
			print(string.format("Case:%s Level: %d", state.battery_status, state.battery_percentage))
		end

		local now = os.time()
		if state.prev_status ~= "Full" or (now - state.lt >= (config.notify * 60)) then
			fn_notify("-t 5000 -r 54321", "CRITICAL", "Battery Full", "Please unplug your Charger")
			state.prev_status = state.battery_status
			state.lt = now
			execute_async(config.execute_charging)
		end

	elseif state.battery_status == "Not charging" then
		if config.verbose then
			print(string.format("Case:%s Level: %d", state.battery_status, state.battery_percentage))
		end
		fn_percentage()

	else
		if config.verbose then
			print(string.format("Unknown status: %s Level: %d", state.battery_status, state.battery_percentage))
		end
		fn_percentage()
	end
end

--- Get battery information from system files
function get_battery_info()
	local total_percentage = 0
	local battery_count = 0
	local status = "Unknown"

	-- Find all battery directories
	local batteries_result = execute_command("find /sys/class/power_supply -name 'BAT*' 2>/dev/null")
	if not batteries_result or batteries_result == "" then
		if config.verbose then
			print("No batteries found")
		end
		return
	end

	for battery_path in batteries_result:gmatch("[^\r\n]+") do
		local status_result = execute_command(string.format("cat %s/status 2>/dev/null", battery_path))
		local capacity_result = execute_command(string.format("cat %s/capacity 2>/dev/null", battery_path))

		if status_result and capacity_result then
			status = status_result
			local percentage = tonumber(capacity_result)
			if percentage then
				total_percentage = total_percentage + percentage
				battery_count = battery_count + 1
				if config.verbose then
					print(string.format("Battery %s: %s %d%%", battery_path, status, percentage))
				end
			end
		end
	end

	if battery_count > 0 then
		state.battery_status = status
		state.battery_percentage = math.floor(total_percentage / battery_count)
	else
		state.battery_status = "Unknown"
		state.battery_percentage = 0
	end
end

--- Display configuration information
local function config_info()
	print(string.format(
		[[

Battery notification configuration:

      STATUS      THRESHOLD    INTERVAL
      Full        %d%%         %d Minutes
      Critical    %d%%         %d Seconds then '%s'
      Low         %d%%         %d%% change then '%s'
      Unplug      %d%%         %d%% change then '%s'

      Charging: %s
      Discharging: %s
]],
		config.battery_full_threshold,
		config.notify,
		config.battery_critical_threshold,
		config.timer,
		config.execute_critical ~= "" and config.execute_critical or "none",
		config.battery_low_threshold,
		config.interval,
		config.execute_low ~= "" and config.execute_low or "none",
		config.unplug_charger_threshold,
		config.interval,
		config.execute_unplug ~= "" and config.execute_unplug or "none",
		config.execute_charging ~= "" and config.execute_charging or "none",
		config.execute_discharging ~= "" and config.execute_discharging or "none"
	))
end

--- Check if a value is within the specified range
--- @param value number
--- @param min_val number
--- @param max_val number
--- @param name string
--- @return boolean
local function check_range(value, min_val, max_val, name)
	if value >= min_val and value <= max_val then
		return true
	else
		print(string.format("WARNING: %s must be %d - %d. Current value: %d", name, min_val, max_val, value))
		return false
	end
end

--- Monitor battery using inotify or polling
local function monitor_battery()
	local sleep_interval = 5
	local last_check = 0

	while true do
		get_battery_info()

		if state.battery_status ~= state.last_battery_status or
		   state.battery_percentage ~= state.last_battery_percentage then

			state.last_battery_status = state.battery_status
			state.last_battery_percentage = state.battery_percentage

			fn_verbose()
			fn_status()
		end

		os.execute(string.format("sleep %d", sleep_interval))
	end
end

--- Main function
local function main()
	-- Clean up any existing lock files
	os.execute("rm -f /tmp/hyprdots.batterynotify* 2>/dev/null")

	config_info()

	if config.verbose then
		print("Verbose Mode is ON...")
	end

	-- Validate configuration ranges
	local valid = true
	valid = check_range(config.battery_full_threshold, 80, 100, "Full Threshold") and valid
	valid = check_range(config.battery_critical_threshold, 2, 50, "Critical Threshold") and valid
	valid = check_range(config.battery_low_threshold, 10, 80, "Low Threshold") and valid
	valid = check_range(config.unplug_charger_threshold, 50, 100, "Unplug Threshold") and valid
	valid = check_range(config.timer, 60, 1000, "Timer") and valid
	valid = check_range(config.notify, 1, 1140, "Notify") and valid
	valid = check_range(config.interval, 1, 10, "Interval") and valid

	if not valid then
		print("Configuration validation failed. Please check your settings.")
		os.exit(1)
	end

	if not is_laptop() then
		return
	end

	-- Initialize battery state
	get_battery_info()
	state.last_notified_percentage = state.battery_percentage
	state.prev_status = state.battery_status

	if config.verbose then
		print("Starting battery monitoring...")
		print(string.format("Initial state: %s at %d%%", state.battery_status, state.battery_percentage))
	end

	-- Start monitoring
	monitor_battery()
end

--- Command line argument handling
local function handle_args()
	local args = arg or {}

	for _, argument in ipairs(args) do
		if argument == "-m" or argument == "--modify" then
			local editor = os.getenv("EDITOR") or "nvim"
			local script_path = debug.getinfo(1, "S").source:sub(2)
			print(string.format("Opening %s with %s", script_path, editor))
			os.execute(string.format("%s '%s'", editor, script_path))
			os.exit(0)
		elseif argument == "-i" or argument == "--info" then
			config_info()
			os.exit(0)
		elseif argument == "-v" or argument == "--verbose" then
			config.verbose = true
		elseif argument == "-t" or argument == "--test" then
			print("Testing battery detection...")
			if is_laptop() then
				get_battery_info()
				print(string.format("Battery Status: %s", state.battery_status))
				print(string.format("Battery Percentage: %d%%", state.battery_percentage))

				-- Test notification
				fn_notify("-t 3000", "NORMAL", "Battery Monitor Test",
				         string.format("Battery is at %d%% and %s", state.battery_percentage, state.battery_status:lower()))
			end
			os.exit(0)
		elseif argument == "-h" or argument == "--help" then
			print([[Usage: batterynotify.lua [options]

Options:
  -m, --modify     Edit this script
  -i, --info       Display configuration information
  -v, --verbose    Enable verbose/debugging mode
  -t, --test       Test battery detection and notifications
  -h, --help       Show this help message

The script monitors battery status and sends notifications for:
- Low battery warnings
- Critical battery with countdown to suspend
- Charger plug/unplug events
- Battery full notifications]])
			os.exit(0)
		elseif argument:match("^%-") then
			print("Unknown option: " .. argument)
			print("Use --help for usage information")
			os.exit(1)
		end
	end
end

-- Initialize and run
handle_args()
main()
