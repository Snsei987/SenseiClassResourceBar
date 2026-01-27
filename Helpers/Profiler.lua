local _, addonTable = ...

------------------------------------------------------------
-- PERFORMANCE PROFILER
-- Measures execution time and call counts for optimization validation
------------------------------------------------------------

local Profiler = {
    enabled = false,
    data = {},
    sessionStart = 0,
}

function Profiler:Init()
    self.enabled = true
    self.sessionStart = debugprofilestop()
    self.data = {}
    print("|cFF00FF00[SCRB Profiler]|r Profiling enabled. Use /scrb profile to view stats.")
end

function Profiler:Reset()
    self.sessionStart = debugprofilestop()
    self.data = {}
    print("|cFF00FF00[SCRB Profiler]|r Statistics reset.")
end

function Profiler:Track(funcName)
    if not self.enabled then return end
    
    if not self.data[funcName] then
        self.data[funcName] = {
            calls = 0,
            totalTime = 0,
            minTime = math.huge,
            maxTime = 0,
        }
    end
end

function Profiler:Start(funcName)
    if not self.enabled then return end
    
    self:Track(funcName)
    
    -- Store start time in a stack to handle nested calls
    if not self.callStack then
        self.callStack = {}
    end
    
    table.insert(self.callStack, {
        name = funcName,
        startTime = debugprofilestop(),
    })
end

function Profiler:Stop(funcName)
    if not self.enabled or not self.callStack or #self.callStack == 0 then return end
    
    local endTime = debugprofilestop()
    local callInfo = table.remove(self.callStack)
    
    -- Verify we're stopping the right function
    if callInfo.name ~= funcName then
        print("|cFFFF0000[SCRB Profiler]|r Warning: Mismatched Stop() call. Expected:", callInfo.name, "Got:", funcName)
        return
    end
    
    local elapsed = endTime - callInfo.startTime
    local stats = self.data[funcName]
    
    stats.calls = stats.calls + 1
    stats.totalTime = stats.totalTime + elapsed
    stats.minTime = math.min(stats.minTime, elapsed)
    stats.maxTime = math.max(stats.maxTime, elapsed)
end

-- Wrap a function to automatically profile it
function Profiler:Wrap(funcName, func)
    if not self.enabled then return func end
    
    return function(...)
        self:Start(funcName)
        local results = {func(...)}
        self:Stop(funcName)
        return unpack(results)
    end
end

function Profiler:GetStats()
    local sessionDuration = (debugprofilestop() - self.sessionStart) / 1000 -- Convert to seconds
    local stats = {}
    
    for funcName, data in pairs(self.data) do
        local avgTime = data.calls > 0 and (data.totalTime / data.calls) or 0
        
        table.insert(stats, {
            name = funcName,
            calls = data.calls,
            totalTime = data.totalTime,
            avgTime = avgTime,
            minTime = data.minTime == math.huge and 0 or data.minTime,
            maxTime = data.maxTime,
            callsPerSec = sessionDuration > 0 and (data.calls / sessionDuration) or 0,
        })
    end
    
    -- Sort by total time (highest first)
    table.sort(stats, function(a, b)
        return a.totalTime > b.totalTime
    end)
    
    return stats, sessionDuration
end

function Profiler:Print()
    if not self.enabled then
        print("|cFFFF0000[SCRB Profiler]|r Profiler is not enabled. Use /scrb profile start to enable.")
        return
    end
    
    local stats, sessionDuration = self:GetStats()
    
    print("|cFF00FF00[SCRB Profiler]|r Performance Statistics:")
    print(string.format("Session Duration: %.2f seconds", sessionDuration))
    print("─────────────────────────────────────────────────────────────────────────")
    print(string.format("%-35s %8s %10s %8s %8s %8s %8s", 
        "Function", "Calls", "Total(ms)", "Avg(ms)", "Min(ms)", "Max(ms)", "Calls/s"))
    print("─────────────────────────────────────────────────────────────────────────")
    
    for _, stat in ipairs(stats) do
        print(string.format("%-35s %8d %10.2f %8.3f %8.3f %8.3f %8.1f",
            stat.name,
            stat.calls,
            stat.totalTime,
            stat.avgTime,
            stat.minTime,
            stat.maxTime,
            stat.callsPerSec
        ))
    end
    
    print("─────────────────────────────────────────────────────────────────────────")
    
    -- Calculate total overhead
    local totalTime = 0
    local totalCalls = 0
    for _, stat in ipairs(stats) do
        totalTime = totalTime + stat.totalTime
        totalCalls = totalCalls + stat.calls
    end
    
    print(string.format("Total: %d calls, %.2f ms (%.2f%% of session)", 
        totalCalls, totalTime, (totalTime / (sessionDuration * 1000)) * 100))
end

function Profiler:PrintToChat()
    if not self.enabled then
        print("|cFFFF0000[SCRB Profiler]|r Profiler is not enabled.")
        return
    end
    
    local stats, sessionDuration = self:GetStats()
    
    print("|cFF00FF00[SCRB Profiler]|r Top 5 functions by total time:")
    for i = 1, math.min(5, #stats) do
        local stat = stats[i]
        print(string.format("%d. %s: %d calls, %.2fms total, %.3fms avg",
            i, stat.name, stat.calls, stat.totalTime, stat.avgTime))
    end
end

-- Slash command handler
SLASH_SCRBPROFILE1 = "/scrbprofile"
SlashCmdList["SCRBPROFILE"] = function(msg)
    msg = msg:lower():trim()
    
    if msg == "start" or msg == "enable" then
        Profiler:Init()
    elseif msg == "stop" or msg == "disable" then
        Profiler.enabled = false
        print("|cFF00FF00[SCRB Profiler]|r Profiling disabled.")
    elseif msg == "reset" then
        Profiler:Reset()
    elseif msg == "print" or msg == "show" or msg == "" then
        Profiler:Print()
    elseif msg == "chat" then
        Profiler:PrintToChat()
    else
        print("|cFF00FF00[SCRB Profiler]|r Commands:")
        print("  /scrbprofile start  - Enable profiling")
        print("  /scrbprofile stop   - Disable profiling")
        print("  /scrbprofile reset  - Reset statistics")
        print("  /scrbprofile print  - Show detailed stats")
        print("  /scrbprofile chat   - Show summary in chat")
    end
end

addonTable.Profiler = Profiler
