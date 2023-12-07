-- /opt/homebrew/bin/yabai stuff

function bindCmd(mods, key, cmd)
    hs.hotkey.bind(mods, key, function() os.execute(cmd) end)
end

-- focus window
bindCmd({"alt"}, "h", "/opt/homebrew/bin/yabai -m window --focus west")
bindCmd({"alt"}, "j", "/opt/homebrew/bin/yabai -m window --focus south")
bindCmd({"alt"}, "k", "/opt/homebrew/bin/yabai -m window --focus north")
bindCmd({"alt"}, "l", "/opt/homebrew/bin/yabai -m window --focus east")

-- swap window
bindCmd({"shift", "alt"}, "h", "/opt/homebrew/bin/yabai -m window --swap west")
bindCmd({"shift", "alt"}, "j", "/opt/homebrew/bin/yabai -m window --swap south")
bindCmd({"shift", "alt"}, "k", "/opt/homebrew/bin/yabai -m window --swap north")
bindCmd({"shift", "alt"}, "l", "/opt/homebrew/bin/yabai -m window --swap east")

-- move window
bindCmd({"shift", "cmd"}, "h", "/opt/homebrew/bin/yabai -m window --warp west")
bindCmd({"shift", "cmd"}, "j", "/opt/homebrew/bin/yabai -m window --warp south")
bindCmd({"shift", "cmd"}, "k", "/opt/homebrew/bin/yabai -m window --warp north")
bindCmd({"shift", "cmd"}, "l", "/opt/homebrew/bin/yabai -m window --warp east")

-- balance size of windows
-- bindCmd({"shift", "alt"}, "0", "/opt/homebrew/bin/yabai -m space --balance")
-- I use this often so I made it easier to trigger
bindCmd({"alt"}, "b", "/opt/homebrew/bin/yabai -m space --balance")

-- make floating window fill screen
-- bindCmd({ "cmd", "alt"}, "up", "/opt/homebrew/bin/yabai -m window --grid 1:1:0:0:1:1")

-- make floating window fill left-half of screen
-- bindCmd({ "cmd", "alt"}, "left", "/opt/homebrew/bin/yabai -m window --grid 1:2:0:0:1:1")

-- make floating window fill right-half of screen
-- bindCmd({ "cmd", "alt"}, "right", "/opt/homebrew/bin/yabai -m window --grid 1:2:1:0:1:1")


-- fast focus
bindCmd({"cmd", "alt"}, "x", "/opt/homebrew/bin/yabai -m space --focus recent")
bindCmd({"cmd", "alt"}, "z", "/opt/homebrew/bin/yabai -m space --focus prev")
-- bindCmd({ "cmd", "alt"}, "c", "/opt/homebrew/bin/yabai -m space --focus next")
bindCmd({"cmd", "alt"}, "1", "/opt/homebrew/bin/yabai -m space --focus 1")
bindCmd({"cmd", "alt"}, "2", "/opt/homebrew/bin/yabai -m space --focus 2")
bindCmd({"cmd", "alt"}, "3", "/opt/homebrew/bin/yabai -m space --focus 3")
bindCmd({"cmd", "alt"}, "4", "/opt/homebrew/bin/yabai -m space --focus 4")
bindCmd({"cmd", "alt"}, "5", "/opt/homebrew/bin/yabai -m space --focus 5")
bindCmd({"cmd", "alt"}, "6", "/opt/homebrew/bin/yabai -m space --focus 6")
bindCmd({"cmd", "alt"}, "7", "/opt/homebrew/bin/yabai -m space --focus 7")
bindCmd({"cmd", "alt"}, "8", "/opt/homebrew/bin/yabai -m space --focus 8")
bindCmd({"cmd", "alt"}, "9", "/opt/homebrew/bin/yabai -m space --focus 9")
bindCmd({"cmd", "alt"}, "0", "/opt/homebrew/bin/yabai -m space --focus 10")

-- send window to desktop and follow focus
bindCmd({"shift", "cmd"}, "x", "/opt/homebrew/bin/yabai -m window --space recent; /opt/homebrew/bin/yabai -m space --focus recent")
-- bindCmd({ "shift", "cmd"}, "z", "/opt/homebrew/bin/yabai -m window --space prev; /opt/homebrew/bin/yabai -m space --focus prev")
bindCmd({"shift", "cmd"}, "c", "/opt/homebrew/bin/yabai -m window --space next; /opt/homebrew/bin/yabai -m space --focus next")
bindCmd({"shift", "cmd"}, "1", "/opt/homebrew/bin/yabai -m window --space  1; /opt/homebrew/bin/yabai -m space --focus 1")
bindCmd({"shift", "cmd"}, "2", "/opt/homebrew/bin/yabai -m window --space  2; /opt/homebrew/bin/yabai -m space --focus 2")
-- bindCmd({ "shift", "cmd"}, "3", "/opt/homebrew/bin/yabai -m window --space  3; /opt/homebrew/bin/yabai -m space --focus 3")
-- bindCmd({ "shift", "cmd"}, "4", "/opt/homebrew/bin/yabai -m window --space  4; /opt/homebrew/bin/yabai -m space --focus 4")
bindCmd({"shift", "cmd"}, "5", "/opt/homebrew/bin/yabai -m window --space  5; /opt/homebrew/bin/yabai -m space --focus 5")
bindCmd({"shift", "cmd"}, "6", "/opt/homebrew/bin/yabai -m window --space  6; /opt/homebrew/bin/yabai -m space --focus 6")
bindCmd({"shift", "cmd"}, "7", "/opt/homebrew/bin/yabai -m window --space  7; /opt/homebrew/bin/yabai -m space --focus 7")
bindCmd({"shift", "cmd"}, "8", "/opt/homebrew/bin/yabai -m window --space  8; /opt/homebrew/bin/yabai -m space --focus 8")
bindCmd({"shift", "cmd"}, "9", "/opt/homebrew/bin/yabai -m window --space  9; /opt/homebrew/bin/yabai -m space --focus 9")
bindCmd({"shift", "cmd"}, "0", "/opt/homebrew/bin/yabai -m window --space 10; /opt/homebrew/bin/yabai -m space --focus 10")

-- focus monitor
bindCmd({"ctrl", "alt" }, "x", "/opt/homebrew/bin/yabai -m display --focus recent")
bindCmd({"ctrl", "alt" }, "z", "/opt/homebrew/bin/yabai -m display --focus prev")
bindCmd({"ctrl", "alt" }, "c", "/opt/homebrew/bin/yabai -m display --focus next")
bindCmd({"ctrl", "alt" }, "1", "/opt/homebrew/bin/yabai -m display --focus 1")
bindCmd({"ctrl", "alt" }, "2", "/opt/homebrew/bin/yabai -m display --focus 2")
bindCmd({"ctrl", "alt" }, "3", "/opt/homebrew/bin/yabai -m display --focus 3")

-- send window to monitor and follow focus
bindCmd({"ctrl", "cmd" }, "x", "/opt/homebrew/bin/yabai -m window --display recent; /opt/homebrew/bin/yabai -m display --focus recent")
bindCmd({"ctrl", "cmd" }, "z", "/opt/homebrew/bin/yabai -m window --display prev; /opt/homebrew/bin/yabai -m display --focus prev")
bindCmd({"ctrl", "cmd" }, "c", "/opt/homebrew/bin/yabai -m window --display next; /opt/homebrew/bin/yabai -m display --focus next")
bindCmd({"ctrl", "cmd" }, "1", "/opt/homebrew/bin/yabai -m window --display 1; /opt/homebrew/bin/yabai -m display --focus 1")
bindCmd({"ctrl", "cmd" }, "2", "/opt/homebrew/bin/yabai -m window --display 2; /opt/homebrew/bin/yabai -m display --focus 2")
bindCmd({"ctrl", "cmd" }, "3", "/opt/homebrew/bin/yabai -m window --display 3; /opt/homebrew/bin/yabai -m display --focus 3")

-- bindCmd({"ctrl", "cmd" }, "h", "/opt/homebrew/bin/yabai -m window --display prev; /opt/homebrew/bin/yabai -m display --focus prev")
bindCmd({"ctrl", "cmd" }, "l", "/opt/homebrew/bin/yabai -m window --display next; /opt/homebrew/bin/yabai -m display --focus next")

-- move window
bindCmd({"shift", "ctrl"}, "a", "/opt/homebrew/bin/yabai -m window --move rel:-20:0")
bindCmd({"shift", "ctrl"}, "s", "/opt/homebrew/bin/yabai -m window --move rel:0:20")
bindCmd({"shift", "ctrl"}, "w", "/opt/homebrew/bin/yabai -m window --move rel:0:-20")
bindCmd({"shift", "ctrl"}, "d", "/opt/homebrew/bin/yabai -m window --move rel:20:0")

-- increase window size
bindCmd({"shift", "alt"}, "a", "/opt/homebrew/bin/yabai -m window --resize left:-20:0")
bindCmd({"shift", "alt"}, "s", "/opt/homebrew/bin/yabai -m window --resize bottom:0:20")
bindCmd({"shift", "alt"}, "w", "/opt/homebrew/bin/yabai -m window --resize top:0:-20")
bindCmd({"shift", "alt"}, "d", "/opt/homebrew/bin/yabai -m window --resize right:20:0")

-- decrease window size
-- bindCmd({ "shift", "cmd"}, "a", "/opt/homebrew/bin/yabai -m window --resize left:20:0")
-- bindCmd({ "shift", "cmd"}, "s", "/opt/homebrew/bin/yabai -m window --resize bottom:0:-20")
bindCmd({"shift", "cmd"}, "w", "/opt/homebrew/bin/yabai -m window --resize top:0:20")
bindCmd({"shift", "cmd"}, "d", "/opt/homebrew/bin/yabai -m window --resize right:-20:0")

-- set insertion point in focused container
bindCmd({"ctrl", "alt"}, "h", "/opt/homebrew/bin/yabai -m window --insert west")
bindCmd({"ctrl", "alt"}, "j", "/opt/homebrew/bin/yabai -m window --insert south")
bindCmd({"ctrl", "alt"}, "k", "/opt/homebrew/bin/yabai -m window --insert north")
bindCmd({"ctrl", "alt"}, "l", "/opt/homebrew/bin/yabai -m window --insert east")

-- rotate tree
bindCmd({"alt"}, "r", "/opt/homebrew/bin/yabai -m space --rotate 90")
bindCmd({"alt", "shift"}, "r", "/opt/homebrew/bin/yabai -m space --rotate 270")

-- mirror tree y-axis
bindCmd({"alt"}, "y", "/opt/homebrew/bin/yabai -m space --mirror y-axis")

-- mirror tree x-axis
bindCmd({"alt"}, "x", "/opt/homebrew/bin/yabai -m space --mirror x-axis")

-- toggle desktop offset
bindCmd({"alt"}, "a", "/opt/homebrew/bin/yabai -m space --toggle padding; /opt/homebrew/bin/yabai -m space --toggle gap")

-- toggle window parent zoom
bindCmd({"alt"}, "d", "/opt/homebrew/bin/yabai -m window --toggle zoom-parent")

-- toggle window fullscreen zoom
bindCmd({"alt"}, "f", "/opt/homebrew/bin/yabai -m window --toggle zoom-fullscreen")

-- toggle window native fullscreen
bindCmd({"shift", "alt"}, "f", "/opt/homebrew/bin/yabai -m window --toggle native-fullscreen")

-- toggle window border
bindCmd({"shift", "alt"}, "b", "/opt/homebrew/bin/yabai -m window --toggle border")

-- toggle window split type
bindCmd({ "alt"}, "w", "/opt/homebrew/bin/yabai -m window --toggle split")

-- float / unfloat window and center on screen
bindCmd({"alt"}, "t", "/opt/homebrew/bin/yabai -m window --toggle float;\
          /opt/homebrew/bin/yabai -m window --grid 4:4:1:1:2:2")

-- -- toggle stiky
-- bindCmd({"alt"}, "s", "/opt/homebrew/bin/yabai -m window --toggle sticky")

-- toggle sticky, float and resize to picture-in-picture size
bindCmd({"alt"}, "p", "/opt/homebrew/bin/yabai -m window --toggle sticky;\
          /opt/homebrew/bin/yabai -m window --grid 5:5:4:0:1:1")

-- change layout of desktop
bindCmd({"ctrl", "alt"}, "a", "/opt/homebrew/bin/yabai -m space --layout bsp")
bindCmd({"ctrl", "alt"}, "d", "/opt/homebrew/bin/yabai -m space --layout float")

-- create desktop and follow focus - uses jq for parsing json (brew install jq)
bindCmd({"cmd", "alt"}, "n", '/opt/homebrew/bin/yabai -m space --create && \
index="$(/opt/homebrew/bin/yabai -m query --spaces --display | /opt/homebrew/bin/jq \'map(select(."native-fullscreen" == 0))[-1].index\')" && \
/opt/homebrew/bin/yabai -m space --focus "${index}"')

-- create desktop, move window and follow focus - uses jq for parsing json (brew install jq)
bindCmd({"ctrl", "cmd"}, "n", '/opt/homebrew/bin/yabai -m space --create && \
index=$(/opt/homebrew/bin/yabai -m query --spaces --display | /opt/homebrew/bin/jq \'map(select(."native-fullscreen" == 0))[-1].index\') && \
/opt/homebrew/bin/yabai -m window --space "${index}" && \
/opt/homebrew/bin/yabai -m space --focus "${index}"')

-- Destroy current space
bindCmd({"cmd", "alt"}, "delete", "/opt/homebrew/bin/yabai -m space --destroy")
