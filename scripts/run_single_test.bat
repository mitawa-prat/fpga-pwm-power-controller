@echo off
REM ============================================
REM Run Single Test
REM Usage: run_single_test.bat [test_name]
REM Example: run_single_test.bat complete_power_controller
REM ============================================

if "%1"=="" (
    echo Usage: run_single_test.bat [test_name]
    echo.
    echo Available tests:
    echo   - counter
    echo   - pwm_generator
    echo   - interlock
    echo   - pwm_controller
    echo   - power_controller_fsm
    echo   - complete_power_controller
    pause
    exit /b 1
)

cd /d %~dp0\..

echo Running %1 test...
echo.

REM Compile dependencies
ghdl -a rtl\*.vhdl
ghdl -a tb\%1_tb.vhdl
ghdl -e %1_tb
ghdl -r %1_tb --vcd=sim\%1.vcd

if %errorlevel% equ 0 (
    echo.
    echo Test completed successfully!
    echo Waveform: sim\%1.vcd
    echo.
    echo Opening GTKWave...
    gtkwave sim\%1.vcd
) else (
    echo.
    echo Test FAILED!
    pause
)