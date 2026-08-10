# Ling Shell

**Ling Shell** is a Niri-only UI shell written in **QuickShell** and integrated with **NixOS**.

---

## Installation

### Manual Installation (Non-NixOS)

> Suitable for Niri users on other distros or for quick testing.

#### Requirements

- `niri`
- `quickshell` (qs)
- `Qt 6`
- `git`

#### Dependencies

For manual installation, you will need to install the following dependencies yourself:

**Runtime Dependencies:**

- `brightnessctl`

`cava` and `matugen` are bundled for spectrum visuals and dynamic themes. `ddcutil`, `mpvpaper`, `mpv`, and `xdg-utils` remain optional; add them to `extraRuntimePackages` for external DDC brightness, live wallpapers, or notification hyperlinks.

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
qs --no-duplicate -p .
```

> ⚠️ This method **does not install system-wide**, and is only for testing or development.
> Run Ling Shell from exactly one startup path. Do not enable the systemd service and a
> `spawn-at-startup "ling-shell"` entry at the same time.

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
        services.ling-shell.extraRuntimePackages = with pkgs; [ ddcutil mpvpaper mpv xdg-utils ];
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
| `extraRuntimePackages` | list of packages | `[]` | Optional executables such as `ddcutil`, `mpvpaper`, and `mpv`; Cava and Matugen are bundled. |

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
| `colours`        | attrset, string or path | `{}`                                   | Ling shell color configuration, written to `~/.local/state/quickshell/ling/colours.json`.     |
| `extraRuntimePackages` | list of packages | `[]` | Optional executables such as `ddcutil`, `mpvpaper`, and `mpv`; Cava and Matugen are bundled. |

### Development Shell

To enter a development shell with all the necessary dependencies, run:

```bash
nix develop
```

---

## Autostart with a Wayland Compositor

`ling-shell` can be started automatically when you log in to your Wayland compositor.

If you are using the NixOS or home-manager module with `systemd.enable = true;`, this should be handled automatically.

If you are not using the systemd service, you can configure Niri to launch `ling-shell` at startup.

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
