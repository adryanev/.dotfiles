# VSCode Extension Profiles

Instead of installing all 155 extensions globally, consider using VSCode profiles for different development contexts:

## Core Extensions (Always Active)
```json
{
  "recommendations": [
    "github.copilot",
    "github.copilot-chat",
    "anthropic.claude-code",
    "eamodio.gitlens",
    "vscodevim.vim",
    "ms-vscode-remote.remote-ssh",
    "ms-vscode-remote.remote-ssh-edit",
    "ms-vscode-remote.vscode-remote-extensionpack",
    "ms-vscode-remote.remote-containers",
    "ms-vscode.remote-explorer",
    "ms-vscode.remote-server",
    "editorconfig.editorconfig",
    "alefragnani.bookmarks",
    "gruntfuggly.todo-tree",
    "donjayamanne.githistory",
    "github.vscode-github-actions",
    "github.vscode-pull-request-github",
    "paragdiwan.gitpatch",
    "wakatime.vscode-wakatime",
    "sleistner.vscode-fileutils",
    "patbenatar.advanced-new-file",
    "ryu1kn.partial-diff",
    "wmaurer.change-case",
    "usernamehw.errorlens",
    "tombonnike.vscode-status-bar-format-toggle"
  ]
}
```

## Web Development Profile
```json
{
  "recommendations": [
    "bradlc.vscode-tailwindcss",
    "esbenp.prettier-vscode",
    "christian-kohler.npm-intellisense",
    "christian-kohler.path-intellisense",
    "burkeholland.simple-react-snippets",
    "infeng.vscode-react-typescript",
    "formulahendry.auto-close-tag",
    "formulahendry.auto-complete-tag",
    "formulahendry.auto-rename-tag",
    "austenc.tailwind-docs",
    "heybourn.headwind",
    "mgmcdermott.vscode-language-babel",
    "wix.vscode-import-cost",
    "xabikos.javascriptsnippets",
    "jasonnutter.search-node-modules",
    "ritwickdey.liveserver",
    "stylelint.vscode-stylelint",
    "yoavbls.pretty-ts-errors",
    "paulshen.paul-typescript-toolkit",
    "oven.bun-vscode"
  ]
}
```

## PHP/Laravel Profile
```json
{
  "recommendations": [
    "bmewburn.vscode-intelephense-client",
    "onecentlin.laravel-extension-pack",
    "onecentlin.laravel-blade",
    "onecentlin.laravel5-snippets",
    "shufo.vscode-blade-formatter",
    "mohamedbenhida.laravel-intellisense",
    "ryannaddy.laravel-artisan",
    "austenc.laravel-blade-spacer",
    "austenc.laravel-docs",
    "ahinkle.laravel-model-snippets",
    "alperenersoy.filament-snippets",
    "amiralizadeh9480.laravel-extra-intellisense",
    "amirmarmul.laravel-blade-vscode",
    "cierra.livewire-vscode",
    "cjhowe7.laravel-blade",
    "codingyu.laravel-goto-view",
    "ctf0.laravel-goto-controller",
    "glitchbl.laravel-create-view",
    "ihunte.laravel-blade-wrapper",
    "juniorpeixoto.vscode-filamentphp-helpers",
    "naoray.laravel-goto-components",
    "pgl.laravel-jump-controller",
    "mehedidracula.php-namespace-resolver",
    "neilbrayfield.php-docblocker",
    "wongjn.php-sniffer",
    "xdebug.php-debug",
    "xdebug.php-pack",
    "zobo.php-intellisense"
  ]
}
```

## Flutter/Dart Profile
```json
{
  "recommendations": [
    "dart-code.dart-code",
    "dart-code.flutter",
    "nash.awesome-flutter-snippets",
    "felixangelov.bloc",
    "jeroen-meijer.pubspec-assist",
    "blaugold.melos-code",
    "flutterbricksproductions.flutterbricks",
    "gaetschwartz.build-runner",
    "hirantha.json-to-dart",
    "hzgood.dart-data-class-generator",
    "innwin.i18n-arb-editor",
    "kiritchoukc.flutter-clean-architecture",
    "localizely.flutter-intl"
  ]
}
```

## Swift/iOS Profile
```json
{
  "recommendations": [
    "swiftlang.swift-vscode",
    "sweetpad.sweetpad",
    "github.copilot-for-xcode",
    "ihsanis.scrcpy"
  ]
}
```

## Android/Kotlin Profile
```json
{
  "recommendations": [
    "esafirm.kotlin-formatter",
    "fwcd.kotlin",
    "mathiasfrohlich.kotlin",
    "loyieking.smalise",
    "surendrajat.apklab",
    "naco-siren.gradle-language",
    "vscjava.vscode-gradle"
  ]
}
```

## Java Development Profile
```json
{
  "recommendations": [
    "redhat.java",
    "vscjava.vscode-java-debug",
    "vscjava.vscode-java-dependency",
    "vscjava.vscode-java-pack",
    "vscjava.vscode-java-test",
    "vscjava.vscode-maven",
    "visualstudioexptteam.intellicode-api-usage-examples",
    "visualstudioexptteam.vscodeintellicode"
  ]
}
```

## Python Profile
```json
{
  "recommendations": [
    "ms-python.python",
    "ms-python.vscode-pylance",
    "ms-python.debugpy",
    "ms-python.vscode-python-envs",
    "kevinrose.vsc-python-indent",
    "donjayamanne.python-environment-manager"
  ]
}
```

## Go Development Profile
```json
{
  "recommendations": [
    "golang.go"
  ]
}
```

## DevOps/Infrastructure Profile
```json
{
  "recommendations": [
    "ms-azuretools.vscode-docker",
    "ms-azuretools.vscode-containers",
    "hashicorp.terraform",
    "redhat.ansible",
    "redhat.vscode-yaml",
    "mikestead.dotenv",
    "mindaro-dev.file-downloader"
  ]
}
```

## API Development Profile
```json
{
  "recommendations": [
    "42crunch.vscode-openapi",
    "arjun.swagger-viewer",
    "dotjoshjohnson.xml",
    "zxh404.vscode-proto3"
  ]
}
```

## Documentation/Markdown Profile
```json
{
  "recommendations": [
    "davidanson.vscode-markdownlint",
    "yzhang.markdown-all-in-one",
    "hnw.vscode-auto-open-markdown-preview"
  ]
}
```

## Build Tools Profile
```json
{
  "recommendations": [
    "ms-vscode.makefile-tools",
    "tamasfe.even-better-toml"
  ]
}
```

## Theme and UI Extensions
```json
{
  "recommendations": [
    "catppuccin.catppuccin-vsc",
    "enkia.tokyo-night",
    "mvllow.rose-pine",
    "monokai.theme-monokai-pro-vscode",
    "azemoh.one-monokai",
    "davidbwaters.macos-modern-theme",
    "ms-vscode.theme-tomorrowkit",
    "mrworkman.papercolor-vscode-redux",
    "zhuangtongfa.material-theme",
    "thang-nm.catppuccin-perfect-icons",
    "vscode-icons-team.vscode-icons",
    "file-icons.file-icons"
  ]
}
```

## Utility Extensions
```json
{
  "recommendations": [
    "albert.tabout",
    "johnpapa.vscode-cloak",
    "kisstkondoros.vscode-gutter-preview",
    "liamhammett.inline-parameters",
    "naumovs.color-highlight",
    "nhoizey.gremlins",
    "pflannery.vscode-versionlens",
    "selcuk-usta.code-complexity-report-generator",
    "jock.svg",
    "vintharas.learn-vim",
    "google.gemini-cli-vscode-ide-companion"
  ]
}
```

## Collaboration Profile
```json
{
  "recommendations": [
    "ms-vsliveshare.vsliveshare",
    "icrawl.discord-vscode"
  ]
}
```

## Debug/Testing Profile
```json
{
  "recommendations": [
    "llvm-vs-code-extensions.lldb-dap",
    "vadimcn.vscode-lldb",
    "diemasmichiels.emulate"
  ]
}
```

## How to Use Profiles

### Creating Profiles
1. Open VSCode
2. Click on the profile icon (person icon) in the bottom left
3. Select "Create Profile..."
4. Name your profile (e.g., "Laravel Development", "Flutter", etc.)
5. Choose which extensions to include

### Switching Profiles
1. Click the profile icon
2. Select the profile you want to use
3. VSCode will reload with only those profile's extensions active

### Importing Extension Lists
1. Create a new profile
2. Go to Extensions view (Ctrl+Shift+X)
3. Click the "..." menu → "Install from VSIX..." or use the command palette
4. Install extensions from the recommendations above

### Benefits of Using Profiles
- **Performance**: Fewer active extensions = faster VSCode startup
- **Context**: Only relevant extensions for your current project
- **Cleaner UI**: Less cluttered activity bar and command palette
- **Memory Usage**: Lower RAM consumption with fewer extensions
- **Debugging**: Easier to identify extension conflicts

### Recommended Profile Strategy
1. **Always Active**: Keep Core Extensions in default profile
2. **Project-Based**: Switch to specific profile based on project type
3. **Minimal Setup**: Start with core + one language profile
4. **Add as Needed**: Install additional extensions only when required

### Profile Management Tips
- Export profiles to share with team members
- Use workspace recommendations (`.vscode/extensions.json`) for project-specific needs
- Regularly review and clean up unused extensions
- Consider separate profiles for debugging vs development

## Extension Categories Summary

- **Core/Essential**: 26 extensions
- **Web Development**: 20 extensions
- **PHP/Laravel**: 27 extensions
- **Flutter/Dart**: 13 extensions
- **Swift/iOS**: 4 extensions
- **Android/Kotlin**: 7 extensions
- **Java**: 8 extensions
- **Python**: 6 extensions
- **Go**: 1 extension
- **DevOps**: 7 extensions
- **API Development**: 4 extensions
- **Documentation**: 3 extensions
- **Build Tools**: 2 extensions
- **Themes/UI**: 13 extensions
- **Utilities**: 11 extensions
- **Collaboration**: 2 extensions
- **Debug/Testing**: 3 extensions

**Total**: 155 extensions organized into 17 profiles

By using profiles, you can reduce the active extension count from 155 to approximately 30-40 for any given development session.