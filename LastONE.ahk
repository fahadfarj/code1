I_Icon = C:\Users\user\nvidia-icon.ico
IfExist, %I_Icon%
  Menu, Tray, Icon, %I_Icon%
;return

#NoEnv
SetWorkingDir %A_ScriptDir%
#SingleInstance Force
#include <gdip64>
global g_gdi_token := Gdip_Startup()
OnExitGdipShutdown() {
    for k,v in bitmaps
        Gdip_DisposeImage(v)
    Gdip_Shutdown(g_gdi_token)
}
global QPF := 0
DllCall("QueryPerformanceFrequency", "Int64*", QPF)
QPF /= 1000
GetTime() { ; milliseconds
    static start := 0
    static counter := 0
    DllCall("QueryPerformanceCounter", "Int64*", counter)
    start := start ? start : (counter / QPF)
    return counter / QPF - start
}
PrecisionSleep(period)
{
    if !(error := DllCall("winmm\timeGetDevCaps", Int64P, TimeCaps, UInt,8)){
        MinSetResolution := TimeCaps & 0xFFFFFFFF
        DllCall("Winmm.dll\timeBeginPeriod", UInt, MinSetResolution)
    }
    if (period >= 0)    
        DllCall("Sleep", UInt, period)
    if (MinSetResolution)                       
    	DllCall("Winmm.dll\timeEndPeriod", UInt, MinSetResolution)
    return error
}	
GetFPS() {
    static UPDATE_INTERVAL := 1
    static timeLast := 0
    static counter := 0
    static fps := 0
    now := GetTime() / 1000
    if ((now - timeLast) >= UPDATE_INTERVAL) {
        fps := Round(counter/(now-timeLast),1)
        timeLast := now
        counter := 0
    } else {
        counter++
    }
    return fps
}
; #include <common>
; #include <memoryClass>
; #include <errors>
OnExit("OnExitGdipShutdown")
#InstallKeybdHook
#InstallMouseHook
#UseHook On
#KeyHistory 0
CoordMode,Mouse,Client
CoordMode,Pixel,Client
; Process, Priority, % DllCall("GetCurrentProcessId"), Realtime
SendMode, Input
ListLines, Off
SetBatchLines, -1
SetWinDelay, -1
SetControlDelay, -1
SetDefaultMouseSpeed, 0
global KeyDelay := 60
global g_ubp:=0
#Persistent
global g_fov := 0
global g_scan_inset_w := 0.4
global g_scan_inset_h := 0.25
global g_scan_margin_x := 0
global g_scan_margin_y := 0
global g_scan_left := 0
global g_scan_top := 0
global g_scan_right := 0
global g_scan_bottom := 0
global g_enemy_health_left := 0
global g_enemy_health_top := 0
global g_enemy_health_right := 0
global g_enemy_health_bottom := 0
global g_player_health_left := 0
global g_player_health_top := 0
global g_player_health_right := 0
global g_player_health_bottom := 0
global g_mouse_icon_left := 0
global g_mouse_icon_right := 0
global g_indicators_left := 0
global g_indicators_top := 0
global g_indicators_right := 0
global g_indicators_bottom := 0
global g_tp := 0
global g_attack_time := 0
global g_unblockable := false

global g_block_times := {6: Object(), 8: Object(), 9: Object(), 12: Object(), 20: Object(), 30: Object(), 40: Object(), 115: Object()}
g_block_times[6]["1"] := {start:50, end:200}
g_block_times[6]["2"] := {start:30, end:60}
g_block_times[8]["1"] := {start:180, end: 320}
g_block_times[8]["2"] := {start:350, end: 610}
g_block_times[9]["1"] := {start:180, end:320}
g_block_times[12]["1"] := {start:480, end:580}
g_block_times[12]["2"] := {start:250, end:280}
g_block_times[12]["3"] := {start:90, end:200}
g_block_times[12]["4"] := {start:75, end:150}
g_block_times[12]["5"] := {start:50, end:100}
g_block_times[20]["1"] := {start:550, end:680}
g_block_times[20]["2"] := {start: 340, end: 680}
g_block_times[20]["3"] := {start: 100, end: 220}
g_block_times[40]["1"] := {start:200, end:400}
g_block_times[115]["1"] := {start:600, end:800}

global g_unblock_times := {6: Object(), 8: Object(), 9: Object(), 12: Object(), 20: Object(), 30: Object(), 40: Object(), 115: Object()}
g_unblock_times[6]["1"] := {start:50, end:200}
g_unblock_times[6]["2"] := {start:30, end:60}
g_unblock_times[8]["1"] := {start:180, end: 320}
g_unblock_times[8]["2"] := {start:350, end: 610}
g_unblock_times[9]["1"] := {start:180, end:320}
g_unblock_times[12]["1"] := {start:480, end:580}
g_unblock_times[12]["2"] := {start:250, end:280}
g_unblock_times[12]["3"] := {start:90, end:200}
g_unblock_times[12]["4"] := {start:75, end:150}
g_unblock_times[12]["5"] := {start:50, end:100}
g_unblock_times[20]["1"] := {start:550, end:680}
g_unblock_times[20]["2"] := {start: 340, end: 680}
g_unblock_times[20]["3"] := {start: 100, end: 220}
g_unblock_times[40]["1"] := {start:200, end:400}
g_unblock_times[115]["1"] := {start:600, end:800}


global g_slow_parry_start := 550
global g_slow_parry_end := 680
global g_fast_parry_start := 150
global g_fast_parry_end := 280
global g_estamina_full_width := 115
global g_estamina := 100
global g_estamina_used := 100

Gui New, +HWNDguihwnd
Gui Font, cWhite
Gui Color, cWhite

Gui Add, GroupBox, cRed x10 y10 w180 h90, Characters
Gui Add, CheckBox, x20 y30 w70 h20 vWarden, Kensei
Gui Add, CheckBox, x20 y50 w100 h20 vBlackprior, Blackprior
Gui Add, CheckBox, x20 y70 w100 h20 vAll_Others, All Others

Gui Add, GroupBox, cRed x10 y105 w180 h70, Auto features for 1x1/2x2/4x4/
Gui Add, CheckBox, x20 y125 w160 h20 vActiveAutoDodge, Dodge Bashes/Unblockables
Gui Add, CheckBox, x20 y145 w80 h20 vActiveAutoBlock, Auto Block

Gui Add, GroupBox, cRed x10 y180 w180 h70, Hotkey1
Gui Add, Hotkey, x102 y180 w60 h18 vHotkey1, C
Gui Add, CheckBox, x20 y200 w80 h20 vActiveHotkey1Parry, Auto Parry
Gui Add, CheckBox, x20 y220 w80 h20 vActiveHotkey1Flip, Auto Flip

Gui Add, GroupBox, cRed x10 y255 w180 h105, Hotkey2
Gui Add, Hotkey, x102 y255 w60 h18 vHotkey2, E
Gui Add, CheckBox, x20 y275 w80 h20 vActiveHotkey2Parry, Auto Parry
Gui Add, CheckBox, x20 y295 w80 h20 vActiveHotkey2CC, Auto CC
Gui Add, CheckBox, x20 y315 w140 h20 vActiveHotkey2Deflect, Auto Deflect Arrow
Gui Add, CheckBox, x20 y335 w140 h20 vActiveHotkey2DeflectG, Auto Deflect Glow

Gui Add, GroupBox, cRed x10 y365 w180 h50, ToggleHotkey3
Gui Add, Hotkey, x102 y365 w60 h18 vHotkey3, \
Gui Add, CheckBox, x20 y385 w165 h20 vActiveWarningBlock, Auto Block Exclamation Mark

Gui Add, GroupBox, cRed x200 y10 w170 h70, Scaling
Gui Add, Text, x205 y26 w65 h20, Field of View:
Gui Add, Edit, c390202 x270 y24 w45 h20 Center vg_fov, 90
Gui Add, Text, x205 y46 w65 h30, Stamina Height:
Gui Add, Edit, c390202 x270 y50 w45 h20 Center vg_stamina_height, 2
Gui Add, Button, x335 y24 w30 h45 gButtonOK, OK

Gui Add, GroupBox, cRed x200 y80 w170 h180, Delays
Gui Add, Text, x210 y100 w120 h20, Dodge Delay in ms:
Gui Add, Edit, c390202 x310 y100 w27 h17 vDodgeDelay, 0
Gui Add, Text, x210 y120 w120 h20, Feints Check Delay:
Gui Add, Edit, c390202 x310 y120 w27 h17 vFeintCheckDelay, 0
Gui Add, CheckBox, x210 y160 w155 h20 vActiveRMBAfterDodge, RMouse Button after dodge
Gui Add, CheckBox, x210 y180 w155 h20 vActiveLMBAfterDodge, LMouse Button after dodge
Gui Add, Text, x210 y200 w130 h20, L/RMouse Delay in ms:
Gui Add, Edit, c390202 x325 y200 w27 h17 vLRMouseDelay, 0
Gui Add, Edit, c390202 x345 y220 w20 h17 vLeft, 0
Gui Add, Edit, c390202 x345 y240 w20 h17 vRight, 0
Gui Add, Text, x210 y220 w128 h20, Delay on left deflect in ms:
Gui Add, Text, x210 y240 w130 h20, Delay on right deflect in ms:
Gui Add, Text, x210 y140 w120 h20, Block Delay in ms:
Gui Add, Edit, c390202 x310 y140 w27 h17 vBlockDelay, 0

Gui Add, GroupBox, cRed x380 y10 w160 h98, Hotkeys
Gui, Add, Text, x405 y30 w120 h16, [Dodges On/Off]  - Insert
Gui, Add, Text, x405 y46 w120 h16, [Pause/Resume]  -  Z
Gui, Add, Text, x405 y62 w120 h16, [Show GUI]  -  Home
Gui, Add, Text, x405 y78 w120 h16, [Screenshot]  -  F12

Gui Add, GroupBox, cRed x380 y145 w160 h112, Help and Settings
Gui Add, Button, x390 y163 w140 h19 gButtonHelp, How to use
Gui Add, Button, x390 y185 w140 h19 gButtonLoad, Load Settings
Gui Add, Button, x390 y207 w140 h19 gButtonSave, Save Settings
Gui Add, Button, x390 y229 w140 h19 gButtonApply, Apply Settings

Gui Add, GroupBox, cRed x380 y260 w160 h80, Controls
Gui Add, Button, x390 y283 w140 h20 gButtonReload, Reload
Gui Add, Button, x390 y306 w140 h20 gButtonStart, Start

Gui Add, GroupBox, cRed x200 y260 w170 h80, Deflect
Gui Add, CheckBox,  x210 y275 w60 h25 vActiveDeflectLight, Light
Gui Add, CheckBox,  x210 y300 w60 h15 vActiveDeflectHeavy, Heavy
Gui Add, CheckBox,  x210 y320 w60 h15 vActiveDeflectGB, GB

Gui Add, CheckBox,  x280 y275 w80 h25 vActiveDeflectLightG, Glow Light
Gui Add, CheckBox,  x280 y300 w80 h15 vActiveDeflectHeavyG, Glow Heavy
Gui Add, CheckBox,  x280 y320 w80 h15 vActiveDeflectGBG, Glow GB

Gui, Add, GroupBox, cRed x200 y345 w170 h85, Distance Threshold
Gui, Add, Edit, c390202 x310 y355 w30 h20 vDistanceThreshold, % "130"

Gui Add, Text, x210 y375 w120 h20, Parry Delay in ms:
Gui Add, Edit, c390202 x310 y375 w27 h17 vParryDelay, 0


GuiShow() {
    global
    Gui, %guihwnd%:Show, w550 h420, yo!
}
GuiShow()
global g_target_wnd := "ahk_class FoxGame"
global g_hwnd := false
global g_screenshot := false
global g_screenshot_time := 0
global g_clientarea := {}
ShowTooltip(str) {
    tooltip % str
    settimer, HideTooltip, -2000
    return
    HideTooltip:
        tooltip
    return
}
GetScreenshot() {
    return Gdip_BitmapFromScreenCoords(g_clientarea.x + g_scan_left, g_clientarea.y + g_scan_top, g_clientarea.x + g_scan_right, g_clientarea.y + g_scan_bottom) 
}
DrawText(bitmap, str:="Empty String",x:=20,y:=20,col:="FF00CCFF",shadow := 0,font:="Lucida Console",size:=12,just:="Left")
{
    g := Gdip_GraphicsFromImage(bitmap)
    if shadow
        Gdip_TextToGraphics(g, str, "x" x+1 " y" y+1 " " just " cFE000000 r" 4 " s" size, font)
    return Gdip_TextToGraphics(g, str, "x" x " y" y " " just " c" col " r" 4 " s" size, font)
    
		; Gdip_DeleteGraphics(this.gdi_G)	
}
SaveScreenshot(screenshot := false, caption := false) {
    ss := screenshot ? screenshot : Gdip_BitmapFromScreenCoords(0, 0, g_clientarea.w, g_clientarea.h)
    if (caption)
        DrawText(ss, caption, 100, 100, "FF00FFFF", shadow:=true, "Lucida Console", size:=16, "Left")
    Gdip_SaveBitmapToFile(ss, "scrcap-" A_Now ".png", 100)
    if (screenshot != ss)
        Gdip_DisposeImage(ss)
}
GetClientArea(g_hwnd)
{
    VarSetCapacity(pWindowInfo, 68, 0)
    DllCall("GetWindowInfo", "UInt", g_hwnd, "UInt", &pWindowInfo)
    cx := NumGet(pWindowInfo, 20, "Int"), cy := NumGet(pWindowInfo, 24, "Int")
    cw := NumGet(pWindowInfo, 28, "Int") - cx, ch := NumGet(pWindowInfo, 32, "Int") - cy
    cx := (cx < 0) ? 0 : cx, cy := (cy < 0) ? 0 : cy
    cw := (cw > A_ScreenWidth) ? A_ScreenWidth : cw, ch := (ch > A_ScreenHeight) ? A_ScreenHeight : ch
    return  {x:cx ,y:cy ,w:cw ,h:ch}
}

ResolutionScaleH(x) {
    return x / 1920 * g_clientarea.w
}
ResolutionScaleV(y) {
    return y / 1080 * g_clientarea.h
}
FovScale(x) {
    return x * (81 / g_fov)
}

SetScaling() {
    g_scan_margin_x := g_scan_inset_w * (g_clientarea.w // 2), g_scan_margin_y := g_scan_inset_h * (g_clientarea.h // 2)
    g_scan_left := g_scan_margin_x, g_scan_top := g_scan_margin_y, g_scan_right := g_clientarea.w - g_scan_margin_x, g_scan_bottom := g_clientarea.h - g_scan_margin_y
    CenterX := (g_clientarea.w // 2), CenterY := (g_clientarea.h // 2)
    g_enemy_health_left := CenterX + FovScale(ResolutionScaleH(860) - CenterX)
    g_enemy_health_top := CenterY + FovScale(ResolutionScaleV(200) - CenterY)
    g_enemy_health_right := CenterX + FovScale(ResolutionScaleH(860) + ResolutionScaleH(200) - CenterX)
    g_enemy_health_bottom := CenterY + FovScale(ResolutionScaleV(200) + ResolutionScaleV(250) - CenterY)
    g_player_health_left := CenterX + FovScale(ResolutionScaleH(645) - CenterX)
    g_player_health_top := CenterY + FovScale(ResolutionScaleV(300) - CenterY)
    g_player_health_right := CenterX + FovScale(ResolutionScaleH(820) - CenterX)
    g_player_health_bottom := CenterY + FovScale(ResolutionScaleV(510) - CenterY)
    g_mouse_icon_left := CenterX + FovScale(ResolutionScaleH(560) - CenterX)
    g_mouse_icon_right := CenterX
    g_tp := CenterX + FovScale(ResolutionScaleH(740) - CenterX)
}

class Brush
{
	h := false
	__new(c)
	{
		this.h := Gdip_BrushCreateSolid(c)
		return this
	}
	__delete()
	{
		Gdip_deleteBrush(this.h)
	}
}
global bitmaps := {}
CreateSearchBitmap(w, h, c) {
    p := Gdip_CreateBitmap(w, h)
    g := Gdip_GraphicsFromImage(p)
    b := new Brush(c)
    Gdip_FillRectangle(g, b.h, 0, 0, w, h)
    bitmaps.Push(p)
    return p
}
LoadSearchBitmap(filepath) {
    p := Gdip_CreateBitmapFromFile(filepath)
    bitmaps.Push(p)
    return p
}
ImageSearch(haystack, needle, l := 0, t := 0, r := 1, b := 1, var := 2, dir := 1, n := 1) {
    if (l < g_scan_left || t < g_scan_top) {
        ShowTooltip("ImageSearch: l < g_scan_left || t < g_scan_top")
    }
    dispose := !haystack
    haystack := haystack ? haystack : GetScreenshot()
    if ((ret := Gdip_ImageSearch(haystack, needle, out, l - g_scan_left, t - g_scan_top, r - g_scan_left, b - g_scan_top, var,,dir, n)) < 1) {
        if (ret < 0) {
            ShowTooltip("Gdip_ImageSearch: " ret)
        }
        return false
    }
    res := {}
    for k,v in StrSplit(out, "`n") {
        pos := StrSplit(v, ",")
        res[a_index] := {x: pos[1] + g_scan_left, y: pos[2] + g_scan_top}
    }
    if (dispose)
        Gdip_DisposeImage(haystack)
    return res
}
GetPixel(haystack, x := 0, y := 0) {
    if (x < g_scan_left || y < g_scan_top) {
        ShowTooltip("GetPixel: x < g_scan_left || y < g_scan_top")
    }
    dispose := !haystack
    haystack := haystack ? haystack : GetScreenshot()
    argb := Gdip_GetPixel(haystack, x - g_scan_left, y - g_scan_top)
    if (dispose)
        Gdip_DisposeImage(haystack)
    return argb
}
MeasureStamina(screenshot, x, y) {
    width := 1
    loop % (g_estamina_full_width - 1) {
        argb := GetPixel(screenshot, x + a_index, y), r := (argb >> 16) & 0xFF, g := (argb >> 8) & 0xFF, b := argb & 0xFF, gd := g / max(r, b, 1)
        if (gd < 1.2)
            break
        width++
    }
    return width
}
InitSearchBitmaps() {
    global
    Gdip_DisposeImage(rect_white)
    rect_white := CreateSearchBitmap(5, 4, 0xFFFFFFFF)
    Gdip_DisposeImage(rect_exred)
    rect_exred := CreateSearchBitmap(4, 18, 0xFFFF1D05)
    Gdip_DisposeImage(pixel_yellow)
    pixel_yellow := CreateSearchBitmap(1, 1, 0xFFFFFF0A)
    Gdip_DisposeImage(pixel_stamina)
    pixel_stamina := CreateSearchBitmap(1, 1, 0xFF058341)
    Gdip_DisposeImage(rect_stamina)
    rect_stamina := CreateSearchBitmap(1, g_stamina_height, 0xFF058341)
    Gdip_DisposeImage(pixel_enemyname)
    pixel_enemyname := CreateSearchBitmap(1, 1, 0xFFFF6D05)
    Gdip_DisposeImage(pixel_orange1)
    pixel_orange1 := CreateSearchBitmap(1, 1, 0xFFDD5D0F) ;:#DD5D0F
    Gdip_DisposeImage(pixel_orange2) ;unblockable
    pixel_orange2 := CreateSearchBitmap(1, 1, 0xFFF66208) ;:#F66208
    Gdip_DisposeImage(pixel_red1)
    pixel_red1 := CreateSearchBitmap(1, 1, 0xFFFF221C)
    Gdip_DisposeImage(pixel_red2) ; early attack indicator
    pixel_red2 := CreateSearchBitmap(1, 1, 0xFFFF3129) ;:#FF3129
    Gdip_DisposeImage(pixel_red3)
    pixel_red3 := CreateSearchBitmap(1, 1, 0xFFFF2922) ;:#FF2922
    Gdip_DisposeImage(pixel_red4)
    pixel_red4 := CreateSearchBitmap(1, 1, 0xFFFF9A8D) ;:#FF9A8D
    Gdip_DisposeImage(pixel_red5) ; late attack indicator
    pixel_red5 := CreateSearchBitmap(1, 1, 0xFFF31C16) ;:#F31C16
    Gdip_DisposeImage(pixel_red_feint) ; feint attack indicator
    pixel_red_feint := CreateSearchBitmap(2, 1, 0xFFFF3129)
}
global g_hotkeys := {}
SetupHotkeys() {
    global
    hotkey_setup := {}
    hotkey_setup[Hotkey3] := "ToggleWarningBlock"
    for hk,fn in g_hotkeys
        Hotkey, % hk, Off
    g_hotkeys := {}
    for hk,fn in hotkey_setup {
        Hotkey, % hk, % fn, On
        g_hotkeys[hk] := fn
    }
}


Calculate() {
    global
    ActiveAutoDodge := false
    phb := ImageSearch(g_screenshot, pixel_stamina, g_player_health_left, g_player_health_top, g_player_health_right, g_player_health_bottom, 1), Bx := phb[1].x, By := phb[1].y
    ehb := ImageSearch(g_screenshot, pixel_enemyname, g_enemy_health_left, g_enemy_health_top, g_enemy_health_right, g_enemy_health_bottom, 1)
        ?  ImageSearch(g_screenshot, rect_stamina, g_enemy_health_left, g_enemy_health_top, g_enemy_health_right, g_enemy_health_bottom, 1) : false
    if (ehb) {
        Ax := ehb[1].x, Ay := ehb[1].y, esta := MeasureStamina(g_screenshot, Ax, Ay), g_estamina_used := ((g_estamina - esta) > 5) ? (g_estamina - esta) : g_estamina_used, g_estamina := esta
        ; ToolTip, | %g_estamina% +%g_estamina_used%, (A_ScreenWidth // 2) - 50, 100, 2
    }
    ; else {
    ;     tooltip
    ; }
    
    if (ehb && !phb) {
        y2 := Ay + FovScale(ResolutionScaleV(20))
        y3 := Ay + FovScale(ResolutionScaleV(170))
        x4 := Ax + FovScale(ResolutionScaleH(5))
        y4 := Ay + FovScale(ResolutionScaleV(195))
        x7 := Ax - FovScale(ResolutionScaleH(30))
        g_indicators_left := Ax - FovScale(ResolutionScaleH(200))
        g_indicators_top := Ay + FovScale(ResolutionScaleV(20))
        g_indicators_right := Ax + FovScale(ResolutionScaleH(160))
        g_indicators_bottom := Ay + FovScale(ResolutionScaleV(430))
        ActiveAutoDodge:=1
    } else if (ehb && phb) {
        y2 := Ay + FovScale(ResolutionScaleH(10))
        y3 := Ay + FovScale(ResolutionScaleV(85))
        x4 := Ax + FovScale(ResolutionScaleH(2.5))
        y4 := Ay + FovScale(ResolutionScaleV(97.5))
        x7 := Ax - FovScale(ResolutionScaleH(15))
        g_indicators_left := Ax - FovScale(ResolutionScaleH(117.6))
        g_indicators_top := Ay + FovScale(ResolutionScaleV(10))
        g_indicators_right := Ax + FovScale(ResolutionScaleH(94.11))
        g_indicators_bottom := Ay + FovScale(ResolutionScaleV(227.7))
        ActiveAutoDodge:=1
    } else if (!ehb) {
        ehb := ImageSearch(g_screenshot, pixel_yellow ,g_enemy_health_left, g_enemy_health_top, g_enemy_health_right, g_enemy_health_bottom), Ax := ehb[1].x, Ay := ehb[1].y
        if (ehb && !phb) {
            y2 := Ay + FovScale(ResolutionScaleV(65))
            y3 := Ay + FovScale(ResolutionScaleV(185))
            x4 := Ax + FovScale(ResolutionScaleH(30))
            y4 := Ay + FovScale(ResolutionScaleV(215))
            x7 := Ax - FovScale(ResolutionScaleH(5))
            g_indicators_left := Ax - FovScale(ResolutionScaleH(175))
            g_indicators_top := Ay + FovScale(ResolutionScaleV(65))
            g_indicators_right := Ax + FovScale(ResolutionScaleH(185))
            g_indicators_bottom := Ay + FovScale(ResolutionScaleV(430))
            ActiveAutoDodge:=1
        } else if (ehb && phb) {
            y2 := Ay + FovScale(ResolutionScaleH(35))
            y3 := Ay + FovScale(ResolutionScaleV(92.5))
            x4 := Ax + FovScale(ResolutionScaleH(15))
            y4 := Ay + FovScale(ResolutionScaleV(107.5))
            x7 := Ax - FovScale(ResolutionScaleH(2.5))
            g_indicators_left := Ax - FovScale(ResolutionScaleH(87.5))
            g_indicators_top := Ay + FovScale(ResolutionScaleV(35))
            g_indicators_right := Ax + FovScale(ResolutionScaleH(92.5))
            g_indicators_bottom := Ay + FovScale(ResolutionScaleV(215))
            ActiveAutoDodge:=1
        }
    }
}
SearchBot() {
    global
    if (ActiveAutoDodge) {
        id1 := ImageSearch(g_screenshot, pixel_orange1, g_indicators_left, g_indicators_top, g_indicators_right, g_indicators_bottom, 2), vx := id1[1].x, vy := id1[1].y
        if (id1) {
            id2 := ImageSearch(g_screenshot, pixel_red1, g_indicators_left, g_indicators_top, g_indicators_right, g_indicators_bottom, 3), px := id2[1].x, py := id2[1].y
            if (id2) {
                g_ubp := 1
                SetTimer, release, -1000
                UBParry()
                return
            }
            if (!id2 && Blackprior == 1) {
                Dodge1()
            }
            if (!id2 && Blackprior == 0) {
                Dodge2()
            }
        }
    }
}
Dodge1() {
    global 
    if (ActiveAutoDodge == 1 && vx > g_tp) {
        while getkeystate("V") {
            Send {numpad9 down}
            PrecisionSleep(KeyDelay)
            Send {numpad9 up}
            Sleep, 2000
            return
        }
    }
}
Dodge2() {
    global 
    if (ActiveAutoDodge == 1 && vx > g_tp) {
        while getkeystate("V") {
            BlockInput, On
            Send {9 down}
            PrecisionSleep(KeyDelay)
            Send {9 up}
            BlockInput, Off
            Sleep, 400
            return
            ; never executed
            if (ActiveLMBAfterDodge == 1) {
                Sleep, LRMouseDelay
                Send, {LButton}
            }
            if (ActiveRMBAfterDodge == 1) {
                Sleep, LRMouseDelay
                Send, {RButton}
            }
            Sleep, 400
            return
        }
    }
}
UBParry() {
    global
    While (g_ubp == 1) {
        temp := GetScreenshot()
        red := ImageSearch(temp, pixel_red1, g_indicators_left, g_indicators_top, g_indicators_right, g_indicators_bottom, 3), px := red[1].x, py := red[1].y
        if (!red) {
            Sleep, FeintCheckDelay
            orange := ImageSearch(temp, pixel_orange2, g_indicators_left, g_indicators_top, g_indicators_right, g_indicators_bottom, 2), px := orange[1].x, py := orange[1].y
            Gdip_DisposeImage(temp)
            if (orange) {
                while getkeystate("V") {
                    if (Blackprior == 1) {
                        Send {numpad9 down}
                        PrecisionSleep(KeyDelay)
                        Send {numpad9 up}
                        Sleep, 2300
                        return
                    }
                    if (Blackprior == 0) {
                        BlockInput, on
                        Send {space down}
                        PrecisionSleep(KeyDelay)
                        Send {space up}
                        BlockInput, Off
                        Sleep, 400
                        return
                    }
                }
            }
        }
        Gdip_DisposeImage(temp)
    }
}
AutoBlock() {
    global
    if !ActiveAutoDodge
        return
    ; Define the reference point and distance threshold
    ref_x := 1920 // 2  ; Half of the screen width (960 for a 1920x1080 resolution)
    ref_y := 1080 // 2  ; Half of the screen height (540 for a 1920x1080 resolution)
    distance_threshold := DistanceThreshold ; Use the value entered in the box edit control
  ; ToolTip, Distance: %distance%`nEstamina_Used: %g_estamina_used%, (A_ScreenWidth // 2) - 200, 100, 2
    red1 := ImageSearch(g_screenshot, pixel_red2, g_indicators_left, g_indicators_top, g_indicators_right, g_indicators_bottom, 3)
    if (red1) {
        zx := red1[1].x, zy := red1[1].y, g_attack_time := ((g_screenshot_time - g_attack_time) < g_slow_parry_end) ? g_attack_time : g_screenshot_time
        g_unblockable := ImageSearch(g_screenshot, pixel_orange2, g_indicators_left, g_indicators_top, g_indicators_right, g_indicators_bottom, 2)
    }
    if (red1 || ImageSearch(g_screenshot, pixel_red5, g_indicators_left, g_indicators_top, g_indicators_right, g_indicators_bottom, 2)) {
        ; Calculate the distance between the found pixel (zx, zy) and the reference point (ref_x, ref_y)
        distance := GetDistance(zx, zy, ref_x, ref_y)
        ; Check if the distance is below the threshold
        if (distance <= distance_threshold) {
            if (zx > x4 && zy > y4) {
                BlockRight()
                return
            }
            if (zx < x7 && zy > y4) {
                BlockLeft()
                return
            }
            if (zy > y2 && zy < y3) {
                BlockTop()
                return
            }
        }
    }
}
; Function to calculate the distance between two points (x1, y1) and (x2, y2)
GetDistance(x1, y1, x2, y2) {
    return sqrt((x1 - x2) ** 2 + (y1 - y2) ** 2)
}
GetDelayFromCost(cost) {
    global
    for k, v in (g_unblockable ? g_unblock_times : g_block_times) {
        if (g_estamina_used <= k) {
            for key, value in v {
                return value
                break
            }
        }
    }
    MsgBox GetDelayFromCost Error
}

BlockTop() {
    global
    PrecisionSleep(BlockDelay)
    Send {numpad8 down}
    PrecisionSleep(KeyDelay)
    Send {numpad8 up}
    While GetKeyState(Hotkey1) {
        if (ImageSearch(false, pixel_red5, g_indicators_left, g_indicators_top, g_indicators_right, g_indicators_bottom, 2) || ImageSearch(false, pixel_red2, g_indicators_left, g_indicators_top, g_indicators_right, g_indicators_bottom, 2)) {
            elapsed := GetTime() - g_attack_time
            delay := GetDelayFromCost(g_estamina_used)
            if (elapsed < delay.start)
                continue
            if (elapsed > delay.end)
                return
            if (ActiveHotkey1Parry == 1 && Warden == 0) {
                PrecisionSleep(ParryDelay)
				Send {RButton down}
                ; SaveScreenshot(false, format("elapsed: {:d}`nestamina_used: {:d}`ndelay.start: {:d}`ndelay.end: {:d}", elapsed, g_estamina_used, delay.start, delay.end))
                PrecisionSleep(KeyDelay)
                Send {RButton up}
                Sleep 1200
                return
            }
            if (ActiveHotkey1Parry == 1 && Warden == 1) {
                BlockInput, On
                Send {up down}{space down}
                PrecisionSleep(100)
                Send {space up}{up up}
                BlockInput, Off
                PrecisionSleep(200)
                Send {MButton down}
                PrecisionSleep(KeyDelay)
                Send {MButton up}
                Sleep 1200
                return
            }
            if (ActiveHotkey1Flip == 1) {
                Send {numpad9 down}
                PrecisionSleep(KeyDelay)
                Send {numpad9 up}
                Sleep 2000
                return
            }
        }
    }
    While GetKeyState(Hotkey2) {
    if (ImageSearch(false, pixel_red5, g_indicators_left, g_indicators_top, g_indicators_right, g_indicators_bottom, 2) || ImageSearch(false, pixel_red2, g_indicators_left, g_indicators_top, g_indicators_right, g_indicators_bottom, 2)) {
        elapsed := GetTime() - g_attack_time
        delay := GetDelayFromCost(g_estamina_used)
        if (elapsed < delay.start)
            continue
        if (elapsed > delay.end)
            return
        if (ActiveHotkey2Parry == 1) {
            PrecisionSleep(ParryDelay)
			Send {RButton down}
            PrecisionSleep(KeyDelay)
            Send {RButton up}
            Sleep 1200
            return
        }
        if (ActiveHotkey2CC == 1) {
            Send {LButton down}
            PrecisionSleep(KeyDelay)
            Send {LButton up}
            Sleep 1200 
            return
        }
        if (ImageSearch(false, pixel_red_feint, g_indicators_left, g_indicators_top, g_indicators_right, g_indicators_bottom, 2)) {
            PrecisionSleep(BlockDelay)
            continue
        }
        if (ActiveHotkey2Deflect == 1) {
            BlockInput, On
            Send {w up}{s up}{a up}{d up}
            Send {up down}{space down}
            PrecisionSleep(KeyDelay)
            Send {space up}{up up}
            BlockInput, Off
            if (ActiveDeflectLight == 1) {
                PrecisionSleep(20)
                Send {LButton down}
                PrecisionSleep(KeyDelay)
                Send {LButton up}
                Sleep 1200
                return
            }
            if (ActiveDeflectHeavy == 1) {
                PrecisionSleep(20)
                Send {RButton down}
                PrecisionSleep(KeyDelay)
                Send {RButton up}
                Sleep 1200
                return
            }
            if (ActiveDeflectGB == 1) {
                PrecisionSleep(20)
                Send {MButton down}
                PrecisionSleep(KeyDelay)
                Send {MButton up}
                Sleep 1200
                return
            }
            Sleep 100
            }
        }
    }
}
BlockLeft() {
    global
    PrecisionSleep(BlockDelay)
    Send {numpad4 down}
    PrecisionSleep(KeyDelay)
    Send {numpad4 up}
    While GetKeyState(Hotkey1) {
        if (ImageSearch(false, pixel_red5, g_indicators_left, g_indicators_top, g_indicators_right, g_indicators_bottom, 2) || (ImageSearch(false, pixel_red_feint, g_indicators_left, g_indicators_top, g_indicators_right, g_indicators_bottom, 2) && ImageSearch(false, pixel_red2, g_indicators_left, g_indicators_top, g_indicators_right, g_indicators_bottom, 2))) {
            elapsed := GetTime() - g_attack_time
            delay := GetDelayFromCost(g_estamina_used)
            if (elapsed < delay.start)
                continue
            if (elapsed > delay.end)
                return
            if (ActiveHotkey1Parry == 1 && Warden == 0) {
                ; SaveScreenshot(false, format("elapsed: {:d}`nestamina_used: {:d}`ndelay.start: {:d}`ndelay.end: {:d}", elapsed, g_estamina_used, delay.start, delay.end))
                PrecisionSleep(ParryDelay)
				Send {RButton down}
                PrecisionSleep(KeyDelay)
                Send {RButton up}
                Sleep 1200
                return
            }
            if (ActiveHotkey1Flip == 1) {
                Send {numpad9 down}
                PrecisionSleep(KeyDelay)
                Send {numpad9 up}
                Sleep 2000
                return
            }
        }
    }
    While GetKeyState(Hotkey2) {
    if (ImageSearch(false, pixel_red5, g_indicators_left, g_indicators_top, g_indicators_right, g_indicators_bottom, 2) || (ImageSearch(false, pixel_red2, g_indicators_left, g_indicators_top, g_indicators_right, g_indicators_bottom, 2) && ImageSearch(false, pixel_red_feint, g_indicators_left+15, g_indicators_top, g_indicators_right, g_indicators_bottom, 2))) {
        elapsed := GetTime() - g_attack_time
        delay := GetDelayFromCost(g_estamina_used)
        if (elapsed < delay.start)
            continue
        if (elapsed > delay.end)
            return
        if (ActiveHotkey2Parry == 1) {
            ; SaveScreenshot(false, format("elapsed: {:d}`nestamina_used: {:d}`ndelay.start: {:d}`ndelay.end: {:d}", elapsed, g_estamina_used, delay.start, delay.end))
            PrecisionSleep(ParryDelay)
			Send {RButton down}
            PrecisionSleep(KeyDelay)
            Send {RButton up}
            Sleep 1200
            return
        }
        if (ActiveHotkey2CC == 1) {
            Send {LButton down}
            PrecisionSleep(KeyDelay)
            Send {LButton up}
            Sleep 1200 
            return
        }
        if (ImageSearch(false, pixel_red_feint, g_indicators_left, g_indicators_top, g_indicators_right, g_indicators_bottom, 2)) {
            PrecisionSleep(BlockDelay)
            continue
        }
        if (ActiveHotkey2Deflect == 1) {
            BlockInput, On
            Send {w up}{s up}{a up}{d up}
            PrecisionSleep(Right)
            Send {left down}{space down}
            PrecisionSleep(KeyDelay)
            Send {space up}{left up}
            BlockInput, Off
            if (ActiveDeflectLight == 1) {
                PrecisionSleep(20)
                Send {LButton down}
                PrecisionSleep(KeyDelay)
                Send {LButton up}
                Sleep 1200
                return
            }
            if (ActiveDeflectHeavy == 1) {
                PrecisionSleep(20)
                Send {RButton down}
                PrecisionSleep(KeyDelay)
                Send {RButton up}
                Sleep 1200
                return
            }
            if (ActiveDeflectGB == 1) {
                PrecisionSleep(20)
                Send {MButton down}
                PrecisionSleep(KeyDelay)
                Send {MButton up}
                Sleep 1200
                return
            }
            Sleep 100
            return
            }
        }
    }
}
BlockRight() {
    global
    PrecisionSleep(BlockDelay)
    Send {numpad6 down}
    PrecisionSleep(KeyDelay)
    Send {numpad6 up}
    While GetKeyState(Hotkey1) {
        if (ImageSearch(false, pixel_red5, g_indicators_left, g_indicators_top, g_indicators_right, g_indicators_bottom, 2) || (ImageSearch(false, pixel_red_feint, g_indicators_left, g_indicators_top, g_indicators_right, g_indicators_bottom, 2) && ImageSearch(false, pixel_red2, g_indicators_left, g_indicators_top, g_indicators_right, g_indicators_bottom, 2))) {
            elapsed := GetTime() - g_attack_time
            delay := GetDelayFromCost(g_estamina_used)
            if (elapsed < delay.start)
                continue
            if (elapsed > delay.end)
                return
            if (ActiveHotkey1Parry == 1 && Warden == 0) {
                PrecisionSleep(ParryDelay)
				Send {RButton down}
                ; SaveScreenshot(false, format("elapsed: {:d}`nestamina_used: {:d}`ndelay.start: {:d}`ndelay.end: {:d}", elapsed, g_estamina_used, delay.start, delay.end))
                PrecisionSleep(KeyDelay)
                Send {RButton up}
                Sleep 1200
                return
            }
            if (ActiveHotkey1Flip == 1) {
                Send {numpad9 down}
                PrecisionSleep(KeyDelay)
                Send {numpad9 up}
                Sleep 2000
                return
            }
        }
    }
    While GetKeyState(Hotkey2) {
    if (ImageSearch(false, pixel_red5, g_indicators_left, g_indicators_top, g_indicators_right, g_indicators_bottom, 2) || (ImageSearch(false, pixel_red2, g_indicators_left, g_indicators_top, g_indicators_right, g_indicators_bottom, 2) && ImageSearch(false, pixel_red_feint, g_indicators_left+15, g_indicators_top, g_indicators_right, g_indicators_bottom, 2))) {
        elapsed := GetTime() - g_attack_time
        delay := GetDelayFromCost(g_estamina_used)
        if (elapsed < delay.start)
            continue
        if (elapsed > delay.end)
            return
        if (ActiveHotkey2Parry == 1) {
		    ; SaveScreenshot(false, format("elapsed: {:d}`nestamina_used: {:d}`ndelay.start: {:d}`ndelay.end: {:d}", elapsed, g_estamina_used, delay.start, delay.end))
            PrecisionSleep(ParryDelay)
			Send {RButton down}
            PrecisionSleep(KeyDelay)
            Send {RButton up}
            Sleep 1200
            return
        }
        if (ActiveHotkey2CC == 1) {
            Send {LButton down}
            PrecisionSleep(KeyDelay)
            Send {LButton up}
            Sleep 1200 
            return
        }
		if (ImageSearch(false, pixel_red_feint, g_indicators_left, g_indicators_top, g_indicators_right, g_indicators_bottom, 2)) {
            PrecisionSleep(BlockDelay)
            continue
        }
        if (ActiveHotkey2Deflect == 1) {
            BlockInput, On
            Send {w up}{s up}{a up}{d up}
            PrecisionSleep(Right)
            Send {right down}{space down}
            PrecisionSleep(KeyDelay)
            Send {space up}{right up}
            BlockInput, Off
            if (ActiveDeflectLight == 1) {
                PrecisionSleep(20)
                Send {LButton down}
                PrecisionSleep(KeyDelay)
                Send {LButton up}
                Sleep 1200
                return
            }
            if (ActiveDeflectHeavy == 1) {
                PrecisionSleep(20)
                Send {RButton down}
                PrecisionSleep(KeyDelay)
                Send {RButton up}
                Sleep 1200
                return
            }
            if (ActiveDeflectGB == 1) {
                PrecisionSleep(20)
                Send {MButton down}
                PrecisionSleep(KeyDelay)
                Send {MButton up}
                Sleep 1200
                return
            }
            Sleep 100
            return
            }
        }
    }
}
AutoDeflect() {
    global
    mic := false
    if (ActiveHotkey2DeflectG && phb && (mic := ImageSearch(g_screenshot, rect_white, g_mouse_icon_left, phb[1].y + FovScale(ResolutionScaleV(120)), g_mouse_icon_right, g_scan_bottom, 0))) {
        local mic_x := mic[1].x + 2, local mic_y := mic[1].y + 2
        local mic_top_x := mic_x, local mic_top_y := mic_y - FovScale(ResolutionScaleV(50))
        local mic_left_x := mic_x - FovScale(ResolutionScaleH(40)), local mic_left_y := mic_y + FovScale(ResolutionScaleV(20))
        local mic_right_x := mic_x + FovScale(ResolutionScaleH(40)),  local mic_right_y := mic_y + FovScale(ResolutionScaleV(20))
        local mic_top_r := 0, local mic_top_g := 0, local mic_top_b := 0
        local mic_left_r := 0, local mic_left_g := 0, local mic_left_b := 0
        local mic_right_r := 0, local mic_right_g := 0, local mic_right_b := 0
        local mic_top_rd := 0, local mic_left_rd := 0, local mic_right_rd := 0
        local mic_top_color := GetPixel(g_screenshot, mic_top_x, mic_top_y)
        mic_top_r := (mic_top_color >> 16) & 0xFF, mic_top_g := (mic_top_color >> 8) & 0xFF, mic_top_b := mic_top_color & 0xFF, mic_top_rd := mic_top_r / max(mic_top_g, mic_top_b, 1)
        local mic_left_color := GetPixel(g_screenshot, mic_left_x, mic_left_y)
        mic_left_r := (mic_left_color >> 16) & 0xFF, mic_left_g := (mic_left_color >> 8) & 0xFF, mic_left_b := mic_left_color & 0xFF, mic_left_rd := mic_left_r / max(mic_left_g, mic_left_b, 1)
        local mic_right_color := GetPixel(g_screenshot, mic_right_x, mic_right_y)
        mic_right_r := (mic_right_color >> 16) & 0xFF, mic_right_g := (mic_right_color >> 8) & 0xFF, mic_right_b := mic_right_color & 0xFF, mic_right_rd := mic_right_r / max(mic_right_g, mic_right_b, 1)
        if ((mic_top_rd > 2.5) || (mic_left_rd > 2.5) || (mic_right_rd > 2.5)) {
            local avg := (mic_top_rd + mic_left_rd + mic_right_rd) / 3
            if ((mic_top_rd * (mic_top_r / 255)) > avg) {
                Sleep BlockDelay
                Send {numpad8 down}
                PrecisionSleep(KeyDelay)
                Send {numpad8 up}
                if GetKeyState(Hotkey2) {
                    if (ActiveHotkey2DeflectG == 1) {
                        BlockInput, On
                        Send {w up}{s up}{a up}{d up}
                        Send {up down}{space down}
                        PrecisionSleep(KeyDelay)
                        Send {space up}{up up}
                        BlockInput, Off
                        if (ActiveDeflectLightG == 1) {
                            Sleep 20
                            Send {LButton down}
                            PrecisionSleep(KeyDelay)
                            Send {LButton up}
                            Sleep 400
                        } else if (ActiveDeflectHeavyG == 1) {
                            Sleep 20
                            Send {RButton down}
                            PrecisionSleep(KeyDelay)
                            Send {RButton up}
                            Sleep 400
                        } else if (ActiveDeflectGBG == 1) {
                            Sleep 20
                            Send {MButton down}
                            PrecisionSleep(KeyDelay)
                            Send {MButton up}
                            Sleep 400
                        }
                    }
                }
            } else if ((mic_left_rd * (mic_left_r / 255)) > avg) {
                Sleep BlockDelay
                Send {numpad4 down}
                PrecisionSleep(KeyDelay)
                Send {numpad4 up}
                if GetKeyState(Hotkey2) {
                    if (ActiveHotkey2DeflectG == 1) {
                        BlockInput, On
                        Send, {w up}{s up}{a up}{d up}
                        Send, {left down}{space down}
                        PrecisionSleep(KeyDelay)
                        Send {space up}{left up}
                        BlockInput, Off
                        if (ActiveDeflectLightG == 1) {
                            Sleep 20
                            Send {LButton down}
                            PrecisionSleep(KeyDelay)
                            Send {LButton up}
                            Sleep 400
                        } else if (ActiveDeflectHeavyG == 1) {
                            Sleep 20
                            Send {RButton down}
                            PrecisionSleep(KeyDelay)
                            Send {RButton up}
                            Sleep 400
                        } else if (ActiveDeflectGBG == 1) {
                            Sleep 20
                            Send {MButton down}
                            PrecisionSleep(KeyDelay)
                            Send {MButton up}
                            Sleep 400
                        }
                    }
                }
            } else if ((mic_right_rd * (mic_right_r / 255)) > avg) {
                Sleep BlockDelay
                Send {numpad6 down}
                PrecisionSleep(KeyDelay)
                Send {numpad6 up}
                if GetKeyState(Hotkey2) {
                    if (ActiveHotkey2DeflectG == 1) {
                        BlockInput, On
                        Send, {w up}{s up}{a up}{d up}
                        Send, {right down}{space down}
                        PrecisionSleep(KeyDelay)
                        Send {space up}{right up}
                        BlockInput, Off
                        if (ActiveDeflectLightG == 1) {
                            Sleep 20
                            Send {LButton down}
                            PrecisionSleep(KeyDelay)
                            Send {LButton up}
                            Sleep 400
                        } else if (ActiveDeflectHeavyG == 1) {
                            Sleep 20
                            Send {RButton down}
                            PrecisionSleep(KeyDelay)
                            Send {RButton up}
                            Sleep 400
                        } else if (ActiveDeflectGBG == 1) {
                            Sleep 20
                            Send {MButton down}
                            PrecisionSleep(KeyDelay)
                            Send {MButton up}
                            Sleep 400
                        }
                    }
                }
            }
        }
    }
}

WarningBlock() {
    global
    exm := false
    if (ActiveWarningBlock && (exm := ImageSearch(g_screenshot, rect_exred, g_scan_left, g_scan_top, g_scan_right, g_scan_bottom, 2))) {
        BlockInput, on
        Send {space down}
        PrecisionSleep(KeyDelay)
        Send {space up}
        BlockInput, Off
        Sleep 400
        return
    }
}
RETURN

ToggleWarningBlock:
    ActiveWarningBlock := !ActiveWarningBlock
    GuiControl,,ActiveWarningBlock, %ActiveWarningBlock%
    SoundBeep, ActiveWarningBlock ? 800 : 500, 10
return

ButtonOK:
    GuiControlGet, g_fov
    GuiControlGet, g_stamina_height
    InitSearchBitmaps()
return

ButtonReload:
Reload
return
ButtonHelp:
{
Msgbox,0, How To Use, What u need for use script? 1. Open game and go into display settings, set feild of view on 81, contrast 55 -< without 55 contrast script not gonna work 2. In graphics settings - disable shadows, Motion Blur, Ambient Occlusion, Dynamic Reflections, Dynamic Shadows 3. keymapping, bind arrows on movements in secondary slot, arrow up - forward, arrow down - backward, arrow left - left, arrow right - right, For parry you need bind left alt in secondary for light and heavy attack, For Flips - numpad 9 in secondary for light attack and fullblock, For autoblock - numpad 4 at left guard, numpad 6 - at right guard, numpad 8 at top guard 4. When all keybinds rdy you can start script, select characters on which you playing, tick in menu features which u want use, put ur resolution where X and Y - like x=1920 y=1080. (resolution in script gui and in game should be the same!) and press small ok button, now you can start script for that press Start Button, now go back in game and test it, all features working automaticly all u can do thats parry - for that you need hold C, before enemy started an attack, when enemy doing heavy feint very important let C go every time! for refresh parry and block direction. Script working in any game mode with borderless windowed mode or fullscreen, - Not working in windowed mode! Best working on 1920x1080 g_fov 81 FPS - 120 (minimum) Monitor Hz 120 (minimum) my discord if u have questions FlorasSecret#9666
}
return
ButtonLoad:
{
IniRead, Left, %A_WorkingDir%\Config.ini, Options, Left
GuiControl,,Left, %Left%
IniRead, Right, %A_WorkingDir%\Config.ini, Options, Right
GuiControl,,Right, %Right%
IniRead, DodgeDelay, %A_WorkingDir%\Config.ini, Options, DodgeDelay
GuiControl,,DodgeDelay, %DodgeDelay%
IniRead, FeintCheckDelay, %A_WorkingDir%\Config.ini, Options, FeintCheckDelay
GuiControl,,FeintCheckDelay, %FeintCheckDelay%
IniRead, LRMouseDelay, %A_WorkingDir%\Config.ini, Options, LRMouseDelay
GuiControl,,LRMouseDelay, %LRMouseDelay%
IniRead, BlockDelay, %A_WorkingDir%\Config.ini, Options, BlockDelay
GuiControl,,BlockDelay, %BlockDelay%
IniRead, g_fov, %A_WorkingDir%\Config.ini, Options, g_fov
GuiControl,,g_fov, %g_fov%
IniRead, g_stamina_height, %A_WorkingDir%\Config.ini, Options, g_stamina_height
GuiControl,,g_stamina_height, %g_stamina_height%
IniRead, ActiveAutoDodge, %A_WorkingDir%\Config.ini, Options, ActiveAutoDodge
GuiControl,,ActiveAutoDodge, %ActiveAutoDodge%
IniRead, ActiveAutoBlock, %A_WorkingDir%\Config.ini, Options, ActiveAutoBlock
GuiControl,,ActiveAutoBlock, %ActiveAutoBlock%

IniRead, Hotkey1, %A_WorkingDir%\Config.ini, Options, Hotkey1
GuiControl,,Hotkey1, %Hotkey1%
IniRead, Hotkey2, %A_WorkingDir%\Config.ini, Options, Hotkey2
GuiControl,,Hotkey2, %Hotkey2%
IniRead, Hotkey3, %A_WorkingDir%\Config.ini, Options, Hotkey3
GuiControl,,Hotkey3, %Hotkey3%

IniRead, ActiveHotkey1Parry, %A_WorkingDir%\Config.ini, Options, ActiveHotkey1Parry
GuiControl,,ActiveHotkey1Parry, %ActiveHotkey1Parry%
IniRead, ActiveHotkey1Flip, %A_WorkingDir%\Config.ini, Options, ActiveHotkey1Flip
GuiControl,,ActiveHotkey1Flip, %ActiveHotkey1Flip%
IniRead, ActiveRMBAfterDodge, %A_WorkingDir%\Config.ini, Options, ActiveRMBAfterDodge
GuiControl,,ActiveRMBAfterDodge, %ActiveRMBAfterDodge%
IniRead, ActiveLMBAfterDodge, %A_WorkingDir%\Config.ini, Options, ActiveLMBAfterDodge
GuiControl,,ActiveLMBAfterDodge, %ActiveLMBAfterDodge%
IniRead, ActiveHotkey2Parry, %A_WorkingDir%\Config.ini, Options, ActiveHotkey2Parry
GuiControl,,ActiveHotkey2Parry, %ActiveHotkey2Parry%
IniRead, ActiveHotkey2CC, %A_WorkingDir%\Config.ini, Options, ActiveHotkey2CC
GuiControl,,ActiveHotkey2CC, %ActiveHotkey2CC%

IniRead, ActiveHotkey2Deflect, %A_WorkingDir%\Config.ini, Options, ActiveHotkey2Deflect
GuiControl,,ActiveHotkey2Deflect, %ActiveHotkey2Deflect%
IniRead, ActiveDeflectLight, %A_WorkingDir%\Config.ini, Options, ActiveDeflectLight
GuiControl,,ActiveDeflectLight, %ActiveDeflectLight%
IniRead, ActiveDeflectHeavy, %A_WorkingDir%\Config.ini, Options, ActiveDeflectHeavy
GuiControl,,ActiveDeflectHeavy, %ActiveDeflectHeavy%
IniRead, ActiveDeflectGB, %A_WorkingDir%\Config.ini, Options, ActiveDeflectGB
GuiControl,,ActiveDeflectGB, %ActiveDeflectGB%

IniRead, ActiveHotkey2DeflectG, %A_WorkingDir%\Config.ini, Options, ActiveHotkey2DeflectG
GuiControl,,ActiveHotkey2DeflectG, %ActiveHotkey2DeflectG%
IniRead, ActiveDeflectLightG, %A_WorkingDir%\Config.ini, Options, ActiveDeflectLightG
GuiControl,,ActiveDeflectLightG, %ActiveDeflectLightG%
IniRead, ActiveDeflectHeavyG, %A_WorkingDir%\Config.ini, Options, ActiveDeflectHeavyG
GuiControl,,ActiveDeflectHeavyG, %ActiveDeflectHeavyG%
IniRead, ActiveDeflectGBG, %A_WorkingDir%\Config.ini, Options, ActiveDeflectGBG
GuiControl,,ActiveDeflectGBG, %ActiveDeflectGBG%

IniRead, ActiveWarningBlock, %A_WorkingDir%\Config.ini, Options, ActiveWarningBlock
GuiControl,,ActiveWarningBlock, %ActiveWarningBlock%
IniRead, ParryDelay, %A_WorkingDir%\Config.ini, Options, ParryDelay
GuiControl,,ParryDelay, %ParryDelay%

IniRead, Warden, %A_WorkingDir%\Config.ini, Options, Warden
GuiControl,,Warden, %Warden%
IniRead, Blackprior, %A_WorkingDir%\Config.ini, Options, Blackprior
GuiControl,,Blackprior, %Blackprior%
IniRead, All_Others, %A_WorkingDir%\Config.ini, Options, All_Others
GuiControl,,All_Others, %All_Others%
InitSearchBitmaps()
msgbox,0, Successfully, Settings successfully loaded!
}
return
ButtonSave:
{
IniWrite, %Left%, %A_WorkingDir%\Config.ini, Options, Left
IniWrite, %Right%, %A_WorkingDir%\Config.ini, Options, Right
IniWrite, %DodgeDelay%, %A_WorkingDir%\Config.ini, Options, DodgeDelay
IniWrite, %FeintCheckDelay%, %A_WorkingDir%\Config.ini, Options, FeintCheckDelay
IniWrite, %LRMouseDelay%, %A_WorkingDir%\Config.ini, Options, LRMouseDelay
IniWrite, %BlockDelay%, %A_WorkingDir%\Config.ini, Options, BlockDelay
IniWrite, %g_fov%, %A_WorkingDir%\Config.ini, Options, g_fov
IniWrite, %g_stamina_height%, %A_WorkingDir%\Config.ini, Options, g_stamina_height
IniWrite, %ActiveAutoDodge%, %A_WorkingDir%\Config.ini, Options, ActiveAutoDodge
IniWrite, %ActiveAutoBlock%, %A_WorkingDir%\Config.ini, Options, ActiveAutoBlock
IniWrite, %ActiveHotkey1Parry%, %A_WorkingDir%\Config.ini, Options, ActiveHotkey1Parry
IniWrite, %ActiveHotkey1Flip%, %A_WorkingDir%\Config.ini, Options, ActiveHotkey1Flip
IniWrite, %ActiveRMBAfterDodge%, %A_WorkingDir%\Config.ini, Options, ActiveRMBAfterDodge
IniWrite, %ActiveLMBAfterDodge%, %A_WorkingDir%\Config.ini, Options, ActiveLMBAfterDodge
IniWrite, %ActiveHotkey2Parry%, %A_WorkingDir%\Config.ini, Options, ActiveHotkey2Parry
IniWrite, %ActiveHotkey2CC%, %A_WorkingDir%\Config.ini, Options, ActiveHotkey2CC

IniWrite, %Hotkey1%, %A_WorkingDir%\Config.ini, Options, Hotkey1
IniWrite, %Hotkey2%, %A_WorkingDir%\Config.ini, Options, Hotkey2
IniWrite, %Hotkey3%, %A_WorkingDir%\Config.ini, Options, Hotkey3

IniWrite, %ActiveHotkey2Deflect%, %A_WorkingDir%\Config.ini, Options, ActiveHotkey2Deflect
IniWrite, %ActiveDeflectLight%, %A_WorkingDir%\Config.ini, Options, ActiveDeflectLight
IniWrite, %ActiveDeflectHeavy%, %A_WorkingDir%\Config.ini, Options, ActiveDeflectHeavy
IniWrite, %ActiveDeflectGB%, %A_WorkingDir%\Config.ini, Options, ActiveDeflectGB

IniWrite, %ActiveHotkey2DeflectG%, %A_WorkingDir%\Config.ini, Options, ActiveHotkey2DeflectG
IniWrite, %ActiveDeflectLightG%, %A_WorkingDir%\Config.ini, Options, ActiveDeflectLightG
IniWrite, %ActiveDeflectHeavyG%, %A_WorkingDir%\Config.ini, Options, ActiveDeflectHeavyG
IniWrite, %ActiveDeflectGBG%, %A_WorkingDir%\Config.ini, Options, ActiveDeflectGBG
IniWrite, %ParryDelay%, %A_WorkingDir%\Config.ini, Options, ParryDelay

IniWrite, %ActiveWarningBlock%, %A_WorkingDir%\Config.ini, Options, ActiveWarningBlock

IniWrite, %Warden%, %A_WorkingDir%\Config.ini, Options, Warden
IniWrite, %Blackprior%, %A_WorkingDir%\Config.ini, Options, Blackprior
IniWrite, %All_Others%, %A_WorkingDir%\Config.ini, Options, All_Others
msgbox,0, Successfully, Settings successfully saved!
}
return
ButtonApply:
{
Gui, Submit, NoHide
InitSearchBitmaps()
SetupHotkeys()
}
msgbox,0, Successfully, Settings successfully updated!
return

ButtonStart:
SoundBeep
Gui, Submit, NoHide
InitSearchBitmaps()
SetupHotkeys()
settimer, main, 1000
return

main:
if (g_hwnd := WinExist(g_target_wnd)) {
    ; mem := new _ClassMemory("ahk_id " g_hwnd)
    ; data := mem.readMem(mem.BaseAddress, 4)
    
    while WinActive("ahk_id " g_hwnd) {
        g_clientarea := GetClientArea(g_hwnd)
        SetScaling()
        g_screenshot := GetScreenshot(), g_screenshot_time := GetTime()
        Calculate()
        SearchBot()
        AutoDeflect()
        AutoBlock()
        WarningBlock()
        Gdip_DisposeImage(g_screenshot)
        ; tooltip % GetFPS()
    }
}
return

release:
g_ubp := 0
return


#MaxThreadsPerHotkey 1
~Z::
pause
SoundPlay, %A_WorkingDir%\buttonclick.wav
return

Insert::
if (g_tp == FovScale(ResolutionScaleH(740))) {
    g_tp := FovScale(ResolutionScaleH(1300))
    SoundPlay, %A_WorkingDir%\buttonunclick.wav
    return
}
if (g_tp == FovScale(ResolutionScaleH(1300))) {
    g_tp := FovScale(ResolutionScaleH(740))
    SoundPlay, %A_WorkingDir%\buttonclick.wav
    return
}
return

Home::
GuiShow()
return

F12::
SaveScreenshot()
return



;DISABLE SCREENSHOTS
