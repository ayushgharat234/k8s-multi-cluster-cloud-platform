const express = require('express');
const client = require('prom-client');
const app = express();
const port = 8080;
// Metrics
const collectDefaultMetrics = client.collectDefaultMetrics;
collectDefaultMetrics();
app.get('/', (req, res) => {
  res.send('Hello from ${{ values.name }}!');
});
app.get('/health', (req, res) => {
  res.json({ status: 'ok', version: '1.0.0' });
});
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', client.register.contentType);
  res.end(await client.register.metrics());
});
app.listen(port, () => {
  console.log(`App listening at http://localhost:${port}`);
});