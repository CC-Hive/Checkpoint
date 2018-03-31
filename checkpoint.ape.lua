--[[
-- @Name: Checkpoint
-- @Author: Lupus590
-- @License: MIT
--
-- If you are interested in the above format: http://www.computercraft.info/forums2/index.php?/topic/18630-rfc-standard-for-program-metadata-for-graphical-shells-use/
-- 
-- Includes parts from Apemanzilla's Trace program which is avaliable from here: http://www.computercraft.info/forums2/index.php?/topic/27844-trace-simple-stack-traces-for-errors/
-- Permission to include these parts was given here: http://www.computercraft.info/forums2/index.php?/topic/29442-checkpoint-a-work-around-for-persistence/page__view__findpost__p__276148
-- See also the following in reguards to permissions: http://www.computercraft.info/forums2/index.php?/topic/27844-trace-simple-stack-traces-for-errors/page__view__findpost__p__261908
--
-- Checkpoint doesn't save your program's data, it must do that itself. Checkpoint only helps it to get to roughly the right area of code to resume execution.
--
-- One may want to have a table with needed data in which gets passed over checkpoints with each checkpoint segment first checking that this table exists and loading it from a file if it doesn't and the last thing it does before reaching the checkpoint is saving this table to that file.
--
-- The MIT License (MIT)
--
-- Copyright (c) 2018 Lupus590
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--]]

local checkpoint = shell and {} or (_ENV or getfenv())

local checkpointFile = ".checkpoint"

local checkpoints = {}

local checkpointTrace = {}

local nextLabel




-- Code from Trace by Apemanzilla
local function buildStackTrace(rootErr)
    -- TODO: if error is "Terminated" then print Terminated only
    local trace = {}
    local i, hitEnd, _, e = 4, false
 
    repeat
        _, e = pcall(function() error("<tracemarker>", i) end)
        i = i + 1
        if e == "xpcall: <tracemarker>" or e == "pcall: <tracemarker>" then
            hitEnd = true
            break
        end
        table.insert(trace, e)
    until i > 10
 
    table.remove(trace)
    table.remove(trace, 1)
 
    if rootErr:match("^" .. trace[1]:match("^(.-:%d+)")) then table.remove(trace, 1) end
 
    local out = {}
 
    table.insert(out, rootErr)
   
    for i, v in ipairs(trace) do
        table.insert(out, "  at " .. v:match("^(.-:%d+)"))
    end
 
    if not hitEnd then
        table.insert(out, "  ...")
    end
 
    return table.concat(out, "\n")
end

local eshell = setmetatable({getRunningProgram=function() return path end}, {__index = shell})
local env = setmetatable({shell=eshell}, {__index=_ENV or getfenv()})

env.pcall = function(f, ...)
    local args = { ... }
    return xpcall(function() f(unpack(args)) end, buildStackTrace)
end

env.xpcall = function(f, e)
    return xpcall(function() f() end, function(err) e(buildStackTrace(err)) end)
end

-- end of code from Trace
    
    
    

function checkpoint.add(label, callback, ...)
  if type(label) ~= "string" then error("Bad arg[1], expected string, got "..type(label), 2) end
  if type(callback) ~= "function" then error("Bad arg[2], expected function, got "..type(callback), 2) end
  
  checkpoints[label] = {callback = callback, args = {...}, }  
end

function checkpoint.remove(label) -- this is intended for debugging, users can use it to make sure that their programs don't loop on itself when it's not meant to
  if type(label) ~= "string" then error("Bad arg[1], expected string, got "..type(label), 2) end
  if not checkpoints[label] then error("Bad arg[1], no known checkpoint with label "..tostring(label), 2) end
  
  checkpoints[label] = nil  
end

function checkpoint.reach(label)
  if type(label) ~= "string" then error("Bad arg[1], expected string, got "..type(label), 2) end
  if not checkpoints[label] then error("Bad arg[1], no known checkpoint with label '"..tostring(label).."'. You may want to check spelling, scope and such.", 1) end

  local f = fs.open(checkpointFile,"w")
  f.writeLine(label)
  f.close()
  checkpointTrace[#checkpointTrace+1] = label
  nextLabel = label
end

function checkpoint.run(defaultLabel, fileName) -- returns whatever the callbacks do
  if type(defaultLabel) ~= "string" then error("Bad arg[1], expected string, got "..type(defaultLabel), 2) end
  if not checkpoints[defaultLabel] then error("Bad arg[1], no known checkpoint with label "..tostring(defaultLabel), 2) end
  if fileName and type(fileName) ~= "string" then error("Bad arg[2], expected string or nil, got "..type(fileName), 2) end
  -- TODO: check that filename is valid
  
  checkpointFile = fileName or checkpointFile
  nextLabel = defaultLabel
  
  if fs.exists(checkpointFile) then
    local f = fs.open(checkpointFile, "r")
    nextLabel = f.readLine()
    f.close()
    if not checkpoints[nextLabel] then error("Found checkpoint file '"..fileName.."' containing unknown label '"..nextLabel.."'. Are your sure that this is the right file and that nothing is changing it?", 0) end
  end
  
  
  local returnValues
  local unpack = unpack or table.unpack
  while nextLabel ~= nil do
    local l = nextLabel 
    nextLabel = nil
    
    
  
    returnValues = { xpcall(function() return checkpoints[l].callback(unpack(checkpoints[l].args)) end, function(err)
          local stack = buildStackTrace(err)
          printError("\nProgram has crashed! Stack trace:")
          printError(stack)
          
          printError("\nCheckpoints ran in this instance:")
          printError("  "..table.concat(checkpointTrace, "\n  "))
      end) }
      
    table.remove(returnValues, 1)
      
   
    
    
  end
  
  
  -- we have finished the program, delete the checkpointFile so that the program starts from the beginning if ran again
  if fs.exists(checkpointFile) then
    fs.delete(checkpointFile)
  end
  
  
  return unpack(returnValues) 
end


return checkpoint