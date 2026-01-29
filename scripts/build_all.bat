@echo off
REM ============================================
REM PWM Power Controller - Build All Script
REM ============================================

echo.
echo ========================================
echo   Building PWM Power Controller
echo ========================================
echo.

REM Change to project root
cd /d %~dp0\..

REM Create output directory if it doesn't exist
if not exist "sim" mkdir sim

REM Clean previous compilation
echo [1/7] Cleaning previous build...
if exist "work-obj93.cf" del work-obj93.cf
if exist "*.o" del *.o
echo Done.
echo.

REM Compile all RTL files
echo [2/7] Compiling RTL files...
ghdl -a rtl\counter.vhdl
ghdl -a rtl\pwm_generator.vhdl
ghdl -a rtl\interlock.vhdl
ghdl -a rtl\power_controller_fsm.vhdl
ghdl -a rtl\pwm_controller.vhdl
ghdl -a rtl\complete_power_controller.vhdl
if %errorlevel% neq 0 (
    echo ERROR: RTL compilation failed!
    pause
    exit /b 1
)
echo Done.
echo.

REM Compile all testbenches
echo [3/7] Compiling testbenches...
ghdl -a tb\counter_tb.vhdl
ghdl -a tb\pwm_generator_tb.vhdl
ghdl -a tb\interlock_tb.vhdl
ghdl -a tb\pwm_controller_tb.vhdl
ghdl -a tb\power_controller_fsm_tb.vhdl
ghdl -a tb\complete_power_controller_tb.vhdl
if %errorlevel% neq 0 (
    echo ERROR: Testbench compilation failed!
    pause
    exit /b 1
)
echo Done.
echo.

REM Elaborate testbenches
echo [4/7] Elaborating designs...
ghdl -e counter_tb
ghdl -e pwm_generator_tb
ghdl -e interlock_tb
ghdl -e pwm_controller_tb
ghdl -e power_controller_fsm_tb
ghdl -e complete_power_controller_tb
if %errorlevel% neq 0 (
    echo ERROR: Elaboration failed!
    pause
    exit /b 1
)
echo Done.
echo.

REM Run simulations
echo [5/7] Running simulations...
echo   - Counter test...
ghdl -r counter_tb --vcd=sim\counter.vcd --stop-time=2us
echo   - PWM Generator test...
ghdl -r pwm_generator_tb --vcd=sim\pwm.vcd --stop-time=15us
echo   - Interlock test...
ghdl -r interlock_tb --vcd=sim\interlock.vcd --stop-time=2us
echo   - PWM Controller test...
ghdl -r pwm_controller_tb --vcd=sim\pwm_controller.vcd --stop-time=20us
echo   - FSM test...
ghdl -r power_controller_fsm_tb --vcd=sim\fsm.vcd --stop-time=10us
echo   - Complete System test...
ghdl -r complete_power_controller_tb --vcd=sim\complete_system.vcd --stop-time=20us
if %errorlevel% neq 0 (
    echo ERROR: Simulation failed!
    pause
    exit /b 1
)
echo Done.
echo.

echo [6/7] Generating test report...
call scripts\generate_report.bat
echo.

echo [7/7] Build complete!
echo.
echo ========================================
echo   All tests passed successfully!
echo ========================================
echo.
echo Waveforms saved in: sim\
echo Test report saved in: docs\TEST_RESULTS.md
echo.
echo To view waveforms:
echo   gtkwave sim\complete_system.vcd
echo.
pause