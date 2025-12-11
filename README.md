> [!NOTE] 
> This plugin is still in beta and may contain bugs or incomplete features. Please report any issues you encounter on the [GitHub repository](https://github.com/jelolul/milestone/issues).

<p align="center">
  <img alt="Milestone logo" src="https://raw.githubusercontent.com/jelolul/milestone/refs/heads/main/assets/logo/cover.png">
</p>

<h1 align="center">Milestone</h1>
<p align="center">
  Create and manage achievements through an in-engine editor and display them in your game!
</p>
<p align="center">
  <a href="https://godotengine.org/download/windows/">
	<img alt="Godot badge" src="https://img.shields.io/badge/godot-v4.4%2B-478cbf?style=flat&logo=godotengine&logoSize=auto&labelColor=eee&color=478cbf">
  </a>
</p>

## Table of Contents

> [!IMPORTANT]
> The API has been moved and can be found [here](https://github.com/jelolul/milestone/wiki/API).

- [Features](#features)
- [Installation](#installation)
- [License](#license)

## Features

- Easily create and manage achievements with an in-engine editor
- Customize the look, behavior, and visibility of each achievement
- Display achievements in-game using a simple API
- Track player progress, completion, and rare achievements
- Seamless integration into existing Godot projects
- Lightweight and optimized for performance

## Installation

To install Milestone, follow these steps:

1. Make sure you have Godot **4.4** or later installed (i didn't test older versions, but i'm using UIDs which weren't really used in 4.3).
2. Download the latest release from the [releases page](https://github.com/jelolul/milestone/releases).
3. Extract the `addons` folder from the downloaded ZIP file into your root project directory.
4. Open your Godot project and navigate to the `Project` → `Project Settings` → `Plugins`.
5. Enable the Milestone plugin by checking the box next to it.
6. Restart the engine/reload the project _(optional, but recommended)_ 
7. You will see a new `Milestone` tab at the top in the editor. Click on it to open the Milestone manager. Have fun!

## Usage

1. Open the Milestone manager by clicking on the `Milestone` tab in the editor.
2. Modify the plugin settings in the `Settings` tab to your liking.
3. Create and manage your achievements in the `Achievements` tab.
4. Create a new `AchievementNotifier` node in your scene to allow for displaying achievements in-game.
5. Modify `AchievementNotifier` properties to change the behavior of the notifications, their position and the notification component.
6. Use the `AchievementManager` API to track player progress and completion of achievements.

---

## License

This project is licensed under the [MIT License](https://github.com/jelolul/milestone?tab=MIT-1-ov-file).
