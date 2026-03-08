FROM ubuntu:24.04

RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -qq --no-install-recommends -y \
    zsh git python3 python3-venv curl ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY test-shell.sh /usr/local/bin/test-shell
WORKDIR /root/.dotfiles

# Entrypoint: clean stale rc files, run setup.py + install.py, then exec CMD
RUN printf '#!/bin/zsh\nrm -f ~/.zshrc ~/.zshenv ~/.zprofile ~/.zlogin ~/.common ~/.aliases ~/.p10k.zsh 2>/dev/null\nrm -rf ~/.config/shell 2>/dev/null\ncd /root/.dotfiles\npython3 setup.py\npython3 install.py --force zsh env\nexec "$@"\n' > /entrypoint.sh && \
    chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["zsh"]
