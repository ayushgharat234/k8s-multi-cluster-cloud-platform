const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({
    message: "Hello from ${{ values.name }}!",
    status: "Running",
    version: "1.0.0"
  });
});

app.get('/healthz', (req, res) => {
  res.status(200).json({ status: "alive" });
});

app.get('/ready', (req, res) => {
  res.status(200).json({ status: "ready" });
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});