ARG BASE_IMAGE=ubuntu:20.04
FROM ${BASE_IMAGE}

COPY prepare-home.sh /
RUN DEBIAN_FRONTEND=noninteractive apt update && \
    DEBIAN_FRONTEND=noninteractive apt install --no-install-recommends -y zsh stow wget git make curl tmux tzdata \
    software-properties-common python3 python3-venv python3-pip && \
    chmod +x /prepare-home.sh && CLEANUP=1 /prepare-home.sh

# Set Zsh as the default shell
RUN chsh -s /usr/bin/zsh root

# Set working directory
WORKDIR /root

# Set the default command to Zsh
CMD ["zsh"]

