-- this is the CI file which will be run
if not howlci then
  error("This file requires howlci, for a self build use howl manually.")
end

-- compied from https://github.com/SquidDev-CC/Howl/blob/954d89371cf3ceeca2b26ec8c690d6540b818a59/.build.lua
if _HOST then howlci.log("info", "Host: " .. _HOST) end
if _CC_VERSION then howlci.log("info", "CC Version" .. _CC_VERSION) end
if _MC_VERSION then howlci.log("info", "MC Version" .. _MC_VERSION) end
if _LUAJ_VERSION then howlci.log("info", "LuaJ Version " .. _LUAJ_VERSION) end



local ok, err = pcall(shell.run, "test.lua")
if not ok then
  howlci.status("error", err)
else
  howlci.status("ok", "no errors have gotten through test.lua")
end





howlci.close() --tell howlci that we are done
