-- Yabai window manager keybindings

local yabai = "/opt/homebrew/bin/yabai"

function bindCmd(mods, key, cmd)
    hs.hotkey.bind(mods, key, function() os.execute(cmd) end)
end

-- Toggle yabai service
hs.hotkey.bind({"alt"}, "q", function()
    local output = os.execute("pgrep yabai > /dev/null")
    if output then
        os.execute(yabai .. " --stop-service")
        hs.alert.show("Yabai service stopped")
    else
        os.execute(yabai .. " --start-service")
        hs.alert.show("Yabai service started")
    end
end)

-- Focus window (falls through to focus display)
bindCmd({"alt"}, "h", yabai .. " -m window --focus west || " .. yabai .. " -m display --focus west")
bindCmd({"alt"}, "j", yabai .. " -m window --focus south || " .. yabai .. " -m display --focus south")
bindCmd({"alt"}, "k", yabai .. " -m window --focus north || " .. yabai .. " -m display --focus north")
bindCmd({"alt"}, "l", yabai .. " -m window --focus east || " .. yabai .. " -m display --focus east")

-- Swap window (falls through to move to display)
bindCmd({"shift", "alt"}, "h", yabai .. " -m window --swap west || $(" .. yabai .. " -m window --display west; " .. yabai .. " -m display --focus west)")
bindCmd({"shift", "alt"}, "j", yabai .. " -m window --swap south || $(" .. yabai .. " -m window --display south; " .. yabai .. " -m display --focus south)")
bindCmd({"shift", "alt"}, "k", yabai .. " -m window --swap north || $(" .. yabai .. " -m window --display north; " .. yabai .. " -m display --focus north)")
bindCmd({"shift", "alt"}, "l", yabai .. " -m window --swap east || $(" .. yabai .. " -m window --display east; " .. yabai .. " -m display --focus east)")

-- Warp window (falls through to move to display)
bindCmd({"shift", "cmd"}, "h", yabai .. " -m window --warp west || $(" .. yabai .. " -m window --display west; " .. yabai .. " -m display --focus west)")
bindCmd({"shift", "cmd"}, "j", yabai .. " -m window --warp south || $(" .. yabai .. " -m window --display south; " .. yabai .. " -m display --focus south)")
bindCmd({"shift", "cmd"}, "k", yabai .. " -m window --warp north || $(" .. yabai .. " -m window --display north; " .. yabai .. " -m display --focus north)")
bindCmd({"shift", "cmd"}, "l", yabai .. " -m window --warp east || $(" .. yabai .. " -m window --display east; " .. yabai .. " -m display --focus east)")

-- Move window to display with arrow keys
bindCmd({"ctrl", "cmd", "alt"}, "left", yabai .. " -m window --display west; " .. yabai .. " -m display --focus west")
bindCmd({"ctrl", "cmd", "alt"}, "right", yabai .. " -m window --display east; " .. yabai .. " -m display --focus east")

-- Balance window sizes
bindCmd({"alt"}, "b", yabai .. " -m space --balance")

-- Focus space
bindCmd({"cmd", "alt"}, "x", yabai .. " -m space --focus recent")
bindCmd({"cmd", "alt"}, "z", yabai .. " -m space --focus prev")
bindCmd({"cmd", "alt"}, "1", yabai .. " -m space --focus 1")
bindCmd({"cmd", "alt"}, "2", yabai .. " -m space --focus 2")
bindCmd({"cmd", "alt"}, "3", yabai .. " -m space --focus 3")
bindCmd({"cmd", "alt"}, "4", yabai .. " -m space --focus 4")
bindCmd({"cmd", "alt"}, "5", yabai .. " -m space --focus 5")
bindCmd({"cmd", "alt"}, "6", yabai .. " -m space --focus 6")
bindCmd({"cmd", "alt"}, "7", yabai .. " -m space --focus 7")
bindCmd({"cmd", "alt"}, "8", yabai .. " -m space --focus 8")
bindCmd({"cmd", "alt"}, "9", yabai .. " -m space --focus 9")
bindCmd({"cmd", "alt"}, "0", yabai .. " -m space --focus 10")

-- Send window to space and follow focus
bindCmd({"shift", "cmd"}, "x", yabai .. " -m window --space recent; " .. yabai .. " -m space --focus recent")
bindCmd({"shift", "cmd"}, "c", yabai .. " -m window --space next; " .. yabai .. " -m space --focus next")
bindCmd({"shift", "cmd"}, "1", yabai .. " -m window --space  1; " .. yabai .. " -m space --focus 1")
bindCmd({"shift", "cmd"}, "2", yabai .. " -m window --space  2; " .. yabai .. " -m space --focus 2")
bindCmd({"shift", "cmd"}, "5", yabai .. " -m window --space  5; " .. yabai .. " -m space --focus 5")
bindCmd({"shift", "cmd"}, "6", yabai .. " -m window --space  6; " .. yabai .. " -m space --focus 6")
bindCmd({"shift", "cmd"}, "7", yabai .. " -m window --space  7; " .. yabai .. " -m space --focus 7")
bindCmd({"shift", "cmd"}, "8", yabai .. " -m window --space  8; " .. yabai .. " -m space --focus 8")
bindCmd({"shift", "cmd"}, "9", yabai .. " -m window --space  9; " .. yabai .. " -m space --focus 9")
bindCmd({"shift", "cmd"}, "0", yabai .. " -m window --space 10; " .. yabai .. " -m space --focus 10")

-- Focus display
bindCmd({"ctrl", "alt"}, "x", yabai .. " -m display --focus recent")
bindCmd({"ctrl", "alt"}, "z", yabai .. " -m display --focus prev")
bindCmd({"ctrl", "alt"}, "c", yabai .. " -m display --focus next")
bindCmd({"ctrl", "alt"}, "1", yabai .. " -m display --focus 1")
bindCmd({"ctrl", "alt"}, "2", yabai .. " -m display --focus 2")
bindCmd({"ctrl", "alt"}, "3", yabai .. " -m display --focus 3")

-- Send window to display and follow focus
bindCmd({"ctrl", "cmd"}, "x", yabai .. " -m window --display recent; " .. yabai .. " -m display --focus recent")
bindCmd({"ctrl", "cmd"}, "z", yabai .. " -m window --display prev; " .. yabai .. " -m display --focus prev")
bindCmd({"ctrl", "cmd"}, "c", yabai .. " -m window --display next; " .. yabai .. " -m display --focus next")
bindCmd({"ctrl", "cmd"}, "1", yabai .. " -m window --display 1; " .. yabai .. " -m display --focus 1")
bindCmd({"ctrl", "cmd"}, "2", yabai .. " -m window --display 2; " .. yabai .. " -m display --focus 2")
bindCmd({"ctrl", "cmd"}, "3", yabai .. " -m window --display 3; " .. yabai .. " -m display --focus 3")
bindCmd({"ctrl", "cmd"}, "l", yabai .. " -m window --display next; " .. yabai .. " -m display --focus next")

-- Move floating window
bindCmd({"shift", "ctrl"}, "a", yabai .. " -m window --move rel:-20:0")
bindCmd({"shift", "ctrl"}, "s", yabai .. " -m window --move rel:0:20")
bindCmd({"shift", "ctrl"}, "w", yabai .. " -m window --move rel:0:-20")
bindCmd({"shift", "ctrl"}, "d", yabai .. " -m window --move rel:20:0")

-- Resize window (grow)
bindCmd({"shift", "alt"}, "a", yabai .. " -m window --resize left:-20:0")
bindCmd({"shift", "alt"}, "s", yabai .. " -m window --resize bottom:0:20")
bindCmd({"shift", "alt"}, "w", yabai .. " -m window --resize top:0:-20")
bindCmd({"shift", "alt"}, "d", yabai .. " -m window --resize right:20:0")

-- Resize window (shrink)
bindCmd({"shift", "cmd"}, "w", yabai .. " -m window --resize top:0:20")
bindCmd({"shift", "cmd"}, "d", yabai .. " -m window --resize right:-20:0")

-- Set insertion point
bindCmd({"ctrl", "alt"}, "h", yabai .. " -m window --insert west")
bindCmd({"ctrl", "alt"}, "j", yabai .. " -m window --insert south")
bindCmd({"ctrl", "alt"}, "k", yabai .. " -m window --insert north")
bindCmd({"ctrl", "alt"}, "l", yabai .. " -m window --insert east")

-- Rotate and mirror
bindCmd({"alt"}, "r", yabai .. " -m space --rotate 90")
bindCmd({"alt", "shift"}, "r", yabai .. " -m space --rotate 270")
bindCmd({"alt"}, "y", yabai .. " -m space --mirror y-axis")
bindCmd({"alt"}, "x", yabai .. " -m space --mirror x-axis")

-- Toggle padding/gap
bindCmd({"alt"}, "a", yabai .. " -m space --toggle padding; " .. yabai .. " -m space --toggle gap")

-- Toggle zoom
bindCmd({"alt"}, "d", yabai .. " -m window --toggle zoom-parent")
bindCmd({"alt"}, "f", yabai .. " -m window --toggle zoom-fullscreen")
bindCmd({"shift", "alt"}, "f", yabai .. " -m window --toggle native-fullscreen")

-- Toggle border
bindCmd({"shift", "alt"}, "b", yabai .. " -m window --toggle border")

-- Toggle split
bindCmd({"alt"}, "w", yabai .. " -m window --toggle split")

-- Float and center
bindCmd({"alt"}, "t", yabai .. " -m window --toggle float; " .. yabai .. " -m window --grid 4:4:1:1:2:2")

-- Sticky picture-in-picture
bindCmd({"alt"}, "p", yabai .. " -m window --toggle sticky; " .. yabai .. " -m window --grid 5:5:4:0:1:1")

-- Layout switching
bindCmd({"ctrl", "alt"}, "a", yabai .. " -m space --layout bsp")
bindCmd({"ctrl", "alt"}, "d", yabai .. " -m space --layout float")

-- Create/destroy spaces
bindCmd({"cmd", "alt"}, "n", yabai .. ' -m space --create && index="$(' .. yabai .. " -m query --spaces --display | /opt/homebrew/bin/jq 'map(select(.\"native-fullscreen\" == 0))[-1].index')\" && " .. yabai .. ' -m space --focus "${index}"')
bindCmd({"ctrl", "cmd"}, "n", yabai .. ' -m space --create && index=$(' .. yabai .. " -m query --spaces --display | /opt/homebrew/bin/jq 'map(select(.\"native-fullscreen\" == 0))[-1].index') && " .. yabai .. ' -m window --space "${index}" && ' .. yabai .. ' -m space --focus "${index}"')
bindCmd({"cmd", "alt"}, "delete", yabai .. " -m space --destroy")

-- Restart yabai
bindCmd({'ctrl', 'cmd', 'alt'}, 'r', yabai .. ' --restart-service')
