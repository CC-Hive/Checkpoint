
local checkpoint = dofile(shell.dir().."/checkpoint.lua") --# Checkpoint can also be loaded with require and os.loadAPI

-- DEMO FLAGS

local doTerminateTest = true --# boolean

local doCheckpointRemoveTest = false --# boolean

local doErrorInCallbackTest = false --# boolean

local useCheckpointErrorTrace = false --# boolean

local checkpointFileName = nil --# nil or string, nil for default, string should be absolute path

-- END OF DEMO FLAGS

local args = {...}


--# Checkpoint works using callbacks, we define a bunch here with inventive names like t, c and d
local function t(...)
  print(table.concat({...}, " ")) --# just test code
  args = {"test"} --# notice that this doesn't effect anything, although 
  checkpoint.reach("second") --# this tells Checkpoint what to run next, checkpoint.reach returns whatever the callback returns
end 

local function c(...)
  print(table.concat({...}, " "))
  
  print("Queuing terminate event, rerun program for next part of test")
  if doTerminateTest then
    os.queueEvent("terminate")
  end
  checkpoint.reach("third")
end

local function d()
  print("Terminate?")
  sleep(0.001) --# catch that terminate if we are on first run, second run won't have a terminate
  print("I'll take that as no")
  
  if doErrorInCallbackTest then
    error("doErrorInCallbackTest")
  end
  
  if doCheckpointRemoveTest then
    checkpoint.remove("third") --# removing checkpoints is more of a debug thing to make sure that your program is flowing in the right direction
    print("removing third checkpoint, prepare for error")

     checkpoint.reach("third")
  end
  return "return test"
end

--# here we define our checkpoints under the following format:
--#   label - this is the name of the checkpoint and what your program will need to use to refer to it
--#   callback - this is the function which gets called when checkpoint.reach is given the corresponding label
--#   callback args - these are the values passed to the callback when it gets called

checkpoint.add("start", t, 1, unpack(args))

checkpoint.add("second", c, 2, unpack(args))

checkpoint.add("third", d)


local r = checkpoint.run("start", checkpointFileName, useCheckpointErrorTrace) --# identifies if your program needs to continue or starts from given label if it doesn't

print(tostring(r)) --# checkpoint.run returns whatever the last checkpoint callback does
