@ -1,71 +0,0 @@
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

# Create godot user
RUN useradd -m -s /bin/bash godot

# Download and install Godot
WORKDIR /opt
RUN wget -q https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.x86_64.zip \
    && unzip Godot_v${GODOT_VERSION}_linux.x86_64.zip \
    && mv Godot_v${GODOT_VERSION}_linux.x86_64 /usr/local/bin/godot \
    && chmod +x /usr/local/bin/godot \
    && rm Godot_v${GODOT_VERSION}_linux.x86_64.zip

# Download export templates
RUN wget -q https://github.com/godotengine/godot/releases/download/4.4-stable/Godot_v4.4-stable_export_templates.tpz \
    && unzip Godot_v4.4-stable_export_templates.tpz \
    && mkdir -p /home/godot/.local/share/godot/export_templates/4.4.stable \
    && cp -r templates/* /home/godot/.local/share/godot/export_templates/4.4.stable/ \
    && chown -R godot:godot /home/godot/.local \
    && rm -rf templates Godot_v4.4-stable_export_templates.tpz
    
# Set working directory for the game
WORKDIR /app

# Copy game files
COPY ["./cool trivia maze/", "./"]

# Change ownership to godot user
RUN chown -R godot:godot /app

# Switch to godot user
USER godot

# Create exports directory
RUN mkdir -p /app/exports

# Expose the default Godot port for web exports
EXPOSE 8060

# Start script that can handle different export types
COPY start.sh /start.sh
USER root
RUN chmod +x /start.sh

USER godot

CMD ["/start.sh"]