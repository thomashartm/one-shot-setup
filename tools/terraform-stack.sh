# Tool: Terraform + Terragrunt
# Depends on: homebrew
# Terraform: install from HashiCorp's official tap: brew tap hashicorp/tap; brew install hashicorp/tap/terraform :contentReference[oaicite:1]{index=1}
# Terragrunt: brew install terragrunt :contentReference[oaicite:2]{index=2}

terraform_stack_show() {
  # Open both official install pages (Terraform + Terragrunt)
  open_url "https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli"
  open_url "https://terragrunt.gruntwork.io/docs/getting-started/install/"
}

terraform_stack_is_installed() {
  command -v terraform >/dev/null 2>&1 || return 1
  command -v terragrunt >/dev/null 2>&1 || return 1
  return 0
}

terraform_stack_version() {
  local tf tg
  tf="$(terraform version 2>/dev/null | head -n 1 || echo "terraform=unknown")"
  tg="$(terragrunt --version 2>/dev/null | head -n 1 || echo "terragrunt=unknown")"
  echo "${tf}; ${tg}"
}

terraform_stack_install() {
  # Terraform (official tap) :contentReference[oaicite:3]{index=3}
  brew tap hashicorp/tap
  brew install hashicorp/tap/terraform

  # Terragrunt :contentReference[oaicite:4]{index=4}
  brew install terragrunt

  echo
  echo "Verify:"
  echo "  terraform version"
  echo "  terragrunt --version"
  echo
}

register_tool \
  "terraform-stack" \
  "Terraform Stack" \
  "Install Terraform (HashiCorp tap) + Terragrunt (Homebrew)" \
  "https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli" \
  "terraform_stack_install" \
  "terraform_stack_show" \
  50 \
  "homebrew" \
  "terraform_stack_is_installed" \
  "terraform_stack_version"
