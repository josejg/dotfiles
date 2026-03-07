-- Keyboard shortcuts

function openTerminal()
    hs.application.launchOrFocus("alacritty")
    hs.eventtap.keyStroke({"cmd"}, "n")
end

function openBrowser()
    k = hs.application.find("Firefox")
    if k == nil then
        hs.application.launchOrFocus("Firefox")
    end
    k:selectMenuItem("New Window")
end

function openBrowser2()
    k = hs.application.find("Brave Browser")
    if k == nil then
        hs.application.launchOrFocus("Brave Browser")
    end
    k:selectMenuItem("New Window")
end

-- Cmd+Return opens new terminal
hs.hotkey.bind({"cmd"}, "return", openTerminal)

-- Cmd+Shift+Return opens new Firefox window
hs.hotkey.bind({"cmd","shift"}, "return", openBrowser)

-- Ctrl+Cmd+Return opens new Brave window
hs.hotkey.bind({"ctrl", "cmd"}, "return", openBrowser2)

-- Hyper+V types contents of clipboard
hs.hotkey.bind(hyper, "V", function() hs.eventtap.keyStrokes(hs.pasteboard.getContents()) end)

-- Hyper+` brings up Hammerspoon console
hs.hotkey.bind(hyper, "`", function() hs.openConsole() end)

-- Hyper+M launches Activity Monitor
hs.hotkey.bind(hyper, "M", function() hs.application.launchOrFocus("Activity Monitor") end)

-- Hyper+S launches Spotify
hs.hotkey.bind(hyper, "S", function() hs.application.launchOrFocus("Spotify") end)

-- Cmd+Alt+Tab provides keyboard-based window switcher
hs.hotkey.bind({"cmd", "alt"}, "tab", function() hs.hints.windowHints() end)

-- Hyper+F toggles app zoom
hs.hotkey.bind(hyper, "F", function() hs.window.focusedWindow():toggleZoom() end)

-- Ctrl+Shift+Escape sleeps the computer
hs.hotkey.bind({"ctrl", "shift"}, "escape", function() hs.caffeinate.systemSleep() end)

-- Ctrl+Cmd+Alt+P toggles Caps Lock
hs.hotkey.bind({"ctrl", "cmd", "alt"}, "P", function() hs.hid.capslock.toggle() end)

-- Cmd+Ctrl+Escape activates screensaver
hs.hotkey.bind({"cmd", "ctrl"}, "escape", function()
  hs.caffeinate.startScreensaver()
end)
