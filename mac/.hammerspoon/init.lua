hyper = {"ctrl", "alt", "cmd", "shift"}

-- Generic Helpers

function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

function require_if_exists(file)
    if file_exists(file .. ".lua") then
        print(" #### Loading " .. file)
        require(file)
    end
end

hs.urlevent.bind("alert", function(eventName, params)
    hs.alert.show(params['msg'])
end)

require_if_exists("autoreload")
require_if_exists("keyboard")
require_if_exists("yabai")
require_if_exists("auto-audio")
require_if_exists("pomo")
require_if_exists("distractions")
require_if_exists("hs-fuzzy-window-picker")
