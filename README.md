# Data Modeling IDE Core

VSCode (code-server) based web IDE tailored for dbt data modeling. Comes preinstalled with Python 3.11, Node.js, dbt adapters, cloud CLIs, and curated extensions/settings to accelerate dbt development.

## Overview

This image powers Fast.BI's browser-accessible data modeling workspace. It provides a ready-to-code environment with opinionated extensions, settings, and CLIs for dbt model authoring, testing, documentation, and integration with warehouse/cloud tooling.

## Tooling & Features

- **Editor**: code-server (VSCode in the browser)
- **Python**: 3.11 runtime with pip, virtualenv
- **Node.js**: v20 with npm
- **Lightdash CLI**: `@lightdash/cli` for analytics workflows
- **Cloud CLIs**: Google Cloud SDK, SnowSQL client
- **Utilities**: yq, jq, yamllint, Go (for fixuid), git
- **Extensions**: Curated VSIX extensions preloaded under `/usr/vsix`
- **Settings**: Opinionated editor/workspace settings under `/usr/settings`

## Docker Image

### Base Image
- **Base**: `codercom/code-server:4.103.2-focal`

### Build

```bash
# Build the image
./build.sh

# Or manually
docker build -t data-modeling-ide-core .
```

## Usage

```bash
docker run -p 8080:8080 \
  -e PASSWORD=changeme \
  -v $PWD:/home/coder/project \
  data-modeling-ide-core
```

Open http://localhost:8080 and log in with the configured password.

## Customization

- Place additional VSIX files in `extensions/` to auto-install
- Adjust editor preferences in `settings/`
- Initialization scripts in `init/` run on first start to prepare the environment

## Health Checks

```bash
# Check container health
docker inspect --format='{{.State.Health.Status}}' data-modeling-ide-core

# View health check logs
docker inspect --format='{{range .State.Health.Log}}{{.Output}}{{end}}' data-modeling-ide-core
```

## Troubleshooting

- **Cannot access IDE**: Ensure port 8080 is open and mapped
- **Missing tools**: Verify image build completed and PATH includes tools
- **Extension issues**: Validate VSIX files and permissions in `/usr/vsix`

## Getting Help

- **Documentation**: https://wiki.fast.bi
- **Issues**: https://github.com/fast-bi/data-modeling-ide-core/issues
- **Email**: support@fast.bi

## License

This project is licensed under the MIT License - see the LICENSE file for details.
