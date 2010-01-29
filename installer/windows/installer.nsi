;NSIS Modern User Interface
;Ekylibre File installation
;Written by Brice Texier

; Use better compression
SetCompressor zlib

;--------------------------------
;Includes
   !include "MUI.nsh"
   !include "EnvVarUpdate.nsh"
   !include "StrRep.nsh"
   !include "ReplaceInFile.nsh"

;--------------------------------
;General

  !define NAME "Ekylibre"
  !define WSPORT 4064
  !define DBMSPORT 4032

  ; Name and file
  Name "${APP}"
  OutFile "${RELEASE}.exe"
  
  ;Default installation folder
  InstallDir "$PROGRAMFILES\${APP}"
  
  ;Get installation folder from registry if available
  InstallDirRegKey HKLM "$INSTDIR" "" 

  ;Request application privileges for Windows Vista
  RequestExecutionLevel user

  ;Interface Settings
  !define MUI_PAGE_HEADER_TEXT "Installation d'${APP} (${VERSION})"

  !define MUI_ABORTWARNING
  !define MUI_ABORTWARNING_TEXT "Vous allez quitter l'installation"
  !define MUI_LICENSEPAGE_BGCOLOR FFFFFF
  ; !define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\orange-install.ico"
  !define MUI_ICON "${RESOURCES}\apps\ekylibre\public\images\ekone.ico"   

   
  ;Start Menu Folder Page Configuration
  ;!define MUI_STARTMENUPAGE_BGCOLOR 22A234
  ;!define MUI_STARTMENUPAGE_REGISTRY_ROOT "HKCU" 
  ;!define MUI_STARTMENUPAGE_REGISTRY_KEY "Software\${APP}" 
  ;!define MUI_STARTMENUPAGE_REGISTRY_VALUENAME ""
  

;--------------------------------
;Pages
  !define MUI_WELCOMEPAGE_TITLE "Bienvenue dans le programme d'installation d'${APP}"
  ;!define MUI_PAGE_WELCOME
  !insertmacro MUI_PAGE_WELCOME
  
  !define MUI_LICENSEPAGE_RADIOBUTTONS
  !define MUI_LICENSEPAGE_RADIOBUTTONS_TEXT_ACCEPT "J'accepte les termes du contrat de licence"
  !define MUI_LICENSEPAGE_RADIOBUTTONS_TEXT_DECLINE "Je n'accepte pas les termes du contrat de licence"
  !insertmacro MUI_PAGE_LICENSE "${RESOURCES}\apps\ekylibre\doc\license.txt"

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
  SetShellVarContext all

  ; Suppression de l'ancien Ekylibre Service
  SimpleSC::StopService   "EkyService"
  SimpleSC::RemoveService "EkyService"
  SimpleSC::StopService   "EkyMySQL"
  SimpleSC::RemoveService "EkyMySQL"

  !define DATADIR $INSTDIR\mysql\data
  !define BACKUP $INSTDIR\backup
  Var /GLOBAL datadir
  ReadRegStr $datadir HKLM Software\${APP} "Data"
  ; Copie de sauvegarde de la base de donnée si le fichier existe
  ${If} $datadir != ""
    DetailPrint "Sauvegarde des données présentes"
    RMDir /r $INSTDIR\backup
    CreateDirectory ${BACKUP}\data
    CopyFiles $datadir\* ${BACKUP}\data
    Rename $INSTDIR\apps\ekylibre\private ${BACKUP}\documents
  ${Else}
    DetailPrint "Pas de données présentes"
  ${EndIf}
  
  ; Mise en place du programme
  File /r ${RESOURCES}/ruby
  File /r ${RESOURCES}/mysql
  !insertmacro ReplaceInFile "$INSTDIR\mysql\my.ini" "__INSTDIR__" "$INSTDIR"
  !insertmacro ReplaceInFile "$INSTDIR\mysql\my.ini" "__DATADIR__" "${DATADIR}"
  !insertmacro ReplaceInFile "$INSTDIR\mysql\my.ini" "3306" "${DBMSPORT}"
  ; File ${RESOURCES}\migrate.cmd
  FileOpen $1 "$INSTDIR\migrate.cmd" "w"
  FileWrite $1 'cd "$INSTDIR\apps\ekylibre"$\r$\n'
  FileWrite $1 '"$INSTDIR\ruby\bin\ruby" "$INSTDIR\ruby\bin\rake" db:migrate RAILS_ENV=production$\r$\n'
  ; FileWrite $1 'pause$\r$\n'
  FileClose $1

  CreateDirectory "$SMPROGRAMS\${APP}"
  CreateShortCut  "$SMPROGRAMS\${APP}\Licence publique générale GNU 3.lnk" "$INSTDIR\license.txt"
  CreateShortCut  "$SMPROGRAMS\${APP}\Désinstaller ${APP}.lnk" "$INSTDIR\uninstall.exe"     
  ; File ${RESOURCES}\${APP}.url
  FileOpen $1 "$SMPROGRAMS\${APP}\${APP}.url" "w"
  FileWrite $1 "[InternetShortcut]$\r$\n"
  FileWrite $1 "URL=http://localhost:${WSPORT}/$\r$\n"
  FileWrite $1 "IconFile=$INSTDIR\apps\ekylibre\public\images\ekone.ico$\r$\n"
  FileWrite $1 "IconIndex=0$\r$\n"
  FileClose $1
  ; File ${RESOURCES}\Website.url
  FileOpen $1 "$SMPROGRAMS\${APP}\Site officiel.url" "w"
  FileWrite $1 "[InternetShortcut]$\r$\n"
  FileWrite $1 "URL=http://www.ekylibre.org/$\r$\n"
  FileClose $1

  ; Mise en place de la copie de sauvegarde de la base de données  
  ${If} $datadir == ""
    DetailPrint "Mise en place d'une nouvelle base"
    ; Rename $INSTDIR\mysql\data $DATADIR
  ${Else}
    DetailPrint "Récupération de la sauvegarde"
    RMDir /r $DATADIR
    Rename ${BACKUP}\data $DATADIR
    RMDir /r $INSTDIR\apps\ekylibre\private
    Rename ${BACKUP}\documents $INSTDIR\apps\ekylibre\private
    RMDir /r ${BACKUP}
  ${EndIf}

  ; Generation des mots de passe  
  Var /GLOBAL password
  Var /GLOBAL username
  StrCpy $username "ekylibre"
  pwgen::GeneratePassword 32
  Pop $password

  ; Mise en place de la conf DB
  Rename $INSTDIR\apps\ekylibre\config\database.mysql.yml $INSTDIR\apps\ekylibre\config\database.yml
  !insertmacro ReplaceInFile "$INSTDIR\apps\ekylibre\config\database.yml" "__username__" "$username"
  !insertmacro ReplaceInFile "$INSTDIR\apps\ekylibre\config\database.yml" "__password__" "$password"
  !insertmacro ReplaceInFile "$INSTDIR\apps\ekylibre\config\database.yml" "3306" "${DBMSPORT}"
   
  ; Write the installation path and uninstall keys into the registry
  WriteUninstaller "uninstall.exe"   ; build uninstall program
  WriteRegStr HKLM "Software\${APP}" "InstallDir"   "$INSTDIR"
  WriteRegStr HKLM "Software\${APP}" "Data"         "${DATADIR}"
  WriteRegStr HKLM "Software\${APP}" "Version"      "${VERSION}"
  WriteRegStr HKLM "Software\${APP}" "Database"     "mysql"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP}" "DisplayName" "${APP} (Supprimer seulement)"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP}" "UninstallString" '"$INSTDIR\uninstall.exe"'

  ; Mise à jour de la variable PATH
  ${EnvVarUpdate} $0 "PATH" "A" "HKLM" "$INSTDIR\ruby\bin" 

  ; Migration
  SimpleSC::InstallService "EkyMySQL" "${APP} DBMS" "16" "2" '"$INSTDIR\mysql\bin\mysqld.exe" --defaults-file="$INSTDIR\mysql\my.ini" EkyMySQL'  "" "" ""
  Pop $0
  ${If} $0 <> 0
    MessageBox MB_OK "Installation du service impossible"  
  ${EndIf}
  SimpleSC::StartService "EkyMySQL" ""
  ExecWait '"$INSTDIR\mysql\bin\mysql" -u root -e "CREATE DATABASE ekylibre_production"'
  ExecWait '"$INSTDIR\mysql\bin\mysql" -u root -e "CREATE USER $username@localhost IDENTIFIED BY $\'$password$\'"'
  ExecWait '"$INSTDIR\mysql\bin\mysql" -u root -e "GRANT ALL PRIVILEGES ON ekylibre_production.* TO $username@localhost"'
  ExecWait '"$INSTDIR\migrate.cmd" "$INSTDIR"'

  ; Ekylibre Service
  SimpleSC::InstallService "EkyService" "${APP} WS" "16" "2"  '"$INSTDIR/ruby/bin/mongrel_service.exe" single -e production -p ${WSPORT} -a 0.0.0.0 -l "log/mongrel.log" -P "log/mongrel.pid" -c "$INSTDIR/apps/ekylibre" -t 0 -r "public" -n 1024' "EkyMySQL" "" ""
  Pop $0
  ${If} $0 <> 0
    MessageBox MB_OK "Installation du service impossible"  
  ${EndIf}
  SimpleSC::StartService "EkyService" ""

SectionEnd


Section "Uninstall"
  SetShellVarContext all

  ; Mise à jour de la base de registre
  SimpleSC::StopService   "EkyService"
  SimpleSC::RemoveService "EkyService"
  SimpleSC::StopService   "EkyMySQL"
  SimpleSC::RemoveService "EkyMySQL"

  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP}"
  DeleteRegKey HKLM "Software\${APP}"

  ; Mise à jour de la variable PATH
  ${un.EnvVarUpdate} $0 "PATH" "R" "HKLM" "$INSTDIR\ruby\bin" 

  ; Sauvegarde des données s'il y en a
  ReadRegStr $datadir HKLM Software\${APP} "Data"
  ${If} $datadir != ""
    RMDir /r ${BACKUP}
    CreateDirectory ${BACKUP}\data
    CopyFiles $datadir ${BACKUP}\data
    Rename $INSTDIR\apps\ekylibre\private ${BACKUP}\documents
    Rename ${BACKUP} $DOCUMENTS\${RELEASE}-backup
    MessageBox MB_OK "Les données ont été sauvegardées dans $DOCUMENTS\${RELEASE}-backup"
  ${EndIf}
  
  ; Suppression des programmes
  Delete $SMPROGRAMS\${APP}\*.*
  RMDir /r $SMPROGRAMS\${APP}
  Delete $INSTDIR\*.*
  RMDir /r /REBOOTOK $INSTDIR
SectionEnd
 