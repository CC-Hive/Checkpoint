--[[
-- @Name: Checkpoint
-- @Author: Lupus590
-- @License: MIT
-- @URL: https://github.com/CC-Hive/Checkpoint
--
-- If you are interested in the above format: http://www.computercraft.info/forums2/index.php?/topic/18630-rfc-standard-for-program-metadata-for-graphical-shells-use/
-- 
-- Includes stack tracing code from SquidDev's Mildly Better Shell (Also known as MBS): http://www.computercraft.info/forums2/index.php?/topic/29253-mildly-better-shell-various-extensions-to-the-default-shell/
--
-- Checkpoint doesn't save your program's data, it must do that itself. Checkpoint only helps it to get to roughly the right area of code to resume execution.
--
-- One may want to have a table with needed data in which gets passed over checkpoints with each checkpoint segment first checking that this table exists and loading it from a file if it doesn't and the last thing it does before reaching the checkpoint is saving this table to that file.
--
-- Checkpoint's License:
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
--
--
-- MBS's License:
--
--  The MIT License (MIT)
--
--  Copyright (c) 2017 SquidDev
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
--
--
--]]

-- TODO: detect when we errored and warn somehow to prevent boot, error, reboot loops
-- May be able to detect rebotes using some monstocity of os.clock os.time os.day


-- TODO: cleanup code

local checkpoint = shell and {} or (_ENV or getfenv())

local checkpointFile = ".checkpoint"

local checkpoints = {}

local checkpointTrace = {}

local nextLabel

local useStackTracing = true -- sets default for the API, program can set at runtime with third arg to checkpoint.run

local intentionalError -- true if traceback function belives the error is intentional, false otherwise, nil if traceback has not be generated

-- MBS Stack Tracing

local function traceback(x)
  -- Attempt to detect error() and error("xyz", 0).
  -- This probably means they're erroring the program intentionally and so we
  -- shouldn't display anything.
  if x == nil or (type(x) == "string" and not x:find(":%d+:")) then
    intentionalError = true
    return x
  end

  intentionalError = false
  if type(debug) == "table" and type(debug.traceback) == "function" then
    return debug.traceback(tostring(x), 2)
  else
    local level = 3
    local out = { tostring(x), "stack traceback:" }
    while true do
      local _, msg = pcall(error, "", level)
      if msg == "" then break end

      out[#out + 1] = "  " .. msg
      level = level + 1
    end

    return table.concat(out, "\n")
  end
end

local function trimTraceback(target, marker)
  local ttarget, tmarker = {}, {}
  for line in target:gmatch("([^\n]*)\n?") do ttarget[#ttarget + 1] = line end
  for line in marker:gmatch("([^\n]*)\n?") do tmarker[#tmarker + 1] = line end

  local t_len, m_len = #ttarget, #tmarker
  while t_len >= 3 and ttarget[t_len] == tmarker[m_len] do
    table.remove(ttarget, t_len)
    t_len, m_len = t_len - 1, m_len - 1
  end

  return ttarget
end

-- ENd of MBS Stack Tracing




function checkpoint.add(label, callback, ...)
  if type(label) ~= "string" then error("Bad arg[1], expected string, got "..type(label), 2) end
  if type(callback) ~= "function" then error("Bad arg[2], expected function, got "..type(callback), 2) end
  
  checkpoints[label] = {callback = callback, args = table.pack(...), }  
end

function checkpoint.remove(label) -- this is intended for debugging, users can use it to make sure that their programs don't loop on itself when it's not meant to
  if type(label) ~= "string" then error("Bad arg[1], expected string, got "..type(label), 2) end
  if not checkpoints[label] then error("Bad arg[1], no known checkpoint with label "..tostring(label), 2) end
  
  checkpoints[label] = nil  
end

function checkpoint.reach(label)
  if type(label) ~= "string" then error("Bad arg[1], expected string, got "..type(label), 2) end
  if not checkpoints[label] then error("Bad arg[1], no known checkpoint with label '"..tostring(label).."'. You may want to check spelling, scope and such.", 2) end

  local f = fs.open(checkpointFile,"w")
  f.writeLine(label)
  f.close()
  nextLabel = label
end

function checkpoint.run(defaultLabel, fileName, stackTracing) -- returns whatever the last callback returns (xpcall stuff stripped if used)
  if type(defaultLabel) ~= "string" then error("Bad arg[1], expected string, got "..type(defaultLabel), 2) end
  if not checkpoints[defaultLabel] then error("Bad arg[1], no known checkpoint with label "..tostring(defaultLabel), 2) end
  if fileName and type(fileName) ~= "string" then error("Bad arg[2], expected string or nil, got "..type(fileName), 2) end
  if stackTracing and type(stackTracing) ~= "boolean" then error("Bad arg[3], expected boolean or nil, got "..type(stackTracing), 2) end
  
  if stackTracing ~= nil then 
    useStackTracing = stackTracing
  end
  
  checkpointFile = fileName or checkpointFile
  nextLabel = defaultLabel
  
 
  
  if fs.exists(checkpointFile) then
    local f = fs.open(checkpointFile, "r")
    nextLabel = f.readLine()
    f.close()
    if not checkpoints[nextLabel] then error("Found checkpoint file '"..fileName.."' containing unknown label '"..nextLabel.."'. Are your sure that this is the right file and that nothing is changing it?", 0) end
  end
    
  
  local returnValues
  
  while nextLabel ~= nil do
    local l = nextLabel 
    checkpointTrace[#checkpointTrace+1] = nextLabel
    nextLabel = nil
    
    if useStackTracing then 
      
      
      
      -- The following line is horrible, but we need to capture the current traceback and run
      -- the function on the same line.
      intentionalError = nil
      returnValues = table.pack(xpcall(function() return checkpoints[l].callback(table.unpack(checkpoints[l].args, 1, checkpoints[l].args.n)) end, traceback))
      local ok   = table.remove(returnValues, 1)
      if not ok then 
        local trace = traceback("checkpoint.lua"..":1:")
        local errorMessage = ""
        if returnValues[1] ~= nil then
          trace = trimTraceback(returnValues[1], trace)

          local max, remaining = 15, 10
          if #trace > max then
            for i = #trace - max, 0, -1 do table.remove(trace, remaining + i) end
            table.insert(trace, remaining, "  ...")
          end
     
          
          errorMessage = table.concat(trace, "\n")
          
          
          if intentionalError == false and errorMessage ~= "Terminated" then
            errorMessage = errorMessage.."\n\nCheckpoints ran in this instance:\n  "..table.concat(checkpointTrace, "\n  ").." <- error occured in\n"
          end
          
        end
        
        error(errorMessage, 0)
      end -- if not ok
    else
      returnValues = table.pack(checkpoints[l].callback(table.unpack(checkpoints[l].args, 1, checkpoints[l].args.n)))
    end
    
  end
   
  
  -- we have finished the program, delete the checkpointFile so that the program starts from the beginning if ran again
  if fs.exists(checkpointFile) then
    fs.delete(checkpointFile)
  end
   
  return type(returnValues) == "table" and table.unpack(returnValues, 1, returnValues.n) or returnValues -- if it's a table, return the unpacked table, else return whatever it is
 
 end


return checkpoint