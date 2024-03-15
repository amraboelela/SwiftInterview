const fs = require('fs');

// Read the MP3 file
fs.readFile('cartoon-game.mp3', (err, data) => {
  if (err) {
    console.error('Error reading file:', err);
    return;
  }

  // Encode the data to Base64
  const base64Data = data.toString('base64');

  // Output the Base64-encoded data
  console.log(base64Data);
});

