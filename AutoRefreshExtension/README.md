# Auto Refresh Extension

A Chrome browser extension that automatically monitors and refreshes job search pages on LinkedIn, Upwork, and Indeed, alerting users when new job postings appear.

## Overview

This extension helps job seekers stay on top of new opportunities by automatically refreshing job search pages and detecting when new job titles appear. It stores a baseline of current jobs and alerts you only when genuinely new listings show up.

## Features

- **Automatic Page Monitoring**: Continuously monitors LinkedIn, Upwork, and Indeed job search pages
- **Smart Job Detection**: Extracts job titles and compares against stored baseline to detect only real new postings
- **Site-Specific Audio Alerts**: Plays a different sound for LinkedIn vs Upwork/Indeed
- **Chrome Notifications**: Displays a browser notification showing how many new jobs were found
- **Quiet Hours**: No alerts between 11 PM and 5 AM
- **Persistent Storage**: Remembers previous job listings per hostname to accurately detect changes
- **Multi-Tab Support**: Works across multiple browser tabs simultaneously

## Supported Websites

- **LinkedIn**: `www.linkedin.com/jobs/search/*` and `www.linkedin.com/jobs/search-results/*`
- **Upwork**: `www.upwork.com/nx/*`
- **Indeed**: `www.indeed.com/*`

## Installation

### Load as Unpacked Extension (Development)

1. Open Chrome and navigate to `chrome://extensions/`
2. Enable "Developer mode" in the top right corner
3. Click "Load unpacked"
4. Select the `AutoRefreshExtension` directory
5. The extension icon should appear in your browser toolbar

### Sound Permission Setup

To ensure notifications can play sound:

1. Open the job site (e.g. **linkedin.com**) in Chrome
2. Click the 🔒 icon in the address bar
3. Select **Site settings**
4. Find **Sound**
5. Set to **Allow**

## Usage

1. Navigate to a job search page on LinkedIn, Upwork, or Indeed
2. The extension automatically begins monitoring the page
3. When new job postings are detected, you'll hear an audio alert and see a Chrome notification
4. Click the extension icon to manually trigger a refresh check

## How It Works

1. **Job Extraction**: The content script extracts job titles from the page using site-specific selectors
2. **Baseline Storage**: On first run, current job titles are stored in Chrome's local storage (no alert)
3. **Change Detection**: On each subsequent refresh, new job titles are compared with stored ones
4. **Alert**: When new jobs are found, an audio alert plays and a Chrome notification is shown
5. **Auto Refresh**: The page automatically reloads every 2–5 minutes (randomized) to check for new listings

## Files

### Core Files

- **manifest.json** - Extension configuration and permissions
- **background.js** - Service worker handling notifications and tab communication
- **content.js** - Content script that monitors job listings and triggers alerts
- **popup.html** - Simple UI with manual refresh button
- **popup.js** - Popup button event handler

### Assets

- **icon.png** - Extension icon
- **alertData.js** - Base64-encoded MP3 audio alert (used for Upwork/Indeed)
- **linkedinAlertData.js** - Base64-encoded WAV audio alert (used for LinkedIn)
- **cartoon-game.mp3** - Source MP3 for Upwork/Indeed alert sound
- **alert1.wav** - Source WAV for LinkedIn alert sound

### Utility Files

- **encode.js** - Node.js script to encode audio files to base64 for use in content scripts

## Permissions

- **tabs** - Access to browser tabs for sending refresh messages
- **activeTab** - Interact with the currently active tab
- **storage** - Store previous job listings per site
- **scripting** - Execute content scripts
- **notifications** - Display Chrome notifications when new jobs are found

## Debugging

1. View content script logs in the page console (F12) — all logs are prefixed with `#refresh`
2. View service worker logs:
   - Go to `chrome://extensions/`
   - Find "Auto Refresh Extension"
   - Click "service worker" to open DevTools

### Testing Alerts Manually

To force an alert without waiting for new jobs, run this in the **service worker console**:

```javascript
chrome.storage.local.set({'www.linkedin.com-previousJobs': ['fake old job']})
```

Then refresh the LinkedIn jobs page — it will detect all current jobs as new and fire the alert.

### Re-encoding Audio

To update the audio files, run in the `AutoRefreshExtension` directory:

```bash
node -e "
const fs = require('fs');
const data = fs.readFileSync('alert1.wav');
fs.writeFileSync('linkedinAlertData.js', 'let linkedinAlertData = \"' + data.toString('base64') + '\";');
"
```

### Modifying Monitored Sites

Edit the `matches` array in `manifest.json`:

```json
"matches": [
    "*://www.linkedin.com/jobs/search/*",
    "*://www.upwork.com/nx/*",
    "*://your-site.com/*"
]
```

## Privacy

- All data is stored locally in your browser
- No data is sent to external servers
- Only monitors the specific websites listed in the manifest
- All comparison and detection happens entirely in your browser

## Limitations

- Only works on Chrome-based browsers (Chrome, Edge, Brave, etc.)
- Requires job search pages to be open in browser tabs
- Audio alerts may not play if browser audio is muted or autoplay is blocked
- Does not work in incognito mode by default

## Author

Created by Amr Aboelela
