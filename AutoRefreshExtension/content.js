
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
        console.log('#refresh Extension context invalidated - skipping storage operation');
        return;
    }

    const storageObject = {};
    storageObject[storageKey] = jobTitles;

    chrome.storage.local.set(storageObject, () => {
        if (chrome.runtime.lastError) {
            console.error('#refresh Storage error:', chrome.runtime.lastError);
            return;
        }
        console.log('#refresh Job titles stored in local storage');
    });
}

function retrieveJobTitlesFromStorage(callback) {
    if (!isExtensionContextValid()) {
        console.log('#refresh Extension context invalidated - skipping storage retrieval');
        callback([]);
        return;
    }

    chrome.storage.local.get([storageKey], (result) => {
        if (chrome.runtime.lastError) {
            console.error('#refresh Storage error:', chrome.runtime.lastError);
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

    if (hostname.includes('linkedin.com')) {
        const seen = new Set();

        // Layout 1: search results page — span.f5bf1c61 contains titles and timestamps
        document.querySelectorAll('span.f5bf1c61').forEach(tile => {
            let title = tile.textContent.trim().toLowerCase();
            if (!title || title.startsWith('posted on') || title.length < 10 || title.length > 200) return;
            title = title.replace(/\s*\(verified job\)\s*$/, '').trim();
            if (title && !seen.has(title)) { seen.add(title); jobTitles.push(title); }
        });

        // Layout 2: job picks / alert view — titles are in <a><strong>
        document.querySelectorAll('a strong').forEach(tile => {
            const title = tile.textContent.trim().toLowerCase();
            if (title && title.length > 10 && title.length < 150 && !seen.has(title)) {
                seen.add(title); jobTitles.push(title);
            }
        });
    } else if (hostname.includes('indeed.com')) {
        const seen = new Set();

        // Layout 1: standard search results — h2.jobTitle span
        document.querySelectorAll('h2.jobTitle span').forEach(tile => {
            const title = tile.textContent.trim().toLowerCase();
            if (title && title.length > 5 && title.length < 200 && !seen.has(title)) {
                seen.add(title); jobTitles.push(title);
            }
        });

        // Layout 2: data-testid attribute
        if (jobTitles.length === 0) {
            document.querySelectorAll('[data-testid="job-title"] span, [data-testid="job-title"]').forEach(tile => {
                const title = tile.textContent.trim().toLowerCase();
                if (title && title.length > 5 && title.length < 200 && !seen.has(title)) {
                    seen.add(title); jobTitles.push(title);
                }
            });
        }
    } else {
        // Upwork selectors
        const jobTiles = document.querySelectorAll('a[data-test*="job-tile-title-link"]');
        jobTiles.forEach(tile => {
            const title = tile.textContent.trim().toLowerCase();
            if (title) {
                jobTitles.push(title);
            }
        });
    }

    console.log('#refresh Found ' + jobTitles.length + ' job titles');
    return jobTitles;
}

function getNewJobs(oldJobs, newJobs) {
    // Find jobs that are in the new list but not in the old list
    // Use Set for O(1) lookup performance
    const oldSet = new Set(oldJobs);
    const addedJobs = newJobs.filter(job => !oldSet.has(job));

    if (addedJobs.length > 0) {
        console.log('#refresh New jobs found:', addedJobs.length);
    }

    return addedJobs;
}

let pendingAudioAlert = false;

function checkChanges() {
    console.log('#refresh checkChanges()');
    retrieveJobTitlesFromStorage((previousJobs) => {
        const currentJobs = extractJobTitles();
        const newJobs = getNewJobs(previousJobs, currentJobs);

        // Only alert if this is NOT the first run (previousJobs should exist)
        if (newJobs.length > 0 && previousJobs.length > 0) {
            console.log('#refresh New jobs detected:\n' + newJobs.join('\n'));

            // Use Chrome notifications (more reliable than audio autoplay)
            if (isExtensionContextValid()) {
                try {
                    chrome.runtime.sendMessage({
                        action: 'showNotification',
                        title: 'New Jobs Found!',
                        message: `${newJobs.length} new job(s) detected`,
                        jobs: newJobs
                    });
                } catch (e) {
                    console.log('#refresh Could not send message to extension:', e.message);
                }
            }

            // Try to play audio immediately
            playAlertAudio();

            // Save updated job list for next comparison
            saveJobTitlesToStorage(currentJobs);
        } else if (previousJobs.length === 0) {
            console.log('#refresh Initial load - storing', currentJobs.length, 'jobs without alert');
            // Save current jobs for next comparison
            saveJobTitlesToStorage(currentJobs);
        } else {
            console.log('#refresh No new jobs found');
        }
    });
}

function playAlertAudio() {
    let audioData, mimeType;
    if (hostname.includes('linkedin.com') && typeof linkedinAlertData !== 'undefined') {
        audioData = linkedinAlertData;
        mimeType = 'audio/wav';
    } else if (typeof alertData !== 'undefined') {
        audioData = alertData;
        mimeType = 'audio/mpeg';
    } else {
        console.error('#refresh No alert audio data available');
        return;
    }
    console.log('#refresh Attempting to play audio for', hostname);
    const audio = new Audio('data:' + mimeType + ';base64,' + audioData);
    audio.play().then(() => {
        console.log('#refresh Audio played successfully!');
        pendingAudioAlert = false;
    }).catch(err => {
        console.log('#refresh Audio autoplay blocked, will retry on user interaction:', err.message);
        pendingAudioAlert = true;
    });
}

// Listen for ANY user interaction to play pending audio
document.addEventListener('click', () => {
    if (pendingAudioAlert) {
        console.log('#refresh User clicked - playing pending audio alert');
        playAlertAudio();
    }
}, { once: false });

chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
    // Get the current date and time
    const currentDate = new Date();

    // Get the current hour (in 24-hour format)
    const currentHour = currentDate.getHours();

    // Check if the current hour is after 11 PM and before 5 AM
    const isQuietHours = currentHour >= 23 || currentHour < 5;
    if (isQuietHours) {
        console.log('#refresh It is after 11 PM or before 5 AM - quiet hours.');
    } else {
        console.log("#refresh (request.action === 'refresh')");
        if (request.action === 'refresh') {
            console.log("#refresh yes it is refresh!");
            const currentJobs = extractJobTitles();
            saveJobTitlesToStorage(currentJobs);
            document.location.reload();
        }
    }
});

//console.log("before checkChanges();");
if (hostname.includes('linkedin.com') || hostname.includes('indeed.com')) {
    setTimeout(checkChanges, 3000);
} else {
    checkChanges();
}
const minutes = Math.floor(Math.random() * 3) + 2; // between 2 and 5 minutes

setTimeout(() => {
    console.log("#refresh setTimeout - preparing to refresh");
    const currentJobs = extractJobTitles();
    saveJobTitlesToStorage(currentJobs);

    // Safety check: only reload if page is fully loaded
    if (document.readyState === 'complete') {
        document.location.reload();
    } else {
        console.log("#refresh Page not fully loaded, skipping reload");
    }
}, minutes * 60 * 1000);

