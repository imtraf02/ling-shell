const keybinds = [
	{
		title: "Core functions",
		actions: [
			{
				fn: "Application Launcher",
				command: "ling-shell ipc call launcher toggle",
				description: "Toggle the application launcher",
			},
			{
				fn: "Bar",
				command: "ling-shell ipc call bar toggle",
				description: "Toggle the bar",
			},
			{
				fn: "Session",
				command: "ling-shell ipc call session toggle",
				description: "Toggle the session menu",
			},
		],
	},

	{
		title: "Audio",
		actions: [
			{
				fn: "Volume Up",
				command: "ling-shell ipc call audio volume raise",
				description: "Increase the volume",
			},
			{
				fn: "Volume Down",
				command: "ling-shell ipc call audio volume lower",
				description: "Decrease the volume",
			},
			{
				fn: "Mute Audio",
				command: "ling-shell ipc call audio volume mute",
				description: "Toggle audio mute",
			},
			{
				fn: "Mute Microphone",
				command: "ling-shell ipc call audio mic mute",
				description: "Toggle microphone mute",
			},
		],
	},

	{
		title: "Notifications",
		actions: [
			{
				fn: "Clear Notifications",
				command: "ling-shell ipc call notifs clear",
				description: "Clear all notifications",
			},
			{
				fn: "Toggle Do Not Disturb",
				command: "ling-shell ipc call notifs toggleDnd",
				description: "Toggle do not disturb mode",
			},
			{
				fn: "Enable Do Not Disturb",
				command: "ling-shell ipc call notifs enableDnd",
				description: "Enable do not disturb mode",
			},
			{
				fn: "Disable Do Not Disturb",
				command: "ling-shell ipc call notifs disableDnd",
				description: "Disable do not disturb mode",
			},
		],
	},
];
