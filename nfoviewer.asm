; nfo viewer
; coded by FiNS//HTBTeam
; puszczono w swiat 7 grudnia 2004
; ostatnie poprawki 30 stycznia 2005

.486
.model flat, stdcall
option casemap:none

include \masm32\include\windows.inc
include \masm32\include\kernel32.inc
include \masm32\include\user32.inc
include \masm32\include\gdi32.inc
include \masm32\include\winmm.inc
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\user32.lib
includelib \masm32\lib\gdi32.lib
includelib \masm32\lib\winmm.lib

RysujProc PROTO :DWORD
DrawNfoText PROTO :DWORD, :DWORD
_udfade proto :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
_fromupfade proto :DWORD, :DWORD, :DWORD, :DWORD, :DWORD

include nfoviewer.inc

.code
start:
    invoke  GetModuleHandle, 0
    mov     hInstance, eax
    invoke  GetFileAttributes, offset pliknfo
    inc     eax
    jne     @F
    invoke  MessageBoxA, 0, offset nonfo, offset error, MB_ICONERROR
    jmp     theend
@@:
    call    WinMain
theend:
    invoke  ExitProcess, 0

WinMain     proc
    LOCAL   wc:WNDCLASSEX
    LOCAL   msg:MSG
    LOCAL   hWnd:HWND

    mov     wc.cbSize, sizeof WNDCLASSEX
    mov     wc.style, CS_HREDRAW or CS_VREDRAW
    mov     wc.lpfnWndProc, offset WndProc
    xor     edx, edx
    mov     wc.cbClsExtra, edx
    mov     wc.cbWndExtra, edx
    push    hInstance
    pop     wc.hInstance
    mov     wc.hbrBackground, COLOR_WINDOW+1
    mov     wc.lpszMenuName, edx
    mov     wc.lpszClassName, offset klasa
    invoke  LoadIcon, edx, IDI_APPLICATION
    mov     wc.hIcon, eax
    mov     wc.hIconSm, eax
    invoke  LoadCursor, 0, IDC_ARROW
    mov     wc.hCursor, eax
    invoke  RegisterClassEx, addr wc
    lea     edi, dmsettings
    assume  edi:ptr DEVMODE
    mov     [edi].dmSize, sizeof dmsettings
    mov     [edi].dmPelsWidth, 800
    mov     [edi].dmPelsHeight, 600
    mov     [edi].dmFields, 00080000h or 00100000h ; DM_PELSWIDTH or DM_PELSHEIGHT
    assume  edi:nothing
    invoke  ChangeDisplaySettings, edi, CDS_FULLSCREEN
    xor     edx, edx
    invoke  CreateWindowEx, edx, offset klasa, offset tytul, WS_POPUP + WS_CLIPSIBLINGS + WS_CLIPCHILDREN, edx, edx, 800, 600, edx, edx, hInstance, edx
    mov     hWnd, eax
    invoke  ShowWindow, eax, SW_SHOWNORMAL
    invoke  UpdateWindow, hWnd

    push    hWnd
    call    Initialize

messageloop:
    cmp     done, 1
    je      koniec
    invoke  PeekMessage, addr msg, 0, 0, 0, PM_REMOVE
    test    eax, eax
    je      rysuj
    cmp     msg.message, WM_QUIT
    jne     @F
    mov     done, 1
@@:
    invoke  TranslateMessage, addr msg
    invoke  DispatchMessage, addr msg
    jmp     messageloop
rysuj:
    cmp     pause, 1
    jne     @F
    invoke  WaitMessage
    jmp     messageloop
@@:
    cmp     framedone, 1
    je      @F
    call    DrawScene
    mov     framedone, 1
@@:
    call    CheckElapsedTime
    test    eax, eax
    je      messageloop

    invoke  BitBlt, hDC, 0, 0, 800, 600, backDC, 0, 0, SRCCOPY
    mov     framedone, 0
    jmp     messageloop

koniec:
    mov     frametime, 10
    add     endanimpos, 20
    invoke  _fromupfade, backppvBits, 800, 600, 00FFFFFFh, endanimpos
@@:
    call    CheckElapsedTime
    test    eax, eax
    je      @B
    xor     edx, edx
    invoke  BitBlt, hDC, edx, edx, 800, 600, backDC, edx, edx, SRCCOPY
    cmp     endanimpos, 600
    jb      koniec

    call    DeInitialize
    invoke  ChangeDisplaySettings, 0, 0

    mov     eax, msg.wParam
    ret
WinMain endp

WndProc     proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    mov     eax, uMsg
    cmp     eax, WM_CLOSE
    je      wmclose
    cmp     eax, WM_KEYDOWN
    je      wmkeydown
    cmp     eax, WM_LBUTTONUP
    je      wmlbuttonup
    cmp     eax, WM_RBUTTONUP
    je      wmclose

    invoke  DefWindowProc, hWnd, uMsg, wParam, lParam
    ret

wmclose:
    invoke  PostQuitMessage, 0
    jmp     return

wmkeydown:
    mov     eax, wParam
    cmp     al, VK_ESCAPE
    je      wmclose
    cmp     al, VK_ADD
    je      szybciej
    cmp     al, 0BBh ; =
    je      szybciej
    cmp     al, VK_SUBTRACT
    je      wolniej
    cmp     al, 0BDh ; -
    je      wolniej
    jmp     return

szybciej:
    cmp     vscroll, 3
    jae     @F
    inc     vscroll
    jmp     return

wolniej:
    cmp     vscroll, 1
    jbe     @F
    dec     vscroll
    jmp     return

wmlbuttonup:
    cmp     pause, 1
    je      @F
    mov     pause, 1
    jmp     return
@@:
    mov     pause, 0

return:
    xor     eax, eax
    ret
WndProc     endp

Initialize  proc hWnd:DWORD
    LOCAL   ileznakow:DWORD
    LOCAL   ilelinii:DWORD

; wczytaj nfo z HTBTeam.nfo
    invoke  CreateFile, offset pliknfo, GENERIC_READ, FILE_SHARE_READ, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
    mov     hFilenfo, eax
    xor     edx, edx
    invoke  CreateFileMapping, eax, edx, PAGE_READONLY, edx, edx, edx
    mov     hMapnfo, eax
    xor     edx, edx
    invoke  MapViewOfFile, eax, FILE_MAP_READ, edx, edx, edx
    mov     Mapnfo, eax
    invoke  GetFileSize, hFilenfo, 0
    mov     filesize, eax

; policz ile linii ma nfo (do obliczenia wysokosci bitmapy)
    mov     ilelinii, 1
    mov     edx, Mapnfo
    add     eax, edx
    dec     edx
liczlinie:
    inc     edx
    cmp     byte ptr [edx], 13
    jne     @F
    inc     ilelinii
@@:
    cmp     edx, eax
    jne     liczlinie
    inc     ilelinii

    invoke  GetDC, hWnd
    mov     hDC, eax

; utworz bitmape monochromatyczna na nfo
    invoke  CreateCompatibleDC, 0
    mov     monotextDC, eax
    xor     edx, edx
    lea     edi, bmpmonotextinfo
    assume  edi:ptr BITMAPINFO
    mov     [edi].bmiHeader.biSize, sizeof BITMAPINFOHEADER
    mov     [edi].bmiHeader.biWidth, 640
    mov     eax, ilelinii
    imul    eax, 16
    mov     wysokoscnfo, eax
    not     eax
    mov     [edi].bmiHeader.biHeight, eax
    mov     [edi].bmiHeader.biPlanes, 1
    mov     [edi].bmiHeader.biBitCount, 1
    mov     [edi].bmiColors.rgbBlue, 0FFh
    mov     [edi].bmiColors.rgbGreen, 0FFh
    mov     [edi].bmiColors.rgbRed, 0FFh
    assume  edi:nothing
    invoke  CreateDIBSection, monotextDC, edi, edx, addr ppvBitsmonotext, edx, edx
    mov     monotextBMP, eax
    invoke  SelectObject, monotextDC, eax

; namaluj nfo na bitmapie monochromatyczna przy uzyciu czcionki raw
    mov     ileznakow, 0
    mov     ilelinii, 0
    mov     edi, ppvBitsmonotext
    mov     esi, offset font
    mov     edx, Mapnfo
nextchar:
    cmp     byte ptr [edx], 13
    jne     @F
    inc     ilelinii
    mov     ileznakow, 0
    add     edx, 2
    jmp     nextchar
@@:
    xor     eax, eax
    mov     al, byte ptr [edx]
    imul    eax, eax, 16
    add     eax, esi
    push    edx
    mov     edx, ilelinii
    imul    edx, edx, (640/8*16)
    add     edx, ileznakow
    add     edx, edi
    mov     cl, 16
@@:
    mov     ch, byte ptr [eax]
    inc     eax
    mov     byte ptr [edx], ch
    add     edx, (640/8)
    dec     cl
    jnz     @B
    pop     edx
    inc     edx
    inc     ileznakow
    mov     eax, Mapnfo
    add     eax, filesize
    cmp     edx, eax
    jb      nextchar

; zamknij plik nfo
    invoke  UnmapViewOfFile, Mapnfo
    invoke  CloseHandle, hMapnfo
    invoke  CloseHandle, hFilenfo

; utworz bitmape na text z cieniem
    invoke  CreateCompatibleDC, hDC
    mov     textDC, eax
    xor     edx, edx
    lea     edi, bmptextinfo
    assume  edi:ptr BITMAPINFO
    mov     [edi].bmiHeader.biSize, sizeof BITMAPINFOHEADER
    mov     [edi].bmiHeader.biWidth, 640
    mov     eax, wysokoscnfo
    not     eax
    mov     [edi].bmiHeader.biHeight, eax
    mov     [edi].bmiHeader.biPlanes, 1
    mov     [edi].bmiHeader.biBitCount, 32
    assume  edi:nothing
    invoke  CreateDIBSection, textDC, edi, edx, addr textppvBits, edx, edx
    mov     textBMP, eax
    invoke  SelectObject, textDC, eax

; pomaluj tlo na niebiesko
    mov     eax, textppvBits
    mov     ecx, 640
    imul    ecx, wysokoscnfo
@@:
    mov     dword ptr[eax], BK_COLOR
    add     eax,4
    loop    @B

; kopiuj tekst nfo z mono bitmapy na bitmape kolorowa na czarno (cien) i na bialo
    invoke  BitBlt, textDC, 2, 2, 640, wysokoscnfo, monotextDC, 0, 0, SRCAND ; na czarno
    xor     edx, edx
    invoke  BitBlt, textDC, edx, edx, 640, wysokoscnfo, monotextDC, edx, edx, MERGEPAINT ; na bialo

    invoke  DeleteDC, monotextDC
    invoke  DeleteObject, monotextBMP

; utworz backbuffer do double buffering
    invoke  CreateCompatibleDC, hDC
    mov     backDC, eax
    xor     edx, edx
    lea     edi, bmpbackinfo
    assume  edi:ptr BITMAPINFO
    mov     [edi].bmiHeader.biSize, sizeof BITMAPINFOHEADER
    mov     [edi].bmiHeader.biWidth, 800
    mov     [edi].bmiHeader.biHeight, (not 600)
    mov     [edi].bmiHeader.biPlanes, 1
    mov     [edi].bmiHeader.biBitCount, 32
    assume  edi:nothing
    invoke  CreateDIBSection, backDC, edi, edx, addr backppvBits, edx, edx
    mov     backBMP, eax
    invoke  SelectObject, backDC, eax

; pomaluj tlo na niebiesko
    mov     eax, backppvBits
    mov     ecx, 800
    imul    ecx, 600
@@:
    mov     dword ptr[eax], BK_COLOR
    add     eax,4
    loop    @B

; przygotuj bialy i czarny pedzel do malowania
    invoke  CreatePen, PS_SOLID, 1, 00FFFFFFh
    mov     hPen1, eax
    invoke  CreatePen, PS_SOLID, 1, 0
    mov     hPen2, eax

; ustaw poczatkowe wspolrzedne dla pojawiajacych sie linii
    mov     xpos1, 0
    mov     xpos2, 800
    mov     ypos1, 550
    mov     ypos2, 50

; ustaw rozdzielczosc timera na 1ms
    invoke  timeBeginPeriod, 1

; schowaj kursor
    invoke  ShowCursor, FALSE

; wypisz teksty informacyjne na backbuffer
    xor     edx, edx
    invoke  CreateFont, 8, 6, edx, edx, FW_NORMAL, edx, edx, edx, OEM_CHARSET, edx, edx, edx, edx, offset fonttname
    mov     hFont, eax
    invoke  SelectObject, backDC, eax
    invoke  SetBkMode, backDC, TRANSPARENT
    invoke  SetTextColor, backDC, 0
    mov     rectangle.top, 8
    mov     rectangle.left, 8
    invoke  DrawText, backDC, offset infotext, infotextsize, offset rectangle, DT_NOCLIP
    invoke  TextOut, backDC, 577, 582, offset infotext2, sizeof infotext2
    invoke  SetTextColor, backDC, 00FFFFFFh
    mov     rectangle.top, 6
    mov     rectangle.left, 6
    invoke  DrawText, backDC, offset infotext, infotextsize, offset rectangle, DT_NOCLIP
    invoke  TextOut, backDC, 575, 580, offset infotext2, sizeof infotext2
    invoke  DeleteObject, hFont
    ret
Initialize  endp

DeInitialize    proc
    invoke  DeleteDC, hDC
    invoke  DeleteDC, backDC
    invoke  DeleteObject, backBMP
    invoke  DeleteDC, textDC
    invoke  DeleteObject, textBMP
    invoke  DeleteObject, hPen1
    invoke  DeleteObject, hPen2
    invoke  timeEndPeriod, 1
    invoke  ShowCursor, TRUE
    ret
DeInitialize    endp

CheckElapsedTime    proc
; sprawdza czy minal okreslony czas od czasu wyswietlenia ostatniej klatki
    invoke  timeGetTime
    mov     currenttime, eax
    sub     eax, lasttime
    cmp     eax, frametime
    jb      return
    push    currenttime
    pop     lasttime
    ret
return:
    xor     eax, eax
    ret
CheckElapsedTime    endp

DrawScene   proc
    push    ebx
    mov     ebx, backDC
; rysuj kolejne klatki animacji
    cmp     xpos1, 740
    jae     @F
; rysuj dolna i gorna czarna kreske
    invoke  SelectObject, ebx, hPen2
    add     xpos1, 22
    invoke  MoveToEx, ebx, 0, 552, 0
    invoke  LineTo, ebx, xpos1, 552
    sub     xpos2, 18
    invoke  MoveToEx, ebx, 800, 52, 0
    invoke  LineTo, ebx, xpos2, 52
; rysuj dolna i gorna biala kreske
    invoke  SelectObject, ebx, hPen1
    sub     xpos1, 2
    invoke  MoveToEx, ebx, 0, 550, 0
    invoke  LineTo, ebx, xpos1, 550
    sub     xpos2, 2
    invoke  MoveToEx, ebx, 800, 50, 0
    invoke  LineTo, ebx, xpos2, 50
    jmp     return
@@:
    cmp     ypos2, 800
    jae     @F
; rysuj prawa i lewa czarna kreske
    invoke  SelectObject, ebx, hPen2
    sub     ypos1, 20
    invoke  MoveToEx, ebx, 742, 552, 0
    invoke  LineTo, ebx, 742, ypos1
    add     ypos2, 20
    invoke  MoveToEx, ebx, 62, 52, 0
    invoke  LineTo, ebx, 62, ypos2
; rysuj prawa i lewa biala kreske
    invoke  SelectObject, backDC, hPen1
    invoke  MoveToEx, ebx, 740, 550, 0
    invoke  LineTo, ebx, 740, ypos1
    invoke  MoveToEx, ebx, 60, 50, 0
    invoke  LineTo, ebx, 60, ypos2
    cmp     ypos2, 800
    jb      return
; po zakonczeniu animacji linii zamaluj 2 czarne pixele na biale na przecieciach
    invoke  SetPixel, ebx, 62, 550, 00FFFFFFh
    invoke  SetPixel, ebx, 742, 50, 00FFFFFFh
@@:

    mov     frametime, 50
    cmp     scrollpos, -90
    jge     @F
    add     scrollpos, 4
    mov     frametime, 40
@@:
    mov     eax, vscroll
    add     scrollpos, eax
    mov     eax, wysokoscnfo
    cmp     scrollpos, eax
    jl      @F
    mov     scrollpos, -480
@@:
    sub     eax, scrollpos
    cmp     eax, 460
    jl      @F
    mov     eax, 460
@@:

    invoke  BitBlt, ebx, 90, 70, 640, eax, textDC, 0, scrollpos, SRCCOPY
    invoke  _udfade, backppvBits, 800, 90, 70, 640, 460, BK_COLOR, 40

return:
    pop     ebx
    ret
DrawScene   endp

; stopniowany u gory i dolu alpha blending
_udfade     proc ppvBits:DWORD, bWidth:DWORD, Xpos:DWORD, Ypos:DWORD, aWidth:DWORD, aHeight:DWORD, BkColor:DWORD, aLines:DWORD
    LOCAL   cos1: DWORD
    LOCAL   cos2: DWORD

    pusha
    mov     esi, ppvBits
    mov     eax, bWidth
    shl     eax, 2
    imul    eax, Ypos
    add     esi, eax
    mov     eax, Xpos
    shl     eax, 2
    add     esi, eax

    xor     edx, edx
    mov     eax, 255
    idiv    aLines
    mov     cos1, eax ; w cos1 wartosc o ile ma byc stopniwana 1 linia = 255/ilelinii

    mov     edx, BkColor

    mov     ecx, aHeight
_zloop:
    push    ecx

    mov     eax, aHeight
    sub     eax, ecx ; w eax numer obecnie obrabianej linii

; sprawdzanie czy linia z zakresu 0 - aLines
    cmp     eax, aLines
    ja      @F
    imul    eax, cos1
    mov     cos2, eax ; w cos2 wspolczynnik do alpha blending dla obecnej linii,
                      ; im wiekszy tym linia bardziej widoczna, 0 < cos2 < 255
    jmp     _endcheck
@@:

; dodatkowe stopniowanie przy gornym brzegu - plynniejsze przejscie
    mov     ecx, aLines
    add     ecx, 3
    cmp     eax, ecx
    ja      @F
    mov     cos2, 250
    jmp     _endcheck
@@:

; sprawdzanie czy linia z zakresu (aHeight-aLines) - aHeight
    sub     eax, aHeight
    neg     eax
    cmp     eax, aLines ; w eax numer linii liczac od konca
    ja      @F
    imul    eax, cos1
    mov     cos2, eax
    jmp     _endcheck
@@:

; dodatkowe stopniowanie przy dolnym brzegu - plynniejsze przejscie
    mov     ecx, aLines
    add     ecx, 3
    cmp     eax, ecx
    ja      @F
    mov     cos2, 250
    jmp     _endcheck
@@:

; linia nie przeznaczona do alpha blendingu
    mov     ecx, bWidth
    shl     ecx, 2
    add     esi, ecx
    pop     ecx
    dec     ecx
    jne    _zloop

; alpha blending na 1 linie, w cos2 stopien intenstywnosci
_endcheck:
    mov     edi, esi
    mov     ecx, aWidth
    shl     ecx, 2
_wloop:
    xor     eax, eax
    lodsb
    movzx   ebx, dl
    sub     eax, ebx
    imul    eax, cos2
    shr     eax, 8
    add     eax, ebx
    stosb
    ror     edx, 8
    loop    _wloop
    mov     eax, bWidth
    sub     eax, aWidth
    shl     eax, 2
    add     esi, eax
    pop     ecx
    dec     ecx
    jne     _zloop

    popa
    ret
_udfade     endp

; wylewanie bialego koloru od gory przy wylaczaniu proga
_fromupfade proc ppvBits:DWORD, pWidth:DWORD, pHeight:DWORD, BkColor:DWORD, Line:DWORD
    LOCAL cos: DWORD

    pusha
    mov     esi, ppvBits
    mov     edx, BkColor
    mov     ecx, Line
    imul    ecx, pWidth

; pomaluj bitmape (ppvBits) do lini (Line) na staly kolor (BkColor)
czyscdoline:
    mov     [esi], edx
    add     esi, 4
    loop    czyscdoline
    mov     edi, esi

    mov     ecx, Line ; potrzebne zeby nie wywalalo sie gdy Line+40>pHeight
    add     ecx, 40
    cmp     ecx, pHeight
    jbe     @F
    sub     ecx, pHeight ; ecx = o ile linii wiecej niz wysokosc
    cmp     ecx, 40
    jae     _end
    neg     ecx
    add     ecx, 40
    jmp     _zloop
@@:

    mov     ecx, 40
_zloop:
    push    ecx
    mov     eax, ecx
    imul    eax, 6
    not     eax
    add     eax, 255
    mov     cos, eax ; im cos mniejsze, tym BkColor bardziej widoczne niz bitmapa

    mov     ecx, pWidth
    shl     ecx, 2
_wloop:
    xor     eax, eax
    lodsb
    movzx   ebx, dl
    sub     eax, ebx
    imul    eax, cos
    shr     eax, 8
    add     eax, ebx
    stosb
    ror     edx, 8
    loop    _wloop
    pop     ecx
    loop    _zloop

_end:
    popa
    ret
_fromupfade endp

end start