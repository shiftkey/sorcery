@echo off
>nul chcp 866

::Lorents & Res2001 2010-2014

setlocal enabledelayedexpansion

set "name=Image Catalyst"
set "version=2.4"

if "%~1" equ "thrt" call:threadwork "%~2" %3 %4 & exit /b
::if "%~1" equ "thrt" echo on & 1>>%4.log 2>&1 call:threadwork "%~2" %3 %4 & exit /b
if "%~1" equ "updateic" call:icupdate & exit /b
if "%~1" equ "" call:helpmsg

title %name% %version%

set "fullname=%~0"
set "scrpath=%~dp0"
set "sconfig=%scrpath%tools\"
set "scripts=%scrpath%tools\scripts\"
set "tmppath=%TEMP%\%name%\"
set "errortimewait=30"
set "iclock=%TEMP%ic.lck"
set "LOG=%scrpath%\iCatalyst"

::BEGIN:�஢�ઠ, �� ����饭 �� 㦥 IC
::1.�������� �����襭�� ����饭���� ������� IC. �� ��᫥���騥 IC, ���� �����, ����� ������� ࠡ��� �।��騥 ��������.
::call:runningcheck "%~nx0"
::2.�� �������� IC ࠡ���� �����६����. ��ன � ��᫥���騥 �������� �뢮��� ���ଠ樮���� ᮮ�饭��, �� ��� �� ����.
set "runic="
call:runic "%~nx0"
if defined runic (
	title [Waiting] %name% %version%
	1>&2 echo �������������������������������������������������������������������������������
	1>&2 echo  Attention: running %runic% of %name%.
	1>&2 echo.
	1>&2 echo  Press Enter to continue.
	1>&2 echo �������������������������������������������������������������������������������
	set "LOG=%LOG%%runic%"
	pause>nul
	cls
)
::END:�஢�ઠ, �� ����饭 �� 㦥 IC
set "LOG=%LOG%.log"
::1>nul 2>&1 del /f/q "%LOG%"
if not defined runic if exist "%tmppath%" 1>nul 2>&1 rd /s /q "%tmppath%"

set "apps=%~dp0Tools\apps\"
PATH %apps%;%PATH%
set "nofile="
if not exist "%scripts%filelist.txt" (
	title [Error] %name% %version%
	if exist "%tmppath%" 1>nul 2>&1 rd /s /q "%tmppath%"
	1>&2 echo �������������������������������������������������������������������������������
	1>&2 echo  Application can not get access to files:
	1>&2 echo.
	1>&2 echo  - Tools\Scripts\filelist.txt
	1>&2 echo.
	1>&2 echo  Press Enter to exit.
	1>&2 echo �������������������������������������������������������������������������������
	pause>nul & exit
)

set "num=0"
for /f "usebackq tokens=*" %%a in ("%scripts%filelist.txt") do if not exist "%scrpath%%%~a" (
	set /a "num+=1"
	if !num! gtr 20 set "nofile=!nofile!..." & goto:filelisterr
	set "nofile=!nofile!"%%~a" "
)

:filelisterr
if defined nofile (
	title [Error] %name% %version%
	if exist "%tmppath%" 1>nul 2>&1 rd /s /q "%tmppath%"
	1>&2 echo �������������������������������������������������������������������������������
	1>&2 echo  Application can not get access to files:
	1>&2 echo.
	for %%j in (%nofile%) do 1>&2 echo  - %%~j
	1>&2 echo.
	1>&2 echo  Press Enter to exit.
	1>&2 echo �������������������������������������������������������������������������������
	pause>nul & exit
)

:settemp
set "rnd=%random%"
if not exist "%tmppath%%rnd%\" (
	set "tmppath=%tmppath%%rnd%"
	1>nul 2>&1 md "%tmppath%%rnd%" || call:errormsg "Can not create temporary folder:^|%tmppath%%rnd%!"
) else (
	goto:settemp
)

set "ImageNumPNG=0"
set "ImageNumJPG=0"
set "TotalNumPNG=0"
set "TotalNumJPG=0"
set "TotalNumErrPNG=0"
set "TotalNumErrJPG=0"
set "TotalSizeJPG=0"
set "ImageSizeJPG=0"
set "TotalSizePNG=0"
set "ImageSizePNG=0"
set "changePNG=0"
set "changeJPG=0"
set "percPNG=0"
set "percJPG=0"
set "png="
set "jpeg="
set "stime="

set "updateurl=http://x128.ho.ua/update.ini"
set "configpath=%~dp0\Tools\config.ini"
set "logfile=%tmppath%\Images"
set "iculog=%tmppath%\icu.log"
set "iculck=%tmppath%\icu.lck"
set "countPNG=%tmppath%\countpng"
set "countJPG=%tmppath%\countjpg"
set "filelist=%tmppath%\filelist"
set "filelisterr=%tmppath%\filerr"
set "params="
set "jpgp=/JPG:yes"
set "pngp=/PNG:yes"

::�⥭�� ��६����� �� config.ini
set "fs=" & set "threadjpg=" & set "threadpng=" & set "updatecheck=" & set "outdir=" & set "outdir1=" & set "nooutfolder="
set "metadata=" & set "chunks=" & set "nc=" & set "na=" & set "np=" & set "ng="
call:readini "%configpath%"
if /i "%fs%" equ "true" (set "fs=/s") else (set "fs=")
::call:sethread %threadpng% & set "threadpng=!thread!" & set "thread="
if not defined threadpng set "threadpng=0"
if "%threadpng%" equ "0" if %NUMBER_OF_PROCESSORS% gtr 1 set /a "threadpng=%NUMBER_OF_PROCESSORS%-1"
call:sethread %threadjpg% & set "threadjpg=!thread!" & set "thread="
::if "%threadjpg%" equ "0" (set /a "threadjpg=2*%thread%") else set "threadjpg=!thread!"
::set "thread="
set "multithread=0"
if %threadpng% gtr 1 set "multithread=1"
if %threadjpg% gtr 1 set "multithread=1"
set "updatecheck=%update%" & set "update="
call set "outdir=%outdir%"
if /i "%outdir%" equ "true" (set "outdir=" & set "nooutfolder=yes") else if /i "%outdir%" equ "false" set "outdir="
if /i "%nc%" equ "false" (set "nc=-nc") else (set "nc=")
if /i "%np%" equ "false" (set "np=-np") else (set "np=")
dir /s/b %* 2>nul | findstr /r "\.jp[ge]$" 1>nul 2>&1 && set "TotalNumJPG=1"
dir /s/b %* 2>nul | findstr /r "\.jpeg$" 1>nul 2>&1 && set "TotalNumJPG=1"
dir /s/b %* 2>nul | findstr /r "\.png$" 1>nul 2>&1 && set "TotalNumPNG=1"
::���� ��ࠬ��஢ ��⨬���樨
if %TotalNumPNG% gtr 0 if not defined png call:png
if %TotalNumJPG% gtr 0 if not defined jpeg call:jpeg
if not defined png set "png=0"
if not defined jpeg set "jpeg=0"
if %png% equ 0 set "pngp=/PNG:no"
if %jpeg% equ 0 set "jpgp=/JPG:no"
set "TotalNumPNG=0"
set "TotalNumJPG=0"
if %png% equ 0 if %jpeg% equ 0 goto:endsetcounters	

if not defined nooutfolder if not defined outdir (
	cls
	title [Loading] %name% %version%
	for /f "tokens=* delims=" %%a in ('dlgmsgbox "Image Catalyst" "Folder3" " " "Select target folder:" ') do set "outdir=%%~a"
)
if defined outdir (
	if "!outdir:~-1!" neq "\" set "outdir=!outdir!\"
	if not exist "!outdir!" (1>nul 2>&1 md "!outdir!" || call:errormsg "Can not create folder for optimized files:^|!outdir!^!")
	for /f "tokens=* delims=" %%a in ("!outdir!") do set outdirparam="/Outdir:%%~a"
) else (
	set "outdirparam="
)

if "%~1" equ "" goto:setcounters
cls
echo.�������������������������������������������������������������������������������
echo.Files are analazing. Please wait...
echo.�������������������������������������������������������������������������������
cscript //nologo //E:JScript "%scripts%filter.js" %pngp% %jpgp% %outdirparam% %* 1>"%filelist%" 2>"%filelisterr%"

:setcounters
::������ ��饣� ������⢠ ��ࠡ��뢠���� � �ய�᪠���� 䠩��� � ࠧ१� png/jpg 
if exist "%filelist%" (
	if defined png for /f "tokens=3 delims=:" %%a in ('find /i /c ".png" "%filelist%" 2^>nul') do set /a "TotalNumPNG+=%%a"
	if defined jpeg for /f "tokens=3 delims=:" %%a in ('find /i /c ".jpg" "%filelist%" 2^>nul') do set /a "TotalNumJPG+=%%a"
	if defined jpeg for /f "tokens=3 delims=:" %%a in ('find /i /c ".jpe" "%filelist%" 2^>nul') do set /a "TotalNumJPG+=%%a"
)
if exist "%filelisterr%" (
	if defined png for /f "tokens=3 delims=:" %%a in ('find /i /c ".png" "%filelisterr%" 2^>nul') do set /a "TotalNumErrPNG+=%%a"
	if defined jpeg for /f "tokens=3 delims=:" %%a in ('find /i /c ".jpg" "%filelisterr%" 2^>nul') do set /a "TotalNumErrJPG+=%%a"
	if defined jpeg for /f "tokens=3 delims=:" %%a in ('find /i /c ".jpe" "%filelisterr%" 2^>nul') do set /a "TotalNumErrJPG+=%%a"
)
:endsetcounters
if %TotalNumPNG% equ 0 if %TotalNumJPG% equ 0 (
	cls
	1>&2 echo �������������������������������������������������������������������������������
	1>&2 echo  There no files found for optimization.
	call:helpmsg
)

for /l %%a in (1,1,%threadpng%) do >"%logfile%png.%%a" echo.
for /l %%a in (1,1,%threadjpg%) do >"%logfile%jpg.%%a" echo.

if /i "%na%" equ "false" (
	set "na=-na"
) else (
	if %png% equ 1 set "na=-a1"
	if %png% equ 2 set "na=-a0"
)

cls
echo _______________________________________________________________________________
echo.
if /i "%updatecheck%" equ "true" start "" /b cmd.exe /c ""%fullname%" updateic"
call:setitle
call:setvtime stime
set "outdirs="
for /f "usebackq tokens=1 delims=	" %%a in ("%filelist%") do (
	call:initsource "%%~a"
	if defined ispng if "%png%" neq "0" call:filework "%%~fa" png %threadpng% ImageNumPNG
	if defined isjpeg if "%jpeg%" neq "0" call:filework "%%~fa" jpg %threadjpg% ImageNumJPG
)
:waithread
call:waitflag "%tmppath%\thrt*.lck"
for /l %%z in (1,1,%threadpng%) do call:typelog png %%z
for /l %%z in (1,1,%threadjpg%) do call:typelog jpg %%z
call:setitle
::set "thrt="
::for /l %%z in (1,1,%threadpng%) do if exist "%tmppath%\thrtpng%%z.lck" (set "thrt=1") else (call:typelog & call:setitle)
::for /l %%z in (1,1,%threadjpg%) do if exist "%tmppath%\thrtjpg%%z.lck" (set "thrt=1") else (call:typelog & call:setitle)
::if defined thrt call:waitrandom 1000 & goto:waithread
::cscript //nologo //E:JScript "%scripts%unfilter.js" <"%filelist%"
call:end
pause>nul & exit /b

::�஢�ઠ �� ����饭 �� �� ���� ������� IC. �᫨ ����饭 - ���� �����襭��.
::��ன ����饭�� ����� ᮧ���� �����஢��� 䠩� %iclock% � ������� �����襭�� ��ࢮ�� IC.
::�� ��⠫�� ������� �᢮�������� �����஢�筮�� 䠩��.
::����� ���� IC �����稢��� ࠡ���, ��ன ��室�� �� �������� � ���᪠�� �����஢��� 䠩�.
::���� �� ��⠫��� IC, �� �ᯥ� ��墠��� 䠩�, �㤥� ᫥���騬 � ��।� �� ��ࠡ���.
::��ࠬ����: %1	-	��ப� ��� ���᪠ �����
:runningcheck
call:runic "%~1"
set "lastrunic=%runic%"
if defined runic (
	title [Waiting] %name% %version%
	echo.Another process is running %name%. Waiting for shuting down.
	call:runningcheck2 "%~1"
)
exit /b

::��ன �⠯ ��������
:runningcheck2
2>nul (
	3>"%iclock%" 1>&3 call:runic2 "%~1" || (call:waitrandom 5000 & goto:runningcheck2)
)
exit /b

::���� �������� ��� ��ண� ����� IC
:runic2
call:waitrandom 5000
call:runic "%~1"
if defined runic (
	if %runic% lss %lastrunic% exit /b 0
	set "lastrunic=%runic%"
	goto:runic2
)	
exit /b 0

::�஢��塞 � ������� wmic ����饭� �� ����� ������ ������� IC. 
::�᫨ ��, � ���⠢�塞 ��६����� runic � ���祭��, ࠢ��� �������� ����饭��� ������஢ IC.
::��ࠬ����: %1	-	��ப� ��� ���᪠ �����
:runic
set "runic="
if exist "%systemroot%\system32\wbem\wmic.exe" (
	for /f "tokens=* delims=" %%a in ('wmic path win32_process where "CommandLine like '%%%~1%%'" get CommandLine /value ^| findstr /i /c:"%~1" ^| findstr /i /c:"cmd" ^| findstr /i /v "find findstr wmi thrt updateic" ^| find /i /c "%~1" ') do (
		if %%a gtr 1 set "runic=%%a"
))
exit /b

::�뢮��� ���������� ���� �롮� 䠩��� �� ������⢨� ��ࠬ��஢.
:notparam
dlgmsgbox "Image Catalyst" "File1" " " "�� �ଠ�� ^(*.png;*.jpg;*.jpeg;*.jpe^)^|JPEG ^(*.jpg;*.jpeg;*.jpe^)^|PNG ^(*.png^)" |	cscript //nologo //E:JScript "%scripts%filter.js" %outdirparam% /IsStdIn:yes 1>"%filelist%" 2>"%filelisterr%"
exit /b

::��⠭���� ���祭�� ��६�����, ��� ���ன ��।��� � %1, � ⥪���� ����/�६� � �ଠ� ��� �뢮�� �⮣��
::��ࠬ����: ���
::�����頥�� ���祭��: ��⠭�������� ���祭�� ��६����� %1
:setvtime
set "%1=%date% %time:~0,2%:%time:~3,2%:%time:~6,2%"
exit /b

::�஢�ઠ ����㯭��� ����� ���ᨨ IC.
::��ࠬ����: ���
::�����頥�� ���祭��: ���
:icupdate
if not exist "%scripts%xmlhttprequest.js" exit /b
>"%iculck%" echo.Update IC
cscript //nologo //E:JScript "%scripts%xmlhttprequest.js" %updateurl% 2>nul 1>"%iculog%" || 1>nul 2>&1 del /f /q "%iculog%"
1>nul 2>&1 del /f /q "%iculck%"
exit /b

::����᪠�� ��ࠡ��稪 䠩�� � �������筮� ��� ��������筮� ०���.
::��ࠬ����:
::	%1 - png | jpg
::	%2 - ������⢮ ��⮪�� ������� ����
::	%3 - ���� � ��ࠡ��뢠����� 䠩��
::�����頥�� ���祭��: ���
:createthread
if %2 equ 1 call:threadwork %3 %1 1 & call:typelog %1 1 & exit /b
for /l %%z in (1,1,%2) do (
	if not exist "%tmppath%\thrt%1%%z.lck" (
		call:typelog %1 %%z
		>"%tmppath%\thrt%1%%z.lck" echo ��ࠡ�⪠ 䠩��: %3
		start /b cmd.exe /s /c ""%fullname%" thrt "%~3" %1 %%z"
		exit /b
	)
)
call:waitrandom 500
goto:createthread

::��ॡ�� 䠩��� ��� �뢮�� ����⨪� ��� ��������筮�� ०���. ����� ������ �� %logfile%*.
::��ࠬ����: 
::	%1 - png | jpg
::	%2 - ����� 䠩�� ������� ���� ��� �뢮��
::�����頥�� ���祭��: ���
:typelog
if %multithread% equ 0 exit /b
if not defined typenum%1%2 set "typenum%1%2=1"
call:typelogfile "%logfile%%1.%2" "typenum%1%2" %%typenum%1%2%% %1
exit /b

::�⥭�� 䠩�� � ࠧ��� ��ப ��� �뢮�� ����⨪� ��� ��������筮�� ०���.
::��ࠬ����:	%1 - 䠩� � �ଠ� images.csv
::		%2 - ��� ��६�����, � ���ன �࠭���� ������⢮ ��ࠡ�⠭��� ��ப � ������ 䠩��
::		%3 - ������⢮ ��ࠡ�⠭��� ��ப � ������ 䠩��
::		%4 - JPG | PNG
::�����頥�� ���祭��: ���
:typelogfile
if not exist "%~1" exit /b
for /f "usebackq skip=%3 tokens=1-5 delims=;" %%b in ("%~1") do (
	if /i "%%d" equ "error" (
		call:printfileerr "%%~b" "%%~c"
	) else (
		call:printfileinfo "%%~b" %%c %%d %%e %%f
	)
	set /a "%~2+=1"
)
exit /b

::�뢮� ���ଠ樨 � 䠩�� � ��ॢ���� ���祭�� � ������.
::��ࠬ����:
::	%1 - ��� 䠩��
::	%2 - ࠧ��� �室���� 䠩�� � �����
::	%3 - ࠧ��� ��室���� 䠩�� � �����
::	%4 - ࠧ��� � �����
::	%5 - ࠧ��� � ��業��
::�����頥�� ���祭��: ���
:printfileinfo
call:echostd " File  - %~f1"
set "float=%2"
call:division float 1024 100
call:echostd " In    - %float% ��"
set "change=%4"
call:division change 1024 100
set "float=%3"
call:division float 1024 100
call:echostd " Out   - %float% �� (%change% ��, %5%%)"
call:echostd _______________________________________________________________________________
call:echostd
exit /b

::�뢮� ���ଠ樨 �� �訡�� ��ࠡ�⪨ 䠩��.
::��ࠬ����:
::	%1 - ��� 䠩��
::	%2 - ����饭�� �� �訡��
::�����頥�� ���祭��: ���
:printfileerr
call:echoerr " File  - %~1"
call:echoerr " Error - %~2"
call:echoerr _______________________________________________________________________________
call:echoerr
exit /b

::�뢮��� %1 � ��� 䠩� %LOG% � � stdout
:echostd
echo.%~1
::>>"%LOG%" echo.%~1
exit /b

::�뢮��� %1 � ��� 䠩� %LOG% � � stderr
:echoerr
1>&2 echo.%~1
::>>"%LOG%" echo.%~1
exit /b

::����� ��ࠡ��稪�� 䠩��� ��� ��������筮� ��ࠡ�⪨.
::��ࠬ����:
::	%1 - ���� � ��ࠡ��뢠����� 䠩��
::	%2 - png | jpg
::	%3 - ����� ��⮪� ������� ����
::�����頥�� ���祭��: ���
:threadwork
if /i "%2" equ "png" call:pngfilework %1 %3 & if %multithread% neq 0 >>"%countPNG%.%3" echo.1
if /i "%2" equ "jpg" call:jpegfilework %1 %3 & if %multithread% neq 0 >>"%countJPG%.%3" echo.1
if exist "%tmppath%\thrt%2%3.lck" >nul 2>&1 del /f /q "%tmppath%\thrt%2%3.lck"
exit /b

::������� ������⢨� ��������� � %1 䠩��. ��㦨� ��� �������� ���� �����஢�� �� ��������筮� ��ࠡ�⪨.
::��ࠬ����: %1 - ���� � 䠩�� 䫠��.
::�����頥�� ���祭��: ���
:waitflag
if not exist "%~1" exit /b
call:waitrandom 2000
goto:waitflag

::������� ��砩��� ������⢮ �����ᥪ㭤, ��࠭�祭��� ������� ��ࠬ��஬.
::��ࠬ����: %1 - ��࠭�祭�� ��砩���� ���祭�� ������⢠ ��ᥪ.
::�����頥�� ���祭��: ���
:waitrandom
set /a "ww=%random%%%%1"
1>nul 2>&1 ping -n 1 -w %ww% 127.255.255.255
exit /b

::��楤�� ���樠����樨 ��६����� ��� ��।���� ���筨�� ��ࠡ�⪨.
::��ࠬ����: %1 - ���� � 䠩��.
::�����頥�� ���祭��: �ந��樠����஢���� ��६���� isjpeg, ispng, isfolder.
:initsource
set "isjpeg="
set "ispng="
set "isfolder="
if /i "%~x1" equ ".png" set "ispng=1"
if /i "%~x1" equ ".jpg" set "isjpeg=1"
if /i "%~x1" equ ".jpeg" set "isjpeg=1"
if /i "%~x1" equ ".jpe" set "isjpeg=1"
exit /b

::��⠭���� ������⢠ ��⮪�� ��� ��������筮� ��ࠡ�⪨. 
::��ࠬ����: %1 - �।�������� ������⢮ ��⮪�� (����� ������⢮����).
::�����頥�� ���祭��: �ந��樠����஢����� ��६����� thread.
:sethread
if "%~1" neq "" if "%~1" neq "0" set "thread=%~1" & exit /b
set /a "thread=%~1+1-1"
if "!thread!" equ "0" set "thread=%NUMBER_OF_PROCESSORS%"
::if %thread% gtr 2 set /a "thread-=1"
exit /b

::���� ��ࠬ��஢ ��⨬���樨 png 䠩���. 
::��ࠬ����: ���
::�����頥�� ���祭��: �ந��樠����஢����� ��६����� png.
:png
cls
title [PNG] %name% %version%
echo  �������������������������
echo  Select optimization mode for PNG:
echo  �������������������������
echo.
echo  [1] Xtreme
echo.
echo  [2] Advanced
echo.
echo  [0] Skip PNG optimization
echo.
set png=
echo  �������������������������������������������������������������
set /p png="#Select mode and press Enter [0-2]: "
echo  �������������������������������������������������������������
echo.
if "%png%" equ "" goto:png
if "%png%" equ "0" exit /b
if "%png%" neq "1" if "%png%" neq "2" goto:png
exit /b

::���� ��ࠬ��஢ ��⨬���樨 jpg 䠩���. 
::��ࠬ����: ���
::�����頥�� ���祭��: �ந��樠����஢����� ��६����� jpeg.
:jpeg
cls
title [JPEG] %name% %version%
echo  ��������������������������
echo  Select optimization mode for JPEG:
echo  ��������������������������
echo.
echo  [1] Baseline
echo.
echo  [2] Progressive
echo.
echo  [3] Default
echo.
echo  [0] Select mode and press Enter JPEG
echo.
set jpeg=
echo  ��������������������������������������������������������������
set /p jpeg="#Select mode and press Enter [0-3]: "
echo  ��������������������������������������������������������������
echo.
if "%jpeg%" equ "" goto:jpeg
if "%jpeg%" equ "0" exit /b
if "%jpeg%" neq "1" if "%jpeg%" neq "2" if "%jpeg%" neq "3" goto:jpeg
exit /b

::��⠭���� ��������� ���� �� �६� ��⨬���樨.
::��ࠬ����: ���
::�����頥�� ���祭��: ���
:setitle
if "%jpeg%" equ "0" if "%png%" equ "0" (title %~1%name% %version% & exit /b)
if %multithread% neq 0 (
	set "ImageNumPNG=0" & set "ImageNumJPG=0"
	for /l %%c in (1,1,%threadpng%) do for %%b in ("%countPNG%.%%c") do set /a "ImageNumPNG+=%%~zb/3" 2>nul
	for /l %%c in (1,1,%threadjpg%) do for %%b in ("%countJPG%.%%c") do set /a "ImageNumJPG+=%%~zb/3" 2>nul
)
if "%png%" equ "1" (set "pngtitle=Xtreme")
if "%png%" equ "2" (set "pngtitle=Advanced")
if "%jpeg%" equ "1" (set "jpegtitle=Optimize")
if "%jpeg%" equ "2" (set "jpegtitle=Progressive")
if "%jpeg%" equ "3" (set "jpegtitle=Default")
if "%jpeg%" equ "0" (
	title %~1[PNG %pngtitle%: %ImageNumPNG%/%TotalNumPNG%] %name% %version%
) else (
	if "%png%" equ "0" (
		title %~1[JPEG %jpegtitle%: %ImageNumJPG%/%TotalNumJPG%] %name% %version%
	) else (
		title %~1[PNG %pngtitle%: %ImageNumPNG%/%TotalNumPNG%] [JPEG %jpegtitle%: %ImageNumJPG%/%TotalNumJPG%] %name% %version%
	)
)
exit /b

::����� ��ࠡ��稪� 䠩���.
::��ࠬ����:
::	%1 - ��ࠡ��뢠��� 䠩�
::	%2 - png | jpg
::	%3 - %threadpng% | %threadjpg%
::	%4 - ImageNumPNG | ImageNumJPG
::�����頥�� ���祭��: ���
:filework
call:createthread %2 %3 "%~f1"
set /a "%4+=1"
call:setitle
exit /b

::��ࠡ��稪 png 䠩���.
::��ࠬ����:
::	%1 - ���� � ��ࠡ��뢠����� 䠩��
::	%2 - ����� ��⮪� ��ࠡ�⪨
::�����頥�� ���祭��: ���
:pngfilework
set "zc="
set "zm="
set "zs="
set "psize=%~z1"
set "errbackup=0"
set "logfile2=%logfile%png.%2"
set "pnglog=%tmppath%\png%2.log"
set "filework=%tmppath%\%~n1-ic%2%~x1"
1>nul 2>&1 copy /b /y "%~f1" "%filework%" || (call:saverrorlog "%~f1" "���� �� ������" & exit /b)
if %png% equ 1 (
	>"%pnglog%" 2>nul truepng -i0 -zw5 -zc7 -zm5-9 -zs0-3 -f0,5 -fs:2 -g%ng% %nc% %na% %np% -force "%filework%"
	if errorlevel 1 (call:saverrorlog "%~f1" "File type not supported" & exit /b)
	for /f "tokens=2,4,6,8,10 delims=:	" %%a in ('findstr /r /i /b /c:"zc:..zm:..zs:" "%pnglog%"') do (
		set "zc=%%a"
		set "zm=%%b"
		set "zs=%%c"
	)
	1>nul 2>&1 del /f /q "%pnglog%"
	pngwolf --even-if-bigger --zlib-window=15 --zlib-level=!zc! --zlib-memlevel=!zm! --zlib-strategy=!zs! --zopfli-iterations=15 --max-time=1 --in="%filework%" --out="%filework%" 1>nul 2>&1
	if errorlevel 1 (call:saverrorlog "%~f1" "File type not supported" & exit /b)
)
if %png% equ 2 (
	truepng -i0 -zw5 -zc7 -zm8-9 -zs0-1 -f0,5 -fs:7 -g%ng% %nc% %na% %np% -force "%filework%" 1>nul 2>&1 && advdef -z3 "%filework%" 1>nul 2>&1
	if errorlevel 1 (call:saverrorlog "%~f1" "File type not supported" & exit /b)
)
deflopt -k "%filework%" >nul && defluff < "%filework%" > "%filework%-defluff.png" 2>nul 
if errorlevel 1 (call:saverrorlog "%~f1" "File type not supported" & 1>nul 2>&1 del /f/q "%filework%-defluff.png" & exit /b)
1>nul 2>&1 move /y "%filework%-defluff.png" "%filework%" && deflopt -k "%filework%" >nul
if errorlevel 1 (call:saverrorlog "%~f1" "File type not supported" & exit /b)
call:backup "%~f1" "%filework%" >nul || set "errbackup=1"
if %errbackup% neq 0 (call:saverrorlog "%~f1" "Access denied or file not exists" & exit /b)
if /i "%chunks%" equ "true" (1>nul 2>&1 truepng -nz -md remove all "%~f1" || (call:saverrorlog "%~f1" "File not supported" & exit /b))
call:savelog "%~f1" %psize% PNG
if %multithread% equ 0 for %%a in ("%~f1") do (set /a "ImageSizePNG+=%%~za" & set /a "TotalSizePNG+=%psize%")
exit /b

::��ࠡ��稪 jpg 䠩���.
::��ࠬ����:
::	%1 - ���� � ��ࠡ��뢠����� 䠩��
::	%2 - ����� ��⮪� ��ࠡ�⪨
::�����頥�� ���祭��: ���
:jpegfilework
set "ep="
set "jsize=%~z1"
set "errbackup=0"
set "logfile2=%logfile%jpg.%2"
set "filework=%tmppath%\%~n1%2%~x1"
set "jpglog=%tmppath%\jpg%2.log"
1>nul 2>&1 copy /b /y "%~f1" "%filework%" || (call:saverrorlog "%~f1" "File not found" & exit /b)
if %jpeg% equ 1 (
	mozjpegtran -verbose -revert -optimize -copy all -outfile "%filework%" "%filework%" 1>"%jpglog%" 2>&1
	if errorlevel 1 (call:saverrorlog "%~f1" "File not supported" & 1>nul 2>&1 del /f /q "%jpglog%" & exit /b)
	for /f "tokens=4,10 delims=:,= " %%a in ('findstr /C:"Start Of Frame" "%jpglog%" 2^>nul') do (set "ep=%%a")
	if "!ep!" equ "0xc0" (
		call:backup "%~f1" "%filework%" >nul || set "errbackup=1"
	) else (
		if "!ep!" equ "0xc2" (
			1>nul 2>&1 move /y "%filework%" "%~f1" || set "errbackup=1"
		) else (
			call:saverrorlog "%~f1" "File not supported" & exit /b
		)
	)
)
if %jpeg% equ 2 (
	mozjpegtran -verbose -copy all -outfile "%filework%" "%filework%" 1>"%jpglog%" 2>&1
	if errorlevel 1 (call:saverrorlog "%~f1" "File not supported" & 1>nul 2>&1 del /f /q "%jpglog%" & exit /b)
	for /f "tokens=4,10 delims=:,= " %%a in ('findstr /C:"Start Of Frame" "%jpglog%" 2^>nul') do (set "ep=%%a")
	if "!ep!" equ "0xc2" (
		call:backup "%~f1" "%filework%" >nul || set "errbackup=1"
	) else (
		if "!ep!" equ "0xc0" (
			1>nul 2>&1 move /y "%filework%" "%~f1" || set "errbackup=1"
		) else (
			call:saverrorlog "%~f1" "File not supported" & exit /b
		)
	)
)
if %jpeg% equ 3 (
	jpginfo "%filework%" 1>"%jpglog%" 2>&1
	if errorlevel 1 (call:saverrorlog "%~f1" "File not supported" & 1>nul 2>&1 del /f /q "%jpglog%" & exit /b)
	for /f "usebackq tokens=5" %%a in ("%jpglog%") do set "ep=%%~a"
	if /i "!ep!" equ "Baseline" (
		mozjpegtran -verbose -revert -optimize -copy all -outfile "%filework%" "%filework%" 1>nul 2>&1
		if errorlevel 1 (call:saverrorlog "%~f1" "File not supported" & exit /b)
		call:backup "%~f1" "%filework%" >nul || set "errbackup=1"
	) else (
		if /i "!ep!" equ "Progressive" (
			mozjpegtran -verbose -copy all -outfile "%filework%" "%filework%" 1>nul 2>&1
			if errorlevel 1 (call:saverrorlog "%~f1" "File not supported" & exit /b)
			call:backup "%~f1" "%filework%" >nul || set "errbackup=1"
		) else (
			call:saverrorlog "%~f1" "File not supported" & exit /b
		)
	)
)
1>nul 2>&1 del /f /q "%jpglog%"
if %errbackup% neq 0 (call:saverrorlog "%~f1" "Access denied or file not exists" & 1>nul 2>&1 del /f /q %filework% & exit /b)
if /i "%metadata%" equ "true" (1>nul 2>&1 jpegstripper -y "%~f1" || (call:saverrorlog "%~f1" "File not supported" & exit /b))
call:savelog "%~f1" %jsize% JPG
if %multithread% equ 0 for %%a in ("%~f1") do (set /a "ImageSizeJPG+=%%~za" & set /a "TotalSizeJPG+=%jsize%")
exit /b

::�᫨ ࠧ��� 䠩�� %2 �����, 祬 ࠧ��� %1, � %2 ��७����� �� ���� %1, ���� %2 㤠�����.
::��ࠬ����:
::	%1 - ���� � ��ࢮ�� 䠩�
::	%2 - ���� �� ��஬� 䠩��
::�����頥�� ���祭��: ���
:backup
if not exist "%~1" exit /b 2
if not exist "%~2" exit /b 3
if %~z2 equ 0 (1>nul 2>&1 del /f /q "%~2" & exit /b 4)
if %~z1 leq %~z2 (1>nul 2>&1 del /f /q "%~2") else (1>nul 2>&1 move /y "%~2" "%~1" || exit /b 1)
exit /b

::���᫥��� ࠧ���� ࠧ��� ��室���� � ��⨬���஢������ 䠩�� (chaneg � perc).
::��� ��������筮� ��ࠡ�⪨ ������ � %logfile% ���ଠ樨 �� ��ࠡ�⠭��� 䠩��.
::��� �������筮� ��ࠡ�⪨ �뢮� ����⨪� �� �࠭.
::��ࠬ����:
::	%1 - ���� � ��⨬���஢������ 䠩��
::	%2 - ࠧ��� ��室���� 䠩��
::�����頥�� ���祭��: ���
:savelog
set /a "change=%~z1-%2"
set /a "perc=%change%*100/%2" 2>nul
set /a "fract=%change%*100%%%2*100/%2" 2>nul
set /a "perc=%perc%*100+%fract%"
call:division perc 100 100
>>"%logfile2%" echo.%~1;%2;%~z1;%change%;%perc%;ok
if %multithread% equ 0 (
	call:printfileinfo "%~1" %2 %~z1 %change% %perc%
)
exit /b

::������ ������� ���� 楫�� �ᥫ, १���� - �஡��� �᫮.
::��ࠬ����:
::	%1 - ��� ��६�����, ᮤ�ঠ饩 楫�� �᫮ �������
::	%2 - ����⥫�
::	%3 - 10/100/1000... - ���㣫���� �஡��� ��� (�� �������, �� ����, �� �������, ...)
::�����頥�� ���祭��: set %1=���᫥���� �஡��� ��⭮�
:division
set "sign="
1>nul 2>&1 set /a "int=!%1!/%2"
1>nul 2>&1 set /a "fractd=!%1!*%3/%2%%%3"
if "%fractd:~,1%" equ "-" (set "sign=-" & set "fractd=%fractd:~1%")
1>nul 2>&1 set /a "fractd=%3+%fractd%"
if "%int:~,1%" equ "-" set "sign="
set "%1=%sign%%int%.%fractd:~1%
exit /b

::��� ��������筮� ��ࠡ�⪨ ������ ᮮ�饭�� �� �訡�� ��ࠡ�⪨ � %logfile%.
::��� �������筮� ��ࠡ�⪨ �뢮� ᮮ�饭�� �� �訡�� �� �࠭.
::��ࠬ����:
::	%1 - ���� � ��⨬���஢������ 䠩��
::	%2 - ᮮ�饭�� �� �訡��
::�����頥�� ���祭��: ���
:saverrorlog
1>nul 2>&1 del /f /q "%filework%"
>>"%logfile2%" echo.%~1;%~2;error
if %multithread% equ 0 (
	call:printfileerr "%~f1" "%~2"
)
exit /b

::�뢮� �⮣����� ᮮ�饭�� � ����⨪� ��ࠡ�⪨ � ����稨 ����������.
::��ࠬ����: ���
::�����頥�� ���祭��: ���
:end
if not defined stime call:setvtime stime
call:setvtime ftime
set "changePNG=0" & set "percPNG=0" & set "fract=0"
set "changeJPG=0" & set "percJPG=0" & set "fract=0"
if "%jpeg%" equ "0" if "%png%" equ "0" 1>nul 2>&1 ping -n 1 -w 500 127.255.255.255 & goto:finmessage
if %multithread% neq 0 (
	for /f "tokens=1-5 delims=;" %%a in ('findstr /e /i /r /c:";ok" "%logfile%png*" ') do (
		set /a "TotalSizePNG+=%%b" & set /a "ImageSizePNG+=%%c"
	)
	for /f "tokens=1-5 delims=;" %%a in ('findstr /e /i /r /c:";ok" "%logfile%jpg*" ') do (
		set /a "TotalSizeJPG+=%%b" & set /a "ImageSizeJPG+=%%c"
	)
)
for /f "tokens=1" %%a in ('findstr /e /i /r /c:";error" "%logfile%png*" 2^>nul ^| find /i /c ";error" 2^>nul') do (
	set /a "TotalNumErrPNG+=%%a" & set /a "TotalNumPNG-=%%a"
)
for /f "tokens=1" %%a in ('findstr /e /i /r /c:";error" "%logfile%jpg*" 2^>nul ^| find /i /c ";error" 2^>nul') do (
	set /a "TotalNumErrJPG+=%%a" & set /a "TotalNumJPG-=%%a"
)

set /a "changePNG=(%ImageSizePNG%-%TotalSizePNG%)" 2>nul
set /a "percPNG=%changePNG%*100/%TotalSizePNG%" 2>nul
set /a "fract=%changePNG%*100%%%TotalSizePNG%*100/%TotalSizePNG%" 2>nul
set /a "percPNG=%percPNG%*100+%fract%" 2>nul
call:division changePNG 1024 100
call:division percPNG 100 100
set /a "changeJPG=(%ImageSizeJPG%-%TotalSizeJPG%)" 2>nul
set /a "percJPG=%changeJPG%*100/%TotalSizeJPG%" 2>nul
set /a "fract=%changeJPG%*100%%%TotalSizeJPG%*100/%TotalSizeJPG%" 2>nul
set /a "percJPG=%percJPG%*100+%fract%" 2>nul
call:division changeJPG 1024 100
call:division percJPG 100 100
:finmessage
call:totalmsg PNG %png%
call:totalmsg JPG %jpeg%
call:echostd " Started  at - %stime%"
call:echostd " Finished at - %ftime%"
echo _______________________________________________________________________________
call:listerrfiles
echo.
echo  Optimization process finished. Press Enter to exit.
echo _______________________________________________________________________________
if /i "%updatecheck%" equ "true" (
	call:waitflag "%iculck%"
	1>nul 2>&1 del /f /q "%iculck%"
	if exist "%iculog%" (
		call:readini "%iculog%"
		if "%version%" neq "!ver!" (
			set "isupdate="
			for /f "tokens=* delims=" %%a in ('dlgmsgbox "Image Catalyst" "Msg1" " " "New version available %name% !ver!^|Do you want to update?" "Q4" "%errortimewait%" 2^>nul') do set "isupdate=%%~a"
			if "!isupdate!" equ "6" start "" !url!
		)
		1>nul 2>&1 del /f /q "%iculog%"
	)
)
1>nul 2>&1 del /f /q "%logfile%*" "%countJPG%" "%countPNG%*" "%filelist%*" "%filelisterr%*" "%iclock%"
if exist "%tmppath%" 1>nul 2>&1 rd /s /q "%tmppath%"
exit /b

:totalmsg
call set /a "tt=%%TotalNum%1%%+%%TotalNumErr%1%%"
if "%2" equ "0" (
	set "opt=0"
	set "tterr=%tt%"
) else (
	call set "opt=%%TotalNum%1%%"
	call set "tterr=%%TotalNumErr%1%%"
)
if "%tt%" neq "0" (
	call:echostd " Total Number of %1:	%tt%"
	call:echostd " Optimized %1:		%opt%"
	if "%tterr%" neq "0" call:echostd " Skipped %1:		%tterr%"
	call:echostd " Total %1:  		%%change%1%% ��, %%perc%1%%%%%%"
	call:echostd
)
exit /b

:listerrfiles
for %%a in ("%filelisterr%") do if %%~za gtr 0 (
	echo.
	echo  Files with specail symbols in filepath:
	type  "%%~a"
	echo _______________________________________________________________________________
)
findstr /e /i /r /c:";error" "%logfile%*" 1>nul 2>&1 && (
	findstr /i /r /c:";File not supported;" "%logfile%*" 1>nul 2>&1 && (
		echo.
		echo  File not supported:
		for /f "tokens=2* delims=:" %%a in ('findstr /i /r /c:";File not supported;" "%logfile%*" 2^>nul') do (
			for /f "tokens=1-2 delims=;" %%c in ("%%~b") do echo  %%~c
		)
		echo _______________________________________________________________________________
	)
	findstr /i /r /c:";File not found;" "%logfile%*" 1>nul 2>&1 && (
		echo.
		echo  File not found:
		for /f "tokens=2* delims=:" %%a in ('findstr /i /r /c:";File not found;" "%logfile%*" 2^>nul') do (
			for /f "tokens=1-2 delims=;" %%c in ("%%~b") do echo  %%~c
		)
		echo _______________________________________________________________________________
	)
	findstr /i /r /c:";Access denied or file not exists;" "%logfile%*" 1>nul 2>&1 && (
		echo  Access denied or file not exists:
		for /f "tokens=2* delims=:" %%a in ('findstr /i /r /c:";Access denied or file not exists;" "%logfile%*" 2^>nul') do (
			for /f "tokens=1-2 delims=;" %%c in ("%%~b") do echo  %%~c
		)
		echo _______________________________________________________________________________
	)
)
exit /b

::��⠥�-ini 䠩�. ����� ��ࠬ��� ini-䠩�� �८�ࠧ��뢠���� � ����������� ��६����� � 
::ᮮ⢥����騬 ᮤ�ন��. ������ਨ � ini - ᨬ��� ";" � ��砫� ��ப�, ����� ᥪ権 - �����������.
::��ࠬ����: %1 - ini-䠩�
::�����頥�� ���祭��: ����� ��६����� ᣥ���஢����� �� �᭮����� ini-䠩��.
:readini
for /f "usebackq tokens=1,* delims== " %%a in ("%~1") do (
	set param=%%a
	if "!param:~,1!" neq ";" if "!param:~,1!" neq "[" set "%%~a=%%~b"
)
exit /b

:helpmsg
title [Manual] %name% %version%
1>&2 echo �������������������������������������������������������������������������������
1>&2 echo  There are two ways to run Util for PNG and JPEG optimization:
1>&2 echo  1. drag and drop image files or folders to "iCatalyst_en.bat" icon;
1>&2 echo  2. run "iCatalyst.bat" with "file/folder path" parameter.
1>&2 echo.
1>&2 echo  You can view russian help file ^(ReadMe.txt^)
1>&2 echo  Press Enter to exit.
1>&2 echo �������������������������������������������������������������������������������
if exist "%tmppath%" 1>nul 2>&1 rd /s /q "%tmppath%"
pause>nul & exit

:errormsg
title [Error] %name% %version%
if exist "%tmppath%" 1>nul 2>&1 rd /s /q "%tmppath%"
if "%~1" neq "" 1>nul 2>&1 dlgmsgbox "Image Catalyst" "Msg1" " " "%~1" "E0" "%errortimewait%"
exit