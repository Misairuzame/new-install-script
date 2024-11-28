if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Changing "ls" to "eza"
alias ls='eza -al --color=always --group-directories-first --icons' # my preferred listing
alias la='eza -a --color=always --group-directories-first --icons'  # all files and dirs
alias ll='eza -l --color=always --group-directories-first --icons'  # long format
alias lt='eza -aT --color=always --group-directories-first --icons' # tree listing
alias l.='eza -ald --color=always --group-directories-first --icons .*' # only dot files and folders

# Ip colorato
alias ip='ip --color'

# Less colorato
alias less='less -R'

# Per risolvere problemi con SSH e Bash
if [ $TERM = "alacritty" ]; alias ssh='TERM=xterm-256color command ssh'; alias bash='TERM=xterm-256color command bash'; end

# Starship prompt
starship init fish | source
