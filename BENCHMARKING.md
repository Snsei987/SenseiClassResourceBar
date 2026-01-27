# Performance Benchmarking System

This system provides tools to measure and validate performance optimizations for SenseiClassResourceBar.

## Quick Start

### 1. Enable Profiling
```
/scrbprofile start
```

### 2. Run Benchmarks
```
/scrbbench full
```

### 3. View Results
```
/scrbprofile print
```

## Profiler Commands

- `/scrbprofile start` - Enable performance profiling
- `/scrbprofile stop` - Disable profiling
- `/scrbprofile reset` - Clear all statistics
- `/scrbprofile print` - Show detailed performance report
- `/scrbprofile chat` - Show summary in chat (top 5 functions)

## Benchmark Commands

- `/scrbbench combat [seconds]` - Simulate combat scenario (default: 30s)
  - Forces frequent bar updates to simulate real combat
  - Good for testing OnUpdate performance
  
- `/scrbbench layout [iterations]` - Test layout recalculation (default: 100)
  - Measures ApplyLayout() performance
  - Should be rare in normal use
  
- `/scrbbench display [iterations]` - Test display updates (default: 1000)
  - Measures UpdateDisplay() performance
  - This is the most frequently called function
  
- `/scrbbench memory` - Show current memory usage
  
- `/scrbbench full` - Run complete benchmark suite
  - Layout test (50 iterations)
  - Display test (500 iterations)
  - Memory snapshot

## Example Workflow

### Before Optimizations

1. Load into game with your character
2. Enable profiling: `/scrbprofile start`
3. Run benchmark suite: `/scrbbench full`
4. Note the results
5. Run a combat simulation: `/scrbbench combat 60`
6. View detailed stats: `/scrbprofile print`
7. **Save/screenshot the results**

### After Optimizations

1. Reload UI (or restart)
2. Enable profiling: `/scrbprofile start`
3. Run the same benchmarks
4. Compare results with "before" data

## What to Look For

### Key Metrics

1. **OnUpdate:Fast / OnUpdate:Slow**
   - Calls/second should be high (10/s for fast, 4/s for slow)
   - Average time per call should be LOW (<0.1ms ideally)
   - This is where polling overhead shows up

2. **BarMixin:UpdateDisplay**
   - Most frequently called function
   - Should have low average time (<0.2ms)
   - High total time is acceptable if calls are necessary

3. **BarMixin:ApplyLayout**
   - Should be called RARELY (not every frame)
   - Can have higher average time (it's expensive)
   - Low call count = good architecture

4. **BarMixin:UpdateFragmentedPowerDisplay**
   - Only relevant for classes with fragmented power (Runes, ComboPoints, etc.)
   - Should have reasonable average time (<0.5ms)

### Expected Improvements After Optimization

- **OnUpdate calls reduced by 90%+** (event-driven updates)
- **Average UpdateDisplay time reduced by 20-40%** (caching, less redundant work)
- **Memory delta should be neutral or lower** (better table reuse)
- **Calls/second for UpdateDisplay should be appropriate** (only when needed, not constant)

## Understanding the Output

```
Function                             Calls  Total(ms)  Avg(ms)  Min(ms)  Max(ms)  Calls/s
─────────────────────────────────────────────────────────────────────────────────────────
OnUpdate:Fast                        10000   1234.56     0.123    0.050    2.500    333.3
BarMixin:UpdateDisplay                5000    567.89     0.114    0.080    1.200    166.7
BarMixin:ApplyLayout                    10    123.45    12.345   10.000   15.000      0.3
```

- **Calls**: How many times the function was called
- **Total(ms)**: Total time spent in this function (cumulative)
- **Avg(ms)**: Average time per call (Total/Calls)
- **Min(ms)**: Fastest single execution
- **Max(ms)**: Slowest single execution (spikes)
- **Calls/s**: How frequently this function is called

## Tips

- Run benchmarks in a consistent location (e.g., Stormwind)
- Disable other addons for cleaner results
- Run each test 2-3 times and average the results
- Test with different classes (some have more complex bars)
- Test both in and out of combat
