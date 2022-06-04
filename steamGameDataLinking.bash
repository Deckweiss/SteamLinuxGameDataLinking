#!/usr/bin/env bash

LINKS_GO_HERE=~/Steam
STEAM_COMPATDATA_PATH=~/.local/share/Steam/steamapps/compatdata
STEAM_APPMANIFEST_PATH=~/.local/share/Steam/steamapps

read -r -d '' STEAM_IGNORE_DIRECTORIES << EOM
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

function containsElement () {
  local e match="$1"
  shift
  for e; do
    [[ "$e" == "$match" ]] && return 0;
  done
  return 1
}

function createLink() {
  local parentDir="$1"
  local targetDir="$2"
  ln -s "$targetDir" "$parentDir"
  echo "Created Link $parentDir -> $targetDir"
}

function createLinksWhenRelevant() {
  local appName="$1"
  local directory="$2"
  local targetParentDirName
  targetParentDirName="$(basename -- "$directory")"

  local listOfSubdirs
  listOfSubdirs="$(ls "$directory" | grep -vFx "$STEAM_IGNORE_DIRECTORIES")"

  [[ -z "$listOfSubdirs" ]] && echo "No interesting subdirectories found in $targetParentDirName" && return

  echo "$listOfSubdirs" | while read -r targetDirName; do
    local fullTargetParent="$LINKS_GO_HERE/$appName/$targetParentDirName"
    [[ ! -d "$fullTargetParent" ]] && mkdir -p "$fullTargetParent"
    local fullTargetDir="$directory/$targetDirName"
    echo "$fullTargetDir"
    local fullDirectParentDir="$LINKS_GO_HERE/$appName/$targetParentDirName/$targetDirName"
    createLink "$fullDirectParentDir" "$fullTargetDir"
  done
}

function updateGameLinks() {
  local appName="$1"
  local directory="$2"

  local documentsPath="$directory"pfx/drive_c/users/steamuser/Documents
  # When documentPath that we assumed does not exists, skip it
  if [[ -d "$documentsPath" && ! -L "$documentsPath" ]]; then
    createLinksWhenRelevant "$appName" "$documentsPath"
  else
    echo "No documents directory found"
  fi

  local myDocumentsPath="$directory"pfx/drive_c/users/steamuser/My\ Documents
  # When my documents path that we assumed does not exists, skip it
  if [[ -d "$myDocumentsPath" && ! -L "$myDocumentsPath" ]]; then
    createLinksWhenRelevant "$appName" "$myDocumentsPath"
  else
    echo "No my documents directory found"
  fi

  local appdataPath="$directory"pfx/drive_c/users/steamuser/AppData/LocalLow
  # When appdata that we assumed does not exists, skip it
  if [[ -d "$appdataPath" && ! -L "$appdataPath" ]]; then
    createLinksWhenRelevant "$appName" "$appdataPath"
  else
    echo "No appdata directory found"
  fi
}

function update() {
  local directory
  for directory in "$STEAM_COMPATDATA_PATH"/*/; do
    # When not a directory, skip it
    [[ -L "${directory%/}" ]] && echo "Not a directory: $directory" && continue

    local appid="$(basename -- "$directory")"
    local appManifest="$STEAM_APPMANIFEST_PATH/appmanifest_$appid.acf"

    # When no appManifest found, skip it
    [[ ! -f "$appManifest" ]] && echo "No appmanifest found for: $appid" && continue

    local appName="$(grep -oP '(?<="name"\t\t).*' "$appManifest" | sed 's/"//g')"

    # When Proton, skip it
    [[ $appName == Proton* ]] && echo "Ignored because this: $appid is called: $appName" && continue

    echo "Working on - id: $appid name: $appName"

    updateGameLinks "$appName" "$directory"

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
update