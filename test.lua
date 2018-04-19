

local checkpoint = dofile(shell.dir().."/checkpoint.lua")

local testAPI = dofile(shell.dir().."/testAPI.lua")
local test = testAPI.test

-- tests:
--   terminate part way through file, restart the file and it continues
--   call a non existing checkpoint
--   run all function in the api
--   have a callback error
--   error tracing on and off
--   custom file


-- function tests
--  expected args



local function dummyCallback()
end

test("function tests: expected args: checkpoint.add", true, nil, checkpoint.add, "testLabel", dummyCallback)

test("function tests: expected args: checkpoint.add", true, nil, checkpoint.add, "testLabel", dummyCallback)

test("function tests: expected args: checkpoint.add", true, nil, checkpoint.add, "testLabel", dummyCallback)
