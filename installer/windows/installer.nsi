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

;--------------------------------
;General

  !define APP "Ekylibre"
  !define WSPORT 4064
  !define DBMSPORT 4032

  VIAddVersionKey "ProductName" "${APP}"
  ; VIAddVersionKey "Comments" "Le logiciel de gestion des petites entreprises"
  VIAddVersionKey "CompanyName" "www.ekylibre.org"
  VIAddVersionKey "FileDescription" "${APP} ${VERSION} Installer"
  VIAddVersionKey "FileVersion" "${VERSION}"
  VIProductVersion "${VERSION}.0"


  ; Name and file
  Name "${APP}"
  OutFile "${RELEASE}.exe"

  ;Default installation folder
  InstallDir "$PROGRAMFILES\${APP}"
  
  ;Get installation folder from registry if available
  InstallDirRegKey HKLM "Software\${APP}" "InstallDir"

  BrandingText "${APP} ${VERSION}"

  ;Request application privileges for Windows Vista/7
  RequestExecutionLevel highest



  ;Interface Settings
  !define MUI_ICON "${IMAGES}\install.ico"
  ; !define MUI_UNICON "${IMAGES}\uninstall.ico"
  !define MUI_HEADERIMAGE
  !define MUI_HEADERIMAGE_RIGHT
  !define MUI_HEADERIMAGE_BITMAP "${IMAGES}\header.bmp"
  !define MUI_HEADERIMAGE_UNBITMAP "${IMAGES}\header.bmp"
  !define MUI_WELCOMEFINISHPAGE_BITMAP "${IMAGES}\welcome.bmp"
  !define MUI_UNWELCOMEFINISHPAGE_BITMAP "${IMAGES}\welcome.bmp"

  !define MUI_PAGE_HEADER_TEXT "Installation d'${APP} ${VERSION}"

  !define MUI_LICENSEPAGE_BGCOLOR FFFFFF
  !define MUI_LICENSEPAGE_BUTTON "J'accepte"

  !define MUI_ABORTWARNING
  !define MUI_ABORTWARNING_TEXT "Vous allez quitter l'installation"


;--------------------------------
;Pages
  !define MUI_WELCOMEPAGE_TITLE "Bienvenue dans le programme d'installation d'${APP}"
  !insertmacro MUI_PAGE_WELCOME

  ; !define MUI_LICENSEPAGE_RADIOBUTTONS
  ; !define MUI_LICENSEPAGE_RADIOBUTTONS_TEXT_ACCEPT "J'accepte les termes du contrat de licence"
  ; !define MUI_LICENSEPAGE_RADIOBUTTONS_TEXT_DECLINE "Je n'accepte pas les termes du contrat de licence"
  !insertmacro MUI_PAGE_LICENSE "${RESOURCES}\apps\ekylibre\doc\license.txt"

  !define MUI_DIRECTORYPAGE_TEXT_DESTINATION "$INSTDIR"
  !define MUI_DIRECTORYPAGE_VERIFYONLEAVE
  !insertmacro MUI_PAGE_DIRECTORY

  ; !define MUI_INSTFILESPAGE_FINISHHEADER_TEXT "Bravo !"
  ; !define MUI_INSTFILESPAGE_ABORTHEADER_TEXT  "Désolé !"
  !insertmacro MUI_PAGE_INSTFILES

  ;!define MUI_FINISHPAGE_NOAUTOCLOSE
  ; !define MUI_FINISHPAGE_TEXT_REBOOT "Vous devez redémarrer l'ordinateur pour que l'installation se termine."
  !define MUI_FINISHPAGE_LINK "Aller sur www.ekylibre.org"
  !define MUI_FINISHPAGE_LINK_LOCATION "http://www.ekylibre.org"
  !insertmacro MUI_PAGE_FINISH

;--------------------------------
;Uninstall pages

  ;!define MUI_UNFINISHPAGE_NOAUTOCLOSE

  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES

;--------------------------------
;Languages
  !insertmacro MUI_LANGUAGE "French"

;--------------------------------

;Sections
Var password
Var username
Var AppDir
Var InstApp
Var Backup
Var DataDir

Section
  SetOutPath $INSTDIR

  StrCpy $InstApp "$INSTDIR\${APP}-${VERSION}"
  StrCpy $Backup  "$INSTDIR\backup-${VERSION}"
  StrCpy $DataDir "$InstApp\data"


  SetShellVarContext all

  ; Suppression des anciens services
  SimpleSC::StopService   "EkyService"
  SimpleSC::RemoveService "EkyService"
  SimpleSC::StopService   "EkyMySQL"
  SimpleSC::RemoveService "EkyMySQL"

  ; Initialisation de quelques valeurs
  ReadRegStr $AppDir HKLM Software\${APP} "AppDir"
  ;${If} $AppDir == ""
  ;  IfFileExists $InstApp 0 +2
  ;    StrCpy $AppDir $InstApp
  ;${EndIf}
  StrCpy $username "ekylibre"
  pwgen::GeneratePassword 32
  Pop $password

  ; IfFileExists $InstApp 0 +2
  ;   StrCpy $AppDir $InstApp

  ; Copie de sauvegarde de la base de données si le fichier existe
  ${If} $AppDir != ""
    DetailPrint "Sauvegarde des données présentes"
    RMDir /r $Backup
    Rename $AppDir $Backup
  ${Else}
    DetailPrint "Pas de données présentes"
  ${EndIf}

  ; Mise en place du programme
  CreateDirectory $InstApp
  SetOutPath $InstApp
  File /r ${RESOURCES}/ruby
  File /r ${RESOURCES}/mysql
  File /r /x .svn ${RESOURCES}/apps
  !insertmacro ReplaceInFile "$InstApp\mysql\my.ini" "__INSTDIR__" "$InstApp"
  !insertmacro ReplaceInFile "$InstApp\mysql\my.ini" "__DATADIR__" "$DataDir"
  !insertmacro ReplaceInFile "$InstApp\mysql\my.ini" "3306" "${DBMSPORT}"
  FileOpen $1 "$InstApp\migrate.cmd" "w"
  FileWrite $1 'cd "$InstApp\apps\ekylibre"$\r$\n'
  FileWrite $1 '"$InstApp\ruby\bin\ruby" "$InstApp\ruby\bin\rake" db:migrate RAILS_ENV=production$\r$\n'
  FileClose $1

  ; Mise en place de la copie de sauvegarde de la base de données
  Delete $InstApp\apps\ekylibre\config\database.yml
  Rename $InstApp\apps\ekylibre\config\database.mysql.yml $InstApp\apps\ekylibre\config\database.yml
  !insertmacro ReplaceInFile "$InstApp\apps\ekylibre\config\database.yml" "__username__" "$username"
  !insertmacro ReplaceInFile "$InstApp\apps\ekylibre\config\database.yml" "__password__" "$password"
  !insertmacro ReplaceInFile "$InstApp\apps\ekylibre\config\database.yml" "3306" "${DBMSPORT}"
  RMDir /r $DataDir
  ${If} $AppDir == ""
    DetailPrint "Mise en place d'une nouvelle base"
    Rename $InstApp\mysql\data $DataDir
  ${Else}
    DetailPrint "Récupération de la sauvegarde"
    Rename $Backup\data $DataDir
    RMDir /r $InstApp\apps\ekylibre\private
    Rename $Backup\documents $InstApp\apps\ekylibre\private
    RMDir /r $Backup
  ${EndIf}

  ; Mise à jour de la variable PATH
  ${EnvVarUpdate} $0 "PATH" "A" "HKLM" "$InstApp\ruby\bin"

  ; Lancement de la base de données
  SimpleSC::InstallService "EkyMySQL" "${APP} DBMS" "16" "2" '"$InstApp\mysql\bin\mysqld.exe" --defaults-file="$InstApp\mysql\my.ini" EkyMySQL'  "" "" ""
  Pop $0
  ${If} $0 <> 0
    MessageBox MB_OK "Installation du service EkyMySQL impossible"
  ${EndIf}
  SimpleSC::SetServiceDescription "EkyMySQL" "Service Base de Données d'Ekylibre"
  SimpleSC::StartService "EkyMySQL" ""

  ; (Ré-)Initialisation et migration
  ${If} $AppDir == ""
    ExecWait '"$InstApp\mysql\bin\mysql" -u root -e "CREATE DATABASE ekylibre_production"'
    ExecWait '"$InstApp\mysql\bin\mysql" -u root -e "CREATE USER $username@localhost IDENTIFIED BY $\'$password$\'"'
  ${Else}
    ExecWait '"$InstApp\mysql\bin\mysql" -u root -e "SET PASSWORD FOR $username@localhost = PASSWORD($\'$password$\')"'
  ${EndIf}
  ExecWait '"$InstApp\mysql\bin\mysql" -u root -e "GRANT ALL PRIVILEGES ON ekylibre_production.* TO $username@localhost"'
  ExecWait '"$InstApp\migrate.cmd" "$InstApp"'

  ; Ekylibre Service
  SimpleSC::InstallService "EkyService" "${APP} WS" "16" "2"  '"$InstApp\ruby\bin\mongrel_service.exe" single -e production -p ${WSPORT} -a 0.0.0.0 -l "log\mongrel.log" -P "log\mongrel.pid" -c "$InstApp/apps/ekylibre" -t 0 -r "public" -n 1024' "EkyMySQL" "" ""
  Pop $0
  ${If} $0 <> 0
    MessageBox MB_OK "Installation du service EkyService impossible"
  ${EndIf}
  SimpleSC::SetServiceDescription "EkyService" "Service Web d'Ekylibre"
  SimpleSC::StartService "EkyService" ""

  SetOutPath $INSTDIR
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
  CreateShortCut  "$SMPROGRAMS\${APP}\Licence publique générale GNU 3.lnk" "$InstApp\apps\ekylibre\doc\license.txt"
  CreateShortCut  "$SMPROGRAMS\${APP}\Désinstaller ${APP}.lnk" "$InstApp\uninstall.exe"
  ; File ${RESOURCES}\${APP}.url
  FileOpen $1 "$SMPROGRAMS\${APP}\${APP} ${VERSION}.url" "w"
  FileWrite $1 "[InternetShortcut]$\r$\n"
  FileWrite $1 "URL=http://localhost:${WSPORT}/$\r$\n"
  FileWrite $1 "IconFile=$InstApp\apps\ekylibre\public\images\ekone.ico$\r$\n"
  FileWrite $1 "IconIndex=0$\r$\n"
  FileClose $1
  ; File ${RESOURCES}\Website.url
  FileOpen $1 "$SMPROGRAMS\${APP}\Site officiel.url" "w"
  FileWrite $1 "[InternetShortcut]$\r$\n"
  FileWrite $1 "URL=http://www.ekylibre.org/$\r$\n"
  FileClose $1
SectionEnd


Section "Uninstall"
  ReadRegStr $InstApp HKLM Software\${APP} "AppDir"
  SetShellVarContext all

  ; Mise à jour de la base de registre
  SimpleSC::StopService   "EkyService"
  SimpleSC::RemoveService "EkyService"
  SimpleSC::StopService   "EkyMySQL"
  SimpleSC::RemoveService "EkyMySQL"

  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP}"
  DeleteRegKey HKLM "Software\${APP}"

  ; Mise à jour de la variable PATH
  ${un.EnvVarUpdate} $0 "PATH" "R" "HKLM" "$InstApp\ruby\bin"

  ; Suppression des programmes
  RMDir /r $SMPROGRAMS\${APP}
  RMDir /r $InstApp\mysql
  RMDir /r $InstApp\ruby
  Delete $InstApp\migrate.cmd
  Delete $InstApp\uninstall.exe

  DetailPrint "Les fichiers ont été conservés dans $InstApp"
SectionEnd
 
