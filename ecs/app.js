const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.send('Hello from Microservice');
});

app.listen(port, () => {
  console.log(`Hello from microservice - Microservice running on port ${port}`);
});
