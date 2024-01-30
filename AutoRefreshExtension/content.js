//let previousContent = '';



// Save text to storage
function saveTextToStorage(text) {
    
    chrome.storage.local.set({ previousContent: text }, function() {
      //console.log('Values stored in local storage');
        //alert('Text saved to storage:' + text);
    });
}

// Retrieve text from storage
function retrieveTextFromStorage(callback) {
    
    chrome.storage.local.get(['previousContent'], function(result) {
        if (callback) {
            callback(result.previousContent);
        }
    });
}

function openMailApp(subject, body) {
    const mailtoLink = document.createElement('a');
    const url = new URL(location.href);
    const hostname = url.hostname;
    
    const encodedSubject = encodeURIComponent(subject);
    const encodedBody = encodeURIComponent(body);
    
    mailtoLink.href = 'mailto:recipient@' + hostname + '?subject=' + encodedSubject + '&body=' + encodedBody;
    mailtoLink.click();
}

function getDifferentLines(str1, str2) {
    const lines1 = str1.split('\n');
    const lines2 = str2.split('\n');
    
    let uniqueLines2 = lines2.filter(line => !lines1.includes(line));
    let rejectedTerms = [
        "window.",
        "<script",
        "script>",
        "stylesheet",
        "<style",
        "</style>",
        "<meta",
        "<body",
        "jobsearch-JapanPage",
        "span class=\"date\"",
        "span class=\"myJobsState\"",
        "<html",
        "<link",
        "function ",
        "if (",
        "}",
        ".mosaic",
        "this[",
        "script.",
        "<img ",
        "</main>",
        "<li>",
        "</li>",
        "mosaic-zone",
        "jobsearch-Main"
    ]
    let filteredLines = uniqueLines2.filter(line => !rejectedTerms.some(substring => line.includes(substring)));

    result = filteredLines.join('\n');
    return result.trim();
}

function checkChanges() {
    retrieveTextFromStorage(function(previousContent) {
        let content = document.documentElement.outerHTML;
        if (content != previousContent) {
            let differentLines = getDifferentLines(previousContent, content)
            previousContent = content;
            if (differentLines.length === 0) {
            } else {
                openMailApp('There is new content', differentLines);
                saveTextToStorage(previousContent);
            }
        }
    });
}

window.addEventListener("load", function() {
    // Code to execute after reload
    checkChanges();
});

chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
    if (request.action === 'refresh') {
        document.location.reload();
    }
});

const minutes = Math.floor(Math.random() * 10) + 5; // between 10 and 20

setInterval(function() {
    chrome.runtime.sendMessage({ action: 'checkChanges' });
}, minutes * 60 * 1000);

