#!/usr/bin/env lua

--- @class Utils
local Utils = {}

--- Execute shell command and return output with exit code
--- @param cmd string Command to execute
--- @return string output Command output (trimmed)
--- @return number exitCode Exit code (0 for success)
function Utils.execute_command(cmd)
  local handle = io.popen(cmd .. ' 2>&1')
  if not handle then
    return '', 1
  end
  local result = handle:read('*a')
  local _, _, code = handle:close()
  return (result or ''):gsub('%s+$', ''), code or 1
end

--- Execute a command without waiting for output (async)
--- @param cmd string Command to execute
--- @param verbose? boolean Print command if true
function Utils.execute_async(cmd, verbose)
  if cmd and cmd ~= '' then
    if verbose then
      print('Executing: ' .. cmd)
    end
    os.execute('nohup ' .. cmd .. ' >/dev/null 2>&1 &')
  end
end

--- Check if file exists
--- @param path string File path to check
--- @return boolean true if file exists
function Utils.file_exists(path)
  local file = io.open(path, 'r')
  if file then
    file:close()
    return true
  end
  return false
end

--- Check if file exists and is not empty
--- @param filename string File path to check
--- @return boolean true if file exists and has content
function Utils.file_exists_and_not_empty(filename)
  local file = io.open(filename, 'r')
  if not file then
    return false
  end
  local content = file:read('*a')
  file:close()
  return #content > 0
end

--- Check if a command exists in PATH
--- @param cmd string Command name to check
--- @return boolean true if command exists
function Utils.command_exists(cmd)
  local _, exit_code = Utils.execute_command('command -v ' .. cmd .. ' >/dev/null 2>&1')
  return exit_code == 0
end

--- Check if a process is running
--- @param name string Process name to check
--- @return boolean true if process is running
function Utils.process_running(name)
  local _, exit_code = Utils.execute_command('pgrep -x ' .. name .. ' >/dev/null')
  return exit_code == 0
end

--- Check if the current script is already running
--- @param script_name string Name of the script
--- @return boolean true if already running
function Utils.is_already_running(script_name)
  local handle = io.popen("pgrep -cf '" .. script_name .. "' | grep -qv 1")
  local result = handle:read('*a')
  handle:close()
  return result ~= ''
end

--- Escape shell argument for safe execution
--- @param str string String to escape
--- @return string Escaped string
function Utils.escape_shell_arg(str) return "'" .. str:gsub("'", "'\"'\"'") .. "'" end

--- Truncate string to specified length with ellipsis
--- @param str string String to truncate
--- @param max_length? integer Maximum length (default: 80)
--- @return string Truncated string
function Utils.truncate_string(str, max_length)
  max_length = max_length or 80
  if #str <= max_length then
    return str
  end
  return str:sub(1, max_length - 3) .. '...'
end

--- Sanitize string for display (replace newlines/tabs with spaces)
--- @param content string Content to sanitize
--- @return string Sanitized string
function Utils.sanitize_for_display(content) return content:gsub('\n', ' '):gsub('\t', ' '):gsub('%s+', ' ') end

--- Check if content is valid (not empty or whitespace-only)
--- @param content string Content to validate
--- @return boolean true if content is valid
function Utils.is_valid_content(content) return content and content ~= '' and not content:match('^%s*$') end

--- Send notification using notify-send
--- @param title string Notification title
--- @param message string Notification message
--- @param urgency? string Urgency level (normal, low, critical)
--- @param flags? string Additional notify-send flags
--- @param app_name? string Application name for notification
function Utils.notify(title, message, urgency, flags, app_name)
  urgency = urgency or 'normal'
  flags = flags or ''
  app_name = app_name or 'HyprDots'

  -- Check if notify-send is available
  if not Utils.command_exists('notify-send') then
    print(string.format('[%s] %s: %s', urgency:upper(), title, message))
    return
  end

  local cmd = string.format('notify-send -a "%s" %s -u %s "%s" "%s"', app_name, flags, urgency:upper(), title, message)
  Utils.execute_command(cmd)
end

--- Read all lines from a file
--- @param filename string File path to read
--- @return string[] Array of lines
function Utils.read_file_lines(filename)
  local lines = {}
  local file = io.open(filename, 'r')
  if file then
    for line in file:lines() do
      table.insert(lines, line)
    end
    file:close()
  end
  return lines
end

--- Write content to file
--- @param filename string File path to write
--- @param content string Content to write
--- @return boolean true if successful
function Utils.write_file(filename, content)
  local file = io.open(filename, 'w')
  if file then
    file:write(content)
    file:close()
    return true
  end
  return false
end

--- Append content to file
--- @param filename string File path to append to
--- @param content string Content to append
--- @return boolean true if successful
function Utils.append_to_file(filename, content)
  local file = io.open(filename, 'a')
  if file then
    file:write(content .. '\n')
    file:close()
    return true
  end
  return false
end

--- Parse simple JSON value (limited implementation)
--- @param json_str string JSON string
--- @param path string Key path to extract
--- @return string Extracted value or '0'
function Utils.parse_json_value(json_str, path)
  local pattern = '"' .. path .. '":%s*([%d%.%-]+)'
  local value = json_str:match(pattern)
  return value or '0'
end

--- Check if a value is within specified range
--- @param value number Value to check
--- @param min_val number Minimum value
--- @param max_val number Maximum value
--- @param name string Name for error message
--- @return boolean true if in range
function Utils.check_range(value, min_val, max_val, name)
  if value >= min_val and value <= max_val then
    return true
  else
    print(string.format('WARNING: %s must be %d - %d. Current value: %d', name, min_val, max_val, value))
    return false
  end
end

--- Get script directory from debug info
--- @param level? number Stack level (default: 2)
--- @return string Script directory path
function Utils.get_script_dir(level)
  level = level or 2
  local script_path = debug.getinfo(level, 'S').source:sub(2):match('(.*/)')
  return script_path or './'
end

--- Get script name from arguments
--- @param arg_zero string arg[0] value
--- @return string Script name without path
function Utils.get_script_name(arg_zero) return arg_zero:match('([^/]+)$') or arg_zero end

--- Encode string to base64
--- @param content string Content to encode
--- @return string Base64 encoded string
function Utils.encode_base64(content)
  local result, _ = Utils.execute_command('echo ' .. Utils.escape_shell_arg(content) .. ' | base64 -w 0')
  return result
end

--- Decode string from base64
--- @param encoded string Base64 encoded content
--- @return string Decoded string
function Utils.decode_base64(encoded)
  local result, _ = Utils.execute_command('echo ' .. Utils.escape_shell_arg(encoded) .. ' | base64 --decode')
  return result
end

--- Find files matching pattern
--- @param directory string Directory to search
--- @param pattern string Find pattern/expression
--- @return string[] Array of file paths
function Utils.find_files(directory, pattern)
  local files = {}
  local cmd = string.format('find "%s" %s 2>/dev/null', directory, pattern)
  local result, exit_code = Utils.execute_command(cmd)

  if exit_code == 0 and result ~= '' then
    for file in result:gmatch('[^\r\n]+') do
      if file ~= '' then
        table.insert(files, file)
      end
    end
  end

  return files
end

--- Validate numeric environment variable
--- @param var_name string Environment variable name
--- @param default_value number Default numeric value
--- @param min_val? number Minimum allowed value
--- @param max_val? number Maximum allowed value
--- @return number Validated numeric value
function Utils.get_env_number(var_name, default_value, min_val, max_val)
  local env_val = os.getenv(var_name)
  if env_val and env_val:match('^%d+$') then
    local num = tonumber(env_val)
    if num then
      if min_val and num < min_val then
        return default_value
      end
      if max_val and num > max_val then
        return default_value
      end
      return num
    end
  end
  return default_value
end

return Utils
