#!/bin/bash

COMPANY=$(echo "$1" | tr '[:upper:]' '[:lower:]')

if [ -z "$COMPANY" ]; then
  echo "❌ Usage: ./generate.sh <company-name>"
  exit 1
fi

mkdir -p branding_configs services output/sites/$COMPANY/assets

BRANDING_FILE="branding_configs/branding_config_${COMPANY}.yml"
SERVICES_FILE="services/services_${COMPANY}.json"
MANUAL_PNG_SOURCE="assets/${COMPANY}.png"
LOGO_PNG_PATH="output/sites/${COMPANY}/assets/${COMPANY}.png"

# Default theming values
case "$COMPANY" in
  nintendo)
    COLOR="#e60012"
    HEADER="⚙ Mushroom Metrics"
    DASHBOARD_URL="https://grafana.nintendo.mock/grafana/d/health"
    ;;
  tesla)
    COLOR="#cc0000"
    HEADER="⚙ Tesla Service Monitor"
    DASHBOARD_URL="https://grafana.tesla.mock/grafana/d/tesla-sre"
    ;;
  blueorigin)
    COLOR="#005288"
    HEADER="🚀 BlueOrigin Service Monitor"
    DASHBOARD_URL="https://grafana.blueorigin.mock/grafana/d/blueorigin-sre"
    ;;
  spacex)
    COLOR="#1b1f23"
    HEADER="🚀 SpaceX Control Panel"
    DASHBOARD_URL="https://grafana.spacex.mock/grafana/d/spacex-monitoring"
    ;;
  t-mobile)
    COLOR="#e20074"
    HEADER="📶 T-Mobile Infra Monitor"
    DASHBOARD_URL="https://grafana.tmobile.mock/grafana/d/infra"
    LOGO_EPS_URL="https://www.brandsoftheworld.com/sites/all/themes/botw/img/s.gif"
    ;;
  meta)
    COLOR="#1877f2"
    HEADER="⚙ Meta Service Monitor"
    DASHBOARD_URL="https://grafana.meta.mock/grafana/d/meta-platform"
    ;;
  *)
    COLOR="#007acc"
    HEADER="⚙ ${COMPANY^} Service Monitor"
    DASHBOARD_URL="https://grafana.${COMPANY}.mock/grafana/d/main"
    ;;
esac



if [ -f "$SVG_SOURCE" ]; then
  echo "📄 Found SVG logo for $COMPANY"
  if ! command -v rsvg-convert &> /dev/null; then
    echo "❌ rsvg-convert not found. Please install it with: sudo apt install librsvg2-bin"
    exit 1
  fi
  rsvg-convert -w 400 -h 400 "$SVG_SOURCE" -o "$LOGO_PNG_PATH"
  echo "✅ Resized SVG to PNG: $LOGO_PNG_PATH"

# If no SVG, try a manually placed PNG and copy it over
elif [ -f "$MANUAL_PNG_SOURCE" ]; then
  echo "📦 Found manual PNG for $COMPANY, copying to output..."
  cp "$MANUAL_PNG_SOURCE" "$LOGO_PNG_PATH"
  echo "✅ Copied manual PNG: $LOGO_PNG_PATH"

else
  echo "❌ No logo found for $COMPANY. Please add either:"
  echo "   - $SVG_SOURCE  (preferred, will auto-resize)"
  echo "   - $MANUAL_PNG_SOURCE  (already 400x400)"
  exit 1
fi

# Write branding config
if [ ! -f "$BRANDING_FILE" ]; then
  cat > "$BRANDING_FILE" <<EOF
company_name: ${COMPANY^}
logo_url: $LOGO_PATH
primary_color: "$COLOR"
page_title: "${COMPANY^} Service Health Dashboard"
header_text: "$HEADER"
dashboard_url: "$DASHBOARD_URL"
EOF
  echo "✅ Created $BRANDING_FILE"
fi

# Write services.json
if [ ! -f "$SERVICES_FILE" ]; then
  cat > "$SERVICES_FILE" <<EOF
[
  { "id": "auth-service",         "region": "us-west-2" },
  { "id": "cdn-cache",            "region": "us-east-1" },
  { "id": "eshop-api",            "region": "us-west-2" },
  { "id": "user-profile-service", "region": "us-east-2" }
]
EOF
  echo "✅ Created $SERVICES_FILE"
fi

# Run Ansible to render HTML
echo "🚀 Rendering dashboard for ${COMPANY^}..."
ansible-playbook render_site.yml -e company=$COMPANY
