<p align="center">
  <img width="350" alt="Milestone logo" src="https://raw.githubusercontent.com/jelolul/milestone/refs/heads/main/addons/milestone/icons/editor/logo.svg">
</p>

<h1 align="center">Milestone</h1>
<p align="center">
  Create and manage achievements through an in-engine editor and display them in your game!
</p>
<p align="center">
  <img alt="Version badge" src="https://img.shields.io/badge/milestone_version-v1.0.0.beta-eee?style=flat&logoSize=auto&labelColor=eee&color=FFCC3F">
  <a href="https://godotengine.org/download/windows/">
    <img alt="Godot badge" src="https://img.shields.io/badge/godot-v4.4%2B-478cbf?style=flat&logo=godotengine&logoSize=auto&labelColor=eee&color=478cbf">
  </a>
</p>


## Table of Contents
- [Note](#note)
- [Features](#features)
- [Installation](#installation)
- [API](#api)
- [License](#license)

## Note
This plugin is still in beta and may contain bugs or incomplete features. Please report any issues you encounter on the [GitHub repository](https://github.com/jelolul/milestone/issues).

## Features
- Easily create and manage achievements with an in-editor editor
- Customize the look, behavior, and visibility of each achievement
- Display achievements in-game using a simple API
- Track player progress, completion, and rare achievements
- Seamless integration into existing Godot projects
- Lightweight and optimized for performance

## Installation
To install Milestone, follow these steps:
1. Make sure you have Godot **4.4** or later installed (i didn't test older versions).
1. Download the latest release from the [releases page](https://github.com/jelolul/milestone/releases).
2. Extract the `addons` folder from the downloaded ZIP file into your root project directory. Should look like this:
   ```
   my_game/
   ├── addons/
   │   └── milestone/
   │       ├── autoload/
   │       ├── components/
   │       ├── scripts/
   │       └── ...
   ├── project.godot
   └── ...
   ```
3. Open your Godot project and navigate to the `Project → Project Settings → Plugins`.
4. Enable the Milestone plugin by checking the box next to it.
5. You will see a new `Milestone` tab at the top in the editor. Click on it to open the Milestone manager. Have fun!

## Usage
1. Open the Milestone manager by clicking on the `Milestone` tab in the editor.
2. Modify the plugin settings in the `Settings` tab to your liking.
3. Create and manage your achievements in the `Achievements` tab.
4. Create a new `AchievementNotifier` node in your scene to allow for displaying achievements in-game.
5. Modify `AchievementNotifier` properties to change the behavior of the notifications, their position and the notification component.
6. Use the `AchievementManager` API to track player progress and completion of achievements.

## API
The `AchievementManager` API provides a simple way to manage and track achievements in your game. You can use the following methods to interact with achievements:
| Method                              | Description                                 |
| ----------------------------------- | ------------------------------------------- |
| `AchievementManager.unlock_achievement(achievement_id: String)`      | Unlocks the achievement with the given ID.   |
| `AchievementManager.is_unlocked(achievement_id: String)` | Returns true if the achievement is unlocked. |
| `AchievementManager.progress_achievement(achievement_id: String, progress_amount: int)`      | Progresses the achievement with the given ID using the specified progress amount.  |
| `AchievementManager.get_progress(achievement_id: String)`      | Returns the progress of the achievement.  |
| `AchievementManager.reset_achievements()`             | Resets all achievements.                     |
| `AchievementManager.reset_achievement(achievemente_id: String)`             | Resets the achievement with the given ID.                     |
| `AchievementManager.unlock_all_achievements()`             | Unlocks all achievements.                     |

## License
This project is licensed under the [MIT License](https://github.com/jelolul/milestone?tab=MIT-1-ov-file).