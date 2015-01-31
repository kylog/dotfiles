-- From http://thume.ca/howto/2014/12/02/using-mjolnir-an-extensible-osx-window-manager/

-- Load Extensions
local application = require "mjolnir.application"
local window      = require "mjolnir.window"
local hotkey      = require "mjolnir.hotkey"
local keycodes    = require "mjolnir.keycodes"
local fnutils     = require "mjolnir.fnutils"
local alert       = require "mjolnir.alert"
local screen      = require "mjolnir.screen"
-- User packages
local grid        = require "mjolnir.bg.grid"
local hints       = require "mjolnir.th.hints"
local appfinder   = require "mjolnir.cmsj.appfinder"

local definitions = nil
local hyper = nil

local gridset = function(frame)
  return function()
    local win = window.focusedwindow()
    if win then
      grid.set(win, frame, win:screen())
    else
      alert.show("No focused window.")
    end
  end
end

auxWin = nil
function saveFocus()
  auxWin = window.focusedwindow()
  alert.show("Window '" .. auxWin:title() .. "' saved.")
end
function focusSaved()
  if auxWin then
    auxWin:focus()
  end
end

local hotkeys = {}

function createHotkeys()
  for key, fun in pairs(definitions) do
    local mod = hyper
    if string.len(key) == 2 and string.sub(key,2,2) == "c" then
      mod = {"cmd"}
    end

    local hk = hotkey.new(mod, string.sub(key,1,1), fun)
    table.insert(hotkeys, hk)
    hk:enable()
  end
end

function rebindHotkeys()
  for i, hk in ipairs(hotkeys) do
    hk:disable()
  end
  hotkeys = {}
  createHotkeys()
  alert.show("Rebound Hotkeys")
end

function applyPlace(win, place)
  local scrs = screen:allscreens()
  local scr = scrs[place[1]]
  if scr then
    grid.set(win, place[2], scr)
  else
    alert.show("Wrong screen layout")
  end
end

function applyLayout(layout)
  return function()
    for appName, place in pairs(layout) do
      local app = appfinder.app_from_name(appName)
      if app then
        for i, win in ipairs(app:allwindows()) do
          applyPlace(win, place)
        end
      end
    end
  end
end

function init()
  createHotkeys()
  keycodes.inputsourcechanged(rebindHotkeys)
  alert.show("Mjolnir, at your service.")
end

-- Actual config =================================

hyper = {"cmd", "alt", "ctrl","shift"}
-- Set grid size.
grid.GRIDWIDTH  = 6
grid.GRIDHEIGHT = 8
grid.MARGINX = 0
grid.MARGINY = 0
local gw = grid.GRIDWIDTH
local gh = grid.GRIDHEIGHT

local gomiddle = {x = 1, y = 1, w = 4, h = 6}
local goleft = {x = 0, y = 0, w = gw/2, h = gh}
local goright = {x = gw/2, y = 0, w = gw/2, h = gh}
local gobig = {x = 0, y = 0, w = gw, h = gh}

local fullApps = {
  "Safari","Xcode","Google Chrome",
}
local layout2 = {
  iTerm = {1, goright},
}
fnutils.each(fullApps, function(app) layout2[app] = {1, gobig} end)

definitions = {
  [";"] = saveFocus,
  a = focusSaved,

  h = gridset(gomiddle),
  t = gridset(goleft),
  n = grid.maximize_window,
  s = gridset(goright),

  g = applyLayout(layout2),

  d = grid.pushwindow_nextscreen,
  r = mjolnir.reload,
  q = function() appfinder.app_from_name("Mjolnir"):kill() end,

  j = function() hints.appHints(window.focusedwindow():application()) end,
  ec = hints.windowHints
}

-- launch and focus applications
fnutils.each({
  { key = "e", app = "Google Chrome" },
  { key = "i", app = "iTerm" },
}, function(object)
    definitions[object.key] = function() application.launchorfocus(object.app) end
end)

init()

-- nudge left/up/down/right with h/j/k/l
-- factor this so it's table-driven
hotkey.bind({"cmd", "alt", "ctrl"}, "H", function()
  local win = window.focusedwindow()
  if win then
    local f = win:frame()
    f.x = f.x - 10
    win:setframe(f)
  end
end)

hotkey.bind({"cmd", "alt", "ctrl"}, "J", function()
  local win = window.focusedwindow()
  if win then
    local f = win:frame()
    f.y = f.y - 10
    win:setframe(f)
  end
end)

hotkey.bind({"cmd", "alt", "ctrl"}, "K", function()
  local win = window.focusedwindow()
  if win then
    local f = win:frame()
    f.y = f.y + 10
    win:setframe(f)
  end
end)

hotkey.bind({"cmd", "alt", "ctrl"}, "L", function()
  local win = window.focusedwindow()
  if win then
    local f = win:frame()
    f.x = f.x + 10
    win:setframe(f)
  end
end)


