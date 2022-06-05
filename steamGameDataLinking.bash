#!/usr/bin/env bash

LINKS_GO_HERE=~/Steam
STEAM_COMPATDATA_PATH=~/.local/share/Steam/steamapps/compatdata
STEAM_APPMANIFEST_PATH=~/.local/share/Steam/steamapps

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
  echo "Created Link $parentDir -> $targetDir"
}

function createLinkIfTargetExists() {
  local parentDir="$1"
  local targetDir="$2"
  [[ ! -d "$targetDir" ]] && echo "Target directory does not exist: $targetDir" && return
  createLink "$parentDir" "$targetDir"
}

function createLinksWhenRelevant() {
  local appName="$1"
  local directory="$2"
  local linkName="${3:-$(basename -- "$directory")}"

  local listOfSubdirs
  listOfSubdirs="$(ls "$directory" | grep -vFx "$STEAM_IGNORE_DIRECTORIES")"

  [[ -z "$listOfSubdirs" ]] && echo "No interesting subdirectories found in $directory" && return

  echo "$listOfSubdirs" | while read -r targetDirName; do
    local parentDir="$LINKS_GO_HERE/$appName/$linkName"
    local targetDir="$directory/$targetDirName"
    createLink "$parentDir" "$targetDir"
  done

  #echo "$listOfSubdirs" | while read -r targetDirName; do
  #  local fullTargetParent="$LINKS_GO_HERE/$appName/$linkName"
  #  [[ ! -d "$fullTargetParent" ]] && mkdir -p "$fullTargetParent"
  #  local fullTargetDir="$directory/$targetDirName"
  #  echo "$fullTargetDir"
  #  local fullDirectParentDir="$LINKS_GO_HERE/$appName/$linkName/$targetDirName"
  #  createLink "$fullDirectParentDir" "$fullTargetDir"
  #done
}

function createUserdataLinks() {
  local appName="$1"
  local directory="$2"
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
    echo "No documents directory found"
  fi

  local myDocumentsPath="$directory"/pfx/drive_c/users/steamuser/My\ Documents
  # When my documents path that we assumed does not exists, skip it
  if [[ -d "$myDocumentsPath" && ! -L "$myDocumentsPath" ]]; then
    createLinksWhenRelevant "$appName" "$myDocumentsPath" "pfx_MyDocuments"
  else
    echo "No my documents directory found"
  fi

  local appdataPath="$directory"/pfx/drive_c/users/steamuser/AppData/LocalLow
  # When appdata that we assumed does not exists, skip it
  if [[ -d "$appdataPath" && ! -L "$appdataPath" ]]; then
    createLinksWhenRelevant "$appName" "$appdataPath" "pfx_AppData_LocalLow"
  else
    echo "No appdata locallow directory found"
  fi

  local appdataPath="$directory"/pfx/drive_c/users/steamuser/AppData/Roaming
  # When appdata that we assumed does not exists, skip it
  if [[ -d "$appdataPath" && ! -L "$appdataPath" ]]; then
    createLinksWhenRelevant "$appName" "$appdataPath" "pfx_AppData_Roaming"
  else
    echo "No appdata roaming directory found"
  fi
}

function create() {
  local appManifest
  for appManifest in "$STEAM_APPMANIFEST_PATH/"*.acf; do
    local appid="$(grep -oP '(?<="appid"\t\t).*' "$appManifest" | sed 's/"//g')"
    local appName="$(grep -oP '(?<="name"\t\t).*' "$appManifest" | sed 's/"//g')"
    local compatdataDir="$STEAM_COMPATDATA_PATH/$appid"

    # When Proton, skip it
    [[ $appName == Proton* ]] && echo "Ignored because this: $appid is called: $appName" && continue

    echo "Working on - id: $appid name: $appName compatdata: $compatdataDir"

    createPfxLinks "$appName" "$compatdataDir"
    createUserdataLinks "$appName" "$compatdataDir"

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
