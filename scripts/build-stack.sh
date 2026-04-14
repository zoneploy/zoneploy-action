#!/bin/bash
# Builds and pushes all Docker Compose stack images to the Zoneploy registry.
# Generates a clean compose file (without build:) ready for deployment.
set -euo pipefail

COMPOSE_FILE="${ZP_COMPOSE_FILE}"

echo "Analyzing $COMPOSE_FILE..."

# Get services with a build context using Python (available on all runners)
SERVICES=$(python3 - <<'EOF'
import yaml, os

compose_path = os.environ.get("ZP_COMPOSE_FILE", "docker-compose.yml")
with open(compose_path) as f:
    compose = yaml.safe_load(f)

services = compose.get("services", {})
buildable = [name for name, svc in services.items() if "build" in svc]
print("\n".join(buildable))
EOF
)

if [ -z "$SERVICES" ]; then
  echo "::warning::No services with a build context found in $COMPOSE_FILE"
  exit 0
fi

echo "Services to build: $(echo "$SERVICES" | tr '\n' ' ')"

# Generate override: point each service to the Zoneploy registry
OVERRIDE=$(mktemp /tmp/zp-override-XXXXXX.yml)
echo "services:" > "$OVERRIDE"
while IFS= read -r SERVICE; do
  printf "  %s:\n    image: %s/%s:%s\n" "$SERVICE" "$ZP_NAMESPACE" "$SERVICE" "$ZP_SHA" >> "$OVERRIDE"
done <<< "$SERVICES"

# Build and push
echo "Building images..."
docker compose -f "$COMPOSE_FILE" -f "$OVERRIDE" build

echo "Pushing images..."
while IFS= read -r SERVICE; do
  IMAGE="${ZP_NAMESPACE}/${SERVICE}:${ZP_SHA}"
  echo "  → $IMAGE"
  docker push "$IMAGE"
done <<< "$SERVICES"

# Generate clean compose: replace build: with image: for each built service.
# The Platform only needs a ready-to-run compose file (no build contexts).
echo "Generating clean compose for deployment..."
python3 - <<EOF > /tmp/zp-compose-clean.yml
import yaml, os

namespace = os.environ["ZP_NAMESPACE"]
sha       = os.environ["ZP_SHA"]
compose_path = os.environ["ZP_COMPOSE_FILE"]
services_to_replace = """${SERVICES}""".strip().splitlines()

with open(compose_path) as f:
    compose = yaml.safe_load(f)

for svc in services_to_replace:
    if svc in compose.get("services", {}):
        compose["services"][svc].pop("build", None)
        compose["services"][svc]["image"] = f"{namespace}/{svc}:{sha}"

print(yaml.dump(compose, default_flow_style=False))
EOF

echo "Clean compose generated."
rm -f "$OVERRIDE"
