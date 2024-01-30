
chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
    if (request.action === 'checkChanges') {
        const currentTime = new Date();
        console.log('checkChanges, Current time:', currentTime);
        chrome.tabs.query({ active: true, currentWindow: true }, function(tabs) {
            // You can loop through tabs and send a message to each one
            tabs.forEach(function(tab) {
                chrome.tabs.sendMessage(tab.id, { action: 'refresh' });
            });
        });
        chrome.tabs.query({ active: false, currentWindow: true }, function(tabs) {
            // You can loop through tabs and send a message to each one
            tabs.forEach(function(tab) {
                chrome.tabs.sendMessage(tab.id, { action: 'refresh' });
            });
        });
        chrome.tabs.query({ active: false, currentWindow: false }, function(tabs) {
            // You can loop through tabs and send a message to each one
            tabs.forEach(function(tab) {
                chrome.tabs.sendMessage(tab.id, { action: 'refresh' });
            });
        });
    }
});
