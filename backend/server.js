const express = require('express');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 3000;

console.log("🚗 Demo ...");

// ✅ Vehicle API route (dynamic)
app.get('/api/vehicles', (req, res) => {
  console.log("🚗 Generating new vehicle data...");

  const statuses = ['Charging', 'In Transit', 'Idle'];
  const locations = ['San Jose, CA', 'Los Angeles, CA', 'Phoenix, AZ', 'Austin, TX', 'Fremont, CA'];

  const getRandom = (arr) => arr[Math.floor(Math.random() * arr.length)];
  const getBattery = () => Math.floor(Math.random() * 51) + 50;
  const getRange = () => Math.floor(Math.random() * 201) + 100;

  const vehicles = ['LUCID-001', 'LUCID-002', 'LUCID-003'].map(id => ({
    id,
    location: getRandom(locations),
    status: getRandom(statuses),
    battery: getBattery(),
    range: getRange()
  }));

  res.json(vehicles);
});

// ✅ Test route
app.get('/hello', (req, res) => {
  console.log("💬 /hello endpoint hit");
  res.send("Hello from the backend");
});

// ✅ Serve static files only for root path and fallback
app.use('/', express.static(path.join(__dirname, '../frontend')));

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Lucid Dashboard running at http://localhost:${PORT}`);
});
