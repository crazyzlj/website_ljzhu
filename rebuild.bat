@echo off
REM SETLOCAL
SETLOCAL EnableDelayedExpansion
REM
REM The batch script is used for rebuilding the website based on jemdoc+MathJax on Windows platform using Command Prompt.
REM
REM Liang-Jun Zhu (zlj@lreis.ac.cn)
REM Updated: 2019-07-15
REM
cd %~dp0
rd /s/q build
REM Copy resources
md build
cp -r images build/images
cp -r styles build/styles
cp -r cv build/cv
cp CNAME build/CNAME
REM Build html
for /f "delims=" %%i in ('dir /s/b "*.jemdoc"') do (
    call :build %%~ni %%i
)
echo All mission done!
goto quit

:build
set tmpfn=%1
set tmpfullfn=%2
echo Building %tmpfn%...
jemdoc.py -c mysite.conf -o build/%tmpfn%.html %tmpfullfn%
REM if "%tmpfn:~-3%"==".zh" (
REM     jemdoc.py -c mysite.conf -o build/zh/%tmpfn%.html %tmpfullfn%
REM ) else (
REM     jemdoc.py -c mysite.conf -o build/%tmpfn%.html %tmpfullfn%
REM )

:quit