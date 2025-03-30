#!/bin/bash

#set -x
set -eu

mysep="================================== "

function go_to_basedir() {
    cd "$(dirs -l -0)" && dirs -c
}

function backup_if_exists() {
    FILE=$1
    if [[ -f $FILE ]]; then
        mv "$FILE" "$FILE.bak"
        echo "${mysep}Backuppato $FILE in $FILE.bak"
    fi
}

function rm_folder_if_exists() {
    FOLDER=$1
    if [[ -d $FOLDER ]]; then
        rm -rf "$FOLDER"
        echo "${mysep}Rimossa la cartella $FOLDER"
    fi
}

as_root="sudo"
if [[ "$(id -u)" == "0" ]]; then
    # Sono già root
    as_root=""
elif [[ ! "$(which sudo)" ]]; then
    # Sudo non è installato
    echo "${mysep}sudo non è installato, installalo e riprova."
    exit 1
elif [[ ! "$(sudo -l)" ]]; then
    # L'utente non può usare sudo
    echo "${mysep}Non puoi usare sudo, configuralo e riprova."
    exit 1
fi

# Controllo se sono in un ambiente desktop o headless
if [[ -z "${XDG_SESSION_TYPE+x}" && -z "${DESKTOP_SESSION+x}" ]]; then
    desktop_environment=""
else
    desktop_environment="1"
fi

echo "${mysep}Aggiorno il sistema..."
$as_root apt update && $as_root apt upgrade -y

echo "${mysep}Imposto l'ora corretta..."
DEBIAN_FRONTEND=noninteractive $as_root apt install -y tzdata
$as_root ln -sf /usr/share/zoneinfo/Europe/Rome /etc/localtime
$as_root dpkg-reconfigure --frontend noninteractive tzdata

echo "${mysep}Installo alcuni pacchetti..."
$as_root apt install -y git python-is-python3 python3-pip python3-venv htop btop fish wget curl
# fastfetch non è ancora nelle repo ufficiali

if [[ -n "$desktop_environment" ]]; then
    echo "${mysep}Installo alcuni Nerd Font..."
    mkdir tmp_font
    pushd tmp_font

    nerd_font_baseurl="https://github.com/ryanoasis/nerd-fonts/releases/latest/download"

    font_names=("CommitMono" "FiraCode" "Hack" "JetBrainsMono" "Mononoki" "RobotoMono" "UbuntuMono")

    for font_name in "${font_names[@]}"; do
        if [[ $(fc-list : family | grep -c "$font_name Nerd Font") == 0 ]]; then
            wget -q --show-progress "$nerd_font_baseurl/$font_name.tar.xz"
        fi
    done

    # Hasklug is downloaded as Hasklig
    if [[ $(fc-list : family | grep -c "Hasklug Nerd Font") == 0 ]]; then
        wget -q --show-progress "$nerd_font_baseurl/Hasklig.tar.xz"
    fi

    if [[ $(find ./*.tar.xz 2>/dev/null | wc -l) -gt 0 ]]; then
        for font in *; do
            tar xJf "$font"
        done
    fi

    mkdir -p ~/.local/share/fonts
    if [[ $(find ./*.ttf 2>/dev/null | wc -l) -gt 0 ]]; then
        mv ./*.ttf ~/.local/share/fonts
    fi
    if [[ $(find ./*.otf 2>/dev/null | wc -l) -gt 0 ]]; then
        mv ./*.otf ~/.local/share/fonts
    fi

    popd

    fc-cache --really-force
    echo "${mysep}Font installati:"
    fc-list : family | grep -i "nerd" | awk -F ',' '{print $1}' | sort | uniq
    rm -r tmp_font

    $as_root apt install -y fonts-noto fonts-noto-color-emoji
else
    echo "${mysep}Ambiente headless, non installo i font"
fi

echo "${mysep}Installo eza..."
$as_root mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | $as_root gpg --yes --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | $as_root tee /etc/apt/sources.list.d/gierens.list
$as_root chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
$as_root apt update
$as_root apt install -y eza

go_to_basedir

if [[ -n "$desktop_environment" ]]; then
    echo "${mysep}Installo Ghostty..."
    source /etc/os-release
    ARCH=$(dpkg --print-architecture)
    GHOSTTY_DEB_URL=$(
        curl -s https://api.github.com/repos/mkasberg/ghostty-ubuntu/releases/latest |
            grep -oP "https://github.com/mkasberg/ghostty-ubuntu/releases/download/[^\s/]+/ghostty_[^\s/_]+_${ARCH}_${VERSION_ID}.deb"
    )
    GHOSTTY_DEB_FILE=$(basename "$GHOSTTY_DEB_URL")
    curl -LO "$GHOSTTY_DEB_URL"
    $as_root dpkg -i "$GHOSTTY_DEB_FILE"
    rm "$GHOSTTY_DEB_FILE"

    mkdir -p "$HOME/.config/ghostty"
    cp ghostty-config "$HOME/.config/ghostty/config"

    go_to_basedir
else
    echo "${mysep}Ambiente headless, non installo Ghostty"
fi

echo "${mysep}Installo gli shell color script..."
mkdir ~/myprograms
pushd ~/myprograms
rm_folder_if_exists shell-color-scripts
git clone https://github.com/Misairuzame/shell-color-scripts.git
pushd shell-color-scripts
$as_root make install
$as_root cp completions/colorscript.fish /usr/share/fish/vendor_completions.d # optional for fish shell completion

go_to_basedir

echo "${mysep}Aggiungo la funzione fish_greeting..."
mkdir -p ~/.config/fish/functions
backup_if_exists ~/.config/fish/functions/fish_greeting.fish
cp ./fish_greeting.fish ~/.config/fish/functions/fish_greeting.fish

go_to_basedir

echo "${mysep}Installo Starship..."
curl -sS https://starship.rs/install.sh | sh -s -- -y
backup_if_exists ~/.config/starship.toml
cp ./starship.toml ~/.config/starship.toml

mkdir -p ~/.config/fish
backup_if_exists ~/.config/fish/config.fish
cp ./config.fish ~/.config/fish/config.fish

if [[ -n "$desktop_environment" ]]; then
    echo "${mysep}Finito! Puoi provare il nuovo terminale!"
    ghostty -e fish
else
    echo "${mysep}Finito!"
    fish
fi
