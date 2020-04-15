#!/usr/bin/env bash
#
# Sccript for setting up Dotfiles

set -euo pipefail

DOTFILES_DIR="${HOME}/.dotfiles/"

dotfiles(){
   /usr/bin/git --git-dir="${HOME}/.dotfiles/" --work-tree="$HOME" "$@"
}

# Clone dotfiles repos into new dir ${HOME}/.dotfiles
donwload_dotfiles(){
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        git clone --bare https://github.com/ahmadkaouk/Dotfiles.git "$DOTFILES_DIR/"
    fi
}

checkout_dotfiles(){
    if dotfiles checkout; then
        echo "Checked out dotfiles"
    else
        echo "Backup old dotfiles..."
        mkdir -p .dotfiles-backup && \
        dotfiles checkout 2>&1 | egrep "\s+\." | awk '{print $1}' | \
        xargs -I{} mv {} .dotfiles-backup/{}
        dotfiles checkout
    fi
}

main(){
    echo ".dotfiles" >> "${HOME}/.gitignore"
    # Clone dotfiles repos to home directory
    donwload_dotfiles
    # Checkout dotfiles (Backup existing config files if exist)
    checkout_dotfiles
    # Hide untracked files
    dotfiles config status.showUntrackedFiles "no"
}

main