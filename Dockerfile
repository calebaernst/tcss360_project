# Dockerfile for Cool Trivia Maze - Godot 4.4 Game
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV GODOT_VERSION=4.4-stable
ENV DISPLAY=:0

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    xvfb \
    pulseaudio \
    libasound2-dev \
    libpulse-dev \
    libudev-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libxrandr2 \
    libxinerama1 \
    libxcursor1 \
    libxi6 \
    libxss1 \
    && rm -rf /var/lib/apt/lists/*

# deps + zip for packaging
RUN apt-get update && apt-get install -y \
    ca-certificates wget unzip zip \
    xvfb \
    libasound2-dev libpulse-dev pulseaudio \
    libudev-dev libgl1-mesa-dev libglu1-mesa-dev \
    libxrandr2 libxinerama1 libxcursor1 libxi6 libxss1 \
 && rm -rf /var/lib/apt/lists/*

# non-root user
RUN useradd -m -s /bin/bash godot

# Godot headless editor
WORKDIR /opt
RUN wget -q https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.x86_64.zip \
 && unzip Godot_v${GODOT_VERSION}_linux.x86_64.zip \
 && mv Godot_v${GODOT_VERSION}_linux.x86_64 /usr/local/bin/godot \
 && chmod +x /usr/local/bin/godot \
 && rm Godot_v${GODOT_VERSION}_linux.x86_64.zip

# Export templates
RUN wget -q https://github.com/godotengine/godot/releases/download/4.4-stable/Godot_v4.4-stable_export_templates.tpz \
 && unzip Godot_v4.4-stable_export_templates.tpz \
 && mkdir -p /home/godot/.local/share/godot/export_templates/4.4.stable \
 && cp -r templates/* /home/godot/.local/share/godot/export_templates/4.4.stable/ \
 && chown -R godot:godot /home/godot/.local \
 && rm -rf templates Godot_v4.4-stable_export_templates.tpz

# app workspace
WORKDIR /app
# copy only your project folder (space is OK here)
COPY ["./cool trivia maze/", "./"]
# start script
COPY start.sh /start.sh
RUN chmod +x /start.sh && chown -R godot:godot /app /start.sh /home/godot

USER godot
RUN mkdir -p /app/exports

# optional for web debug servers
EXPOSE 8060

CMD ["/start.sh"]