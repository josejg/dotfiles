ARG BASE_IMAGE=ubuntu:20.04
FROM ${BASE_IMAGE}

COPY ubuntu-home.sh /
RUN DEBIAN_FRONTEND=noninteractive apt update -qqq && \
    DEBIAN_FRONTEND=noninteractive apt install -qq --no-install-recommends -y zsh stow wget git make curl tmux tzdata \
    software-properties-common python3 python3-venv python3-pip && \
    chmod +x /ubuntu-home.sh && CLEANUP=1 /ubuntu-home.sh

# Set Zsh as the default shell
RUN chsh -s /usr/bin/zsh root

# Set working directory
WORKDIR /root

# Set the default command to Zsh
CMD ["zsh"]

