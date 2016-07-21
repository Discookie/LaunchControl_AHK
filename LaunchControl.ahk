/*

LaunchControl - a launchpad API
- based on the work of genmce, TomB, Lazslo, Orbik, and many others
Read the README.md for more info

heavily WIP !!

- Discookie
*/

#Persistent
#SingleInstance force
SendMode Input
SetWorkingDir %A_ScriptDir%

if A_OSVersion in WIN_NT4,WIN_95,WIN_98,WIN_ME 
{
MsgBox This script requires Windows 2000/XP or later. ; You should seriously consider updating...
ExitApp
}

version = LaunchControl 0.0.1a

readini() 
gosub, MidiPortRefresh ; used to refresh the input and output port lists
port_test(numports,numports2) ; tests the ports
gosub, midiin_go ; opens the midi input port listening routine
gosub, midiout ; opens the midi out port
gosub, midiMon ; opens the feedback gui



; VARIABLES HERE


; These will be used to make updates faster and whole screen updates more reliable
Buffer := Array(0, 0, 0, 0, 0, 0, 0, 0,    0, 0, 0, 0, 0, 0, 0, 0,    0, 0, 0, 0, 0, 0, 0, 0,    0, 0, 0, 0, 0, 0, 0, 0,    0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 0, 0, 0, 0,          0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 17, 0, 0, 3)
Display := Array(0, 0, 0, 0, 0, 0, 0, 0,    0, 0, 0, 0, 0, 0, 0, 0,    0, 0, 0, 0, 0, 0, 0, 0,    0, 0, 0, 0, 0, 0, 0, 0,    0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 0, 0, 0, 0,          0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 17, 0, 0, 3)
Pressed:=Array(false, false, false, false, false, false, false, false,      false, false, false, false, false, false, false, false,      false, false, false, false, false, false, false, false,      false, false, false, false, false, false, false, false,      false, false, false, false, false, false, false, false,      false, false, false, false, false, false, false, false,      false, false, false, false, false, false, false, false,      false, false, false, false, false, false, false, false,      false, false, false, false, false, false, false, false,      false, false, false, false, false, false, false, false)
cBuf:=true


return ; End of  -- AutoExec


; --- MIDI MSG PARSE

MidiMsgDetect(hInput, midiMsg, wMsg) 
{
global statusbyte, chan, note, cc, byte1, byte2

statusbyte := midiMsg & 0xFF ; What kind of msg
chan := (statusbyte & 0x0f) + 1 ; Which channel
byte1 := (midiMsg >> 8) & 0xFF ; Note number
byte2 := (midiMsg >> 16) & 0xFF ; Note velocity


GuiControl,12:, MidiMs, MidiMon:%statusbyte% %chan% %byte1% %byte2% ; Feedback GUI - MidiMon

gosub, MidiRules ; We have to detect it somehow

} 

MidiRules: ; == WILL OUTSOURCE IT VERY SOON

if statusbyte between 128 and 159 ; The 8x8 grid plus the sidebar
{
global Buffer := Array(0, 0, 0, 0, 0, 0, 0, 0,    0, 0, 0, 0, 0, 0, 0, 0,    0, 0, 0, 0, 0, 0, 0, 0,    0, 0, 0, 0, 0, 0, 0, 0,    0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 0, 0, 0, 0,          0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 17, 0, 0, 3)
global Display := Array(0, 0, 0, 0, 0, 0, 0, 0,    0, 0, 0, 0, 0, 0, 0, 0,    0, 0, 0, 0, 0, 0, 0, 0,    0, 0, 0, 0, 0, 0, 0, 0,    0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 0, 0, 0, 0,          0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 17, 0, 0, 3)
SendDisplay(h_midiout)
}


if statusbyte between 176 and 191 ; The top bar
{
ifequal, byte2, 0
{
	Pressed[byte1-32]:=false
	ifequal, byte1, 109
	{
		SNT(h_midiout, 77, 0, 1)
	}
	ifequal, byte1, 111
	ExitApp
}
else
{
	Pressed[byte1-32]:=true
	ifequal, byte1, 109
	{
		SNT(h_midiout, 77, 3, 3)
	}
}
}

if statusbyte between 192 and 208 
{

GuiControl,12:, MidiMsOut, ProgC:%statusbyte% %chan% %byte1% %byte2%
}
;SetMeta(h_midiout, 1, 0)
Return

/* HOTKEYS 

*/


LoadDefault(mode=0, resetVars=true) {
BufferDef := Array(0, 0, 0, 0, 0, 0, 0, 0,    0, 0, 0, 0, 0, 0, 0, 0,    0, 0, 0, 0, 0, 0, 0, 0,    0, 0, 0, 0, 0, 0, 0, 0,    0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 0, 0, 0, 0,          0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 17, 0, 0, 3)
DisplayDef := Array(0, 0, 0, 0, 0, 0, 0, 0,    0, 0, 0, 0, 0, 0, 0, 0,    0, 0, 0, 0, 0, 0, 0, 0,    0, 0, 0, 0, 0, 0, 0, 0,    0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 0, 0, 0, 0,          0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 17, 0, 0, 3)
	ifequal, mode, 0
		ifequal, resetVars, true
		{
			global Displayed:=DisplayDef
			global Buffer:=BufferDef
		}
}
/*
DisplayBuf(flashing=false) {
	for i, v in Buffer {
		if i < 64
		{
			SendNote(h_midiout, 143, (i>>3)<<4+(i mod 8), v)
		} 
		else if i < 72
		{
			SendNote(h_midiout, 143, (i-64)*16+8, v)
		}
		else
		{
			SendNote(h_midiout, 176,i+42, v)
		}
			Buffer[i]:=Displayed[i]
			Displayed[i]:=v
	}
}
*/
SetMeta(cO, swap=0, flashing=0) {
	if swap
	{
	if cBuf
	{
	if flashing
	{
	SendNote(cO, 176, 0, 41)
	}
	else
	{
	   SendNote(cO, 176, 0, 33)
	}
	}
	else 
	{
	if flashing
	{
		SendNote(cO, 176, 0, 44)
	}
	else
	{
		SendNote(cO, 176, 0, 36)
	}
	}
	cBuf:=!cBuf
	}
	else  
	{
	if !cBuf
	{
	if flashing
	{
	SendNote(cO, 176, 0, 41)
	}
	else
	{
	   SendNote(cO, 176, 0, 33)
	}
	}
	else 
	{
	if flashing
	{
		SendNote(cO, 176, 0, 44)
	}
	else
	{
		SendNote(cO, 176, 0,  36)
	}
	}
	}
}

; TODO Will remove SendNote from all of this
SNT(cO, i, red=0, green=0, flashing=1, live=1) {
		if i < 64
		{
			SendNote(cO, 143, (i>>3)<<4+(i mod 8), green*16+red+flashing*8+live*4)
		} 
		else if i < 72
		{
			SendNote(cO, 143, ((i-64)*16+8), (green*16+red+flashing*8+live*4))
		}
		else
		{
			asd:=green*16+red+flashing*8+live*4
			fgh:=i+32
			midiOutShortMsg(cO, 176, fgh, asd)
		}
		ifequal, live, 1
		{
			Displayed[i]:=green*16+red+flashing*8+live*4
		}
		Buffer[i]:=green*16+red+flashing*8+live*4
}

SendDisplay(cO) {
was:=true
For, i, v in Display
{
	;MsgBox, %v%
	if was
	{
		global t1:=v
		was:=false
	}
	else {
		global t2:=v
		was:=true
		SendNote(cO, 146, t1, t2)
	}
}
}

; Ye olde SendNote
; DEPRECATED

SendNote(nOUT, nET, nCC, nVEL) 
{
GuiControl,12:, MidiMsOutSend, NoteOut:%statusbyte% %chan% %byte1% %byte2%
MidiStatus := nET
midiOutShortMsg(nOUT, nET, nCC, nVEL) 
Return
}
SendCC(nOUT, nET, nCC, nVEL) 
{
GuiControl,12:, MidiMsOutSend, CCOut:%statusbyte% %chan% %cc% %byte2%
midiOutShortMsg(nOUT, nET, nCC, nVEL)
Return
}

SendPC:
GuiControl,12:, MidiMsOutSend, ProgChOut:%statusbyte% %chan% %byte1% %byte2%
midiOutShortMsg(h_midiout, statusbyte, pc, byte2)
/*
COULD BE TRANSLATED TO SOME OTHER MIDI MESSAGE BESIDES PROGRAM CHANGE.
*/
Return















/*
 FEEDBACK GUI
*/
midiMon: 

Gui, 12: +LastFound +AlwaysOnTop +Caption +ToolWindow ; 
Gui,12: Color, white ; %CustomColor% ;blue ;
Gui,12: Font, s15 ; Set a large font size (32-point).
Gui,12: Add, Text, w250 vMidiMs cgreen, XXXXX YYYYY ; XX & YY serve to auto-size the window.
gui, 12: add, text, w250 vMidiMsOut cblue, XXXXX YYYYY
gui, 12: add, text, w250 vMidiMsOutSend cred, XXXXX YYYYY
Gui,12: Show, xcenter y0 w500 NoActivate, %version% feedback ; NoActivate avoids deactivating the currently active window.


/*

Output by TomB and Lazslo
http://www.autohotkey.com/forum/viewtopic.php?t=18711&highlight=midi+output

Input based on this thread
http://www.autohotkey.com/forum/topic30715.html
 - using WinMM instead of MIDI_IN
*/

MidiPortRefresh: ; get the list of ports

MIlist := MidiInsList(NumPorts)
Loop Parse, MIlist, |
{
}
TheChoice := MidiInDevice + 1

MOlist := MidiOutsList(NumPorts2)
Loop Parse, MOlist, |
{
}
TheChoice2 := MidiOutDevice + 1

return


ReadIni() ; also set up the tray Menu
{
Menu, tray, add, MidiSet 
Menu, tray, add, ResetAll 

global MidiInDevice, MidiOutDevice, version
IfExist, LaunchControl.ini ;read the contents of the ini
{
IniRead, MidiInDevice, %version%io.ini, Settings, MidiInDevice , %MidiInDevice% 
IniRead, MidiOutDevice, %version%io.ini, Settings, MidiOutDevice , %MidiOutDevice% 
}
Else ; no ini exists and this is either the first run or reset settings.
{
MsgBox, 1, No ini file found, Select midi ports?
IfMsgBox, Cancel
ExitApp
IfMsgBox, yes
gosub, midiset
}
}

;CALLED TO UPDATE INI WHENEVER SAVED PARAMETERS CHANGE
WriteIni()
{
global MidiInDevice, MidiOutDevice, version

IfNotExist, %version%io.ini
FileAppend,, %version%io.ini 
IniWrite, %MidiInDevice%, %version%io.ini, Settings, MidiInDevice
IniWrite, %MidiOutDevice%, %version%io.ini, Settings, MidiOutDevice
}

; Testing the port selected

port_test(numports,numports2) ; confirm selected ports exist

{
global midiInDevice, midiOutDevice, midiok

; ----- In port selection test based on numports
If MidiInDevice not Between 0 and %numports%
{
MidiIn := 0 ; Error
If (MidiInDevice = "") 
MidiInerr = Midi In Port EMPTY. 

If (midiInDevice > %numports%) 
MidiInnerr = Midi In Port Invalid. 

}
Else
{
MidiIn := 1 ; Valid
}
; ----- out port selection test based on numports2
If MidiOutDevice not Between 0 and %numports2%
{
MidiOut := 0 ; Error
If (MidiOutDevice = "") 
MidiOuterr = Midi Out Port EMPTY. 
If (midiOutDevice > %numports2%) 
MidiOuterr = Midi Out Port Out Invalid. 
}
Else
{
MidiOut := 1 ; Valid
}
If (%MidiIn% = 0) Or (%MidiOut% = 0)
{
MsgBox, 49, Midi Port Error!,%MidiInerr%`n%MidiOuterr%`n`nLaunch Midi Port Selection!
IfMsgBox, Cancel
ExitApp
midiok = 0 ; really dude?
Gosub, MidiSet 
}
Else
{
midiok = 1 ;Pls....
Return 
}
}
Return



MidiSet: ; GUI select

;Gui, Destroy
;Gosub, Suspendit
Gui, 6: Destroy
Gui, 2: Destroy
Gui, 3: Destroy
Gui, 4: Destroy
;Gui, 5: Destroy
Gui, 4: +LastFound +AlwaysOnTop +Caption +ToolWindow ;-SysMenu
Gui, 4: Font, s12
Gui, 4: add, text, x10 y10 w300 cmaroon, Select Midi Ports. ; Text title
Gui, 4: Font, s8
Gui, 4: Add, Text, x10 y+10 w175 Center , Midi In Port ;Just text label
Gui, 4: font, s8
; midi ins list box
Gui, 4: Add, ListBox, x10 w200 h100 Choose%TheChoice% vMidiInPort gDoneInChange AltSubmit, %MiList% ; --- midi in listing of ports
;Gui, Add, DropDownList, x10 w200 h120 Choose%TheChoice% vMidiInPort gDoneInChange altsubmit, %MiList% ; ( you may prefer this style, may need tweak)

; --------------- MidiOutSet ---------------------
Gui, 4: Add, TEXT, x220 y40 w175 Center, Midi Out Port ; gDoneOutChange
; midi outlist box
Gui, 4: Add, ListBox, x220 y62 w200 h100 Choose%TheChoice2% vMidiOutPort gDoneOutChange AltSubmit, %MoList% ; --- midi out listing
;Gui, Add, DropDownList, x220 y97 w200 h120 Choose%TheChoice2% vMidiOutPort gDoneOutChange altsubmit , %MoList%
Gui, 4: add, Button, x10 w205 gSet_Done, Done - Reload script.
Gui, 4: add, Button, xp+205 w205 gCancel, Cancel
;gui, 4: add, checkbox, x10 y+10 vNotShown gDontShow, Do Not Show at startup.
;IfEqual, NotShown, 1
;guicontrol, 4:, NotShown, 1
Gui, 4: show , , %version% Midi Port Selection ; main window title and command to show it.

Return

;-----------------gui done change stuff - see label in both gui listbox line

DoneInChange:
Gui, 4: Submit, NoHide
Gui, 4: Flash
If %MidiInPort%
UDPort:= MidiInPort - 1, MidiInDevice:= UDPort ; probably a much better way do this, I took this from JimF's qwmidi without out editing much.... it does work same with doneoutchange below.
GuiControl, 4:, UDPort, %MidiIndevice%
WriteIni()
;MsgBox, 32, , midi in device = %MidiInDevice%`nmidiinport = %MidiInPort%`nport = %port%`ndevice= %device% `n UDPort = %port% ; only for testing
Return

DoneOutChange:
Gui, 4: Submit, NoHide
Gui, 4: Flash
If %MidiOutPort%
UDPort2:= MidiOutPort - 1 , MidiOutDevice:= UDPort2
GuiControl, 4: , UDPort2, %MidiOutdevice%
WriteIni()
;Gui, Destroy
Return

;------------------------ end of the doneout change stuff.

Set_Done: ; aka reload program, called from midi selection gui
Gui, 3: Destroy
Gui, 4: Destroy
sleep, 100
Reload
Return

Cancel:
Gui, Destroy
Gui, 2: Destroy
Gui, 3: Destroy
Gui, 4: Destroy
Gui, 5: Destroy
Return

; ********************** Midi output detection

MidiOut: ; Function to load new settings from midi out menu item
OpenCloseMidiAPI()
h_midiout := midiOutOpen(MidiOutDevice) ; OUTPUT PORT 1 SEE BELOW FOR PORT 2
return

ResetAll: ; for development only, leaving this in for a program reset if needed by user
MsgBox, 33, %version% - Reset All?, This will delete ALL settings`, and restart this program!
IfMsgBox, OK
{
FileDelete, %version%io.ini ; delete the ini file to reset ports, probably a better way to do this ...
Reload ; restart the app.
}
IfMsgBox, Cancel
Return

GuiClose: ; on x exit app
Suspend, Permit ; allow Exit to work Paused. I just added this yesterday 3.16.09 Can now quit when Paused.

MsgBox, 4, Exit %version%, Exit %version% %ver%? ;
IfMsgBox No
Return
Else IfMsgBox Yes
midiOutClose(h_midiout)

Gui, 6: Destroy
Gui, 2: Destroy
Gui, 3: Destroy
Gui, 4: Destroy
Gui, 5: Destroy
gui, 7: destroy
;gui,
Sleep 100
;winclose, Midi_in_2 ;close the midi in 2 ahk file
ExitApp


;############################################## MIDI LIB from orbik and lazslo#############
;-------- orbiks midi input code --------------
; Set up midi input and callback_window based on the ini file above.
; This code copied from ahk forum Orbik's post on midi input

; nothing below here to edit.

; =============== midi in =====================

Midiin_go:
DeviceID := MidiInDevice ; midiindevice from IniRead above assigned to deviceid
CALLBACK_WINDOW := 0x10000 ; from orbiks code for midi input

Gui, +LastFound ; set up the window for midi data to arrive.
hWnd := WinExist() ;MsgBox, 32, , line 176 - mcu-input is := %MidiInDevice% , 3 ; this is just a test to show midi device selection

hMidiIn =
VarSetCapacity(hMidiIn, 4, 0)
result := DllCall("winmm.dll\midiInOpen", UInt,&hMidiIn, UInt,DeviceID, UInt,hWnd, UInt,0, UInt,CALLBACK_WINDOW, "UInt")
If result
{
MsgBox, Error, midiInOpen Returned %result%`n
;GoSub, sub_exit
}

hMidiIn := NumGet(hMidiIn) ; because midiInOpen writes the value in 32 bit binary Number, AHK stores it as a string
result := DllCall("winmm.dll\midiInStart", UInt,hMidiIn)
If result
{
MsgBox, Error, midiInStart Returned %result%`nRight Click on the Tray Icon - Left click on MidiSet to select valid midi_in port.
;GoSub, sub_exit
}

OpenCloseMidiAPI()

; ----- the OnMessage listeners ----

; #define MM_MIM_OPEN 0x3C1 /* MIDI input */
; #define MM_MIM_CLOSE 0x3C2
; #define MM_MIM_DATA 0x3C3
; #define MM_MIM_LONGDATA 0x3C4
; #define MM_MIM_ERROR 0x3C5
; #define MM_MIM_LONGERROR 0x3C6

OnMessage(0x3C1, "MidiMsgDetect") ; calling the function MidiMsgDetect in get_midi_in.ahk
OnMessage(0x3C2, "MidiMsgDetect")
OnMessage(0x3C3, "MidiMsgDetect")
OnMessage(0x3C4, "MidiMsgDetect")
OnMessage(0x3C5, "MidiMsgDetect")
OnMessage(0x3C6, "MidiMsgDetect")

Return

;--- MIDI INS LIST FUNCTIONS - port handling -----

MidiInsList(ByRef NumPorts)
{ ; Returns a "|"-separated list of midi output devices
local List, MidiInCaps, PortName, result
VarSetCapacity(MidiInCaps, 50, 0)
VarSetCapacity(PortName, 32) ; PortNameSize 32

NumPorts := DllCall("winmm.dll\midiInGetNumDevs") ; #midi output devices on system, First device ID = 0

Loop %NumPorts%
{
result := DllCall("winmm.dll\midiInGetDevCapsA", UInt,A_Index-1, UInt,&MidiInCaps, UInt,50, UInt)
If (result OR ErrorLevel) {
List .= "|-Error-"
Continue
}
DllCall("RtlMoveMemory", Str,PortName, UInt,&MidiInCaps+8, UInt,32) ; PortNameOffset 8, PortNameSize 32
List .= "|" PortName
}
Return SubStr(List,2)
}

MidiInGetNumDevs() { ; Get number of midi output devices on system, first device has an ID of 0
Return DllCall("winmm.dll\midiInGetNumDevs")
}
MidiInNameGet(uDeviceID = 0) { ; Get name of a midiOut device for a given ID

;MIDIOUTCAPS struct
; WORD wMid;
; WORD wPid;
; MMVERSION vDriverVersion;
; CHAR szPname[MAXPNAMELEN];
; WORD wTechnology;
; WORD wVoices;
; WORD wNotes;
; WORD wChannelMask;
; DWORD dwSupport;

VarSetCapacity(MidiInCaps, 50, 0) ; allows for szPname to be 32 bytes
OffsettoPortName := 8, PortNameSize := 32
result := DllCall("winmm.dll\midiInGetDevCapsA", UInt,uDeviceID, UInt,&MidiInCaps, UInt,50, UInt)

If (result OR ErrorLevel) {
MsgBox Error %result% (ErrorLevel = %ErrorLevel%) in retrieving the name of midi Input %DeviceID%
Return -1
}

VarSetCapacity(PortName, PortNameSize)
DllCall("RtlMoveMemory", Str,PortName, Uint,&MidiInCaps+OffsettoPortName, Uint,PortNameSize)
Return PortName
}

MidiInsEnumerate() { ; Returns number of midi output devices, creates global array MidiOutPortName with their names
local NumPorts, PortID
MidiInPortName =
NumPorts := MidiInGetNumDevs()

Loop %NumPorts% {
PortID := A_Index -1
MidiInPortName%PortID% := MidiInNameGet(PortID)
}
Return NumPorts
}


; =============== end of midi selection stuff


MidiOutsList(ByRef NumPorts)
{ ; Returns a "|"-separated list of midi output devices
local List, MidiOutCaps, PortName, result
VarSetCapacity(MidiOutCaps, 50, 0)
VarSetCapacity(PortName, 32) ; PortNameSize 32

NumPorts := DllCall("winmm.dll\midiOutGetNumDevs") ; #midi output devices on system, First device ID = 0

Loop %NumPorts%
{
result := DllCall("winmm.dll\midiOutGetDevCapsA", UInt,A_Index-1, UInt,&MidiOutCaps, UInt,50, UInt)
If (result OR ErrorLevel)
{
List .= "|-Error-"
Continue
}
DllCall("RtlMoveMemory", Str,PortName, UInt,&MidiOutCaps+8, UInt,32) ; PortNameOffset 8, PortNameSize 32
List .= "|" PortName
}
Return SubStr(List,2)
}
;---------------------midiOut from TomB and Lazslo and JimF --------------------------------

;THATS THE END OF MY STUFF (JimF) THE REST ID WHAT LASZLo AND PAXOPHONE WERE USING ALREADY
;AHK FUNCTIONS FOR MIDI OUTPUT - calling winmm.dll
;http://msdn.microsoft.com/library/default.asp?url=/library/en-us/multimed/htm/_win32_multimedia_functions.asp
;Derived from Midi.ahk dated 29 August 2008 - streaming support removed - (JimF)


OpenCloseMidiAPI() { ; at the beginning to load, at the end to unload winmm.dll
static hModule
If hModule
DllCall("FreeLibrary", UInt,hModule), hModule := ""
If (0 = hModule := DllCall("LoadLibrary",Str,"winmm.dll")) {
MsgBox Cannot load libray winmm.dll
Exit
}
}

;FUNCTIONS FOR SENDING SHORT MESSAGES

midiOutOpen(uDeviceID = 0) { ; Open midi port for sending individual midi messages --> handle
strh_midiout = 0000

result := DllCall("winmm.dll\midiOutOpen", UInt,&strh_midiout, UInt,uDeviceID, UInt,0, UInt,0, UInt,0, UInt)
If (result or ErrorLevel) {
MsgBox There was an Error opening the midi port.`nError code %result%`nErrorLevel = %ErrorLevel%
Return -1
}
Return UInt@(&strh_midiout)
}

midiOutShortMsg(h_midiout, MidiStat, Param1, Param2) { ;Channel,
;h_midiout: handle to midi output device returned by midiOutOpen
;EventType, Channel combined -> MidiStatus byte: http://www.harmony-central.com/MIDI/Doc/table1.html
;Param3 should be 0 for PChange, ChanAT, or Wheel
;Wheel events: entire Wheel value in Param2 - the function splits it into two bytes
/*
If (EventType = "NoteOn" OR EventType = "N1")
MidiStatus := 143 + Channel
Else If (EventType = "NoteOff" OR EventType = "N0")
MidiStatus := 127 + Channel
Else If (EventType = "CC")
MidiStatus := 175 + Channel
Else If (EventType = "PolyAT" OR EventType = "PA")
MidiStatus := 159 + Channel
Else If (EventType = "ChanAT" OR EventType = "AT")
MidiStatus := 207 + Channel
Else If (EventType = "PChange" OR EventType = "PC")
MidiStatus := 191 + Channel
Else If (EventType = "Wheel" OR EventType = "W") {
MidiStatus := 223 + Channel
Param2 := Param1 >> 8 ; MSB of wheel value
Param1 := Param1 & 0x00FF ; strip MSB
}
*/
 ;MsgBox, 0, , %MidiStat% %Param1% %Param2%
result := DllCall("winmm.dll\midiOutShortMsg", UInt,h_midiout, UInt, MidiStat|(Param1<<8)|(Param2<<16), UInt)
If (result or ErrorLevel) {
MsgBox There was an Error Sending the midi event: (%result%`, %ErrorLevel%)
Return -1
}
}

/*
From the Paddy dev group
Function to send long Midi Messages
*/
  

midiOutClose(h_midiout) { ; Close MidiOutput
Loop 9 {
result := DllCall("winmm.dll\midiOutClose", UInt,h_midiout)
If !(result or ErrorLevel)
Return
Sleep 250
}
MsgBox Error in closing the midi output port. There may still be midi events being Processed.
Return -1
}

;UTILITY FUNCTIONS
MidiOutGetNumDevs() { ; Get number of midi output devices on system, first device has an ID of 0
Return DllCall("winmm.dll\midiOutGetNumDevs")
}

MidiOutNameGet(uDeviceID = 0) { ; Get name of a midiOut device for a given ID

;MIDIOUTCAPS struct
; WORD wMid;
; WORD wPid;
; MMVERSION vDriverVersion;
; CHAR szPname[MAXPNAMELEN];
; WORD wTechnology;
; WORD wVoices;
; WORD wNotes;
; WORD wChannelMask;
; DWORD dwSupport;

VarSetCapacity(MidiOutCaps, 50, 0) ; allows for szPname to be 32 bytes
OffsettoPortName := 8, PortNameSize := 32
result := DllCall("winmm.dll\midiOutGetDevCapsA", UInt,uDeviceID, UInt,&MidiOutCaps, UInt,50, UInt)

If (result OR ErrorLevel) {
MsgBox Error %result% (ErrorLevel = %ErrorLevel%) in retrieving the name of midi output %DeviceID%
Return -1
}

VarSetCapacity(PortName, PortNameSize)
DllCall("RtlMoveMemory", Str,PortName, Uint,&MidiOutCaps+OffsettoPortName, Uint,PortNameSize)
Return PortName
}

MidiOutsEnumerate() { ; Returns number of midi output devices, creates global array MidiOutPortName with their names
local NumPorts, PortID
MidiOutPortName =
NumPorts := MidiOutGetNumDevs()

Loop %NumPorts% {
PortID := A_Index -1
MidiOutPortName%PortID% := MidiOutNameGet(PortID)
}
Return NumPorts
}

UInt@(ptr) {
Return *ptr | *(ptr+1) << 8 | *(ptr+2) << 16 | *(ptr+3) << 24
}

PokeInt(p_value, p_address) { ; Windows 2000 and later
DllCall("ntdll\RtlFillMemoryUlong", UInt,p_address, UInt,4, UInt,p_value)
}

Struct(Structure,pointer:=0,init:=0){
return new _Struct(Structure,pointer,init)
}