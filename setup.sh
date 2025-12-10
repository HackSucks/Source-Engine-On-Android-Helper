
#!/bin/bash
# SEOAH Installer Script
# Installs Source Engine on Android Helper with all dependencies

echo "========================================"
echo " Source Engine on Android Helper Setup"
echo "========================================"
echo ""
echo "This script will:"
echo "1. Install required packages (python3, mpv, ffmpeg, curl, unzip)"
echo "2. Install Python packages (gdown)"
echo "3. Download the SEOAH application"
echo "4. Set up a shortcut command 'seoah'"
echo ""
echo "Make sure you have Termux updated!"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Installation directory
INSTALL_DIR="/data/data/com.termux/files/home/seoah"
BIN_DIR="/data/data/com.termux/files/usr/bin"

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install packages
install_packages() {
    print_info "Updating package lists..."
    pkg update -y
    
    print_info "Installing required packages..."
    pkg install x11-repo

    pkg install -y python python-pip mpv ffmpeg curl unzip vlc
    
    # Check if installations were successful
    if command_exists python3 && command_exists mpv && command_exists ffplay && command_exists curl && command_exists unzip; then
        print_success "All required packages installed!"
    else
        print_error "Some packages failed to install. Trying individual installation..."
        
        # Try installing individually
        for pkg_name in python mpv ffmpeg curl unzip; do
            if ! command_exists "$pkg_name" && [ "$pkg_name" != "ffmpeg" ]; then
                print_info "Installing $pkg_name..."
                pkg install -y "$pkg_name"
            fi
        done
        
        # Special check for ffplay (part of ffmpeg)
        if ! command_exists ffplay; then
            print_info "Installing ffmpeg for ffplay..."
            pkg install -y ffmpeg
        fi
    fi
}

# Function to install Python packages
install_python_packages() {
    print_info "Installing Python packages (gdown)..."
    
    # Upgrade pip first
    pip install --upgrade pip
    
    # Install gdown
    if pip install gdown; then
        print_success "gdown installed successfully!"
    else
        print_error "Failed to install gdown. Trying alternative method..."
        pip install --user gdown
    fi
    
    # Verify gdown installation
    if python3 -c "import gdown" 2>/dev/null; then
        print_success "gdown is working correctly!"
    else
        print_warning "gdown import test failed, but continuing installation..."
    fi
}

# Function to download and extract SEOAH
download_seoah() {
    print_info "Creating installation directory: $INSTALL_DIR"
    
    # Clean up old installation if it exists
    if [ -d "$INSTALL_DIR" ]; then
        print_warning "Old installation found. Backing up and removing..."
        BACKUP_DIR="${INSTALL_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
        mv "$INSTALL_DIR" "$BACKUP_DIR"
        print_info "Backed up to: $BACKUP_DIR"
    fi
    
    mkdir -p "$INSTALL_DIR"
    
    # Download URL
    DOWNLOAD_URL="https://github.com/HackSucks/Source-Engine-On-Android-Helper/releases/download/v1.01/seoah-v1.01.zip"
    ZIP_FILE="$INSTALL_DIR/seoah.zip"
    
    print_info "Downloading SEOAH from: $DOWNLOAD_URL"
    
    # Download using curl with progress bar
    if curl -L -o "$ZIP_FILE" "$DOWNLOAD_URL"; then
        print_success "Download completed!"
        
        # Check file size
        FILE_SIZE=$(stat -c%s "$ZIP_FILE" 2>/dev/null || stat -f%z "$ZIP_FILE" 2>/dev/null)
        if [ "$FILE_SIZE" -lt 1000 ]; then
            print_error "Downloaded file seems too small ($FILE_SIZE bytes). May be corrupted."
            return 1
        fi
        print_info "File size: $((FILE_SIZE / 1024 / 1024)) MB"
    else
        print_error "Download failed!"
        return 1
    fi
    
    print_info "Extracting files..."
    
    # Extract to installation directory
    if unzip -o "$ZIP_FILE" -d "$INSTALL_DIR"; then
        print_success "Extraction completed!"
        
        # Check if main.py exists
        if [ -f "$INSTALL_DIR/main.py" ]; then
            print_success "main.py found at: $INSTALL_DIR/main.py"
        else
            # Look for main.py in subdirectories
            FOUND_MAIN=$(find "$INSTALL_DIR" -name "main.py" -type f | head -1)
            if [ -n "$FOUND_MAIN" ]; then
                print_info "main.py found at: $FOUND_MAIN"
            else
                print_error "main.py not found in the extracted files!"
                print_info "Contents of $INSTALL_DIR:"
                ls -la "$INSTALL_DIR"
                return 1
            fi
        fi
    else
        print_error "Extraction failed!"
        return 1
    fi
    
    # Clean up zip file
    rm -f "$ZIP_FILE"
    print_info "Cleaned up temporary files."
    
    # Make Python files executable
    chmod +x "$INSTALL_DIR"/*.py 2>/dev/null
    
    return 0
}

# Function to create seoah command
create_seoah_command() {
    print_info "Setting up 'seoah' command..."
    
    # Find main.py location
    MAIN_PY="$INSTALL_DIR/main.py"
    if [ ! -f "$MAIN_PY" ]; then
        MAIN_PY=$(find "$INSTALL_DIR" -name "main.py" -type f | head -1)
        if [ -z "$MAIN_PY" ]; then
            print_error "Could not find main.py!"
            return 1
        fi
    fi
    
    # Create the seoah command script
    SEOAH_SCRIPT="$BIN_DIR/seoah"
    
    # Create the script
    cat > "$SEOAH_SCRIPT" << 'EOF'
#!/bin/bash
# SEOAH launcher script
# Launch Source Engine on Android Helper

cd "/data/data/com.termux/files/home/seoah"
exec python3 "main.py" "$@"
EOF
    
    # Make it executable
    chmod +x "$SEOAH_SCRIPT"
    
    if [ -x "$SEOAH_SCRIPT" ]; then
        print_success "'seoah' command created at: $SEOAH_SCRIPT"
        print_info "You can now run 'seoah' from anywhere in Termux!"
    else
        print_error "Failed to create seoah command!"
        return 1
    fi
    
    return 0
}

# Function to verify installation
verify_installation() {
    print_info "Verifying installation..."
    
    echo ""
    echo "========================================"
    echo " Installation Verification"
    echo "========================================"
    
    # Check required commands
    echo ""
    echo "Checking required commands:"
    for cmd in python3 mpv ffplay curl unzip; do
        if command_exists "$cmd"; then
            echo -e "  ${GREEN}✓${NC} $cmd"
        else
            echo -e "  ${RED}✗${NC} $cmd"
        fi
    done
    
    # Check Python package
    echo ""
    echo "Checking Python packages:"
    if python3 -c "import gdown" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} gdown"
    else
        echo -e "  ${RED}✗${NC} gdown"
    fi
    
    # Check installation files
    echo ""
    echo "Checking installation files:"
    if [ -f "$INSTALL_DIR/main.py" ]; then
        echo -e "  ${GREEN}✓${NC} main.py found"
    else
        FOUND_MAIN=$(find "$INSTALL_DIR" -name "main.py" -type f | head -1)
        if [ -n "$FOUND_MAIN" ]; then
            echo -e "  ${GREEN}✓${NC} main.py found at: $FOUND_MAIN"
        else
            echo -e "  ${RED}✗${NC} main.py not found"
        fi
    fi
    
    # Check seoah command
    echo ""
    echo "Checking 'seoah' command:"
    if [ -x "$BIN_DIR/seoah" ]; then
        echo -e "  ${GREEN}✓${NC} seoah command is executable"
    else
        echo -e "  ${RED}✗${NC} seoah command not found or not executable"
    fi
    
    # Check for ASCII art files
    echo ""
    echo "Checking for game ASCII art files:"
    for game in portal hl2 tf2 css; do
        if [ -f "$INSTALL_DIR/$game.txt" ]; then
            echo -e "  ${GREEN}✓${NC} $game.txt"
        else
            echo -e "  ${YELLOW}⚠${NC} $game.txt (not found, will need to create)"
        fi
    done
    
    # Check for media files
    echo ""
    echo "Checking for media files:"
    if [ -f "$INSTALL_DIR/valve.mp4" ]; then
        echo -e "  ${GREEN}✓${NC} valve.mp4 (intro video)"
    else
        echo -e "  ${YELLOW}⚠${NC} valve.mp4 (not found, optional)"
    fi
    
    MUSIC_FILES=0
    for i in {1..6}; do
        if [ -f "$INSTALL_DIR/$i.mp3" ] || [ -f "$INSTALL_DIR/$i.m4a" ]; then
            MUSIC_FILES=$((MUSIC_FILES + 1))
        fi
    done
    echo -e "  ${GREEN}✓${NC} Found $MUSIC_FILES music files"
    
    echo ""
    echo "========================================"
}

# Function to create sample ASCII art files if missing
create_sample_art() {
    print_info "Creating sample ASCII art files if needed..."
    
    # Create portal.txt if missing
    if [ ! -f "$INSTALL_DIR/portal.txt" ]; then
        cat > "$INSTALL_DIR/portal.txt" << 'PORTAL_EOF'
  _____           _        _ 
 |  __ \         | |      | |
 | |__) |__  _ __| |_ __ _| |
 |  ___/ _ \| '__| __/ _` | |
 | |  | (_) | |  | || (_| | |
 |_|   \___/|_|   \__\__,_|_|
PORTAL_EOF
        print_info "Created sample portal.txt"
    fi
    
    # Create hl2.txt if missing
    if [ ! -f "$INSTALL_DIR/hl2.txt" ]; then
        cat > "$INSTALL_DIR/hl2.txt" << 'HL2_EOF'
 _   _       _   ____    _    _   _ 
| | | |     | | |  _ \  / \  | \ | |
| |_| |_____| | | | | |/ _ \ |  \| |
|  _  |_____| | | |_| / ___ \| |\  |
|_| |_|     |_| |____/_/   \_\_| \_|
HL2_EOF
        print_info "Created sample hl2.txt"
    fi
    
    # Create tf2.txt if missing
    if [ ! -f "$INSTALL_DIR/tf2.txt" ]; then
        cat > "$INSTALL_DIR/tf2.txt" << 'TF2_EOF'
 _______ ______   _____ 
|__   __|  ____| |  __ \
   | |  | |__    | |__) |
   | |  |  __|   |  _  / 
   | |  | |____  | | \ \ 
   |_|  |______| |_|  \_\
TF2_EOF
        print_info "Created sample tf2.txt"
    fi
    
    # Create css.txt if missing
    if [ ! -f "$INSTALL_DIR/css.txt" ]; then
        cat > "$INSTALL_DIR/css.txt" << 'CSS_EOF'
  ______           _             _____ _                 
 / _____)         | |           / ____| |                
| /     ___   ___ | | _____ _ _| (___ | |_ ___  _ __ ___ 
| |   / _ \ / _ \| |(____ | | | \___ \| __/ _ \| '__/ _ \
| \__| (_) | (_) | |/ ___ | | | ____) | || (_) | | |  __/
 \______\___/ \___/ \_____|_| |_|_____/ \__\___/|_|  \___|
CSS_EOF
        print_info "Created sample css.txt"
    fi
}

# Function to create README
create_readme() {
    print_info "Creating README file..."
    
    cat > "$INSTALL_DIR/README.md" << 'EOF'
# Source Engine on Android Helper (SEOAH)

## Installation Location
`/data/data/com.termux/files/home/seoah/`

## Quick Start
1. Run the helper by typing: `seoah`
2. Follow the on-screen instructions

## Game Installation Process
For EACH game you want to install:

1. **Install the Main APK** (REQUIRED for all games):
   - Select option 1 in the main menu
   - The APK will be saved to `/sdcard/SourceEngine/`
   - Open your file manager and install it manually

2. **Install Game Data**:
   - Select option 2 in the main menu
   - Choose your game (HL2, Portal, TF2, or CSS)
   - The game data will be downloaded and extracted
   - Remember the installation path shown

3. **Install Game Launcher APK**:
   - Each game download includes its own launcher APK
   - Find it in the game installation folder
   - Install it via file manager

## Important Notes
- The Main APK contains the actual Source Engine runtime
- Game launcher APKs are just frontends that pass arguments to the Main APK
- BOTH APKs are required for each game to work
- Set the game path in each launcher to where you installed the game data


Troubleshooting

1. If "assets not found" error appears:
   · Open the game launcher app
   · Set the assets/game path to your installation folder
2. If APKs won't install:
   · Enable "Install from unknown sources" in Android settings
   · Use a file manager app to install the APKs
3. If downloads fail:
   · Check your internet connection
   · Ensure you have enough storage space

Game Links

· Half-Life 2: Ready
· Portal: Ready
· Team Fortress 2: 2008 version (old)
· Counter-Strike: Source: Ready

Created by

HackSucks - 2025
EOF

}



main() {
echo "Starting installation..."
echo ""
# Check if we're in Termux
if [ ! -d "/data/data/com.termux" ]; then
    print_error "This script must be run in Termux!"
    echo "Please install Termux from F-Droid or Google Play Store."
    exit 1
fi

# Ask for confirmation
echo "Press Enter to continue or Ctrl+C to cancel..."
read -r

# Step 1: Install packages
echo ""
print_info "Step 1: Installing system packages..."
install_packages

# Step 2: Install Python packages
echo ""
print_info "Step 2: Installing Python packages..."
install_python_packages

# Step 3: Download and extract SEOAH
echo ""
print_info "Step 3: Downloading SEOAH application..."
if ! download_seoah; then
    print_error "Failed to download or extract SEOAH!"
    echo "Please check your internet connection and try again."
    exit 1
fi

# Step 4: Create sample ASCII art
echo ""
print_info "Step 4: Setting up game art files..."
create_sample_art

# Step 5: Create seoah command
echo ""
print_info "Step 5: Creating 'seoah' command..."
if ! create_seoah_command; then
    print_warning "Failed to create seoah command, but installation continues..."
fi

# Step 6: Create README
echo ""
print_info "Step 6: Creating documentation..."
create_readme

# Step 7: Verify installation
echo ""
verify_installation

# Final message
echo ""
echo "========================================"
echo " Installation Complete!"
echo "========================================"
echo ""
echo -e "${GREEN}✓${NC} Source Engine on Android Helper is now installed!"
echo ""
echo "To start the application, type:"
echo -e "  ${YELLOW}seoah${NC}"
echo ""
echo "Or manually:"
echo -e "  ${YELLOW}cd ~/seoah && python3 main.py${NC}"
echo ""
echo "Installation directory:"
echo -e "  ${BLUE}$INSTALL_DIR${NC}"
echo ""
echo "Check the README.md file for more information."
echo ""
echo "Happy gaming! 🎮"
echo ""
}


main "$@"


