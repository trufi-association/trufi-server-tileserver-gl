#!/bin/bash

# Trufi TileServer GL - Init Script
# Sets up the tile server with your mbtiles file
#
# Usage: ./init.sh BBOX=<bbox> <mbtiles>
# Example: ./init.sh BBOX=29.9,-2.1,30.3,-1.8 /path/to/kigali.mbtiles

set -e

# ============================================
# Color output functions
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}$1${NC}"
}

print_info() {
    echo -e "${BLUE}$1${NC}"
}

print_step() {
    echo -e "${YELLOW}→ $1${NC}"
}

# ============================================
# Configuration
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="$SCRIPT_DIR/data"
SRC_DIR="$SCRIPT_DIR/src"

# ============================================
# Display usage
# ============================================

show_usage() {
    echo ""
    echo "Trufi TileServer GL - Init Script"
    echo "=================================="
    echo ""
    echo "Usage: $0 BBOX=<bbox> <mbtiles>"
    echo ""
    echo "Arguments:"
    echo "  BBOX=<bbox>  Bounding box in format: BBOX=minLon,minLat,maxLon,maxLat"
    echo "  <mbtiles>    Path to your .mbtiles file"
    echo ""
    echo "Example:"
    echo "  $0 BBOX=29.979526,-2.079821,30.27987,-1.779581 /path/to/kigali.mbtiles"
    echo ""
    echo "You can generate mbtiles files using:"
    echo "  https://github.com/trufi-association/trufi-mbtiles-generator"
    echo ""
}

# ============================================
# Validate arguments
# ============================================

validate_arguments() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        print_error "Missing arguments"
        show_usage
        exit 1
    fi

    # Parse BBOX= format
    BBOX_ARG="$1"
    if [[ "$BBOX_ARG" != BBOX=* ]]; then
        print_error "First argument must start with BBOX="
        echo "Example: BBOX=29.979526,-2.079821,30.27987,-1.779581"
        exit 1
    fi

    BOUNDS="${BBOX_ARG#BBOX=}"
    MBTILES_PATH="$2"
    MBTILES_FILENAME=$(basename "$MBTILES_PATH")

    # Validate mbtiles file exists
    if [ ! -f "$MBTILES_PATH" ]; then
        print_error "File not found: $MBTILES_PATH"
        exit 1
    fi

    # Validate extension
    if [[ "$MBTILES_FILENAME" != *.mbtiles ]]; then
        print_error "File must have .mbtiles extension"
        exit 1
    fi

    # Check src directory exists
    if [ ! -d "$SRC_DIR" ]; then
        print_error "src directory not found at $SRC_DIR"
        exit 1
    fi

    if [ ! -d "$SRC_DIR/fonts" ] || [ ! -d "$SRC_DIR/styles" ]; then
        print_error "src/fonts or src/styles directory not found"
        exit 1
    fi
}

# ============================================
# Check for existing data
# ============================================

check_existing_data() {
    if [ -d "$DATA_DIR" ] && [ "$(ls -A "$DATA_DIR" 2>/dev/null)" ]; then
        print_warning "Data directory already exists with content."
        echo ""
        read -p "Do you want to overwrite? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Cancelled by user."
            exit 0
        fi
        echo ""
        print_step "Removing existing data..."
        rm -rf "$DATA_DIR"
    fi
}

# ============================================
# Setup data directory
# ============================================

setup_data() {
    print_step "Creating data directory..."
    mkdir -p "$DATA_DIR"

    print_step "Copying fonts..."
    cp -r "$SRC_DIR/fonts" "$DATA_DIR/"

    print_step "Copying styles..."
    cp -r "$SRC_DIR/styles" "$DATA_DIR/"

    print_step "Copying $MBTILES_FILENAME..."
    cp "$MBTILES_PATH" "$DATA_DIR/$MBTILES_FILENAME"

    print_step "Setting permissions for Docker..."
    chmod -R 755 "$DATA_DIR"
}

# ============================================
# Generate config.json
# ============================================

generate_config() {
    print_step "Generating config.json..."

    # Parse bbox
    IFS=',' read -r MIN_LON MIN_LAT MAX_LON MAX_LAT <<< "$BOUNDS"

    cat > "$DATA_DIR/config.json" << EOF
{
  "options": {
    "paths": {
      "root": "",
      "fonts": "/data/fonts",
      "styles": "/data/styles",
      "mbtiles": "/data"
    }
  },
  "styles": {
    "osm-bright": {
      "style": "osm-bright/style.json",
      "tilejson": {
        "type": "overlay",
        "bounds": [$MIN_LON, $MIN_LAT, $MAX_LON, $MAX_LAT]
      }
    },
    "maptiler-basic": {
      "style": "maptiler-basic/style.json",
      "tilejson": {
        "type": "overlay",
        "bounds": [$MIN_LON, $MIN_LAT, $MAX_LON, $MAX_LAT]
      }
    },
    "osm-liberty": {
      "style": "osm-liberty/style.json",
      "tilejson": {
        "type": "overlay",
        "bounds": [$MIN_LON, $MIN_LAT, $MAX_LON, $MAX_LAT]
      }
    },
    "positron": {
      "style": "positron/style.json",
      "tilejson": {
        "type": "overlay",
        "bounds": [$MIN_LON, $MIN_LAT, $MAX_LON, $MAX_LAT]
      }
    },
    "dark-matter": {
      "style": "dark-matter/style.json",
      "tilejson": {
        "type": "overlay",
        "bounds": [$MIN_LON, $MIN_LAT, $MAX_LON, $MAX_LAT]
      }
    },
    "fiord-color": {
      "style": "fiord-color/style.json",
      "tilejson": {
        "type": "overlay",
        "bounds": [$MIN_LON, $MIN_LAT, $MAX_LON, $MAX_LAT]
      }
    }
  },
  "data": {
    "openmaptiles": {
      "mbtiles": "/data/$MBTILES_FILENAME"
    }
  }
}
EOF
}

# ============================================
# Show completion message
# ============================================

show_completion() {
    echo ""
    print_success "============================================"
    print_success "  Setup complete!"
    print_success "============================================"
    echo ""
    echo "Data directory: $DATA_DIR"
    echo "MBTiles file:   $MBTILES_FILENAME"
    echo "Bounds:         $BOUNDS"
    echo ""
    echo "Next steps:"
    echo ""
    echo "  1. Start the server:"
    print_info "     docker compose up -d"
    echo ""
    echo "  2. Access the map viewer:"
    print_info "     http://localhost:5656"
    echo ""
    echo "  3. Test the API:"
    print_info "     curl http://localhost:5656/health"
    echo ""
    echo "Available styles:"
    echo "  - osm-bright"
    echo "  - maptiler-basic"
    echo "  - osm-liberty"
    echo "  - positron"
    echo "  - dark-matter"
    echo "  - fiord-color"
    echo ""
}

# ============================================
# Main
# ============================================

main() {
    echo ""
    print_info "Trufi TileServer GL - Init"
    echo "=================================="
    echo ""

    validate_arguments "$@"
    check_existing_data
    setup_data
    generate_config
    show_completion
}

main "$@"
