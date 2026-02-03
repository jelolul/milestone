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
  <a href="https://godotengine.org/download" target="_blank" style="text-decoration:none"><img alt="Godot v4.6+" src="https://img.shields.io/badge/godot-v4.6%2B-478cbf?style=flat-square&logo=godotengine&labelColor=e8e8e8"></a>
  <a href="https://github.com/jelolul/milestone/releases" target="_blank" style="text-decoration:none"><img alt="Latest GitHub release" src="https://img.shields.io/github/v/release/jelolul/milestone?include_prereleases&style=flat-square&labelColor=e8e8e8&color=ffcc3f"></a>
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

1. Download the latest release from the [releases page](https://github.com/jelolul/milestone/releases).
2. Extract the `addons` folder from the downloaded ZIP file into your root project directory.
3. Open your Godot project and navigate to the `Project` → `Project Settings` → `Plugins`.
4. Enable the Milestone plugin by checking the box next to it.
5. Restart the engine/reload the project _(optional, but recommended)_
6. You will see a new `Milestone` tab at the top in the editor. Click on it to open the Milestone editor.

## Usage

1. Open the Milestone editor by clicking on the `Milestone` tab in the editor.
2. Modify the plugin settings in the `Settings` tab to your liking.
3. Create and manage your achievements in the `Achievements` tab.
4. Create a new `AchievementNotifier` node in your scene to allow for displaying achievements in-game.
5. Modify `AchievementNotifier` properties to change the behavior of the notifications, their position and the notification component.
6. Use the `AchievementManager` API to track player progress and completion of achievements.

---

## License

This project is licensed under the [MIT License](https://github.com/jelolul/milestone?tab=MIT-1-ov-file).
