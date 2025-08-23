#!/bin/bash
# start.sh - Docker entrypoint for Cool Trivia Maze

set -e

# Function to export game for different platforms
export_game() {
    local platform=$1
    local preset_name=$2
    local output_file=$3
    
    echo "Exporting game for $platform..."
    
    # Import project first to ensure resources are recognized
    godot --headless --import /app/project.godot
    
    # Export the game
    godot --headless --export-release "$preset_name" "/app/exports/$output_file"
    
    echo "Export completed: /app/exports/$output_file"
}

# Function to run game directly in Docker (for testing)
run_game() {
    echo "Running Cool Trivia Maze in headless mode..."
    Xvfb :0 -screen 0 1280x1280x24 &
    export DISPLAY=:0
    
    # Import project first
    godot --headless --import /app/project.gotl
    
    # Run the game
    godot --main-pack /app/project.godot
}

# Function to serve web export
serve_web() {
    echo "Exporting for web and serving..."
    
    # Import project
    godot --headless --import /app/project.godot
    
    # Export for web
    mkdir -p /app/exports/web
    godot --headless --export-release "Web" "/app/exports/web/index.html"
    
    # Serve the web export
    cd /app/exports/web
    python3 -m http.server 8060
}

# Main execution logic
case "${1:-export}" in
    "linux")
        export_game "Linux" "Linux/X11" "cool_trivia_maze_linux.x86_64"
        ;;
    "windows")
        export_game "Windows" "Windows Desktop" "cool_trivia_maze_windows.exe"
        ;;
    "web")
        serve_web
        ;;
    "run")
        run_game
        ;;
    "export"|*)
        echo "Available commands:"
        echo "  linux   - Export Linux executable"
        echo "  windows - Export Windows executable" 
        echo "  web     - Export and serve web version"
        echo "  run     - Run game directly (for testing)"
        echo ""
        echo "Defaulting to Linux export..."
        export_game "Linux" "Linux/X11" "cool_trivia_maze_linux.x86_64"
        ;;
esac

# Keep container running if serving web
if [ "$1" = "web" ]; then
    tail -f /dev/null
fi