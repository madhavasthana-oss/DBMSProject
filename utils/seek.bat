@echo off
:: ============================================================
::  Oracle Credential Checker
::  Run this to find your username, service name, and status
:: ============================================================

echo.
echo  =========================================
echo   Oracle DB — Credential Checker
echo  =========================================
echo.

:: Try connecting as sysdba (no password needed locally)
echo [1/3] Connecting as SYSDBA...
echo.

sqlplus -s / as sysdba <<EOF 2>nul
SET PAGESIZE 50
SET LINESIZE 120
SET FEEDBACK OFF
SET HEADING ON

PROMPT === Current Container / Service Name ===
SHOW CON_NAME;

PROMPT.
PROMPT === Open User Accounts ===
SELECT username, account_status, default_tablespace
FROM dba_users
WHERE account_status = 'OPEN'
ORDER BY username;

PROMPT.
PROMPT === All PDBs (Pluggable Databases) ===
SELECT name, open_mode FROM v$pdbs;

PROMPT.
PROMPT === Listener Services ===
SELECT value FROM v$parameter WHERE name = 'service_names';

EXIT;
EOF

:: Fallback for Windows (no heredoc support)
echo SET PAGESIZE 50 > %TEMP%\oracle_check.sql
echo SET LINESIZE 120 >> %TEMP%\oracle_check.sql
echo SET FEEDBACK OFF >> %TEMP%\oracle_check.sql
echo PROMPT === Current Container / Service Name === >> %TEMP%\oracle_check.sql
echo SHOW CON_NAME; >> %TEMP%\oracle_check.sql
echo PROMPT. >> %TEMP%\oracle_check.sql
echo PROMPT === Open User Accounts === >> %TEMP%\oracle_check.sql
echo SELECT username, account_status, default_tablespace FROM dba_users WHERE account_status = 'OPEN' ORDER BY username; >> %TEMP%\oracle_check.sql
echo PROMPT. >> %TEMP%\oracle_check.sql
echo PROMPT === All PDBs === >> %TEMP%\oracle_check.sql
echo SELECT name, open_mode FROM v$pdbs; >> %TEMP%\oracle_check.sql
echo PROMPT. >> %TEMP%\oracle_check.sql
echo PROMPT === Service Names === >> %TEMP%\oracle_check.sql
echo SELECT value FROM v$parameter WHERE name = 'service_names'; >> %TEMP%\oracle_check.sql
echo EXIT; >> %TEMP%\oracle_check.sql

echo [2/3] Running SQL queries...
echo.
sqlplus -s / as sysdba @%TEMP%\oracle_check.sql

echo.
echo [3/3] Done. Copy the output above and share it.
echo.
pause