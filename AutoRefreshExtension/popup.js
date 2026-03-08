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
