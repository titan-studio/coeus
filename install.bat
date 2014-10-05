rem Install script for Windows.
rem Usage: install [directory]

@echo off

if [%1] == [] goto PROMPT
goto SETARG

:PROMPT
set /P Install_Dir=Install Coeus to: 
if [%Install_Dir%] == [] goto PROMPT
goto INSTALL

:SETARG
set Install_Dir=%1

:INSTALL
echo Installing Coeus to %Install_Dir%...
robocopy . %Install_Dir% /e /nfl /ndl /njh /njs /nc /ns /np /xd .git /xf .git*

echo Setting environment variables...
setx COEUS_SRC_DIR %Install_Dir%\src 1> nul
setx COEUS_BIN_DIR %Install_Dir%\bin 1> nul

echo Install complete!