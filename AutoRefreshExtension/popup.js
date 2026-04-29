document.getElementById('refreshButton').addEventListener('click', function() {
    chrome.tabs.query({ active: true, currentWindow: true }, function(tabs) {
        chrome.tabs.sendMessage(tabs[0].id, { action: 'refresh' });
    });
});

document.getElementById('resetButton').addEventListener('click', function() {
    chrome.tabs.query({ active: true, currentWindow: true }, function(tabs) {
        const url = new URL(tabs[0].url);
        const key = url.hostname + '-previousJobs';
        chrome.storage.local.remove(key, function() {
            chrome.tabs.reload(tabs[0].id);
        });
    });
});

const pauseButton = document.getElementById('pauseButton');

chrome.storage.local.get('paused', function(result) {
    pauseButton.textContent = result.paused ? 'Resume' : 'Pause';
});

pauseButton.addEventListener('click', function() {
    chrome.storage.local.get('paused', function(result) {
        const nowPaused = !result.paused;
        chrome.storage.local.set({ paused: nowPaused }, function() {
            pauseButton.textContent = nowPaused ? 'Resume' : 'Pause';
        });
    });
});
