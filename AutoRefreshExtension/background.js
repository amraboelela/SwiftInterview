
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
    if (request.action === 'showNotification') {
        // Create a Chrome notification for new jobs
        const notificationOptions = {
            type: 'basic',
            iconUrl: 'icon.png',
            title: request.title,
            message: request.message,
            priority: 2
        };

        chrome.notifications.create('newJobsNotification', notificationOptions, (notificationId) => {
            if (chrome.runtime.lastError) {
                console.error('Notification error:', chrome.runtime.lastError);
            } else {
                console.log('Notification created:', notificationId);
            }
        });
    } else if (request.action === 'checkChanges') {
        const currentTime = new Date();
        console.log('checkChanges, Current time:', currentTime);
        chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
            tabs.forEach((tab) => {
                chrome.tabs.sendMessage(tab.id, { action: 'refresh' });
            });
        });
        chrome.tabs.query({ active: false, currentWindow: true }, (tabs) => {
            tabs.forEach((tab) => {
                chrome.tabs.sendMessage(tab.id, { action: 'refresh' });
            });
        });
        chrome.tabs.query({ active: false, currentWindow: false }, (tabs) => {
            tabs.forEach((tab) => {
                chrome.tabs.sendMessage(tab.id, { action: 'refresh' });
            });
        });
    }
});
