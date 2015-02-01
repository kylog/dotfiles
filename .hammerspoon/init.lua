-- Ensure the IPC command line client is available
hs.ipc.cliInstall()

-- disable animation
hs.window.animationDuration = 0

-- Things we need to clean up at reload
local configFileWatcher = nil
local appWatcher        = nil
local wifiWatcher       = nil
local screenWatcher     = nil

-- Define some keyboard modifier variables
local alt = {"⌥"}
-- TODO: consider binding capslock to cmd+alt+ctrl+shift via Seil and Karabiner
--local hyper = {"⌘", "⌥", "⌃", "⇧"}
local hyper = {"⌘", "⌥", "⌃"}

-- Define monitor names for layout purposes
local display_laptop = "Color LCD"
local display_monitor = "Thunderbolt Display"

-- Defines for WiFi watcher
local homeSSID = "gracie" -- My home WiFi SSID
local lastSSID = hs.wifi.currentNetwork()

-- Defines for screen watcher
local lastNumberOfScreens = #hs.screen.allScreens()

-- Define window layouts
--   Format reminder:
--     {"App name", "Window name", "Display Name", "unitrect", "framerect", "fullframerect"},
local laptop_only = {
    {"iTerm",             nil,          display_laptop, hs.layout.maximized, nil, nil},
    {"Textual",           nil,          display_laptop, hs.layout.maximized, nil, nil},
    {"Google Chrome",     nil,          display_laptop, hs.layout.maximized, nil, nil},
    {"RubyMine",          nil,          display_laptop, hs.layout.maximized, nil, nil},
    {"HipChat",           nil,          display_laptop, hs.layout.maximized, nil, nil},
    {"Evernote",          nil,          display_laptop, hs.layout.maximized, nil, nil},
}

local dual_display = {
    {"iTerm",             nil,          display_laptop,  hs.layout.maximized, nil, nil},
    {"Textual",           nil,          display_laptop,  hs.layout.maximized, nil, nil},
    {"Google Chrome",     nil,          display_laptop,  hs.layout.maximized, nil, nil},
    {"RubyMine",          nil,          display_laptop,  hs.layout.maximized, nil, nil},
    {"HipChat",           nil,          display_monitor, hs.layout.right50,   nil, nil},
    {"Evernote",          nil,          display_monitor, hs.layout.right50,   nil, nil},
}

-- Toggle an application between being the frontmost app, and being hidden
function toggle_application(_app)
    local app = hs.appfinder.appFromName(_app)
    if not app then
        -- FIXME: This should really launch _app
        return
    end
    local mainwin = app:mainWindow()
    if mainwin == hs.window.focusedWindow() then
        mainwin:application():hide()
    else
        mainwin:application():activate(true)
        mainwin:application():unhide()
        mainwin:focus()
    end
end

-- Nudge a window up/down/left/right by a fixed amount
function nudge(direction)
    -- get focused window, if there is one
    win = hs.window.focusedWindow()
    if not win then
      return
    end

    -- get current frame geometry, adjust and apply new setting
    -- no saturation math, sometimes I want to nudge a window off-screen
    frame = win:frame()
    if     direction == "left"  then frame.x = frame.x - 10
    elseif direction == "right" then frame.x = frame.x + 10
    elseif direction == "up"    then frame.y = frame.y - 10
    elseif direction == "down"  then frame.y = frame.y + 10
    end
    win:setFrame(frame)
end

-- Callback function for application events
function applicationWatcher(appName, eventType, appObject)
    if (eventType == hs.application.watcher.activated) then
        if (appName == "Finder") then
            -- Bring all Finder windows forward when one gets activated
            appObject:selectMenuItem({"Window", "Bring All to Front"})
        end
    end
end

-- Callback function for WiFi SSID change events
function ssidChangedCallback()
    newSSID = hs.wifi.currentNetwork()

    if newSSID == homeSSID and lastSSID ~= homeSSID then
        -- We have gone from something that isn't my home WiFi, to something that is
        home_arrived()
    elseif newSSID ~= homeSSID and lastSSID == homeSSID then
        -- We have gone from something that is my home WiFi, to something that isn't
        home_departed()
    end

    lastSSID = newSSID
end

-- Callback function for changes in screen layout
function screensChangedCallback()
    newNumberOfScreens = #hs.screen.allScreens()

    if lastNumberOfScreens ~= newNumberOfScreens then
        if newNumberOfScreens == 1 then
            hs.layout.apply(laptop_only)
        elseif newNumberOfScreens == 2 then
            hs.layout.apply(dual_display)
        end
    end

    lastNumberOfScreens = newNumberOfScreens
end

-- Perform tasks to configure the system for my home WiFi network
function home_arrived()
    hs.notify.show("Hammerspoon", "", "On home wifi", "")
end

-- Perform tasks to configure the system for any WiFi network other than my home
function home_departed()
    hs.notify.show("Hammerspoon", "", "Left home wifi", "")
end

-- Reload config automatically
function reloadConfig()
    configFileWatcher:stop()
    configFileWatcher = nil

    appWatcher:stop()
    appWatcher = nil

    screenWatcher:stop()
    screenWatcher = nil

    wifiWatcher:stop()
    wifiWatcher = nil

    hs.reload()
end

-- Hotkeys to move windows between screens
hs.hotkey.bind(hyper, 'Left', function() hs.window.focusedWindow():moveOneScreenWest() end)
hs.hotkey.bind(hyper, 'Right', function() hs.window.focusedWindow():moveOneScreenEast() end)

-- Hotkeys to resize windows absolutely
hs.hotkey.bind(hyper, 'a', function() hs.window.focusedWindow():moveToUnit(hs.layout.left30) end)
hs.hotkey.bind(hyper, 's', function() hs.window.focusedWindow():moveToUnit(hs.layout.right70) end)
hs.hotkey.bind(hyper, '[', function() hs.window.focusedWindow():moveToUnit(hs.layout.left50) end)
hs.hotkey.bind(hyper, ']', function() hs.window.focusedWindow():moveToUnit(hs.layout.right50) end)
hs.hotkey.bind(hyper, 'm', function() hs.window.focusedWindow():maximize() end)
hs.hotkey.bind(hyper, 'r', function() hs.window.focusedWindow():toggleFullScreen() end)

-- Hotkeys to nudge windows in a direction
hs.hotkey.bind(hyper, 'h', function() nudge("left")  end)
hs.hotkey.bind(hyper, 'j', function() nudge("up")    end)
hs.hotkey.bind(hyper, 'k', function() nudge("down")  end)
hs.hotkey.bind(hyper, 'l', function() nudge("right") end)

-- Hotkeys to trigger defined layouts
-- TODO: 4 layouts: laptop, dual, laptop + dual, laptop + single
hs.hotkey.bind(hyper, '0', function() hs.layout.apply(laptop_only) end)
hs.hotkey.bind(hyper, '9', function() hs.layout.apply(dual_display) end)

-- Application hotkeys
hs.hotkey.bind(hyper, 'i', function() hs.application.launchOrFocus("iTerm") end)
hs.hotkey.bind(hyper, 'c', function() toggle_application("Google Chrome") end)
hs.hotkey.bind(hyper, 't', function() toggle_application("Textual") end)
hs.hotkey.bind(hyper, 'x', function() toggle_application("HipChat") end)

-- Misc hotkeys
hs.hotkey.bind(hyper, 'y', hs.toggleConsole)
hs.hotkey.bind(hyper, 'n', function() os.execute("open ~") end)

-- Window Hints
hs.hotkey.bind(hyper, '.', hs.hints.windowHints)

-- Create and start our callbacks
configFileWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig)
configFileWatcher:start()

appWatcher = hs.application.watcher.new(applicationWatcher)
appWatcher:start()

screenWatcher = hs.screen.watcher.new(screensChangedCallback)
screenWatcher:start()

wifiWatcher = hs.wifi.watcher.new(ssidChangedCallback)
wifiWatcher:start()

-- Finally, show a notification that we finished loading the config successfully
hs.notify.show("Hammerspoon", "", "Config loaded", "")

-- This is some developer debugging stuff. It will cause Hammerspoon to crash if any Lua is being executed on the wrong thread. You probably don't want this in your config :)
local function crashifnotmain(reason)
--  print("crashifnotmain called with reason", reason) -- may want to remove this, very verbose otherwise
  if not hs.crash.isMainThread() then
    print("not in main thread, crashing")
    hs.crash.crash()
  end
end
debug.sethook(crashifnotmain, 'c')

