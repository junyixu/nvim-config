local vim = vim
local M = { loaded = false }
_G.fcitx_loaded = false

local function warn(msg)
  if vim and vim.api and vim.api.nvim_echo then
    vim.api.nvim_echo({ { msg, 'WarningMsg' } }, true, {})
  else
    print(msg)
  end
end

local ok, ldbus = pcall(require, 'ldbus')
if not ok then
  warn('fcitx.vim not loaded: ' .. tostring(ldbus))
  return M
end

local controller = {
  bus_name = 'org.fcitx.Fcitx5',
  path = '/controller',
  interface = 'org.fcitx.Fcitx.Controller1',
}

local FcitxComm = {}
FcitxComm.__index = FcitxComm

function FcitxComm.new()
  local bus, err = ldbus.bus.get 'session'
  if not bus then
    error(err or 'failed to connect to the DBus session bus')
  end
  return setmetatable({ bus = bus }, FcitxComm)
end

function FcitxComm:_call(method)
  local msg, err = ldbus.message.new_method_call(controller.bus_name, controller.path, controller.interface, method)
  if not msg then
    error(err or ('failed to build DBus message: ' .. method))
  end
  local reply, send_err = self.bus:send_with_reply_and_block(msg)
  if not reply then
    error(send_err or ('DBus call failed: ' .. method))
  end
  return reply
end

function FcitxComm:_call_value(method)
  local reply = self:_call(method)
  local iter = reply:iter_init()
  if not iter then
    return nil
  end
  return iter:get_basic()
end

function FcitxComm:status()
  local state = tonumber(self:_call_value 'State') or 0
  return state == 2
end

function FcitxComm:activate()
  self:_call 'Activate'
end

function FcitxComm:deactivate()
  self:_call 'Deactivate'
end

function FcitxComm:current()
  return self:_call_value 'CurrentInputMethod' or ''
end

function FcitxComm:current_and_rime()
  return self:current()
end

local Fcitx
local fcitx_loaded = false

local function set_loaded(value)
  fcitx_loaded = not not value
  M.loaded = fcitx_loaded
  _G.fcitx_loaded = fcitx_loaded
end

local function is_silent()
  if not vim or not vim.g then
    return false
  end
  local value = vim.g.silent_unsupported
  if value == nil then
    return false
  end
  if type(value) == 'number' then
    return value ~= 0
  end
  if type(value) == 'string' then
    return value ~= '' and value ~= '0'
  end
  return not not value
end

local function init_connection()
  local ok_conn, conn_or_err = pcall(FcitxComm.new)
  if not ok_conn then
    set_loaded(false)
    if not is_silent() then
      warn(('fcitx.vim not loaded: %s'):format(tostring(conn_or_err)))
    end
    return nil, conn_or_err
  end
  Fcitx = conn_or_err
  set_loaded(true)
  return true
end

local function may_reconnect(fn)
  return function(...)
    if not fcitx_loaded or not Fcitx then
      return
    end
    for _ = 1, 2 do
      local ok_call, result = pcall(fn, ...)
      if ok_call then
        return result
      end
      warn(('fcitx.vim: %s'):format(tostring(result)))
      local reconnect_ok = init_connection()
      if not reconnect_ok then
        break
      end
    end
  end
end

local function fcitx2en_impl()
  if not Fcitx then
    return
  end
  if Fcitx:status() then
    vim.b.inputtoggle = 1
    Fcitx:deactivate()
  end
end

local function fcitx2zh_impl()
  if not Fcitx then
    return
  end
  local toggle = vim.b.inputtoggle
  if toggle ~= nil then
    if toggle == 1 then
      Fcitx:activate()
      vim.b.inputtoggle = 0
    end
  else
    vim.b.inputtoggle = 0
  end
end

local function fcitx_current_im_impl()
  if not Fcitx then
    return ''
  end
  return Fcitx:current()
end

local function fcitx_current_im_and_rime_impl()
  if not Fcitx then
    return ''
  end
  return Fcitx:current_and_rime()
end

M.fcitx2en = may_reconnect(fcitx2en_impl)
M.fcitx2zh = may_reconnect(fcitx2zh_impl)
M.fcitx_current_im = may_reconnect(fcitx_current_im_impl)
M.fcitx_current_im_and_rime = may_reconnect(fcitx_current_im_and_rime_impl)
M.reconnect = init_connection

init_connection()

return M
