#!/bin/bash

# Trufi TileServer GL - Init Script
# Usage: ./init.sh BBOX=<bbox> <mbtiles>
# Example: ./init.sh BBOX=29.9,-2.1,30.3,-1.8 /path/to/kigali.mbtiles

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="$SCRIPT_DIR/data"
SRC_DIR="$SCRIPT_DIR/src"

# Check arguments
if [ -z "$1" ] || [ -z "$2" ]; then
    echo -e "${RED}Error: Missing arguments${NC}"
    echo ""
    echo "Usage: $0 BBOX=<bbox> <mbtiles>"
    echo ""
    echo "Arguments:"
    echo "  BBOX=<bbox>  Bounding box: BBOX=minLon,minLat,maxLon,maxLat"
    echo "  <mbtiles>    Path to your .mbtiles file"
    echo ""
    echo "Example:"
    echo "  $0 BBOX=29.979526,-2.079821,30.27987,-1.779581 /path/to/kigali.mbtiles"
    exit 1
fi

# Parse BBOX= format
BBOX_ARG="$1"
if [[ "$BBOX_ARG" != BBOX=* ]]; then
    echo -e "${RED}Error: First argument must start with BBOX=${NC}"
    echo "Example: BBOX=29.979526,-2.079821,30.27987,-1.779581"
    exit 1
fi

BOUNDS="${BBOX_ARG#BBOX=}"
MBTILES_PATH="$2"
MBTILES_FILENAME=$(basename "$MBTILES_PATH")

# Validate mbtiles file
if [ ! -f "$MBTILES_PATH" ]; then
    echo -e "${RED}Error: File not found: $MBTILES_PATH${NC}"
    exit 1
fi

if [[ "$MBTILES_FILENAME" != *.mbtiles ]]; then
    echo -e "${RED}Error: File must have .mbtiles extension${NC}"
    exit 1
fi

# Check src directory
if [ ! -d "$SRC_DIR" ]; then
    echo -e "${RED}Error: src directory not found${NC}"
    exit 1
fi

echo -e "${GREEN}Trufi TileServer GL - Init${NC}"
echo "================================"
echo ""

# Create data directory
echo -e "${YELLOW}Creating data directory...${NC}"
mkdir -p "$DATA_DIR"

# Copy src (fonts and styles)
echo -e "${YELLOW}Copying fonts and styles...${NC}"
cp -r "$SRC_DIR/fonts" "$DATA_DIR/"
cp -r "$SRC_DIR/styles" "$DATA_DIR/"

# Copy mbtiles
echo -e "${YELLOW}Copying $MBTILES_FILENAME...${NC}"
cp "$MBTILES_PATH" "$DATA_DIR/$MBTILES_FILENAME"

# Parse bbox
IFS=',' read -r MIN_LON MIN_LAT MAX_LON MAX_LAT <<< "$BOUNDS"

# Generate config.json
echo -e "${YELLOW}Generating config.json...${NC}"
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

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Init complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo "Start server: docker compose up -d"
echo "Access: http://localhost:5656"
