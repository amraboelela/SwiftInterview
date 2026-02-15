
let url = new URL(location.href);
let hostname = url.hostname;
let storageKey = hostname + '-previousJobs';

// Check if extension context is still valid
function isExtensionContextValid() {
    return !!(chrome.runtime && chrome.runtime.id);
}

// Save job titles to storage
function saveJobTitlesToStorage(jobTitles) {
    if (!isExtensionContextValid()) {
        console.log('Extension context invalidated - skipping storage operation');
        return;
    }

    const storageObject = {};
    storageObject[storageKey] = jobTitles;

    chrome.storage.local.set(storageObject, () => {
        if (chrome.runtime.lastError) {
            console.error('Storage error:', chrome.runtime.lastError);
            return;
        }
        console.log('Job titles stored in local storage');
    });
}

function retrieveJobTitlesFromStorage(callback) {
    if (!isExtensionContextValid()) {
        console.log('Extension context invalidated - skipping storage retrieval');
        callback([]);
        return;
    }

    chrome.storage.local.get([storageKey], (result) => {
        if (chrome.runtime.lastError) {
            console.error('Storage error:', chrome.runtime.lastError);
            callback([]);
            return;
        }
        const storedJobs = result[storageKey] || [];
        if (callback) {
            callback(storedJobs);
        }
    });
}

function openMailApp(subject, body) {
    const mailtoLink = document.createElement('a');
    const encodedSubject = encodeURIComponent(subject);
    const encodedBody = encodeURIComponent(body);

    mailtoLink.href = 'mailto:recipient@' + hostname + '?subject=' + encodedSubject + '&body=' + encodedBody;
    document.body.appendChild(mailtoLink);
    mailtoLink.click();
    mailtoLink.remove();
}

// Extract job titles from the page
function extractJobTitles() {
    const jobTitles = [];

    // Query the live DOM directly (not parsing HTML string)
    const jobTiles = document.querySelectorAll('a[data-test*="job-tile-title-link"]');

    jobTiles.forEach(tile => {
        const title = tile.textContent.trim().toLowerCase();
        if (title) {
            jobTitles.push(title);
        }
    });

    console.log('Found ' + jobTitles.length + ' job titles');
    return jobTitles;
}

function getNewJobs(oldJobs, newJobs) {
    // Find jobs that are in the new list but not in the old list
    // Use Set for O(1) lookup performance
    const oldSet = new Set(oldJobs);
    const addedJobs = newJobs.filter(job => !oldSet.has(job));

    if (addedJobs.length > 0) {
        console.log('New jobs found:', addedJobs.length);
        console.log('New job titles:', addedJobs.join('\n'));
    }

    return addedJobs;
}

let pendingAudioAlert = false;

function checkChanges() {
    console.log('checkChanges()');
    retrieveJobTitlesFromStorage((previousJobs) => {
        const currentJobs = extractJobTitles();
        const newJobs = getNewJobs(previousJobs, currentJobs);

        // Only alert if this is NOT the first run (previousJobs should exist)
        if (newJobs.length > 0 && previousJobs.length > 0) {
            console.log('New jobs detected:\n' + newJobs.join('\n'));

            // Use Chrome notifications (more reliable than audio autoplay)
            if (isExtensionContextValid()) {
                chrome.runtime.sendMessage({
                    action: 'showNotification',
                    title: 'New Jobs Found!',
                    message: `${newJobs.length} new job(s) detected`,
                    jobs: newJobs
                });
            }

            // Try to play audio immediately
            playAlertAudio();

            // Save updated job list for next comparison
            saveJobTitlesToStorage(currentJobs);
        } else if (previousJobs.length === 0) {
            console.log('Initial load - storing', currentJobs.length, 'jobs without alert');
            // Save current jobs for next comparison
            saveJobTitlesToStorage(currentJobs);
        } else {
            console.log('No new jobs found');
            playAlertAudio();
        }
    });
}

function playAlertAudio() {
    // Check if alertData is available
    if (typeof alertData !== 'undefined') {
        console.log('alertData is available, attempting to play audio');
        const audio = new Audio("data:audio/mpeg;base64," + alertData);
        audio.play().then(() => {
            console.log('Audio played successfully!');
            pendingAudioAlert = false;
        }).catch(err => {
            console.log('Audio autoplay blocked, will retry on user interaction:', err.message);
            pendingAudioAlert = true;
        });
    } else {
        console.error('alertData is not defined - audio cannot play');
    }
}

// Listen for ANY user interaction to play pending audio
document.addEventListener('click', () => {
    if (pendingAudioAlert) {
        console.log('User clicked - playing pending audio alert');
        playAlertAudio();
    }
}, { once: false });

/*window.addEventListener("load", function() {
    console.log("window.addEventListener(load");
    // Code to execute after reload
    checkChanges();
});*/

chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
    // Get the current date and time
    const currentDate = new Date();

    // Get the current hour (in 24-hour format)
    const currentHour = currentDate.getHours();

    // Check if the current hour is after 11 PM and before 5 AM
    const isQuietHours = currentHour >= 23 || currentHour < 5;
    if (isQuietHours) {
        console.log('It is after 11 PM or before 5 AM - quiet hours.');
    } else {
        console.log("(request.action === 'refresh')");
        if (request.action === 'refresh') {
            console.log("yes it is refresh!");
            const currentJobs = extractJobTitles();
            saveJobTitlesToStorage(currentJobs);
            document.location.reload();
        }
    }
});

//console.log("before checkChanges();");
checkChanges();
const minutes = Math.floor(Math.random() * 1) + 1; // between 5 and 15

setTimeout(() => {
    console.log("setTimeout - preparing to refresh");
    const currentJobs = extractJobTitles();
    saveJobTitlesToStorage(currentJobs);

    // Safety check: only reload if page is fully loaded
    if (document.readyState === 'complete') {
        document.location.reload();
    } else {
        console.log("Page not fully loaded, skipping reload");
    }
}, minutes * 60 * 1000);

