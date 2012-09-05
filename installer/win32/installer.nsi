;NSIS Modern User Interface
;Ekylibre File installation
;Written by Brice Texier

; Use better compression
SetCompressor /SOLID /FINAL zlib

;--------------------------------
;Includes
!include "MUI.nsh"
!include "EnvVarUpdate.nsh"
; !include "StrRep.nsh"
; !include "ReplaceInFile.nsh"
; !include "InstallOptions.nsh"

;--------------------------------
;General

!define APP "Ekylibre"
!define WSPORT 4064
!define DBMSPORT 5432

; Can not work with Product Version
; VIAddVersionKey "ProductName" "${APP}"
; VIAddVersionKey "Comments" "Le logiciel de gestion des petites entreprises"
; VIAddVersionKey "CompanyName" "www.ekylibre.org"
; VIAddVersionKey "FileDescription" "${APP} ${VERSION} Installer"
; VIAddVersionKey "FileVersion" "${VERSION}"
; VIProductVersion "${VERSION}.156"


; Name and file
Name "${APP}"
OutFile "packages/${RELEASE}.exe"

; Default installation folder
;InstallDir "$PROGRAMFILES\${APP}"
InstallDir "C:\${APP}"

; Get installation folder from registry if available
InstallDirRegKey HKLM "Software\${APP}" "InstallDir"

BrandingText "${APP} ${VERSION}"

; Request application privileges for Windows Vista/7
RequestExecutionLevel highest



; Interface Settings
; ReserveFile "select_database.ini"
!define MUI_LANGDLL_ALLLANGUAGES
!define MUI_ICON "${IMAGES}\install.ico"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_RIGHT
!define MUI_HEADERIMAGE_BITMAP "${IMAGES}\header.bmp"
!define MUI_HEADERIMAGE_BITMAP_RTL "${IMAGES}\header_rtl.bmp"
!define MUI_HEADERIMAGE_UNBITMAP "${IMAGES}\header.bmp"
!define MUI_HEADERIMAGE_UNBITMAP_RTL "${IMAGES}\header_rtl.bmp"
!define MUI_WELCOMEFINISHPAGE_BITMAP "${IMAGES}\welcome.bmp"
!define MUI_UNWELCOMEFINISHPAGE_BITMAP "${IMAGES}\welcome.bmp"
!define MUI_LICENSEPAGE_BGCOLOR FFFFFF
!define MUI_DIRECTORYPAGE_TEXT_DESTINATION "$INSTDIR"
!define MUI_DIRECTORYPAGE_VERIFYONLEAVE
!define MUI_COMPONENTSPAGE
!define MUI_COMPONENTSPAGE_NODESC
!define MUI_FINISHPAGE_LINK "www.ekylibre.org"
!define MUI_FINISHPAGE_LINK_LOCATION "http://www.ekylibre.org"
!define MUI_ABORTWARNING


!insertmacro MUI_RESERVEFILE_INSTALLOPTIONS
!insertmacro MUI_RESERVEFILE_LANGDLL

;--------------------------------
; Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "${RESOURCES}\apps\ekylibre\LICENSE"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

;--------------------------------
; Uninstall pages
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

;--------------------------------
; Languages
!insertmacro MUI_LANGUAGE "Arabic"
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "French"
!insertmacro MUI_LANGUAGE "Japanese"
!insertmacro MUI_LANGUAGE "Spanish"


;--------------------------------
; Sections
Var /GLOBAL password
Var /GLOBAL username
Var /GLOBAL PreviousInstApp
Var /GLOBAL InstApp
Var /GLOBAL DataDir
Var /GLOBAL Backuping
Var /GLOBAL Backup
Var /GLOBAL Initialized

InstType "Typical (Database included)"
; InstType "PostgreSQL Configuration (Expert)"
; InstType "SQL Server Configuration (Expert)"
InstType "Minimal (Expert)"
InstType /NOCUSTOM

Section "-Reserve files"
  ReserveFile ${RESOURCES}/vcredist_x86.exe
SectionEnd

Section "Ekylibre" sec_ekylibre
  SectionIn 1 2
  DetailPrint "Step -1"
  Call initEnv
  DetailPrint "Step 0"
  
  ; Suppression des anciens services
  SimpleSC::StopService   "EkyService" 1 30
  DetailPrint "Step 0.1"
  SimpleSC::RemoveService "EkyService"
  DetailPrint "Step 0.2"

  ; Copie de sauvegarde de la base de données si le fichier existe
  StrCpy $Backuping "false"
  DetailPrint "Step 0.3"
  ${If} $PreviousInstApp != ""
    MessageBox MB_YESNO|MB_ICONQUESTION "Une précédente installation a été trouvée. Voulez-vous récupérerez les données avant de la mettre à jour ?" /SD IDYES IDYES yes IDNO no
    yes:
      StrCpy $Backuping "true"
      RMDir /r $Backup
      CreateDirectory $Backup
      CopyFiles /SILENT $PreviousInstApp\data $Backup\data
      CopyFiles /SILENT $PreviousInstApp\apps\${APP}\private $Backup\private
      CopyFiles /SILENT $PreviousInstApp\apps\${APP}\config\database.yml $Backup\database.yml
      RMDir /r /REBOOTOK $PreviousInstApp
      ; MessageBox MB_OK "Données sauvegardées. Merci de procéder à la désinstallation de l'ancienne version."
      Goto next
    no:
      StrCpy $Backuping "false"
      StrCpy $PreviousInstApp ""
    next:
    ${EndIf}

    ; Mise en place du programme
    DetailPrint "Step 1"
    CreateDirectory $InstApp
    DetailPrint "Step 2"
    SetOutPath $InstApp
    DetailPrint "Step 3"
    File /r ${RESOURCES}/ruby
    DetailPrint "Step 4"
    File /r ${RESOURCES}/apps
    DetailPrint "Step 5"
    ; Mise à jour de la variable PATH
    ${EnvVarUpdate} $0 "PATH" "R" "HKLM" "$PreviousInstApp\ruby\bin"
    DetailPrint "Step 6"
    ${EnvVarUpdate} $0 "PATH" "A" "HKLM" "$InstApp\ruby\bin"
    DetailPrint "Step 7"

    ; Mise en place de la copie de sauvegarde des documents
    ${If} $Backuping == "true"
      RMDir /r $InstApp\apps\ekylibre\private
      CopyFiles $Backup\private $InstApp\apps\ekylibre\private
      RMDir /r $Backup\private
    ${EndIf}

    ; Set Ekylibre Service
    SimpleSC::InstallService "EkyService" "${APP} WS" "16" "2"  '"$InstApp\ruby\bin\srvany.exe"' "" "" ""
    Pop $0
    ${If} $0 <> 0
      MessageBox MB_OK "Installation du service EkyService impossible"
    ${EndIf}
    WriteRegStr HKLM "SYSTEM\CurrentControlSet\Services\EkyService\Parameters" "Application" '$InstApp\ruby\bin\ruby.exe'
    WriteRegStr HKLM "SYSTEM\CurrentControlSet\Services\EkyService\Parameters" "AppParameters" '"$InstApp\ruby\bin\thin" start -p ${WSPORT} -e production'
    WriteRegStr HKLM "SYSTEM\CurrentControlSet\Services\EkyService\Parameters" "AppDirectory" '$InstApp\apps\ekylibre'
    SimpleSC::SetServiceDescription "EkyService" "Service Web d'Ekylibre"
    
    FileOpen $1 "$InstApp\migrate.cmd" "w"
    FileWrite $1 'cd "$InstApp\apps\ekylibre"$\r$\n'
    FileWrite $1 'echo %PATH%$\r$\n'
    FileWrite $1 'SET PATH=%PATH%;$InstApp\ruby\bin$\r$\n'
    FileWrite $1 'echo %PATH%$\r$\n'
    FileWrite $1 '"$InstApp\ruby\bin\ruby" "$InstApp\ruby\bin\bundle" exec "$InstApp\ruby\bin\rake" db:migrate RAILS_ENV=production$\r$\n'
    FileClose $1

    FileOpen $1 "$InstApp\rollback.cmd" "w"
    FileWrite $1 'cd "$InstApp\apps\ekylibre"$\r$\n'
    FileWrite $1 '"$InstApp\ruby\bin\ruby" "$InstApp\ruby\bin\bundle" exec "$InstApp\ruby\bin\rake" db:rollback RAILS_ENV=production$\r$\n'
    FileClose $1

    FileOpen $1 "$InstApp\ekylibre-start.cmd" "w"
    FileWrite $1 'sc start EkyService$\r$\n'
    FileClose $1

    FileOpen $1 "$InstApp\ekylibre-stop.cmd" "w"
    FileWrite $1 'sc stop EkyService$\r$\n'
    FileClose $1
SectionEnd


SectionGroup /e "Database"
  
  ; PostgreSQL
  Section "PostgreSQL Installation and Configuration" sec_postgresql
    SectionIn 1
    Call initEnv

    ; Suppression des anciens services
    SimpleSC::StopService   "EkyDatabase" 1 30
    SimpleSC::RemoveService "EkyDatabase"
    ; Retro compatility
    SimpleSC::StopService   "EkyMySQL" 1 30
    SimpleSC::RemoveService "EkyMySQL"

    ; Initialisation de quelques valeurs
    ; ReadRegStr $PreviousInstApp HKLM Software\${APP} "AppDir"
    StrCpy $username "ekylibre"
    pwgen::GeneratePassword 32
    Pop $password
    
    ; Mise en place du programme
    SetOutPath $InstApp
    File /r ${RESOURCES}/pgsql

    ; Mise en place de la copie de sauvegarde de la base de données
    Delete $InstApp\apps\ekylibre\config\database.yml
    FileOpen $1 "$InstApp\apps\ekylibre\config\database.yml" "w"
    FileWrite $1 "# Generated with installer$\n"
    FileWrite $1 "production:$\n"
    FileWrite $1 "  adapter: postgresql$\n"
    FileWrite $1 "  encoding: utf-8$\n"
    FileWrite $1 "  database: ekylibre_production$\n"
    FileWrite $1 "  pool: 5$\n"
    FileWrite $1 "  username: $username$\n"
    FileWrite $1 "  password: $password$\n"
    FileWrite $1 "  host: 127.0.0.1$\n"
    FileWrite $1 "  port: ${DBMSPORT}$\n"
    FileClose $1
    RMDir /r $DataDir
    CreateDirectory $DataDir
    ${If} $Backuping == "true"
      CopyFiles /SILENT $Backup\data\* $DataDir
      RMDir /r $Backup\data
    ${Else}
      ExecWait '"$InstApp\pgsql\bin\initdb" -E UTF-8 --locale="French, France" -D "$DataDir"'
    ${EndIf}
    
    ; Lancement de la base de données
    ExecWait '"$InstApp\pgsql\bin\pg_ctl" register -N EkyDatabase -D "$DataDir"'
    ; SimpleSC::InstallService "EkyDatabase" "${APP} DBMS" "16" "2" '"$InstApp\mysql\bin\mysqld.exe" --defaults-file="$InstApp\mysql\my.ini" EkyDatabase'  "" "" ""
    ; Pop $0
    ; ${If} $0 <> 0
    ;   MessageBox MB_OK "Installation du service EkyDatabase impossible"
    ; ${EndIf}
    SimpleSC::SetServiceDescription "EkyDatabase" "Service Base de Données d'Ekylibre"
    WriteRegStr HKLM "SYSTEM\CurrentControlSet\Services\EkyService" "DependOnService" 'EkyDatabase'
    ; SimpleSC::StartService "EkyDatabase" "" 30
    ; ExecWait 'sc start EkyDatabase'

    FileOpen $1 "$InstApp\start_synchronously.cmd" "w"
    FileWrite $1 'sc start EkyDatabase$\r$\n'
    FileWrite $1 ':wait$\r$\n'
    FileWrite $1 'rem cause a ~1 second sleep before checking the service state$\r$\n'
    FileWrite $1 'ping 127.0.0.1 -n 10 -w 100 > nul$\r$\n'
    FileWrite $1 'sc query EkyDatabase | find /I "STATE" | find "STARTED"$\r$\n'
    FileWrite $1 'if errorlevel 1 goto :continue$\r$\n'
    FileWrite $1 'goto wait$\r$\n'
    FileWrite $1 ':continue$\r$\n'
    FileClose $1
    ExecWait '"$InstApp\start_synchronously.cmd"'
    Delete "$InstApp\start_synchronously.cmd"
    
    ; (Ré-)Initialisation
    ${If} $PreviousInstApp == ""
      ExecWait '"$InstApp\pgsql\bin\createdb" ekylibre_production'
      FileOpen $1 "$InstApp\config_user.sql" "w"
      FileWrite $1 "CREATE USER $username WITH NOSUPERUSER NOCREATEDB NOCREATEROLE ENCRYPTED PASSWORD '$password';$\n"
      FileClose $1
      ExecWait '"$InstApp\pgsql\bin\psql" -f "$InstApp\config_user.sql" ekylibre_production'
    ${Else}
      FileOpen $1 "$InstApp\config_user.sql" "w"
      FileWrite $1 "ALTER USER $username WITH NOSUPERUSER NOCREATEDB NOCREATEROLE ENCRYPTED PASSWORD '$password';$\n"
      FileClose $1
      ExecWait '"$InstApp\pgsql\bin\psql" -f "$InstApp\config_user.sql" ekylibre_production'
    ${EndIf}
    Delete $InstApp\config_user.sql     
    ExecWait '"$InstApp\pgsql\bin\psql" -e "GRANT ALL PRIVILEGES ON DATABASE ekylibre_production TO $username" ekylibre_production'
    
    ExecWait '"$InstApp\migrate.cmd"'
  SectionEnd  

SectionGroupEnd


Section "-Finish installation" sec_finish
  SectionIn 1 2 3 4
  Call initEnv

  SimpleSC::StartService "EkyService" ""
  
  ; Write the installation path and uninstall keys into the registry
  WriteUninstaller "$InstApp\uninstall.exe"   ; build uninstall program
  WriteRegStr HKLM "Software\${APP}" ""             "$INSTDIR"
  WriteRegStr HKLM "Software\${APP}" "AppDir"       "$InstApp"
  WriteRegStr HKLM "Software\${APP}" "Version"      "${VERSION}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP}" "DisplayName" "${APP} (Supprimer seulement)"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP}" "UninstallString" '"$InstApp\uninstall.exe"'

  ; Mise en place des raccourcis
  RMDir /r $SMPROGRAMS\${APP}
  CreateDirectory "$SMPROGRAMS\${APP}"

  FileOpen $1 "$SMPROGRAMS\${APP}\${APP} ${VERSION}.url" "w"
  FileWrite $1 "[InternetShortcut]$\r$\n"
  FileWrite $1 "URL=http://localhost:${WSPORT}/$\r$\n"
  FileWrite $1 "IconFile=$InstApp\apps\ekylibre\public\images\ekone.ico$\r$\n"
  FileWrite $1 "IconIndex=0$\r$\n"
  FileClose $1

  FileOpen $1 "$SMPROGRAMS\${APP}\Site officiel.url" "w"
  FileWrite $1 "[InternetShortcut]$\r$\n"
  FileWrite $1 "URL=http://www.ekylibre.org/$\r$\n"
  FileClose $1
  ; Uninstall
  CreateShortCut  "$SMPROGRAMS\${APP}\Désinstaller ${APP}.lnk" "$InstApp\uninstall.exe"
  
  ${If} $Backuping == "true"
    RMDir /r $Backup
  ${EndIf}
SectionEnd

Section "Add Expert Shortcuts" sec_shorcuts
  SectionIn 2 3 4
  Call initEnv  
  CreateDirectory "$SMPROGRAMS\${APP}\Expert"
  CreateShortCut "$SMPROGRAMS\${APP}\Expert\Launch migration.lnk" "$InstApp\migrate.cmd"
  CreateShortCut "$SMPROGRAMS\${APP}\Expert\Cancel last migration.lnk" "$InstApp\rollback.cmd"
  CreateShortCut "$SMPROGRAMS\${APP}\Expert\Start Ekylibre Service.lnk" "$InstApp\ekylibre-start.cmd"
  CreateShortCut "$SMPROGRAMS\${APP}\Expert\Stop Ekylibre Service.lnk" "$InstApp\ekylibre-stop.cmd"
SectionEnd


Section "Uninstall"
  ReadRegStr $InstApp HKLM Software\${APP} "AppDir"
  SetShellVarContext all

  ; Mise à jour de la base de registre
  SimpleSC::StopService   "EkyService" 1 30
  SimpleSC::RemoveService "EkyService"
  SimpleSC::StopService   "EkyDatabase" 1 30
  SimpleSC::RemoveService "EkyDatabase"

  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP}"
  DeleteRegKey HKLM "Software\${APP}"

  ; Mise à jour de la variable PATH
  ${un.EnvVarUpdate} $0 "PATH" "R" "HKLM" "$InstApp\ruby\bin"

  ; Suppression des programmes
  RMDir /r $SMPROGRAMS\${APP}
  RMDir /r $InstApp\pgsql
  RMDir /r $InstApp\ruby
  Delete $InstApp\migrate.cmd
  Delete $InstApp\rollback.cmd
  Delete $InstApp\ekylibre-start.cmd
  Delete $InstApp\ekylibre-stop.cmd
  Delete $InstApp\uninstall.exe

  DetailPrint "Les fichiers ont été conservés dans $InstApp"
SectionEnd

Function initEnv
  ${If} $Initialized != "true"
    StrCpy $InstApp "$INSTDIR\${APP}-${VERSION}"
    StrCpy $Backup  "$INSTDIR\backup"
    StrCpy $DataDir "$InstApp\data"
    StrCpy $Initialized "true"
    ReadRegStr $PreviousInstApp HKLM Software\${APP} "AppDir"
    SetShellVarContext all
    SetOutPath $INSTDIR
  ${EndIf}
FunctionEnd


Function .onInit
  !insertmacro MUI_LANGDLL_DISPLAY

  ; Installation de Visual C++ 2008 redistributable packages
  ; Nécessaire pour PostgreSQL
  ; Chargé au début car nécessite du temps avec lancement initdb...
  ; http://blogs.msdn.com/b/astebner/archive/2009/03/26/9513328.aspx
  SetOutPath $TEMP
  File ${RESOURCES}/vcredist_x86.exe
  ExecWait '"$TEMP\vcredist_x86.exe" /qb'
  Delete "$TEMP\vcredist_x86.exe"
  ; !insertmacro INSTALLOPTIONS_EXTRACT "select_database.ini"
  ; SectionSetText ${sec_ekylibre} "Install Ekylibre Web Service"
  ; SectionSetText ${sec_mysql} "Install and configure Integrated MySQL Service"
  ; SectionSetText ${sec_sqlserver} "Only configure Ekylibre for SQL Server"

FunctionEnd


