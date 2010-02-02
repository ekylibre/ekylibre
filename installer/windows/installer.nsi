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

  !define APP "Ekylibre"
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
  !define INSTAPP "$INSTDIR\Stack"
  !define BACKUP  "$INSTDIR\backup-${VERSION}"
  !define DATADIR "${INSTAPP}\data"


  SetShellVarContext all

  ; Suppression des anciens services
  SimpleSC::StopService   "EkyService"
  SimpleSC::RemoveService "EkyService"
  SimpleSC::StopService   "EkyMySQL"
  SimpleSC::RemoveService "EkyMySQL"

  ; Initialisation de quelques valeurs
  Var /GLOBAL app_dir
  Var /GLOBAL password
  Var /GLOBAL username
  ReadRegStr $app_dir  HKLM Software\${APP} ""
  StrCpy $username "ekylibre"
  pwgen::GeneratePassword 32
  Pop $password

  IfFileExists ${INSTAPP} 0 +2
    StrCpy $app_dir ${INSTAPP}

  ; Copie de sauvegarde de la base de données si le fichier existe
  ${If} $app_dir != ""
    DetailPrint "Sauvegarde des données présentes"
    RMDir /r ${BACKUP}
    Rename $app_dir ${BACKUP}
  ${Else}
    DetailPrint "Pas de données présentes"
  ${EndIf}
  
  ; Mise en place du programme
  CreateDirectory ${INSTAPP}
  SetOutPath ${INSTAPP}
  File /r ${RESOURCES}/ruby
  File /r ${RESOURCES}/mysql
  File /r /x .svn ${RESOURCES}/apps
  !insertmacro ReplaceInFile "${INSTAPP}\mysql\my.ini" "__INSTDIR__" "${INSTAPP}"
  !insertmacro ReplaceInFile "${INSTAPP}\mysql\my.ini" "__DATADIR__" "${DATADIR}"
  !insertmacro ReplaceInFile "${INSTAPP}\mysql\my.ini" "3306" "${DBMSPORT}"
  FileOpen $1 "${INSTAPP}\migrate.cmd" "w"
  FileWrite $1 'cd "${INSTAPP}\apps\ekylibre"$\r$\n'
  FileWrite $1 '"${INSTAPP}\ruby\bin\ruby" "${INSTAPP}\ruby\bin\rake" db:migrate RAILS_ENV=production$\r$\n'
  FileClose $1

  ; Mise en place de la copie de sauvegarde de la base de données  
  Delete ${INSTAPP}\apps\ekylibre\config\database.yml
  Rename ${INSTAPP}\apps\ekylibre\config\database.mysql.yml ${INSTAPP}\apps\ekylibre\config\database.yml
  !insertmacro ReplaceInFile "${INSTAPP}\apps\ekylibre\config\database.yml" "__username__" "$username"
  !insertmacro ReplaceInFile "${INSTAPP}\apps\ekylibre\config\database.yml" "__password__" "$password"
  !insertmacro ReplaceInFile "${INSTAPP}\apps\ekylibre\config\database.yml" "3306" "${DBMSPORT}"
  RMDir /r ${DATADIR}
  ${If} $app_dir == ""
    DetailPrint "Mise en place d'une nouvelle base"
    Rename ${INSTAPP}\mysql\data ${DATADIR}
  ${Else}
    DetailPrint "Récupération de la sauvegarde"
    Rename ${BACKUP}\data ${DATADIR}
    RMDir /r ${INSTAPP}\apps\ekylibre\private
    Rename ${BACKUP}\documents ${INSTAPP}\apps\ekylibre\private
    RMDir /r ${BACKUP}
  ${EndIf}
   
  ; Write the installation path and uninstall keys into the registry
  WriteUninstaller "${INSTAPP}\uninstall.exe"   ; build uninstall program
  WriteRegStr HKLM "Software\${APP}" ""             "${INSTAPP}"
  WriteRegStr HKLM "Software\${APP}" "InstallDir"   "$INSTDIR"
  WriteRegStr HKLM "Software\${APP}" "Version"      "${VERSION}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP}" "DisplayName" "${APP} (Supprimer seulement)"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP}" "UninstallString" '"${INSTAPP}\uninstall.exe"'

  ; Mise à jour de la variable PATH
  ${EnvVarUpdate} $0 "PATH" "A" "HKLM" "${INSTAPP}\ruby\bin" 

  ; Lancement de la base de données
  SimpleSC::InstallService "EkyMySQL" "${APP} DBMS" "16" "2" '"${INSTAPP}\mysql\bin\mysqld.exe" --defaults-file="${INSTAPP}\mysql\my.ini" EkyMySQL'  "" "" ""
  Pop $0
  ${If} $0 <> 0
    MessageBox MB_OK "Installation du service impossible"  
  ${EndIf}
  SimpleSC::StartService "EkyMySQL" ""

  ; (Ré-)Initialisation et migration
  ${If} $app_dir == ""
    ExecWait '"${INSTAPP}\mysql\bin\mysql" -u root -e "CREATE DATABASE ekylibre_production"'
    ExecWait '"${INSTAPP}\mysql\bin\mysql" -u root -e "CREATE USER $username@localhost IDENTIFIED BY $\'$password$\'"'
  ${Else}
    ExecWait '"${INSTAPP}\mysql\bin\mysql" -u root -e "SET PASSWORD FOR $username@localhost = PASSWORD($\'$password$\')"'
  ${EndIf}
  ExecWait '"${INSTAPP}\mysql\bin\mysql" -u root -e "GRANT ALL PRIVILEGES ON ekylibre_production.* TO $username@localhost"'
  ExecWait '"${INSTAPP}\migrate.cmd" "${INSTAPP}"'

  ; Ekylibre Service
  SimpleSC::InstallService "EkyService" "${APP} WS" "16" "2"  '"${INSTAPP}/ruby/bin/mongrel_service.exe" single -e production -p ${WSPORT} -a 0.0.0.0 -l "log/mongrel.log" -P "log/mongrel.pid" -c "${INSTAPP}/apps/ekylibre" -t 0 -r "public" -n 1024' "EkyMySQL" "" ""
  Pop $0
  ${If} $0 <> 0
    MessageBox MB_OK "Installation du service impossible"  
  ${EndIf}
  SimpleSC::StartService "EkyService" ""

  ; Mise en place des raccourcis
  CreateDirectory "$SMPROGRAMS\${APP}"
  CreateShortCut  "$SMPROGRAMS\${APP}\Licence publique générale GNU 3.lnk" "${INSTAPP}\apps\ekylibre\doc\license.txt"
  CreateShortCut  "$SMPROGRAMS\${APP}\Désinstaller ${APP}.lnk" "${INSTAPP}\uninstall.exe"     
  ; File ${RESOURCES}\${APP}.url
  FileOpen $1 "$SMPROGRAMS\${APP}\${APP}.url" "w"
  FileWrite $1 "[InternetShortcut]$\r$\n"
  FileWrite $1 "URL=http://localhost:${WSPORT}/$\r$\n"
  FileWrite $1 "IconFile=${INSTAPP}\apps\ekylibre\public\images\ekone.ico$\r$\n"
  FileWrite $1 "IconIndex=0$\r$\n"
  FileClose $1
  ; File ${RESOURCES}\Website.url
  FileOpen $1 "$SMPROGRAMS\${APP}\Site officiel.url" "w"
  FileWrite $1 "[InternetShortcut]$\r$\n"
  FileWrite $1 "URL=http://www.ekylibre.org/$\r$\n"
  FileClose $1
SectionEnd


Section "Uninstall"
  SetShellVarContext all
  SetOutPath $INSTDIR

  ; Mise à jour de la base de registre
  SimpleSC::StopService   "EkyService"
  SimpleSC::RemoveService "EkyService"
  SimpleSC::StopService   "EkyMySQL"
  SimpleSC::RemoveService "EkyMySQL"

  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP}"
  DeleteRegKey HKLM "Software\${APP}"

  ; Mise à jour de la variable PATH
  ${un.EnvVarUpdate} $0 "PATH" "R" "HKLM" "${INSTAPP}\ruby\bin" 
  
  ; Suppression des programmes
  RMDir /r $SMPROGRAMS\${APP}
  RMDir /r ${INSTAPP}\mysql
  RMDir /r ${INSTAPP}\ruby
  RMDir /r ${INSTAPP}\migrate.cmd
  RMDir /r ${INSTAPP}\uninstall.exe

  DetailPrint "Les fichiers ont été conservés dans ${INSTAPP}"
SectionEnd
 