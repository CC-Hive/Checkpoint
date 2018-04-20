

local checkpoint = dofile(shell.dir().."/checkpoint.lua")

local testAPI = dofile(shell.dir().."/testAPI.lua")
local test = testAPI.test
local howlciLog = testAPI.howlci.log

-- tests:
--   terminate part way through file, restart the file and it continues
--   call a non existing checkpoint
--   run all function in the api
--   have a callback error
--   error tracing on and off
--   custom file


-- function tests
--  expected args

local function warnFailCausedSkips()
  howlciLog("warn", "some tests were skipped due to a dependent function failing it's test")
end




local function dummyCallback()
end

local addPassed= test("function tests: expected args: checkpoint.add", true, nil, checkpoint.add, "testLabel", dummyCallback)

if addPassed then 

  local reachPassed = test("function tests: expected args: checkpoint.reach", true, nil, checkpoint.reach, "testLabel", dummyCallback)

  local removePassed = test("function tests: expected args: checkpoint.remove", true, nil, checkpoint.remove, "testLabel", dummyCallback)
  
  checkpoint.add("testLabel", dummyCallback)
  local runPassed = test("function tests: expected args: checkpoint.run", true, nil, checkpoint.run, "testLabel")

else
  warnFailCausedSkips()
end

