::---------------------------------------------------------------------------
:: Compile code
::   Assemble twice: 1 to generate listing, 2 to generate object
::---------------------------------------------------------------------------
cd ..\build


:: Game
ca65 -I ..\src -t apple2 ..\src\pickman.asm -l pickman.dis   || exit
cl65 -I ..\src -t apple2 -u __EXEHDR__ ..\src\pickman.asm apple2.lib  -o pickman.apple2 -C ..\src\start6000.cfg  || exit

:: Engine
ca65 -I ..\src -t apple2 ..\src\engine.asm -l engine.dis  || exit
cl65 -I ..\src -t apple2 -u __EXEHDR__ ..\src\engine.asm apple2.lib  -o engine.apple2 -C ..\src\startC00.cfg  || exit

:: Loader
ca65 -I ..\src -t apple2 ..\src\loader.asm -l loader.dis  || exit
cl65 -I ..\src -t apple2 -u __EXEHDR__ ..\src\loader.asm apple2.lib  -o loader.apple2 -C ..\src\start2000.cfg  || exit

::---------------------------------------------------------------------------
:: Compile example
::---------------------------------------------------------------------------
cl65 -I ..\src -t apple2 -u __EXEHDR__ ..\src\tileset14x16_0.asm apple2.lib  -o tileset14x16_0.apple2 -C ..\src\start6000.cfg  || exit

cl65 -I ..\src -t apple2 -u __EXEHDR__ ..\src\tileset7x8_0.asm apple2.lib  -o tileset7x8_0.apple2 -C ..\src\start6000.cfg  || exit
cl65 -I ..\src -t apple2 -u __EXEHDR__ ..\src\tileset7x8_1.asm apple2.lib  -o tileset7x8_1.apple2 -C ..\src\start6000.cfg  || exit
cl65 -I ..\src -t apple2 -u __EXEHDR__ ..\src\tileset7x8_2.asm apple2.lib  -o tileset7x8_2.apple2 -C ..\src\start6000.cfg  || exit

::---------------------------------------------------------------------------
:: Build disk
::---------------------------------------------------------------------------

:: Start with a blank prodos disk
copy ..\disk\template_prodos.dsk pickman_prodos.dsk  || exit

:: Put boot program first

:: Loader
java -jar C:\jar\AppleCommander.jar -p  pickman_prodos.dsk loader.system sys < C:\cc65\target\apple2\util\loader.system  || exit
java -jar C:\jar\AppleCommander.jar -as pickman_prodos.dsk loader bin < loader.apple2  || exit

:: Engine
java -jar C:\jar\AppleCommander.jar -as pickman_prodos.dsk data/engine bin < engine.apple2  || exit

:: Game
java -jar C:\jar\AppleCommander.jar -as pickman_prodos.dsk data/game bin < pickman.apple2  || exit

:: Throw on basic
java -jar C:\jar\AppleCommander.jar -p pickman_prodos.dsk basic.system sys < ..\disk\BASIC.SYSTEM  || exit

:: Add samples
java -jar C:\jar\AppleCommander.jar -as pickman_prodos.dsk data/tileset14x16.0 bin < tileset14x16_0.apple2  || exit
java -jar C:\jar\AppleCommander.jar -as pickman_prodos.dsk data/tileset7x8.0 bin < tileset7x8_0.apple2  || exit
java -jar C:\jar\AppleCommander.jar -as pickman_prodos.dsk data/tileset7x8.1 bin < tileset7x8_1.apple2  || exit
java -jar C:\jar\AppleCommander.jar -as pickman_prodos.dsk data/tileset7x8.2 bin < tileset7x8_2.apple2  || exit

:: Copy results out of the build directory
copy pickman_prodos.dsk ..\disk  || exit

::---------------------------------------------------------------------------
:: Test on emulator
::---------------------------------------------------------------------------
C:\AppleWin\Applewin.exe -no-printscreen-dlg -d1 pickman_prodos.dsk

