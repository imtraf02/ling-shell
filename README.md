# Ling Shell

**Ling Shell** is a UI shell written in **QuickShell**, designed to run on Wayland compositors (like **niri**, **Hyprland**) and integrates well with **NixOS**.

---

## Installation

### Manual Installation (Non-NixOS)

> Suitable for other distros or for quick testing.

#### Requirements

- `A Wayland compositor`
- `quickshell` (qs)
- `Qt 6`
- `git`

#### Dependencies

For manual installation, you will need to install the following dependencies yourself:

**Runtime Dependencies:**

- `brightnessctl`
- `cava`
- `cliphist`
- `ddcutil`
- `matugen`
- `wlsunset`
- `wl-clipboard`
- `imagemagick`
- `wget`

**Fonts:**

- [Material Symbols](https://fonts.google.com/icons)
- [Rubik](https://fonts.google.com/specimen/Rubik)
- [Nerd Fonts (Caskaydia Cove)](https://www.nerdfonts.com/font-downloads)

#### Clone the repo

```bash
git clone https://github.com/imtraf02/ling-shell.git
cd ling-shell
```

#### Run directly with QuickShell

```bash
qs -p .
```

> ⚠️ This method **does not install system-wide**, and is only for testing or development.

---

## Nix

`ling-shell` is built with Nix and provides a flake with packages, modules, and a development shell.

### Flake

Add `ling-shell` to your `flake.nix` inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    ling-shell = {
      url = "github:imtraf02/ling-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

### Packages

You can install the `ling-shell` package by adding it to your `systemPackages`.

Example:

```nix
# flake.nix
# ...
outputs = { self, nixpkgs, ling-shell, ... }: {
  nixosConfigurations.my-machine = nixpkgs.lib.nixosSystem {
    # ...
    modules = [
      ({ pkgs, ... }: {
        environment.systemPackages = [
          ling-shell.packages.${pkgs.system}.default
        ];
      })
    ];
  };
};
```

### NixOS Module

The flake provides a NixOS module to enable `ling-shell` as a systemd service.

**Usage:**

```nix
# flake.nix
# ...
outputs = { self, nixpkgs, ling-shell, ... }: {
  nixosConfigurations.my-machine = nixpkgs.lib.nixosSystem {
    # ...
    modules = [
      ling-shell.nixosModules.default
      ({ pkgs, ... }: {
        services.ling-shell.enable = true;
      })
    ];
  };
};
```

**Options:**

| Name      | Type    | Default                                | Description                                    |
| --------- | ------- | -------------------------------------- | ---------------------------------------------- |
| `enable`  | boolean | `false`                                | Enable Ling shell systemd service.             |
| `package` | package | `ling-shell.packages.<system>.default` | The ling-shell package to use.                 |
| `target`  | string  | `graphical-session.target`             | The systemd target for the ling-shell service. |

### Home Manager Module

A Home Manager module is also provided for enabling and configuring the shell.

**Usage:**

```nix
# home.nix
{ inputs, ... }: {
  imports = [
    inputs.ling-shell.homeModules.default
  ];

  programs.ling-shell = {
    enable = true;
    systemd.enable = true; # to run ling-shell as a systemd service
  };
}
```

Then rebuild your system:

```bash
sudo nixos-rebuild switch --flake .#<hostname>
```

**Options:**

| Name             | Type                    | Default                                | Description                                                                                   |
| ---------------- | ----------------------- | -------------------------------------- | --------------------------------------------------------------------------------------------- |
| `enable`         | boolean                 | `false`                                | Enable Ling shell configuration.                                                              |
| `systemd.enable` | boolean                 | `false`                                | Enable Ling shell systemd integration.                                                        |
| `package`        | package                 | `ling-shell.packages.<system>.default` | The ling-shell package to use.                                                                |
| `settings`       | attrset, string or path | `{}`                                   | Ling shell configuration settings, written to `~/.local/state/quickshell/ling/settings.json`. |
| `config`         | attrset, string or path | `{}`                                   | Ling shell configuration, written to `~/.config/quickshell/ling/config.json`.                 |
| `colours`        | attrset, string or path | `{}`                                   | Ling shell color configuration, written to `~/.local/state/quickshell/ling/colours.json`.     |

### Development Shell

To enter a development shell with all the necessary dependencies, run:

```bash
nix develop
```

---

## Autostart with a Wayland Compositor

`ling-shell` can be started automatically when you log in to your Wayland compositor.

If you are using the NixOS or home-manager module with `systemd.enable = true;`, this should be handled automatically.

If you are not using the systemd service, you can configure your compositor to launch `ling-shell` at startup.

**Example for niri:**

Add the following to `~/.config/niri/config.kdl`:

```kdl
spawn-at-startup "ling-shell"
```

---

## Related Projects

- [QuickShell](https://git.outfoxxed.me/outfoxxed/quickshell)
- [niri](https://github.com/YaLTeR/niri)
- [NixOS](https://nixos.org)

## 📄 License

MIT License - see [LICENSE](./LICENSE) for details.
