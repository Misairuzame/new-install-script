#!/bin/bash

#set -x
set -eu

echo "Aggiorno il sistema..."
sudo apt update && sudo apt upgrade -y

echo "Installo alcuni pacchetti..."
sudo apt install -y python-is-python3 python3-venv htop btop tmux fish gpg neofetch wget curl

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

for font in *;
do
    tar xJf $font
done

mkdir -p ~/.local/share/fonts
mv *.ttf ~/.local/share/fonts

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
if [[ -d alacritty ]];
then
    rm -rf alacritty
fi
git clone https://github.com/alacritty/alacritty.git
pushd alacritty

sudo apt install -y cmake pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev python3 gzip scdoc

if [[ $(echo $XDG_SESSION_TYPE) == "x11" ]];
then
    cargo build --release --no-default-features --features=x11
elif [[ $(echo $XDG_SESSION_TYPE) == "wayland" ]];
then
    cargo build --release --no-default-features --features=wayland
else
    echo "Display manager non riconosciuto (non è X11 o Wayland), installo tutte le feature"
    cargo build --release
fi

if [[ ! $(infocmp alacritty) ]];
then
    sudo tic -xe alacritty,alacritty-direct extra/alacritty.info
fi

sudo cp target/release/alacritty /usr/local/bin # or anywhere else in $PATH
sudo cp extra/logo/alacritty-term.svg /usr/share/pixmaps/Alacritty.svg
sudo desktop-file-install extra/linux/Alacritty.desktop
sudo update-desktop-database

sudo mkdir -p /usr/local/share/man/man1
sudo mkdir -p /usr/local/share/man/man5
scdoc < extra/man/alacritty.1.scd | gzip -c | sudo tee /usr/local/share/man/man1/alacritty.1.gz > /dev/null
scdoc < extra/man/alacritty-msg.1.scd | gzip -c | sudo tee /usr/local/share/man/man1/alacritty-msg.1.gz > /dev/null
scdoc < extra/man/alacritty.5.scd | gzip -c | sudo tee /usr/local/share/man/man5/alacritty.5.gz > /dev/null
scdoc < extra/man/alacritty-bindings.5.scd | gzip -c | sudo tee /usr/local/share/man/man5/alacritty-bindings.5.gz > /dev/null

cd "$(dirs -l -0)" && dirs -c

echo "Installo i temi di Alacritty..."
if [[ -d ~/.config/alacritty/themes ]];
then
    rm -rf ~/.config/alacritty/themes
fi
mkdir -p ~/.config/alacritty/themes
git clone https://github.com/alacritty/alacritty-theme ~/.config/alacritty/themes

echo "Configuro Alacritty..."
if [[ -f ~/.config/alacritty/alacritty.toml ]];
then
    mv ~/.config/alacritty/alacritty.toml ~/.config/alacritty/alacritty.toml.bak
fi

cat <<EOF > ~/.config/alacritty/alacritty.toml
import = ["~/.config/alacritty/themes/themes/argonaut.toml"]

[font.bold]
family = "FiraCode Nerd Font"

[font.bold_italic]
family = "FiraCode Nerd Font"

[font.italic]
family = "FiraCode Nerd Font"

[font.normal]
family = "FiraCode Nerd Font"

[window.dimensions]
columns = 125
lines = 35
EOF

echo "Configuro fish..."
fish -c 'mkdir -p $fish_complete_path[1]; cp extra/completions/alacritty.fish $fish_complete_path[1]/alacritty.fish'
mkdir -p ~/.config/fish

cat <<EOF >> ~/.config/fish/config.fish

# Changing "ls" to "eza"
alias ls='eza -al --color=always --group-directories-first --icons'
alias la='eza -a --color=always --group-directories-first --icons'
alias ll='eza -l --color=always --group-directories-first --icons'
alias lt='eza -aT --color=always --group-directories-first --icons'
alias l.='eza -a | grep -E "^\."'
EOF

echo "Installo gli shell color scripts..."
pushd ~/myprograms
if [[ -d shell-color-scripts ]];
then
    rm -rf shell-color-scripts
fi
git clone https://gitlab.com/dwt1/shell-color-scripts.git
pushd shell-color-scripts
sudo make install

# optional for fish shell completion
sudo cp completions/colorscript.fish /usr/share/fish/vendor_completions.d

cd "$(dirs -l -0)" && dirs -c

mkdir -p ~/.config/fish/functions
cat <<EOF > ~/.config/fish/functions/fish_greeting.fish
function fish_greeting
    if set -q fish_private_mode
        colorscript random
        echo "fish is running in private mode, history will not be persisted."
    else
        colorscript random
    end
end
EOF

echo "Installo Starship..."
curl -sS https://starship.rs/install.sh | sh -s -- -y

cat <<EOF >> ~/.config/fish/config.fish

# Starship prompt
starship init fish | source
EOF

cat <<'EOF' > ~/.config/starship.toml
## FIRST LINE/ROW: Info & Status
# First param ─┌
[username]
format = " [╭─$user]($style)@"
style_user = "bold green"
style_root = "bold yellow"
show_always = true

# Second param
[hostname]
format = "[$hostname]($style) in "
style = "bold dimmed green"
trim_at = "-"
ssh_only = false
disabled = false

# Third param
[directory]
style = "purple"
truncation_length = 0
truncate_to_repo = true
truncation_symbol = "repo: "

# Before all the version info (python, nodejs, php, etc.)
[git_status]
style = "white"
ahead = "⇡${count}"
diverged = "⇕⇡${ahead_count}⇣${behind_count}"
behind = "⇣${count}"
deleted = "x"

# Last param in the first line/row
[cmd_duration]
min_time = 1
format = "took [$duration]($style)"
disabled = false


## SECOND LINE/ROW: Prompt
# Somethere at the beginning
[battery]
full_symbol = " "
charging_symbol = " "
discharging_symbol = " "
disabled = true

[[battery.display]]  # "bold red" style when capacity is between 0% and 10%
threshold = 15
style = "bold red"
disabled = true

[[battery.display]]  # "bold yellow" style when capacity is between 10% and 30%
threshold = 50
style = "bold yellow"
disabled = true

[[battery.display]]  # "bold green" style when capacity is between 10% and 30%
threshold = 80
style = "bold green"
disabled = true

# Prompt: optional param 1
[time]
format = " 🕙 $time($style)\n"
time_format = "%T"
style = "bright-white"
disabled = true

# Prompt: param 2 └─
[character]
success_symbol = " [╰─λ](bold green)"
error_symbol = " [×](bold red)"
#use_symbol_for_status = true

# SYMBOLS
[status]
symbol = "🔴"
format = '[\[$symbol$status_common_meaning$status_signal_name$status_maybe_int\]]($style)'
map_symbol = true
disabled = false

[aws]
symbol = " "

[conda]
symbol = " "

[dart]
symbol = " "

#[docker]
#symbol = " "

[elixir]
symbol = " "

[elm]
symbol = " "

[git_branch]
symbol = " "

[golang]
symbol = " "

[haskell]
symbol = " "

[hg_branch]
symbol = " "

[java]
symbol = " "

[julia]
symbol = " "

[nim]
symbol = " "

[nix_shell]
symbol = " "

[nodejs]
symbol = " "

[package]
symbol = " "

[perl]
symbol = " "

[php]
symbol = " "

[python]
symbol = " "

[ruby]
symbol = " "

[rust]
symbol = " "

[swift]
symbol = "ﯣ "
EOF

cd "$(dirs -l -0)" && dirs -c

echo "Finito! Puoi provare il nuovo terminale!"
alacritty -e fish
echo -e "Se il terminale è molto grande, aggiungi:\nexport WINIT_X11_SCALE_FACTOR=1\nal file /etc/profile"
