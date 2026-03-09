# Dashbin

Dashbin is a modern macOS application featuring an integrated terminal and an interactive command shelf.

## Downloading and Installing

You can easily download and install the latest version of Dashbin directly from the releases page of this repository. The application is compiled as a Universal Binary, meaning the download natively supports both **Apple Silicon (M1/M2/M3)** and **Intel** Macs.

### Requirements

- macOS 14.0 (Sonoma) or newer.

### Step-by-step Installation Guide

1. **Find the Release**
   Navigate to the **Releases** section on the right-hand sidebar of this GitHub repository. If you are currently on a specific branch, look for the release or tag associated with the branch's latest updates.

2. **Download the App**
   Under the **Assets** section of the latest relevant release, click to download the application file (typically named `Dashbin.zip`, `Dashbin.app.zip`, or `Dashbin.dmg`).

3. **Install the Application**
   - Locate the downloaded file in your `Downloads` folder.
   - **If it's a `.zip` file:** Double-click it to extract the `Dashbin.app` file.
   - **If it's a `.dmg` file:** Double-click to mount it, then drag the `Dashbin` app icon into the provided **Applications** folder shortcut.
   - Once extracted or mounted, ensure `Dashbin.app` is moved to your **Applications** directory (`/Applications`).

4. **First-Time Launch (Important)**
   Because Dashbin is downloaded directly from GitHub rather than the Mac App Store, macOS Gatekeeper may display a warning stating that the app "cannot be opened because the developer cannot be verified" when you try to open it normally.
   
   **To successfully open the app for the first time:**
   - Open your **Applications** folder in Finder.
   - **Control-click** (or Right-click) on the `Dashbin.app` icon.
   - Select **Open** from the context menu.
   - A dialog will appear asking for confirmation to open the application. Click **Open**.
   
   *(Note: You will only need to perform this step once. On all subsequent launches, you can open Dashbin normally from your Applications folder, Launchpad, or Spotlight search).*

## Features

- **Built-in Terminal**: Powered by SwiftTerm.
- **Dynamic Command Shelf**: Store, search, and edit common commands.
- **Customizable Themes**: Supports Dark Modern, Light Modern, and other high-contrast themes out of the box.

Enjoy using Dashbin!
