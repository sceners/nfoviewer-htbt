.const
BK_COLOR = 004A79ADh

.data
klasa       db  "WinClass", 0
tytul       db  "HTBTeam.nfo viewer", 0
pliknfo     db  "HTBTeam.nfo", 0
frametime   dd  10
scrollpos   dd  -480
vscroll     dd  1
fonttname   db  "Terminal",0
infotext    db  "RMB .... exit",13,10
            db  "LMB ... pause",13,10
            db  "+ .... faster",13,10
            db  "- .... slower",0
infotextsize = $ - offset infotext
infotext2   db  "nfo viewer created by FiNS//HTBTeam", 0
nonfo       db  "HTBTeam.nfo not found!", 0
error       db  "Error", 0

font equ $
include font.inc

.data?
hInstance   dd  ?
hFilenfo    dd  ?
hMapnfo     dd  ?
Mapnfo      dd  ?
done        dd  ?
hDC         dd  ?
monotextDC  dd  ?
ppvBitsmonotext dd  ?
monotextBMP dd  ?
backDC      dd  ?
backppvBits dd  ?
backBMP     dd  ?
textDC      dd  ?
textppvBits dd  ?
textBMP     dd  ?
hPen1       dd  ?
hPen2       dd  ?
xpos1       dd  ?
ypos1       dd  ?
xpos2       dd  ?
ypos2       dd  ?
lasttime    dd  ?
currenttime dd  ?
wysokoscnfo dd  ?
pause       dd  ?
hFont       dd  ?
endanimpos  dd  ?
framedone   dd  ?
filesize    dd  ?

bmpmonotextinfo BITMAPINFO <>
            db  4 dup (?)
bmpbackinfo BITMAPINFO <>
bmptextinfo BITMAPINFO <>
rectangle   RECT <>
dmsettings  DEVMODE <>
