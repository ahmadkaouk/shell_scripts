#!/usr/bin/env bash
#
# Bootstrap sccript for setting up a new OSX machine
#
# This should be idempotent so it can be run multiple times.
#
# Steps:
# - install homebrew (if not already installed)
# - update brew
# - install packages (check Brewfile)
# - install extensions (vscode)
# - configure zsh and install oh-my-zsh
# - install and configure dotfiles

set -euo pipefail

#include ../lib
# shellcheck disable=SC1091
source ../lib/lib

check_os(){
  echo_info "Checking OS..."
  if [ "$USER_OS" != "Darwin" ]; then
    echo_error "It looks like you're using a non-UNIX system. This script
    only supports Mac. Exiting..."
    exit 1
  fi
}

install_or_update_brew(){
  if  [[ ! "$(command -v brew)" ]] ; then
    echo_info "Installing homebrew..."
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  else
    echo_info "Updating Homebrew..."
    brew update
  fi
}

install_vscode_extensions(){
    # Test if vscode is installed
    if ! hash code 2>/dev/null; then
        error_exit "VS Code is Not Installed on your Machine, install it before contine"
    else
        local extensions=(
          akamud.vscode-theme-onedark
          jolaleye.horizon-theme-vscode
          ms-vscode-remote.remote-containers
          ms-vscode-remote.remote-ssh
          ms-vscode-remote.remote-ssh-edit
          ms-vscode-remote.vscode-remote-extensionpack
          ms-vscode.cpptools
          PKief.material-icon-theme
          rafamel.subtle-brackets
          timonwong.shellcheck
        )
    
        for extension in "${extensions[@]}"; do
          if ! code --list-extensions | grep "$extension" > /dev/null; then
            code --install-extension "$extension" 
          fi
        done
    fi
}

zsh_config(){
  local shell_path;
  shell_path="$(command -v zsh)"
  # make zsh default shell
  if ! grep "$shell_path" /etc/shells > /dev/null; then
    sudo sh -c "echo ${shell_path} >> /etc/shells"
  fi
  chsh -s "$shell_path"

  # install oh-my-zsh
  local OMZ_DIR="${HOME}/.oh-my-zsh"
  if [[ ! -d "$OMZ_DIR" ]]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
  fi

  # Install zsh plugins:
  # - spaceship-prompt
  # - zsh-autosuggestions
  local ZSH_CUSTOM_DIR="${OMZ_DIR}/custom"
  if [[ ! -d "${ZSH_CUSTOM_DIR}/themes/spaceship-prompt" ]]; then
    git clone https://github.com/denysdovhan/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt"
    ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"
  fi
  if [[ ! -d "${ZSH_CUSTOM_DIR}/plugins/zsh-autosuggestions" ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
  fi
}

main(){
  echo_info "Start OS X bootstraping..."

  # Make sure we're on a Mac before continuing
  check_os

  # Install Packages defined in Brewfile
  echo_info "Installing packages..."
  brew bundle

  # Remove outdated versions from the cellar
  echo_info "Cleaning up..."
  brew cleanup

  # Installing Extensions
  echo_info "Installing Extensions for Vscode..."
  install_vscode_extensions

  # Update ZSH
  echo_info "Configuring ZSH..."
  zsh_config

  # Config dotfiles
  echo_info "Configuring dotfiles..."
  # shellcheck disable=SC1091
  source config_dotfiles.sh

  echo_info "Bootstrap complete"
}

main