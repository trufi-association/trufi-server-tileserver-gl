# Trufi TileServer GL

Part of the [Trufi Association](https://www.trufi-association.org/) ecosystem for public transit apps.

A self-hosted vector tile server using [TileServer GL](https://github.com/maptiler/tileserver-gl) for serving OpenMapTiles-compatible vector tiles. This service provides map tiles and styles for the Trufi transit application stack.

## Features

- Serves vector tiles from `.mbtiles` files
- Multiple map styles included (OSM Bright, MapTiler Basic, OSM Liberty, Positron, Dark Matter, Fiord Color)
- Docker-based deployment with health checks
- Compatible with Mapbox GL JS, MapLibre GL JS, and other vector tile clients
- Designed for integration with [trufi-server](https://github.com/trufi-association/trufi-server)

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)
- An `.mbtiles` file with vector tiles

## Quick Start

```bash
# Clone the repository
git clone https://github.com/trufi-association/trufi-server-tileserver-gl
cd trufi-server-tileserver-gl

# Initialize with bbox and mbtiles file
./init.sh BBOX=29.979526,-2.079821,30.27987,-1.779581 /path/to/your-city.mbtiles

# Start the server
docker compose up -d

# Test the server
curl http://localhost:5656/health
```

Access the map viewer at http://localhost:5656

## Getting MBTiles Files

You can generate `.mbtiles` files using [trufi-mbtiles-generator](https://github.com/trufi-association/trufi-mbtiles-generator):

```bash
git clone https://github.com/trufi-association/trufi-mbtiles-generator.git
cd trufi-mbtiles-generator
# Follow the instructions in that repository
```

Alternatively, you can use [OpenMapTiles](https://github.com/openmaptiles/openmaptiles) directly.

## Memory Configuration

The default memory limit is **1GB**, which is sufficient for small to medium cities. Adjust in `docker-compose.yml` based on your mbtiles file size:

| Data Size | Recommended Memory |
|-----------|-------------------|
| Small city (< 50MB) | 512m - 1g |
| Medium city (50-200MB) | 1g - 2g |
| Large city/region (> 200MB) | 2g - 4g |

## Available Styles

| Style ID | Name | Description |
|----------|------|-------------|
| `osm-bright` | OSM Bright | General purpose bright style with detailed OSM data |
| `maptiler-basic` | MapTiler Basic | Clean, minimal basemap |
| `osm-liberty` | OSM Liberty | Free open-source Mapbox-like style |
| `positron` | Positron | Light, elegant style ideal for data visualization |
| `dark-matter` | Dark Matter | Dark theme, great for night mode or dashboards |
| `fiord-color` | Fiord Color | Dark blue elegant style |

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `/` | Web interface with map preview |
| `/styles/` | List of available styles |
| `/styles/{style}/style.json` | Mapbox GL style JSON |
| `/styles/{style}/{z}/{x}/{y}.png` | Raster tiles |
| `/data/` | List of available data sources |
| `/data/{source}/{z}/{x}/{y}.pbf` | Vector tiles (Protocol Buffers) |
| `/data/{source}.json` | TileJSON metadata |
| `/fonts/` | Available fonts |
| `/health` | Health check endpoint |

## Integration with trufi-server

This service is designed to work with [trufi-server](https://github.com/trufi-association/trufi-server).

### 1. Clone into trufi-server directory

```bash
cd /path/to/trufi-server
git clone https://github.com/trufi-association/trufi-server-tileserver-gl
cd trufi-server-tileserver-gl
./init.sh BBOX=<your-bbox> /path/to/your.mbtiles
```

### 2. Add to trufi-server docker-compose.yml

```yaml
services:
  tileserver:
    image: maptiler/tileserver-gl:latest
    container_name: trufi-tileserver-gl
    volumes:
      - ./trufi-server-tileserver-gl/data:/data
    command: tileserver-gl -p 5656
    mem_limit: 1g
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost:5656/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - trufi-server
```

### 3. Configure reverse proxy

Add to your `appsettings.json` (or use `trufi-proxy.json`):

```json
{
  "name": "tileserver",
  "description": "Vector tile server for serving map tiles and styles",
  "container": "trufi-tileserver-gl",
  "port": 5656
}
```

### 4. Configure Nginx (if using external proxy)

```nginx
server {
    listen 80;
    server_name tiles.example.com;

    location / {
        proxy_pass http://trufi-tileserver-gl:5656;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 5. Test the integration

```bash
curl 'https://tiles.example.com/health'
```

SSL is handled automatically by trufi-server's LettuceEncrypt.

## Using with Mapbox GL JS / MapLibre GL JS

```javascript
const map = new maplibregl.Map({
  container: 'map',
  style: 'http://localhost:5656/styles/osm-bright/style.json',
  center: [30.06, -1.94], // Your city coordinates
  zoom: 12
});
```

## Troubleshooting

### Container won't start

Check if the data directory exists and has content:
```bash
ls -la data/
```

### Styles not loading

Verify the config was generated correctly:
```bash
cat data/config.json
```

### Check container health

```bash
docker compose ps
docker compose logs -f trufi-tileserver-gl
```

### Memory issues

If the container is being killed, increase the memory limit in `docker-compose.yml`:
```yaml
mem_limit: 2g
```

## Project Structure

```
trufi-server-tileserver-gl/
├── src/                      # Source files
│   ├── fonts/                # Font files (PBF format)
│   └── styles/               # Map style definitions
├── data/                     # Generated by init.sh (gitignored)
├── init.sh                   # Setup script
├── docker-compose.yml        # Docker configuration
├── trufi-proxy.json          # trufi-server proxy config
├── nginx.conf                # Nginx reverse proxy snippet
└── README.md
```

## Related Projects

- [trufi-server](https://github.com/trufi-association/trufi-server) - Main Trufi server
- [trufi-server-photon](https://github.com/trufi-association/trufi-server-photon) - Geocoding server
- [trufi-mbtiles-generator](https://github.com/trufi-association/trufi-mbtiles-generator) - Generate MBTiles for your city
- [Trufi Core](https://github.com/trufi-association/trufi-core) - Flutter app for public transit
- [Trufi Association](https://www.trufi-association.org/) - Making public transit accessible

## Licenses and Attribution

### Required Map Attribution

When displaying maps using these styles, you **must** include:

```
© OpenMapTiles © OpenStreetMap contributors
```

With links to:
- https://openmaptiles.org/
- https://www.openstreetmap.org/copyright

### Map Styles Licenses

| Style | License |
|-------|---------|
| OSM Bright | BSD-3-Clause + CC-BY 4.0 |
| MapTiler Basic | BSD-3-Clause + CC-BY 4.0 |
| OSM Liberty | BSD-3-Clause + CC-BY 3.0/4.0 |
| Positron | BSD-3-Clause + CC-BY 4.0 |
| Dark Matter | BSD-3-Clause + CC-BY 4.0 |
| Fiord Color | BSD-3-Clause + CC-BY 4.0 |

### Font Licenses

| Font Family | License |
|-------------|---------|
| Noto Sans | SIL Open Font License 1.1 |
| Open Sans | SIL Open Font License 1.1 |
| Roboto | Apache License 2.0 |
| Metropolis | SIL Open Font License 1.1 |

## Credits

- [TileServer GL](https://github.com/maptiler/tileserver-gl) by MapTiler
- [OpenMapTiles](https://openmaptiles.org/) for map data schema
- [OpenStreetMap](https://www.openstreetmap.org/) contributors for map data
- [Trufi Association](https://www.trufi-association.org/) for the transit ecosystem

## License

Apache License 2.0
