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
sudo apt install -y python-is-python3 python3-pip python3-venv htop btop tmux fish gpg neofetch wget curl

echo "Installo alcuni font..."
mkdir tmp_font
pushd tmp_font

font_baseurl="https://github.com/ryanoasis/nerd-fonts/releases/latest/download"

wget -q --show-progress "$font_baseurl/CommitMono.tar.xz"
wget -q --show-progress "$font_baseurl/FiraCode.tar.xz"
wget -q --show-progress "$font_baseurl/Hack.tar.xz"
wget -q --show-progress "$font_baseurl/Hasklig.tar.xz"
wget -q --show-progress "$font_baseurl/JetBrainsMono.tar.xz"
wget -q --show-progress "$font_baseurl/Mononoki.tar.xz"
wget -q --show-progress "$font_baseurl/RobotoMono.tar.xz"
wget -q --show-progress "$font_baseurl/UbuntuMono.tar.xz"

for font in *; do
    tar xJf "$font"
done

mkdir -p ~/.local/share/fonts
mv *.ttf *.otf ~/.local/share/fonts

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

echo "Installo rustup.rs per Alacritty..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
rustup override set stable
rustup update stable

echo "Installo Alacritty..."
mkdir -p ~/myprograms
pushd ~/myprograms
rm_folder_if_exists alacritty
git clone https://github.com/alacritty/alacritty.git
pushd alacritty

sudo apt install -y cmake pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev python3 gzip scdoc

if [[ $XDG_SESSION_TYPE == "x11" ]]; then
    cargo build --release --no-default-features --features=x11
elif [[ $XDG_SESSION_TYPE == "wayland" ]]; then
    cargo build --release --no-default-features --features=wayland
else
    echo "Display manager non riconosciuto (non è X11 o Wayland), installo tutte le feature"
    cargo build --release
fi

if [[ ! $(infocmp alacritty) ]]; then
    sudo tic -xe alacritty,alacritty-direct extra/alacritty.info
fi

sudo cp target/release/alacritty /usr/local/bin # or anywhere else in $PATH
sudo cp extra/logo/alacritty-term.svg /usr/share/pixmaps/Alacritty.svg
sudo desktop-file-install extra/linux/Alacritty.desktop
sudo update-desktop-database

sudo mkdir -p /usr/local/share/man/man1
sudo mkdir -p /usr/local/share/man/man5
scdoc <extra/man/alacritty.1.scd | gzip -c | sudo tee /usr/local/share/man/man1/alacritty.1.gz >/dev/null
scdoc <extra/man/alacritty-msg.1.scd | gzip -c | sudo tee /usr/local/share/man/man1/alacritty-msg.1.gz >/dev/null
scdoc <extra/man/alacritty.5.scd | gzip -c | sudo tee /usr/local/share/man/man5/alacritty.5.gz >/dev/null
scdoc <extra/man/alacritty-bindings.5.scd | gzip -c | sudo tee /usr/local/share/man/man5/alacritty-bindings.5.gz >/dev/null

echo "Configuro fish per Alacritty..."
fish -c 'mkdir -p $fish_complete_path[1]; cp extra/completions/alacritty.fish $fish_complete_path[1]/alacritty.fish'

go_to_basedir

echo "Installo i temi di Alacritty..."
rm_folder_if_exists ~/.config/alacritty/themes
mkdir -p ~/.config/alacritty/themes
git clone https://github.com/alacritty/alacritty-theme ~/.config/alacritty/themes

echo "Configuro Alacritty..."
backup_if_exists ~/.config/alacritty/alacritty.toml
cp ./alacritty.toml ~/.config/alacritty/alacritty.toml

echo "Installo gli shell color script..."
pushd ~/myprograms
rm_folder_if_exists shell-color-scripts
git clone https://gitlab.com/dwt1/shell-color-scripts.git
pushd shell-color-scripts
sudo make install
sudo cp completions/colorscript.fish /usr/share/fish/vendor_completions.d # optional for fish shell completion

go_to_basedir

# Aggiungo questo file che definisce alcuni colori usati da uno dei color script
cat ./.Xresources >> ~/.Xresources

mkdir -p ~/.config/fish/functions
backup_if_exists ~/.config/fish/functions/fish_greeting.fish
cp ./fish_greeting.fish ~/.config/fish/functions/fish_greeting.fish
cp ./light-dark.txt ~/.config/alacritty/light-dark.txt
cp ./alacritty-dark.fish ./alacritty-light.fish ~/.config/fish/functions

echo "Installo Starship..."
curl -sS https://starship.rs/install.sh | sh -s -- -y
backup_if_exists ~/.config/starship.toml
cp ./starship.toml ~/.config/starship.toml

mkdir -p ~/.config/fish
backup_if_exists ~/.config/fish/config.fish
cp ./config.fish ~/.config/fish/config.fish

echo "Finito! Puoi provare il nuovo terminale!"
alacritty -e fish
echo -e "Se il terminale è molto grande, aggiungi:\nexport WINIT_X11_SCALE_FACTOR=1\nal file /etc/profile"
