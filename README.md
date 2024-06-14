# Neon Caron

Neon Caron is an iOS application that brings augmented reality (AR) experiences to life using ARKit. The app showcases various collections of paintings and videos, providing an immersive and interactive way to explore art.

## Features

- **Augmented Reality**: Utilizes ARKit to display AR experiences triggered by image recognition.
- **Video Caching**: Implements a caching system for video playback using `CachingPlayerItem`.
- **Download Manager**: Manages file downloads efficiently, including background downloads and notifications.

## Project Structure

- **Base.lproj**
  - `LaunchScreen.storyboard`: The launch screen of the application.
  - `Main.storyboard`: The main storyboard containing the app's navigation flow.
- **Common**
  - `SDDownloadManager`: Handles file downloads with progress tracking and background support.
  - `CachingPlayerItem`: Extends `AVPlayerItem` to add caching capabilities.
  - `PaintingCollections`: Contains the URLs and names of painting collections.
  - `UserDefaultWrapper`: Property wrapper for managing `UserDefaults`.
- **Controllers**
  - `HomeViewController`: Displays the list of painting collections.
  - `ViewController`: Manages the AR experience.
- **Models**
  - `CodableHelper`: Aids in JSON encoding and decoding.
- **Resources**
  - `Assets.xcassets`: Contains image resources used in the app.
- **Views**
  - `HomeTableCell`: Custom table view cell for displaying collection items.

## Getting Started

### Prerequisites

- Xcode 12.0 or later
- iOS 14.0 or later

### Installation

1. Clone the repository:
    ```sh
    git clone https://github.com/emmanuelmartinezfreelancer/neon-caron-app.git
    ```
2. Open the project in Xcode:
    ```sh
    cd neon-caron-app
    open NeonCaron.xcodeproj
    ```
3. Build and run the project on a physical iOS device (ARKit requires a device with an A9 chip or later).

## Usage

- Launch the app and point the camera at any of the supported images to trigger the AR experience.
- The app will automatically download and cache video content as needed.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [ARKit](https://developer.apple.com/arkit/)
- [Vuforia](https://www.ptc.com/en/products/augmented-reality/vuforia)

## Contact

For any inquiries or support, please contact [emmanuel@neoncaron.com](mailto:emmanuel@neoncaron.com).

