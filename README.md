# Zoneploy Deploy Action

GitHub Action to build, push and deploy your app to [Zoneploy](https://zoneploy.com). Supports Docker containers and Docker Compose stacks.

## Usage

```yaml
name: Deploy to Zoneploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: zoneploy/deploy-action@0.1.0
        with:
          token: ${{ secrets.ZP_DEPLOY_TOKEN }}
```

Add `ZP_DEPLOY_TOKEN` as a secret in your repository (**Settings → Secrets and variables → Actions**). You can generate a deploy token from your stack or container settings in the Zoneploy dashboard.

## How it works

The action automatically detects whether your project is a **Container** or a **Stack** based on the deploy token:

- **Container** — builds the Docker image, pushes it to the Zoneploy registry, and triggers a redeploy.
- **Stack** — sends the `docker-compose.yml` to Zoneploy and triggers a redeploy of all services.

## Inputs

| Input | Required | Default | Description |
|---|---|---|---|
| `token` | Yes | — | Zoneploy deploy token |
| `dockerfile` | No | `Dockerfile` | Path to Dockerfile (containers only) |
| `compose-file` | No | `docker-compose.yml` | Path to Docker Compose file (stacks only) |

## Examples

**Custom Dockerfile path:**
```yaml
- uses: zoneploy/deploy-action@0.1.0
  with:
    token: ${{ secrets.ZP_DEPLOY_TOKEN }}
    dockerfile: docker/Dockerfile.prod
```

**Custom Compose file path:**
```yaml
- uses: zoneploy/deploy-action@0.1.0
  with:
    token: ${{ secrets.ZP_DEPLOY_TOKEN }}
    compose-file: infra/docker-compose.yml
```

## License

MIT