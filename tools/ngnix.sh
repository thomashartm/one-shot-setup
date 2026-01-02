# Tool: nginx - High-performance HTTP server and reverse proxy
# Depends on: homebrew
# Links: https://nginx.org/

nginx_show() {
  open_url "https://nginx.org/en/docs/"
}

nginx_is_installed() {
  command -v nginx >/dev/null 2>&1
}

nginx_version() {
  if command -v nginx >/dev/null 2>&1; then
    nginx -v 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown"
  else
    echo "unknown"
  fi
}

nginx_install() {
  # Install nginx via Homebrew
  brew install nginx

  echo "Done. nginx installed successfully."
  echo ""
  echo "Usage:"
  echo "  Start nginx:   brew services start nginx"
  echo "  Stop nginx:    brew services stop nginx"
  echo "  Restart:       brew services restart nginx"
  echo "  Manual start:  nginx"
  echo "  Test config:   nginx -t"
  echo ""
  echo "Configuration: /opt/homebrew/etc/nginx/nginx.conf"
  echo "Document root: /opt/homebrew/var/www"
  echo "Logs:          /opt/homebrew/var/log/nginx/"
  echo ""
  echo "Verify with: nginx -v"
}

register_tool \
  "nginx" \
  "nginx" \
  "Install nginx HTTP server and reverse proxy via Homebrew" \
  "https://nginx.org/" \
  "nginx_install" \
  "nginx_show" \
  55 \
  "homebrew" \
  "nginx_is_installed" \
  "nginx_version"
