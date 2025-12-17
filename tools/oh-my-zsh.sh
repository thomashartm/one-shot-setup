oh_my_zsh_show() { open_url "https://ohmyz.sh/"; }

oh_my_zsh_is_installed() {
  [[ -d "${HOME}/.oh-my-zsh" ]]
}

oh_my_zsh_version() {
  if [[ -d "${HOME}/.oh-my-zsh/.git" ]] && command -v git >/dev/null 2>&1; then
    git -C "${HOME}/.oh-my-zsh" rev-parse --short HEAD 2>/dev/null || echo "unknown"
  else
    echo "unknown"
  fi
}

oh_my_zsh_install() {
  if oh_my_zsh_is_installed; then
    echo "Oh My Zsh already installed at: ${HOME}/.oh-my-zsh"
    return 0
  fi

  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

register_tool \
  "oh-my-zsh" \
  "Oh My Zsh" \
  "Install Oh My Zsh framework" \
  "https://ohmyz.sh/" \
  "oh_my_zsh_install" \
  "oh_my_zsh_show" \
  20 \
  "homebrew" \
  "oh_my_zsh_is_installed" \
  "oh_my_zsh_version"
