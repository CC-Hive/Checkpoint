--[[
-- @Name: testAPI
-- @Author: Lupus590
-- @License: MIT
-- @Description: testing API for use with howl.ci
--
-- If you are interested in the above format: http://www.computercraft.info/forums2/index.php?/topic/18630-rfc-standard-for-program-metadata-for-graphical-shells-use/
-- 
--
--  The MIT License (MIT)
--
--  Copyright (c) 2018 Lupus590
--
--  Permission is hereby granted, free of charge, to any person obtaining a copy
--  of this software and associated documentation files (the "Software"), to deal
--  in the Software without restriction, including without limitation the rights
--  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--  copies of the Software, and to permit persons to whom the Software is
--  furnished to do so, subject to the following conditions:
--
--  The above copyright notice and this permission notice shall be included in all
--  copies or substantial portions of the Software.
--
--  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--  SOFTWARE.
--]]

-- This stub of howlci is public domain as far as Lupus590 is conserned, the howlci API may have strings attached which may exstend to this stub.
local howlci = howlci or {status = function(status, message) -- stub the bit of howlci that we use so that tests can be run manually
  if not type(status) == "string" then error("arg[1] must be a string",2) end
  status = string.lower(status)
  local termIsColour = term and term.isColour and term.isColour()
  if status == "success" or status == "ok" or status == "pass" then
    if termIsColour then term.setTextColour(colours.green) end
    write("[success] ")
  elseif status == "failure" or status == "fail" then
    if termIsColour then term.setTextColour(colours.yellow) end
    write("[failure] ")
  elseif status == "error" then
    if termIsColour then term.setTextColour(colours.red) end
    write("[error] ")
  else
    error("arg[1] not a valid status, see https://squiddev-cc.github.io/howl.ci/docs/api.html", 2)
  end
  
  if termIsColour then term.setTextColour(colours.white) end
  print(tostring(message))
end, 
-- TODO: decide if I will put the rest of the howl.ci API here
}


local testAPI = {
howlci = howlci,

-- returnValueCheckFunction should take the actual return values as args, this is table.unpacked into the args of the callback function
test = function(testName, expectOK, returnValueCheckFunction, funcToTest, ...) -- the bulk of the API, this is what you are going to want to use most
  if returnValueCheckFunction and type(returnValueCheckFunction) ~= "function" then
    error("Bad arg[3], expected function or nil, got "..type(returnValueCheckFunction),2)
  end
  local funcArgs = table.pack(...)
  local returnedValues = table.pack(pcall(funcToTest, table.unpack(funcArgs, 1, funcArgs.n)))
  local ok = table.remove(returnedValues, 1)
  if ok == expectOK then
    if returnValueCheckFunction then
      local r = returnValueCheckFunction(table.unpack(returnedValues, 1, returnedValues.n)
      if type(r) ~= "boolean" then
        error("Bad arg[3], got function which returned non boolean value "..tostring(r))
      end
      if r then 
        howlci.status("ok", testName)
      else
        howlci.status("fail", testName.."\nFailed with error:\nreturnValueCheckFunction returned false")
      end
    else
      howlci.status("ok", testName)
    end
  else
    howlci.status("fail", testName.."\nFailed with error:\n"..err)
  end
end,

-- below are utility functions which you may want to use in your returnValueCheckFunctions
-- based off: https://github.com/IUdalov/u-test#list-of-all-assertions
equal = function(a, b)
  return a ==  b
end,
not_equal = function(a, b)
  return a~= b
end,
is_false = function(a)
  return a == false
end,
is_true = function(a)
  return a == true
end,
is_not_nil = function(a)
  return type(a) ~= nil
end,
is_truthy = function(a) -- will a resolve as true in an if statement without any comparison: if a then...
  return (a ~= nil and a~= false)
end,
is_nil = function(a)
  return type(a) == "nil"
end,
is_boolean = function(a)
  return type(a) == "boolean"
end,
is_string = function(a)
  return type(a) == "string"
end,
is_number = function(a)
  return type(a) == "number"
end,
is_table = function(a)
  return type(a) == "table"
end,
is_function = function(a)
  return type(a) == "function"
end,
}

return testAPI


