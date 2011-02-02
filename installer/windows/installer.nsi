;NSIS Modern User Interface
;Ekylibre File installation
;Written by Brice Texier

; Use better compression
SetCompressor /SOLID /FINAL zlib

;--------------------------------
;Includes
   !include "MUI.nsh"
   !include "EnvVarUpdate.nsh"
   !include "StrRep.nsh"
   !include "ReplaceInFile.nsh"
   ; !include "InstallOptions.nsh"

;--------------------------------
;General

  !define APP "Ekylibre"
  !define WSPORT 4064
  !define DBMSPORT 4032

  ; VIAddVersionKey "ProductName" "${APP}"
  ; VIAddVersionKey "Comments" "Le logiciel de gestion des petites entreprises"
  ; VIAddVersionKey "CompanyName" "www.ekylibre.org"
  ; VIAddVersionKey "FileDescription" "${APP} ${VERSION} Installer"
  ; VIAddVersionKey "FileVersion" "${VERSION}"
  ; VIProductVersion "0.3.0.2"


  ; Name and file
  Name "${APP}"
  OutFile "${RELEASE}.exe"

  ;Default installation folder
  ;InstallDir "$PROGRAMFILES\${APP}"
  InstallDir "C:\${APP}"
  
  ;Get installation folder from registry if available
  InstallDirRegKey HKLM "Software\${APP}" "InstallDir"

  BrandingText "${APP} ${VERSION}"

  ;Request application privileges for Windows Vista/7
  RequestExecutionLevel highest



  ;Interface Settings
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
;Sections
Var password
Var username
Var AppDir
Var InstApp
Var Backup
Var DataDir

InstType "Typical (MySQL included)"
InstType "PostgreSQL Configuration (Expert)"
InstType "SQL Server Configuration (Expert)"
InstType "Only Ekylibre (Expert)"
InstType /NOCUSTOM

Section "Ekylibre" sec_ekylibre
  SectionIn 1 2 3 4
  Call initEnv
  
  ; Suppression des anciens services
  SimpleSC::StopService   "EkyService"
  SimpleSC::RemoveService "EkyService"

  ; Copie de sauvegarde de la base de données si le fichier existe
  ${If} $AppDir != ""
    RMDir /r $Backup
    Rename $AppDir $Backup
  ${EndIf}

  ; Mise en place du programme
  CreateDirectory $InstApp
  SetOutPath $InstApp
  File /r ${RESOURCES}/ruby
  File /r /x .svn ${RESOURCES}/apps
  ; Mise à jour de la variable PATH
  ${EnvVarUpdate} $0 "PATH" "A" "HKLM" "$InstApp\ruby\bin"

  ; Mise en place de la copie de sauvegarde des documents
  ${If} $AppDir != ""
    RMDir /r $InstApp\apps\ekylibre\private
    Rename $Backup\documents $InstApp\apps\ekylibre\private
  ${EndIf}

  ; Set Ekylibre Service
  SimpleSC::InstallService "EkyService" "${APP} WS" "16" "2"  '"$InstApp\ruby\bin\srvany.exe"' "" "" ""
  Pop $0
  ${If} $0 <> 0
    MessageBox MB_OK "Installation du service EkyService impossible"
  ${EndIf}
  WriteRegStr HKLM "SYSTEM\CurrentControlSet\Services\EkyService\Parameters" "Application" '$InstApp\ruby\bin\ruby.exe'
  WriteRegStr HKLM "SYSTEM\CurrentControlSet\Services\EkyService\Parameters" "AppParameters" '"$InstApp\ruby\bin\thin" start -p ${WSPORT} -e production -A rails'
  WriteRegStr HKLM "SYSTEM\CurrentControlSet\Services\EkyService\Parameters" "AppDirectory" '$InstApp\apps\ekylibre'
  SimpleSC::SetServiceDescription "EkyService" "Service Web d'Ekylibre"
  
  FileOpen $1 "$InstApp\migrate.cmd" "w"
  FileWrite $1 'cd "$InstApp\apps\ekylibre"$\r$\n'
  FileWrite $1 '"$InstApp\ruby\bin\ruby" "$InstApp\ruby\bin\rake" db:migrate RAILS_ENV=production$\r$\n'
  FileClose $1

  FileOpen $1 "$InstApp\rollback.cmd" "w"
  FileWrite $1 'cd "$InstApp\apps\ekylibre"$\r$\n'
  FileWrite $1 '"$InstApp\ruby\bin\ruby" "$InstApp\ruby\bin\rake" db:rollback RAILS_ENV=production$\r$\n'
  FileClose $1

  FileOpen $1 "$InstApp\ekylibre-start.cmd" "w"
  FileWrite $1 'sc start EkyService$\r$\n'
  FileClose $1

  FileOpen $1 "$InstApp\ekylibre-stop.cmd" "w"
  FileWrite $1 'sc stop EkyService$\r$\n'
  FileClose $1
SectionEnd


SectionGroup /e "Database"

Section "MySQL Installation and Configuration" sec_mysql
  SectionIn 1
  Call initEnv

  ; Suppression des anciens services
  SimpleSC::StopService   "EkyDatabase"
  SimpleSC::RemoveService "EkyDatabase"
  ; Retro compatility
  SimpleSC::StopService   "EkyMySQL"
  SimpleSC::RemoveService "EkyMySQL"

  ; Initialisation de quelques valeurs
  ReadRegStr $AppDir HKLM Software\${APP} "AppDir"
  StrCpy $username "ekylibre"
  pwgen::GeneratePassword 32
  Pop $password

  ; Mise en place du programme
  SetOutPath $InstApp
  File /r ${RESOURCES}/mysql
  !insertmacro ReplaceInFile "$InstApp\mysql\my.ini" "__INSTDIR__" "$InstApp"
  !insertmacro ReplaceInFile "$InstApp\mysql\my.ini" "__DATADIR__" "$DataDir"
  !insertmacro ReplaceInFile "$InstApp\mysql\my.ini" "3306" "${DBMSPORT}"

  ; Mise en place de la copie de sauvegarde de la base de données
  Delete $InstApp\apps\ekylibre\config\database.yml
  Rename $InstApp\apps\ekylibre\config\database.mysql.yml $InstApp\apps\ekylibre\config\database.yml
  !insertmacro ReplaceInFile "$InstApp\apps\ekylibre\config\database.yml" "__username__" "$username"
  !insertmacro ReplaceInFile "$InstApp\apps\ekylibre\config\database.yml" "__password__" "$password"
  !insertmacro ReplaceInFile "$InstApp\apps\ekylibre\config\database.yml" "3306" "${DBMSPORT}"
  RMDir /r $DataDir
  ${If} $AppDir == ""
    Rename $InstApp\mysql\data $DataDir
  ${Else}
    Rename $Backup\data $DataDir
  ${EndIf}

  ; Lancement de la base de données
  SimpleSC::InstallService "EkyDatabase" "${APP} DBMS" "16" "2" '"$InstApp\mysql\bin\mysqld.exe" --defaults-file="$InstApp\mysql\my.ini" EkyDatabase'  "" "" ""
  Pop $0
  ${If} $0 <> 0
    MessageBox MB_OK "Installation du service EkyDatabase impossible"
  ${EndIf}
  SimpleSC::SetServiceDescription "EkyDatabase" "Service Base de Données d'Ekylibre"
  WriteRegStr HKLM "SYSTEM\CurrentControlSet\Services\EkyService" "DependOnService" 'EkyDatabase'
  SimpleSC::StartService "EkyDatabase" ""

  ; (Ré-)Initialisation
  ${If} $AppDir == ""
    ExecWait '"$InstApp\mysql\bin\mysql" -u root -e "CREATE DATABASE ekylibre_production"'
    ExecWait '"$InstApp\mysql\bin\mysql" -u root -e "CREATE USER $username@localhost IDENTIFIED BY $\'$password$\'"'
  ${Else}
    ExecWait '"$InstApp\mysql\bin\mysql" -u root -e "SET PASSWORD FOR $username@localhost = PASSWORD($\'$password$\')"'
  ${EndIf}
  ExecWait '"$InstApp\mysql\bin\mysql" -u root -e "GRANT ALL PRIVILEGES ON ekylibre_production.* TO $username@localhost"'

  ExecWait '"$InstApp\migrate.cmd" "$InstApp"'
  
  SimpleSC::StartService "EkyService" ""
SectionEnd


Section "PostgreSQL Configuration" sec_postgresql
  SectionIn 2
  Call initEnv
    
  Delete $InstApp\apps\ekylibre\config\database.yml
  Rename $InstApp\apps\ekylibre\config\database.postgresql.yml $InstApp\apps\ekylibre\config\database.yml

  !insertmacro ReplaceInFile "$InstApp\apps\ekylibre\config\database.yml" "__username__" "ekylibre"
  !insertmacro ReplaceInFile "$InstApp\apps\ekylibre\config\database.yml" "__password__" "ekylibre"
  
  DetailPrint "Configure database.yml before launch migration"
SectionEnd

Section "SQL Server Configuration" sec_sqlserver
  SectionIn 3
  Call initEnv

  FileOpen $1 "$InstApp\apps\ekylibre\Gemfile" "a"
  FileSeek $1 0 END
  FileWrite $1 '$\r$\n'
  FileWrite $1 'gem "ruby-odbc"$\r$\n'
  ; FileWrite $1 'gem "activerecord-sqlserver-adapter"$\r$\n'
  FileClose $1
  
  Delete $InstApp\apps\ekylibre\config\database.yml
  Rename $InstApp\apps\ekylibre\config\database.sqlserver.yml $InstApp\apps\ekylibre\config\database.yml

  !insertmacro ReplaceInFile "$InstApp\apps\ekylibre\config\database.yml" "__username__" "ekylibre"
  !insertmacro ReplaceInFile "$InstApp\apps\ekylibre\config\database.yml" "__password__" "ekylibre"
  !insertmacro ReplaceInFile "$InstApp\apps\ekylibre\config\database.yml" "__dsn__" "sql2005dsn"
  
  DetailPrint "Configure database.yml before launch migration"
SectionEnd

SectionGroupEnd


Section "-Finish installation" sec_finish
  SectionIn 1 2 3 4
  Call initEnv
  
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
  
  RMDir /r $Backup
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
  SimpleSC::StopService   "EkyService"
  SimpleSC::RemoveService "EkyService"
  SimpleSC::StopService   "EkyDatabase"
  SimpleSC::RemoveService "EkyDatabase"

  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP}"
  DeleteRegKey HKLM "Software\${APP}"

  ; Mise à jour de la variable PATH
  ${un.EnvVarUpdate} $0 "PATH" "R" "HKLM" "$InstApp\ruby\bin"

  ; Suppression des programmes
  RMDir /r $SMPROGRAMS\${APP}
  RMDir /r $InstApp\mysql
  RMDir /r $InstApp\ruby
  Delete $InstApp\migrate.cmd
  Delete $InstApp\rollback.cmd
  Delete $InstApp\ekylibre-start.cmd
  Delete $InstApp\ekylibre-stop.cmd
  Delete $InstApp\uninstall.exe

  DetailPrint "Les fichiers ont été conservés dans $InstApp"
SectionEnd

Function initEnv
  StrCpy $InstApp "$INSTDIR\${APP}-${VERSION}"
  StrCpy $Backup  "$INSTDIR\backup-${VERSION}"
  StrCpy $DataDir "$InstApp\data"
  ReadRegStr $AppDir HKLM Software\${APP} "AppDir"
  SetShellVarContext all
  SetOutPath $INSTDIR
FunctionEnd


Function .onInit
  !insertmacro MUI_LANGDLL_DISPLAY
  ; !insertmacro INSTALLOPTIONS_EXTRACT "select_database.ini"
  ; SectionSetText ${sec_ekylibre} "Install Ekylibre Web Service"
  ; SectionSetText ${sec_mysql} "Install and configure Integrated MySQL Service"
  ; SectionSetText ${sec_sqlserver} "Only configure Ekylibre for SQL Server"
FunctionEnd

 
