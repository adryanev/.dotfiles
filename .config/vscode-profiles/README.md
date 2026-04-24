# VSCode Extension Profiles

This directory contains profile definitions for managing VSCode extensions efficiently.

## Quick Start

```bash
# List all profiles
vscode-profile-manager.sh list

# Install extensions
vscode-profile-manager.sh install core
vscode-profile-manager.sh install-multiple core web laravel
```

**Note**: The script is linked to `~/Scripts` and available in your PATH after running `deploy-dotfiles.sh`.

## Available Profiles

| Profile    | Extensions | Description                          |
|------------|------------|--------------------------------------|
| core       | 27         | Essential extensions for all dev     |
| web        | 20         | React, TypeScript, Tailwind          |
| laravel    | 28         | PHP/Laravel development              |
| flutter    | 13         | Flutter/Dart development             |
| swift      | 4          | Swift/iOS development                |
| android    | 7          | Android/Kotlin development           |
| java       | 4          | Java development                     |
| python     | 7          | Python development                   |
| go         | 1          | Go development                       |
| devops     | 5          | Docker, YAML, env files              |
| api        | 3          | Swagger, XML, Proto                  |
| markdown   | 2          | Markdown editing                     |
| build      | 2          | Make, TOML                           |
| themes     | 12         | UI themes and icon packs             |
| utils      | 12         | Utility extensions                   |
| collab     | 2          | Collaboration tools                  |
| debug      | 2          | Debugging and testing                |

**Total**: 149 extensions across 17 profiles

## Common Use Cases

### Laravel Developer
```bash
vscode-profile-manager.sh install-multiple core web laravel themes utils
```

### Flutter Developer
```bash
vscode-profile-manager.sh install-multiple core flutter themes utils
```

### Full-Stack Developer
```bash
vscode-profile-manager.sh install-multiple core web python go devops themes utils
```

## Profile Format

Each profile is a JSON file following VSCode's `extensions.json` format:

```json
{
  "recommendations": [
    "publisher.extension-name",
    "another.extension"
  ]
}
```

## Management Commands

```bash
# Compare installed vs profile
vscode-profile-manager.sh compare flutter

# Create workspace recommendations
cd /path/to/project
vscode-profile-manager.sh workspace laravel

# List installed extensions
vscode-profile-manager.sh installed
```

## More Information

See [../.config/vscode-profiles.md](../vscode-profiles.md) for detailed documentation.
