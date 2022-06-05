#!/usr/bin/env bash

LINKS_GO_HERE=~/Steam
STEAM_COMPATDATA_PATH=~/.local/share/Steam/steamapps/compatdata
STEAM_APPMANIFEST_PATH=~/.local/share/Steam/steamapps
STEAM_USERDATA_PATH=~/.local/share/Steam/userdata
STEAM_INSTALL_PATH=~/.local/share/Steam/steamapps/common/

read -r -d '' STEAM_IGNORE_DIRECTORIES <<EOM
Downloads
Music
My Music
My Pictures
My Videos
Pictures
Templates
Videos
Microsoft
CryptnetUrlCache
EOM

function containsElement() {
  local e match="$1"
  shift
  for e; do
    [[ "$e" == "$match" ]] && return 0
  done
  return 1
}

function createLink() {
  local parentDir="$1"
  local targetDir="$2"
  ln -s "$targetDir" "$parentDir"
  echo "  Created Link $parentDir -> $targetDir"
}

function createLinkIfTargetExists() {
  local parentDir="$1"
  local targetDir="$2"
  [[ ! -d "$targetDir" ]] && echo "  Target directory does not exist: $targetDir" && return
  createLink "$parentDir" "$targetDir"
}

function createLinksWhenRelevant() {
  local appName="$1"
  local directory="$2"
  local linkName="${3:-$(basename -- "$directory")}"

  local listOfSubdirs
  listOfSubdirs="$(ls "$directory" | grep -vFx "$STEAM_IGNORE_DIRECTORIES")"

  [[ -z "$listOfSubdirs" ]] && echo "  No interesting subdirectories found in $directory" && return

  echo "$listOfSubdirs" | while read -r targetDirName; do
    local parentDir="$LINKS_GO_HERE/$appName/$linkName"
    local targetDir="$directory/$targetDirName"
    createLink "$parentDir" "$targetDir"
  done
}

function createPfxLinks() {
  local appName="$1"
  local directory="$2"

  mkdir -p "$LINKS_GO_HERE/$appName"

  local driveC="$directory"/pfx/drive_c
  createLinkIfTargetExists "$LINKS_GO_HERE/$appName/pfx_DriveC" "$driveC"

  local documentsPath="$directory"/pfx/drive_c/users/steamuser/Documents
  # When documentPath that we assumed does not exists, skip it
  if [[ -d "$documentsPath" && ! -L "$documentsPath" ]]; then
    createLinksWhenRelevant "$appName" "$documentsPath" "pfx_Documents"
  else
    echo "  No documents directory found"
  fi

  local myDocumentsPath="$directory"/pfx/drive_c/users/steamuser/My\ Documents
  # When my documents path that we assumed does not exists, skip it
  if [[ -d "$myDocumentsPath" && ! -L "$myDocumentsPath" ]]; then
    createLinksWhenRelevant "$appName" "$myDocumentsPath" "pfx_MyDocuments"
  else
    echo "  No my documents directory found"
  fi

  local appdataPath="$directory"/pfx/drive_c/users/steamuser/AppData/LocalLow
  # When appdata that we assumed does not exists, skip it
  if [[ -d "$appdataPath" && ! -L "$appdataPath" ]]; then
    createLinksWhenRelevant "$appName" "$appdataPath" "pfx_AppData_LocalLow"
  else
    echo "  No appdata locallow directory found"
  fi

  local appdataPath="$directory"/pfx/drive_c/users/steamuser/AppData/Roaming
  # When appdata that we assumed does not exists, skip it
  if [[ -d "$appdataPath" && ! -L "$appdataPath" ]]; then
    createLinksWhenRelevant "$appName" "$appdataPath" "pfx_AppData_Roaming"
  else
    echo "  No appdata roaming directory found"
  fi
}

function createUserdataLinks() {
  local appName="$1"
  local appId="$2"

  local directory
  for directory in "$STEAM_USERDATA_PATH"/*/; do
    # When not a directory, skip it
    [[ -L "${directory%/}" ]] && echo "  Not a directory: $directory" && continue

    local userConfig="$directory/config/localconfig.vdf"
    local userId="$(basename -- "$directory")"
    local userName="$(grep -oP '(?<="PersonaName"\t\t).*' "$userConfig" | tr "\"/><|:&" " " | sed 's/ //g')"

    local gameUserdataDir="$directory$appId"

    [[ ! -d "$gameUserdataDir" ]] && echo "  Target directory does not exist: $gameUserdataDir" && continue
    mkdir -p "$LINKS_GO_HERE/$appName/steam_userdata/"
    createLink "$LINKS_GO_HERE/$appName/steam_userdata/$userName" "$directory$appId"

  done
}

function create() {
  local appManifest
  for appManifest in "$STEAM_APPMANIFEST_PATH/"*.acf; do
    local appId="$(grep -oP '(?<="appid"\t\t).*' "$appManifest" | sed 's/"//g')"
    local appName="$(grep -oP '(?<="name"\t\t).*' "$appManifest" | sed 's/"//g')"
    local installDirName="$(grep -oP '(?<="installdir"\t\t).*' "$appManifest" | sed 's/"//g')"
    local compatdataDir="$STEAM_COMPATDATA_PATH/$appId"

    # When Proton, Steam Linux runtime or Steamworks, skip it
    [[ $appName == Proton* ]] && echo "  Ignored because this: $appId is called: $appName" && continue
    [[ $appName == "Steam Linux"* ]] && echo "  Ignored because this: $appId is called: $appName" && continue
    [[ $appName == Steamworks* ]] && echo "  Ignored because this: $appId is called: $appName" && continue

    echo "Working on - id: $appId name: $appName compatdata: $compatdataDir"

    createPfxLinks "$appName" "$compatdataDir"
    createUserdataLinks "$appName" "$appId"

    # When we find an installdir in appManifest, lets link it as well
    [[ ! -z "$installDirName" ]] && createLink "$LINKS_GO_HERE/$appName/steam_localFiles" "$STEAM_INSTALL_PATH$installDirName"

    echo " "
    echo " "
  done
}

function cleanup() {
  # Remove old links
  [[ -d "$LINKS_GO_HERE" ]] && rm -vr "$LINKS_GO_HERE"

  # Create directory for links, if it doesn't exist yet
  [[ ! -d "$LINKS_GO_HERE" ]] && mkdir -p "$LINKS_GO_HERE"
  echo " "
  echo " "
}

cleanup
create
