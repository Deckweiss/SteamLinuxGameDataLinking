#!/usr/bin/env bash

mkdir ~/.steamGameDataLinking
cd ~/.steamGameDataLinking
curl https://raw.githubusercontent.com/Deckweiss/SteamLinuxGameDataLinking/main/steamGameDataLinking.bash -O
chmod +x ~/.steamGameDataLinking/steamGameDataLinking.bash

cd ~/.config/autostart/
curl https://raw.githubusercontent.com/Deckweiss/SteamLinuxGameDataLinking/main/steamGameDataLinking.desktop -O
chmod +x ~/.config/autostart/steamGameDataLinking.desktop

#curl https://raw.githubusercontent.com/Deckweiss/SteamLinuxGameDataLinking/main/install.bash | bash