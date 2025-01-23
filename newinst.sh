#!/bin/bash

#set -x
set -eu

function go_to_basedir() {
    cd "$(dirs -l -0)" && dirs -c
}

function backup_if_exists() {
    FILE=$1
    if [[ -f $FILE ]]; then
        mv "$FILE" "$FILE.bak"
        echo "Backuppato $FILE in $FILE.bak"
    fi
}

function rm_folder_if_exists() {
    FOLDER=$1
    if [[ -d $FOLDER ]]; then
        rm -rf "$FOLDER"
        echo "Rimossa la cartella $FOLDER"
    fi
}

echo "Aggiorno il sistema..."
sudo apt update && sudo apt upgrade -y

echo "Installo alcuni pacchetti..."
sudo apt install -y git python-is-python3 python3-pip python3-venv htop btop fish wget curl
# fastfetch non è ancora nelle repo ufficiali

echo "Installo alcuni Nerd Font..."
mkdir tmp_font
pushd tmp_font

nerd_font_baseurl="https://github.com/ryanoasis/nerd-fonts/releases/latest/download"

font_names=("CommitMono" "FiraCode" "Hack" "JetBrainsMono" "Mononoki" "RobotoMono" "UbuntuMono")

for font_name in "${font_names[@]}"
do
    if [[ $(fc-list : family | grep -c "$font_name Nerd Font") == 0 ]]; then
        wget -q --show-progress "$nerd_font_baseurl/$font_name.tar.xz"
    fi
done

# Hasklug is downloaded as Hasklig
if [[ $(fc-list : family | grep -c "Hasklug Nerd Font") == 0 ]]; then
    wget -q --show-progress "$nerd_font_baseurl/Hasklig.tar.xz"
fi

for font in *; do
    tar xJf "$font"
done

mkdir -p ~/.local/share/fonts
mv ./*.ttf ./*.otf ~/.local/share/fonts

popd

fc-cache --really-force
echo "Font installati:"
fc-list : family | grep -i "nerd" | awk -F ',' '{print $1}' | sort | uniq
rm -r tmp_font

sudo apt install -y fonts-noto fonts-noto-color-emoji

echo "Installo eza..."
sudo mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --yes --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
sudo apt update
sudo apt install -y eza

go_to_basedir

echo "Installo Ghostty..."
source /etc/os-release
ARCH=$(dpkg --print-architecture)
GHOSTTY_DEB_URL=$(
   curl -s https://api.github.com/repos/mkasberg/ghostty-ubuntu/releases/latest | \
   grep -oP "https://github.com/mkasberg/ghostty-ubuntu/releases/download/[^\s/]+/ghostty_[^\s/_]+_${ARCH}_${VERSION_ID}.deb"
)
GHOSTTY_DEB_FILE=$(basename "$GHOSTTY_DEB_URL")
curl -LO "$GHOSTTY_DEB_URL"
sudo dpkg -i "$GHOSTTY_DEB_FILE"
rm "$GHOSTTY_DEB_FILE"

mkdir -p "$HOME/.config/ghostty"
cp ghostty-config "$HOME/.config/ghostty/config"

go_to_basedir

echo "Installo gli shell color script..."
pushd ~/myprograms
rm_folder_if_exists shell-color-scripts
git clone https://github.com/Misairuzame/shell-color-scripts.git
pushd shell-color-scripts
sudo make install
sudo cp completions/colorscript.fish /usr/share/fish/vendor_completions.d # optional for fish shell completion

go_to_basedir

echo "Aggiungo la funzione fish_greeting..."
mkdir -p ~/.config/fish/functions
backup_if_exists ~/.config/fish/functions/fish_greeting.fish
cp ./fish_greeting.fish ~/.config/fish/functions/fish_greeting.fish

go_to_basedir

echo "Installo Starship..."
curl -sS https://starship.rs/install.sh | sh -s -- -y
backup_if_exists ~/.config/starship.toml
cp ./starship.toml ~/.config/starship.toml

mkdir -p ~/.config/fish
backup_if_exists ~/.config/fish/config.fish
cp ./config.fish ~/.config/fish/config.fish

echo "Finito! Puoi provare il nuovo terminale!"
ghostty -e fish
