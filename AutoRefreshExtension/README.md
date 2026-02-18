# Auto Refresh Extension

A Chrome browser extension that automatically monitors and refreshes job search pages on Indeed and Upwork, alerting users when new job postings appear.

## Overview

This extension helps job seekers stay on top of new opportunities by automatically refreshing job search pages and detecting when new content appears. It intelligently filters out HTML/CSS/JavaScript changes to focus only on meaningful content updates.

## Features

- **Automatic Page Monitoring**: Continuously monitors Indeed and Upwork job search pages
- **Smart Content Detection**: Filters out technical changes (HTML tags, CSS, scripts) to detect only real content updates
- **Audio Alerts**: Plays a sound notification when new job postings are detected
- **Manual Refresh**: Popup button to manually trigger a refresh check
- **Persistent Storage**: Remembers previous page content to accurately detect changes
- **Multi-Tab Support**: Works across multiple browser tabs simultaneously

## Supported Websites

- **Indeed**: `www.indeed.com/*`
- **Upwork**: `www.upwork.com/nx/search/*`

## Installation

### Load as Unpacked Extension (Development)

1. Open Chrome and navigate to `chrome://extensions/`
2. Enable "Developer mode" in the top right corner
3. Click "Load unpacked"
4. Select the `AutoRefreshExtension` directory
5. The extension icon should appear in your browser toolbar

### Sound Permission Setup

To ensure Upwork notifications can play sound:

1. Open **upwork.com** in Chrome
2. Click the 🔒 icon in the address bar
3. Select **Site settings**
4. Find **Sound**
5. Set to **Allow**

### Usage

1. Navigate to a job search page on Indeed or Upwork
2. The extension automatically begins monitoring the page
3. When new content is detected, you'll hear an audio alert
4. Click the extension icon to manually trigger a refresh check

## Files

### Core Files

- **manifest.json** - Extension configuration and permissions
- **background.js** - Service worker handling tab communication
- **content.js** - Content script that monitors page changes
- **popup.html** - Simple UI with manual refresh button
- **popup.js** - Popup button event handler

### Assets

- **icon.png** - Extension icon (128x128)
- **alert1.wav** - Audio alert sound for notifications
- **cartoon-game.mp3** - Alternative audio file

### Utility Files

- **encode.js** - Text encoding utilities
- **diff_js.txt** - Change detection documentation
- **cartoon.txt** - Text content for testing

## How It Works

1. **Content Monitoring**: The content script runs on supported websites and captures page content
2. **Storage**: Current page content is stored in Chrome's local storage
3. **Change Detection**: On each refresh, new content is compared with stored content
4. **Filtering**: HTML tags, CSS, and JavaScript are filtered out to identify real changes
5. **Notification**: When meaningful changes are detected, an audio alert plays

## Permissions

The extension requires the following permissions:

- **tabs** - Access to browser tabs
- **activeTab** - Interact with the currently active tab
- **storage** - Store previous page content
- **scripting** - Execute content scripts
- **notifications** - Display notifications (future feature)

## Technical Details

### Manifest Version

Uses Manifest V3, the latest Chrome extension architecture.

### Content Filtering

The extension filters out numerous HTML/CSS/JavaScript patterns to avoid false positives:
- Script tags and inline JavaScript
- CSS styles and stylesheets
- Meta tags and HTML structure
- SVG and image elements
- Common CSS variables and styling attributes

This ensures alerts are triggered only for actual content changes like new job postings.

## Development

### Debugging

1. Open Chrome DevTools on the extension popup (right-click → Inspect)
2. View console logs in the extension's service worker:
   - Go to `chrome://extensions/`
   - Find "Auto Refresh Extension"
   - Click "service worker" to open DevTools
3. View content script logs in the page's console (F12)

### Modifying Monitored Sites

Edit the `matches` array in `manifest.json`:

```json
"matches": [
    "*://www.indeed.com/*",
    "*://www.upwork.com/nx/search/*",
    "*://your-site.com/*"
]
```

### Customizing Refresh Interval

The refresh timing is controlled in `content.js`. Modify the timing logic to adjust how frequently pages are checked.

## Privacy

- All data is stored locally in your browser
- No data is sent to external servers
- Only monitors the specific websites listed in the manifest
- Content comparison happens entirely in your browser

## Limitations

- Only works on Chrome-based browsers (Chrome, Edge, Brave, etc.)
- Requires pages to be open in browser tabs
- Audio alerts may not work if browser audio is muted
- Does not work in incognito mode by default

## Future Enhancements

- Configurable refresh intervals via options page
- Support for additional job search websites
- Browser notification support
- Customizable audio alerts
- Settings for filtering sensitivity

## License

See main repository LICENSE file for details.

## Author

Created by Amr Aboelela
