pragma Singleton
import Quickshell
import QtQuick
import qs.config
import qs.commons
import qs.services
import qs.modules.panels.settings as SettingsPanel
import ".."
import "../../../../helpers/fuzzysort.js" as Fuzzysort

Singleton {
  id: root
  property list<QtObject> list: variants.instances

  Variants {
    id: variants
    model: [
      {
        name: "Settings",
        icon: "settings",
        description: "Configure system settings",
        command: ["open-panel", "settings", SettingsPanel.Panel.System]
      },
      {
        name: "Personalization",
        icon: "palette",
        description: "Customize the look and feel of the system",
        command: ["open-panel", "settings", SettingsPanel.Panel.Personalization]
      },
      {
        name: "Dark",
        icon: "dark_mode",
        description: "Switch to dark color scheme",
        command: ["theme-mode", "dark"]
      },
      {
        name: "Light",
        icon: "light_mode",
        description: "Switch to light color scheme",
        command: ["theme-mode", "light"]
      },
      {
        name: "Lock",
        icon: "lock",
        description: "Lock the current session",
        command: ["compositor", "lock"]
      },
      {
        name: "Lock & Sleep",
        icon: "bedtime",
        description: "Lock the session and suspend the system",
        command: ["compositor", "lockAndSuspend"]
      },
      {
        name: "Logout",
        icon: "exit_to_app",
        description: "Log out of the current session",
        command: ["compositor", "logout"]
      },
      {
        name: "Reboot",
        icon: "cached",
        description: "Restart the system",
        command: ["compositor", "reboot"]
      },
      {
        name: "Shutdown",
        icon: "power_settings_new",
        description: "Power off the system",
        command: ["compositor", "shutdown"]
      },
      {
        name: "Sleep",
        icon: "bedtime",
        description: "Suspend the system to save power",
        command: ["compositor", "suspend"]
      },
      {
        name: "Wallpaper",
        icon: "image",
        description: "Change the desktop wallpaper",
        command: ["autocomplete", "wallpaper"]
      }
    ]
    Action {}
  }

  component Action: QtObject {
    required property var modelData
    readonly property string name: modelData.name ?? "Unnamed"
    readonly property string desc: modelData.description ?? "No description"
    readonly property string icon: modelData.icon ?? "help_outline"
    readonly property list<string> command: modelData.command ?? []
    readonly property bool enabled: modelData.enabled ?? true

    function onClicked(list: AppList): void {
      if (command.length === 0)
        return;

      // Handle autocomplete for wallpaper
      if (command[0] === "autocomplete" && command.length > 1) {
        list.searchInput.inputItem.text = `${Config.launcher.actionPrefix}${command[1]} `;
        return;
      }

      if (command[0] === "open-panel" && command.length > 1) {
        const panel = VisibilityService.getPanel(command[1], list.panel.screen);
        if (command[1] === "settings") {
          panel.requestedTab = command[2];
        }
        panel.open();
        return;
      }

      // Handle color mode changes
      if (command[0] === "theme-mode" && command.length > 1) {
        Settings.appearance.theme.mode = command[1];
        list.panel.close();
        return;
      }

      // Handle compositor actions
      if (command[0] === "compositor" && command.length > 1) {
        const compositorAction = command[1];
        list.panel.close();

        // Call CompositorService methods
        switch (compositorAction) {
        case "shutdown":
          CompositorService.shutdown();
          break;
        case "reboot":
          CompositorService.reboot();
          break;
        case "logout":
          CompositorService.logout();
          break;
        case "lock":
          CompositorService.lock();
          break;
        case "suspend":
          CompositorService.suspend();
          break;
        case "lockAndSuspend":
          CompositorService.lockAndSuspend();
          break;
        default:
        }
        return;
      }

      // Fallback to executing command directly
      list.panel.close();
      Quickshell.execDetached(command);
    }
  }

  function transformSearch(search: string): string {
    return search.slice(Config.launcher.actionPrefix.length);
  }

  function query(search: string): list<var> {
    search = transformSearch(search);
    if (!search || search.length === 0)
      return [...list];
    const results = Fuzzysort.go(search, list, {
      all: true,
      keys: ["name"]
    });
    return results.map(r => r.obj);
  }
}
