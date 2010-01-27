;NSIS Modern User Interface
;Ekylibre File installation
;Written by Brice Texier

;--------------------------------
;Includes
   !include "MUI.nsh"
   !include "EnvVarUpdate.nsh"

;--------------------------------
;General

  ; Name and file
  ; !define VERSION "v 2.0"
  Name "Ekylibre"
  OutFile "${RELEASE}.exe"
  
  ; OutFile "ekylibre-win32.exe"

  ;Default installation folder
  InstallDir "$PROGRAMFILES\Ekylibre"
  
  ;Get installation folder from registry if available
  InstallDirRegKey HKLM "$INSTDIR" "" 

  ;Request application privileges for Windows Vista
  RequestExecutionLevel user

  ;Interface Settings
  !define MUI_PAGE_HEADER_TEXT "Installation d'Ekylibre (${VERSION})"

  !define MUI_ABORTWARNING
  !define MUI_ABORTWARNING_TEXT "Vous allez quitter l'installation"
  !define MUI_LICENSEPAGE_BGCOLOR FFFFFF
  ; !define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\orange-install.ico"
  !define MUI_ICON "ekylibre-win32\apps\ekylibre\public\images\ekone.ico"   

   
  ;Start Menu Folder Page Configuration
  ;!define MUI_STARTMENUPAGE_BGCOLOR 22A234
  ;!define MUI_STARTMENUPAGE_REGISTRY_ROOT "HKCU" 
  ;!define MUI_STARTMENUPAGE_REGISTRY_KEY "Software\Ekylibre" 
  ;!define MUI_STARTMENUPAGE_REGISTRY_VALUENAME ""
  

;--------------------------------
;Pages
  !define MUI_WELCOMEPAGE_TITLE "Bienvenue dans le programme d'installation d'Ekylibre"
  ;!define MUI_PAGE_WELCOME
  !insertmacro MUI_PAGE_WELCOME
  
  !define MUI_LICENSEPAGE_RADIOBUTTONS
  !define MUI_LICENSEPAGE_RADIOBUTTONS_TEXT_ACCEPT "J'accepte les termes du contrat de licence"
  !define MUI_LICENSEPAGE_RADIOBUTTONS_TEXT_DECLINE "Je n'accepte pas les termes du contrat de licence"
  !insertmacro MUI_PAGE_LICENSE "ekylibre-win32\apps\ekylibre\doc\license.txt"

  !define MUI_DIRECTORYPAGE_TEXT_DESTINATION "$INSTDIR"  
  !define MUI_DIRECTORYPAGE_VERIFYONLEAVE
  !insertmacro MUI_PAGE_DIRECTORY

  !define MUI_INSTFILESPAGE_FINISHHEADER_TEXT "Bravo !"  
  !define MUI_INSTFILESPAGE_ABORTHEADER_TEXT  "Désolé !"  
  !insertmacro MUI_PAGE_INSTFILES
  
  !define MUI_FINISHPAGE_NOAUTOCLOSE
  !define MUI_UNFINISHPAGE_NOAUTOCLOSE  
  !define MUI_FINISHPAGE_TEXT_REBOOT "Vous devez redémarrer l'ordinateur pour que l'installation se termine."
  !define MUI_FINISHPAGE_LINK "Visitez le site officiel"  
  !define MUI_FINISHPAGE_LINK_LOCATION "http://www.ekylibre.org"
  !insertmacro MUI_PAGE_FINISH

  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES

;--------------------------------
;Languages
  !insertmacro MUI_LANGUAGE "French"

;--------------------------------

;Sections


Section 
  SetOutPath $INSTDIR 

  ; Copie de sauvegarde de la base de donnée si le fichier existe
  IfFileExists $INSTDIR\apps\ekylibre 0 +5
    RMDir /r $INSTDIR\backup
    CreateDirectory $INSTDIR\backup
    CopyFiles $INSTDIR\apps\ekylibre\db\*.sqlite3 $INSTDIR\backup
    Rename $INSTDIR\apps\ekylibre\private $INSTDIR\backup\documents
  
  ; Mise en place du programme
  File /r ekylibre-win32\ruby
  File /r ekylibre-win32\image_magick
  File /r ekylibre-win32\apps
  File ekylibre-win32\Ekylibre.url
  File ekylibre-win32\Website.url
  ; File ekylibre-win32\server.cmd
  File ekylibre-win32\update.cmd
 
  ; Suppression de Gruff qui fait planter le service pour l'instantavec mongrel_service
  RMDir /r $INSTDIR\apps\ekylibre\vendor\plugins\gruff
  
  ; Mise en place de la copie de sauvegarde de la base de données  
  IfFileExists $INSTDIR\db-backup\*.sqlite3 0 +4
    CopyFiles $INSTDIR\db-backup\*.sqlite3 $INSTDIR\apps\ekylibre\db
    RMDir /r $INSTDIR\apps\ekylibre\private
    Rename $INSTDIR\backup\documents $INSTDIR\apps\ekylibre\private
  
  ; Mise en place de la conf DB
  Rename $INSTDIR\apps\ekylibre\config\database.sqlite3.yml $INSTDIR\apps\ekylibre\config\database.yml
   
  ; Write the installation path and uninstall keys into the registry
  WriteUninstaller "uninstall.exe"   ; build uninstall program
  WriteRegStr HKLM "Software\Ekylibre" "Install_Dir" "$INSTDIR"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Ekylibre" "DisplayName" "Ekylibre (Supprimer seulement)"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Ekylibre" "UninstallString" '"$INSTDIR\uninstall.exe"'

  ; Mise à jour de la variable PATH
  ${EnvVarUpdate} $0 "PATH" "A" "HKLM" "$INSTDIR\ruby\bin" 
  ${EnvVarUpdate} $0 "PATH" "A" "HKLM" "$INSTDIR\image_magick" 

  ; Suppression de l'ancien Ekylibre Service
  SimpleSC::StopService "EkyService"
  SimpleSC::RemoveService "EkyService"

  ; Migration
  ExecWait '"$INSTDIR\update.cmd" "$INSTDIR"'

  ; Ekylibre Service
  ; '"$INSTDIR/ruby/bin/mongrel_service.exe" single -e development -p 4000 -a 0.0.0.0 -l "log/mongrel.log" -P "log/mongrel.pid" -c "$INSTDIR/apps/ekylibre" -t 0 -r "public" -n 1024'
  ; '"$INSTDIR\ruby\bin\mongrel_service.exe" single -l log\mongrel.log -a 127.0.0.1 -n 1024 -r public -c "$INSTDIR\apps\ekylibre" -t 0 -p 4040 -e production'
  SimpleSC::InstallService "EkyService" "Service web Ekylibre" "16" "2"  '"$INSTDIR/ruby/bin/mongrel_service.exe" single -e production -p 4040 -a 0.0.0.0 -l "log/mongrel.log" -P "log/mongrel.pid" -c "$INSTDIR/apps/ekylibre" -t 0 -r "public" -n 1024'  "" "" ""
  Pop $0
  ${If} $0 <> 0
    MessageBox MB_OK "Installation du service impossible"  
  ${EndIf}
  SimpleSC::StartService "EkyService" ""

SectionEnd


Section "Uninstall"
  ; Mise à jour de la base de registre
  SimpleSC::StopService "EkyService"
  SimpleSC::RemoveService "EkyService"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Ekylibre"
  DeleteRegKey HKLM "Software\Ekylibre"

  ; Mise à jour de la variable PATH
  ${un.EnvVarUpdate} $0 "PATH" "R" "HKLM" "$INSTDIR\ruby\bin" 
  ${un.EnvVarUpdate} $0 "PATH" "R" "HKLM" "$INSTDIR\image_magick" 

  ; Sauvegarde des données s'il y en a
  IfFileExists $INSTDIR\apps\ekylibre\db\*.sqlite3 0 +7
  RMDir /r $INSTDIR\backup
  CreateDirectory $INSTDIR\backup
    CopyFiles $INSTDIR\apps\ekylibre\db\*.sqlite3 $INSTDIR\backup
  Rename $INSTDIR\apps\ekylibre\private $INSTDIR\backup\documents
  Rename $INSTDIR\backup $DOCUMENTS\${RELEASE}-backup
  DetailPrint "Les données ont été sauvegardées dans $DOCUMENTS\Backup-Ekylibre"
  
  ; Suppression des programmes
  Delete $SMPROGRAMS\Ekylibre\*.*
  RMDir /r $SMPROGRAMS\Ekylibre
  Delete $INSTDIR\*.*
  RMDir /r /REBOOTOK $INSTDIR
SectionEnd
 

Section "Start Menu Shortcuts"
  CreateDirectory "$SMPROGRAMS\Ekylibre"
  CreateShortCut  "$SMPROGRAMS\Ekylibre\Ekylibre.lnk" "$INSTDIR\Ekylibre.url" "" "$INSTDIR\apps\ekylibre\public\images\ekone.ico"
  CreateShortCut  "$SMPROGRAMS\Ekylibre\Site web.lnk" "$INSTDIR\Website.url"
  CreateShortCut  "$SMPROGRAMS\Ekylibre\Licence publique générale GNU 3.lnk" "$INSTDIR\license.txt"
  CreateShortCut  "$SMPROGRAMS\Ekylibre\Désinstaller Ekylibre.lnk" "$INSTDIR\uninstall.exe"     
SectionEnd 


;--------------------------------

; Functions

Function .onInstFailed
  MessageBox MB_OK "L'installation a été interrompue"
FunctionEnd

