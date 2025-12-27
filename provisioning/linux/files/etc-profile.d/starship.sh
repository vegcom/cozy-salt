#/etc/profile.d/starship.sh
if ! which starship &>/dev/null ; then
    sh <(curl -sS https://starship.rs/install.sh) --force
fi

if [[ ! -f $HOME/.config/starship.toml ]]; then
    # leverage the Twilite theme from my GitHub repo to make it look like a purple paradise
    mkdir -p $HOME/.config
    # download the Twilite theme from my GitHub
    # this is a custom starship.toml file that I've created and made available on GitHub
    wget -O ~/.config/starship.toml https://raw.githubusercontent.com/vegcom/Starship-Twilite/main/starship.toml

fi

eval "$(starship init bash)"