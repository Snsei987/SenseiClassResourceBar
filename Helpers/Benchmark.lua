local _, addonTable = ...

------------------------------------------------------------
-- BENCHMARK UTILITIES
-- Helps create reproducible performance test scenarios
------------------------------------------------------------

local Benchmark = {}

-- Simulates a combat scenario by forcing frequent updates
function Benchmark:RunCombatSimulation(duration)
    duration = duration or 30 -- Default 30 seconds
    
    print("|cFF00FF00[SCRB Benchmark]|r Starting combat simulation for " .. duration .. " seconds...")
    print("|cFF00FF00[SCRB Benchmark]|r Make sure profiling is enabled: /scrbprofile start")
    
    local startTime = GetTime()
    local endTime = startTime + duration
    local updateCount = 0
    
    -- Create a frame to simulate combat updates
    local frame = CreateFrame("Frame")
    frame:SetScript("OnUpdate", function(self, elapsed)
        local now = GetTime()
        
        if now >= endTime then
            frame:SetScript("OnUpdate", nil)
            print("|cFF00FF00[SCRB Benchmark]|r Combat simulation complete!")
            print("|cFF00FF00[SCRB Benchmark]|r " .. updateCount .. " update cycles simulated")
            print("|cFF00FF00[SCRB Benchmark]|r Use /scrbprofile print to see results")
            return
        end
        
        -- Force all bars to update
        if addonTable.barInstances then
            for _, bar in pairs(addonTable.barInstances) do
                if bar and bar.UpdateDisplay then
                    bar:UpdateDisplay()
                    updateCount = updateCount + 1
                end
            end
        end
    end)
end

-- Test layout recalculation performance
function Benchmark:TestLayoutPerformance(iterations)
    iterations = iterations or 100
    
    print("|cFF00FF00[SCRB Benchmark]|r Testing layout performance with " .. iterations .. " iterations...")
    
    local startTime = debugprofilestop()
    
    if addonTable.barInstances then
        for i = 1, iterations do
            for _, bar in pairs(addonTable.barInstances) do
                if bar and bar.ApplyLayout then
                    bar:ApplyLayout(nil, true)
                end
            end
        end
    end
    
    local endTime = debugprofilestop()
    local elapsed = endTime - startTime
    
    local barCount = 0
    if addonTable.barInstances then
        for _ in pairs(addonTable.barInstances) do
            barCount = barCount + 1
        end
    end
    
    local totalCalls = iterations * barCount
    local avgTime = totalCalls > 0 and (elapsed / totalCalls) or 0
    
    print("|cFF00FF00[SCRB Benchmark]|r Layout test complete!")
    print(string.format("  Total time: %.2f ms", elapsed))
    print(string.format("  Iterations: %d x %d bars = %d calls", iterations, barCount, totalCalls))
    print(string.format("  Average: %.3f ms per call", avgTime))
end

-- Test display update performance
function Benchmark:TestDisplayPerformance(iterations)
    iterations = iterations or 1000
    
    print("|cFF00FF00[SCRB Benchmark]|r Testing display update performance with " .. iterations .. " iterations...")
    
    local startTime = debugprofilestop()
    
    if addonTable.barInstances then
        for i = 1, iterations do
            for _, bar in pairs(addonTable.barInstances) do
                if bar and bar.UpdateDisplay then
                    bar:UpdateDisplay()
                end
            end
        end
    end
    
    local endTime = debugprofilestop()
    local elapsed = endTime - startTime
    
    local barCount = 0
    if addonTable.barInstances then
        for _ in pairs(addonTable.barInstances) do
            barCount = barCount + 1
        end
    end
    
    local totalCalls = iterations * barCount
    local avgTime = totalCalls > 0 and (elapsed / totalCalls) or 0
    
    print("|cFF00FF00[SCRB Benchmark]|r Display update test complete!")
    print(string.format("  Total time: %.2f ms", elapsed))
    print(string.format("  Iterations: %d x %d bars = %d calls", iterations, barCount, totalCalls))
    print(string.format("  Average: %.3f ms per call", avgTime))
end

-- Memory usage snapshot
function Benchmark:MemorySnapshot()
    UpdateAddOnMemoryUsage()
    local memory = GetAddOnMemoryUsage("SenseiClassResourceBar")
    
    print("|cFF00FF00[SCRB Benchmark]|r Memory Usage:")
    print(string.format("  Current: %.2f KB", memory))
    
    return memory
end

-- Run a full benchmark suite
function Benchmark:RunFullSuite()
    print("|cFF00FF00[SCRB Benchmark]|r ═══════════════════════════════════════")
    print("|cFF00FF00[SCRB Benchmark]|r Running Full Benchmark Suite")
    print("|cFF00FF00[SCRB Benchmark]|r ═══════════════════════════════════════")
    
    -- Memory before
    local memBefore = self:MemorySnapshot()
    
    -- Layout test
    print("")
    self:TestLayoutPerformance(50)
    
    -- Display test
    print("")
    self:TestDisplayPerformance(500)
    
    -- Memory after
    print("")
    local memAfter = self:MemorySnapshot()
    local memDelta = memAfter - memBefore
    print(string.format("  Memory delta: %.2f KB", memDelta))
    
    print("")
    print("|cFF00FF00[SCRB Benchmark]|r ═══════════════════════════════════════")
    print("|cFF00FF00[SCRB Benchmark]|r Benchmark Suite Complete!")
    print("|cFF00FF00[SCRB Benchmark]|r ═══════════════════════════════════════")
end

-- Slash command
SLASH_SCRBBENCH1 = "/scrbbench"
SlashCmdList["SCRBBENCH"] = function(msg)
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    cmd = cmd:lower()
    
    if cmd == "combat" then
        local duration = tonumber(arg) or 30
        Benchmark:RunCombatSimulation(duration)
    elseif cmd == "layout" then
        local iterations = tonumber(arg) or 100
        Benchmark:TestLayoutPerformance(iterations)
    elseif cmd == "display" then
        local iterations = tonumber(arg) or 1000
        Benchmark:TestDisplayPerformance(iterations)
    elseif cmd == "memory" or cmd == "mem" then
        Benchmark:MemorySnapshot()
    elseif cmd == "full" or cmd == "suite" then
        Benchmark:RunFullSuite()
    else
        print("|cFF00FF00[SCRB Benchmark]|r Commands:")
        print("  /scrbbench combat [seconds]     - Simulate combat (default: 30s)")
        print("  /scrbbench layout [iterations]  - Test layout performance (default: 100)")
        print("  /scrbbench display [iterations] - Test display updates (default: 1000)")
        print("  /scrbbench memory               - Show current memory usage")
        print("  /scrbbench full                 - Run complete benchmark suite")
    end
end

addonTable.Benchmark = Benchmark
