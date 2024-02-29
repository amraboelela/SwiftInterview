
let url = new URL(location.href);
let hostname = url.hostname;
let storageKey = hostname + '-previousContent';

// Save text to storage
function saveTextToStorage(text) {
    var storageObject = {};
    storageObject[storageKey] = text;

    chrome.storage.local.set(storageObject, function() {
        console.log('Value stored in local storage');
        //alert('Text saved to storage: ' + text);
    });
}

function retrieveTextFromStorage(callback) {
    
    chrome.storage.local.get([storageKey], function(result) {
        // result is an object with keys corresponding to the provided array, e.g., { 'yourKey': 'storedValue' }
        var storedText = result[storageKey];

        if (callback) {
            //openMailApp('storedText', storedText);
            callback(storedText);
        }
    });
}

function openMailApp(subject, body) {
    const mailtoLink = document.createElement('a');
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
        "{",
        "}",
        ".mosaic",
        "this[",
        "script.",
        "<img ",
        "</main>",
        "<li",
        "</li>",
        "mosaic-zone",
        "jobsearch-Main",
        "<code",
        "</code",
        "<!---->",
        "<div",
        "</div",
        "<button",
        "</svg>",
        "form>",
        "</span>",
        "<path",
        "performance.mark",
        "<a ",
        "<svg",
        "<span",
        "artdeco-card",
        "Saved jobs",
        "(1)",
        "(32)",
        "37"
    ]
        /*
        "<title>ios developer Jobs in San Jose",
        "urn:li:page",
        "</ul>",
        "data-ember-action",
        "<input",
        "<label",
        "search-reusables",
        "Hatch",
        "Learn how to get started on Upwork",
        "Upwork 101",
        "minutes ago",
        "Boosted Proposals",
        "Show me",
        "$200",
        "<p data-v",
        "slide 1 of",
        "data-occludable-job",
        "Page 1",
        "Vori",
        "--",
        "h4",
        "My Pro",
        "Jobs recommended",
        "Best Matches",
        "Most Recent",
        "U.S. Only",
        "Saved Jobs",
        "Browse jobs",
        "Posted",
        "hours ago",
        "Cookie Settings",
        "(4)",
        "(5)",
        "border-radius: ",
        ".air3-transition-hide-show-enter-active",
        "Select Categories",
        "(6)",
        "Select client locations",
        "Select client time zones",
        "Saving this search will save",
        "(1)",
        "Sort by: Newest",
        "Just not interested",
        "Vague Description",
        "Unrealistic Expectations",
        "Too Many Applicants",
        "Job posted too long ago",
        "Poor reviews about the client",
        "Doesn't Match Skills",
        "I am overqualified",
        "Budget too low",
        "Not in my preferred location",
        "The client will not be notified.",
        "8",
        "+5",
        "+2"
    ]*/
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
            //openMailApp('content != previousContent previousContent', previousContent);
            if (differentLines.length !== 0) {
                openMailApp('There is new content', differentLines);
                //saveTextToStorage(previousContent);
            }
        }
    });
}

window.addEventListener("load", function() {
    // Code to execute after reload
    checkChanges();
});

chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
    // Get the current date and time
    const currentDate = new Date();

    // Get the current hour (in 24-hour format)
    const currentHour = currentDate.getHours();

    // Check if the current hour is after 10 PM (21:00) and before 9 AM (09:00)
    if (currentHour >= 22 || currentHour < 9) {
        console.log('It is after 10 PM or before 9 AM.');
    } else {
        //console.log('It is between 9 AM and 9 PM.');
        if (request.action === 'refresh') {
            previousContent = document.documentElement.outerHTML;
            saveTextToStorage(previousContent);
            document.location.reload();
        }
    }
});

const minutes = Math.floor(Math.random() * 10) + 5; // between 5 and 15

setInterval(function() {
    chrome.runtime.sendMessage({ action: 'checkChanges' });
}, minutes * 60 * 1000);

