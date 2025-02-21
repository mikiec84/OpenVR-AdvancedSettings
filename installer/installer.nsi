;--------------------------------
;Include Modern UI

	!include "MUI2.nsh"

;--------------------------------
;General

        !define BASEDIR "..\bin\win64\AdvancedSettings"
		!define SRCDIR "..\src"
		!define THIRDDIR "..\third-party"

	;Name and file
	Name "OpenVR Advanced Settings"
        OutFile "AdvancedSettings-Installer.exe"
	
	;Default installation folder
	InstallDir "$PROGRAMFILES64\OpenVR-AdvancedSettings"
	
	;Get installation folder from registry if available
	InstallDirRegKey HKLM "Software\OpenVR-AdvancedSettings" ""
	
	;Request application privileges for Windows Vista
	RequestExecutionLevel admin
	
;--------------------------------
;Variables

VAR upgradeInstallation

;--------------------------------
;Interface Settings

	!define MUI_ABORTWARNING

;--------------------------------
;Pages

	!insertmacro MUI_PAGE_LICENSE "..\LICENSE"
	!define MUI_PAGE_CUSTOMFUNCTION_PRE dirPre
	!insertmacro MUI_PAGE_DIRECTORY
	!insertmacro MUI_PAGE_INSTFILES
  
	!insertmacro MUI_UNPAGE_CONFIRM
	!insertmacro MUI_UNPAGE_INSTFILES
  
;--------------------------------
;Languages
 
	!insertmacro MUI_LANGUAGE "English"

;--------------------------------
;Macros

!macro TerminateOverlay
	DetailPrint "Terminating OpenVR Advanced Settings overlay..."
	ExecWait '"taskkill" /F /IM AdvancedSettings.exe'
	Sleep 2000 ; give 2 seconds for the application to finish exiting
!macroend

;--------------------------------
;Functions

Function dirPre
	StrCmp $upgradeInstallation "true" 0 +2 
		Abort
FunctionEnd

Function .onInit
	StrCpy $upgradeInstallation "false"
 
	ReadRegStr $R0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\OpenVRAdvancedSettings" "UninstallString"
	StrCmp $R0 "" done
 
	MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION \
		"OpenVR Advanced Settings is already installed. $\n$\nClick `OK` to upgrade the \
		existing installation or `Cancel` to cancel this upgrade." \
		IDOK upgrade
	Abort
 
	upgrade:
		StrCpy $upgradeInstallation "true"
	done:
FunctionEnd

;--------------------------------
;Installer Sections

Section "Install" SecInstall

	!insertmacro TerminateOverlay
	
	StrCmp $upgradeInstallation "true" 0 noupgrade 
		DetailPrint "Uninstall previous version..."
		ExecWait '"$INSTDIR\Uninstall.exe" /S _?=$INSTDIR'
		Delete $INSTDIR\Uninstall.exe
		Goto afterupgrade
		
	noupgrade:

	afterupgrade:

	SetOutPath "$INSTDIR"

	;ADD YOUR OWN FILES HERE...
    File "${SRCDIR}\LICENSE.txt"
	File "${BASEDIR}\*.exe"
	File "${THIRDDIR}\openvr\bin\win64\*.dll"
	File "${BASEDIR}\*.dll"
	File "${SRCDIR}\*.bat"
	File "${SRCDIR}\*.vrmanifest"
	File "${SRCDIR}\*.conf"
	File /r "${SRCDIR}\res"
	File /r "${BASEDIR}\qtdata"

	; Install redistributable
	ExecWait '"$INSTDIR\vcredist_x64.exe" /install /quiet'

	; Install the vrmanifest
	nsExec::ExecToLog '"$INSTDIR\AdvancedSettings.exe" -installmanifest'
  
	;Store installation folder
	WriteRegStr HKLM "Software\OpenVR-AdvancedSettings" "" $INSTDIR
  
	;Create uninstaller
	WriteUninstaller "$INSTDIR\Uninstall.exe"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\OpenVRAdvancedSettings" "DisplayName" "OpenVR Advanced Settings"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\OpenVRAdvancedSettings" "UninstallString" "$\"$INSTDIR\Uninstall.exe$\""

	; If SteamVR is already running, execute the dashboard as the user
	FindWindow $0 "Qt5QWindowIcon" "SteamVR Status"
	StrCmp $0 0 +2
		Exec '"$INSTDIR\AdvancedSettings.exe"'

SectionEnd

;--------------------------------
;Uninstaller Section

Section "Uninstall"

	!insertmacro TerminateOverlay

	; Remove the vrmanifest
	nsExec::ExecToLog '"$INSTDIR\AdvancedSettings.exe" -removemanifest'

	; Delete installed files
	!include uninstallFiles.list

	DeleteRegKey HKLM "Software\OpenVR-AdvancedSettings"
	DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\OpenVRAdvancedSettings"



SectionEnd

