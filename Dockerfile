FROM ubuntu:24.04

RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -qq --no-install-recommends -y \
    zsh git stow curl ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install zsh plugins
RUN mkdir -p /root/.zsh && \
    git clone --depth=1 https://github.com/zdharma-continuum/fast-syntax-highlighting.git /root/.zsh/fast-syntax-highlighting && \
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git /root/.zsh/zsh-autosuggestions && \
    git clone --depth=1 https://github.com/zsh-users/zsh-history-substring-search.git /root/.zsh/zsh-history-substring-search && \
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /root/.zsh/powerlevel10k && \
    git clone --depth=1 https://github.com/zsh-users/zsh-completions.git /root/.zsh/zsh-completions && \
    git clone --depth=1 https://github.com/MichaelAquilina/zsh-you-should-use.git /root/.zsh/zsh-you-should-use

# Install zoxide
RUN curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

# Install fzf (remove generated rc files so stow can link ours)
RUN git clone --depth=1 https://github.com/junegunn/fzf.git /root/.fzf && \
    yes | /root/.fzf/install && \
    rm -f /root/.zshrc /root/.bashrc

COPY test-shell.sh /usr/local/bin/test-shell
WORKDIR /root/.dotfiles

# Entrypoint: remove stale rc files, stow from volume, then run CMD
RUN printf '#!/bin/zsh\nrm -f ~/.zshrc ~/.zshenv ~/.zprofile ~/.zlogin ~/.common ~/.aliases ~/.p10k.zsh 2>/dev/null\ncd /root/.dotfiles\nstow --target=$HOME zsh env\nexec "$@"\n' > /entrypoint.sh && \
    chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["zsh"]
