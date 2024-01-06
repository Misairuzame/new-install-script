function alacritty-light
    set -l light_theme (grep LIGHT ~/.config/alacritty/light-dark.txt | cut -f2 -d'=')
    set -l dark_theme (grep DARK ~/.config/alacritty/light-dark.txt | cut -f2 -d'=')
    grep $dark_theme ~/.config/alacritty/alacritty.toml | grep -qE '^#'
    and grep $light_theme ~/.config/alacritty/alacritty.toml | grep -qvE '^#'
    and echo "Alacritty è già impostato al tema chiaro"
    or sed -i "/$dark_theme/s/^/#/g" ~/.config/alacritty/alacritty.toml
    and sed -i "/$light_theme/s/^#//g" ~/.config/alacritty/alacritty.toml
end
