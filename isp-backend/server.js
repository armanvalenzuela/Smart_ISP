// server.js
const express = require("express");
const cors = require("cors");
const axios = require("axios");
const fs = require("fs");
require("dotenv").config();

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static("public")); // serve your web GUI

const COLLECTORS_FILE = "./collectors.json";
const ADMINS_FILE = "./admins.json";
const DATA_FILE = "./subscribers.json";
const GENIEACS_API = process.env.GENIEACS_API || "http://localhost:7557";
const PORT = process.env.PORT || 4000;

// --- Helper functions ---
const loadFile = (file) =>
  fs.existsSync(file) ? JSON.parse(fs.readFileSync(file)) : [];
const saveFile = (file, data) =>
  fs.writeFileSync(file, JSON.stringify(data, null, 2));

const loadSubs = () => loadFile(DATA_FILE);
const saveSubs = (subs) => saveFile(DATA_FILE, subs);
const loadCollectors = () => loadFile(COLLECTORS_FILE);
const saveCollectors = (collectors) => saveFile(COLLECTORS_FILE, collectors);
const loadAdmins = () => loadFile(ADMINS_FILE);
const saveAdmins = (admins) => saveFile(ADMINS_FILE, admins);

// ---------------- ROUTES ----------------

// 🧩 Add or update subscriber
app.post("/api/subscribers", (req, res) => {
  const {
    name,
    plan,
    town,
    serial,
    paymentStatus,
    routerStatus,
    lastPaymentDate,
    phone,
  } = req.body;

  if (!name || !serial) {
    return res.status(400).json({ error: "Name & Serial required" });
  }

  let subs = loadSubs();
  let sub = subs.find((s) => s.serial === serial);

  if (sub) {
    Object.assign(sub, {
      name,
      plan,
      town,
      paymentStatus,
      routerStatus,
      lastPaymentDate,
      phone,
    });
  } else {
    subs.push({
      id: Date.now(),
      name,
      plan,
      town,
      serial,
      paymentStatus: paymentStatus || "Pending",
      routerStatus: routerStatus || "Offline",
      lastPaymentDate: lastPaymentDate || "",
      phone,
      active: true,
    });
  }

  saveSubs(subs);
  res.json({ message: "Subscriber saved", subscribers: subs });
});

// 🧩 Get all subscribers
app.get("/api/subscribers", (req, res) => {
  res.json(loadSubs());
});

// 🧩 Get all collectors
app.get("/api/collectors", (req, res) => {
  res.json(loadCollectors());
});

// 🧩 Add or update collector
app.post("/api/collectors", (req, res) => {
  const { name, town, activeClients, lastCollectionDate, performanceScore, coords, password, phone } = req.body;
  
  if (!name || !coords || !password) {
    return res.status(400).json({ error: "Name, coordinates and password are required" });
  }

  let collectors = loadCollectors();
  let collector = collectors.find((c) => c.name === name);
  
  if (collector) {
    Object.assign(collector, { town, activeClients, lastCollectionDate, performanceScore, coords, password, phone });
  } else {
    collectors.push({
      id: Date.now(),
      name,
      password,
      town,
      phone,
      activeClients: activeClients || 0,
      lastCollectionDate: lastCollectionDate || new Date().toISOString().split('T')[0],
      performanceScore: performanceScore || 0,
      coords,
    });
  }
  
  saveCollectors(collectors);
  res.json({ message: "Collector saved", collectors });
});

// 🧩 Admin registration
app.post("/api/admins", (req, res) => {
  const { username, email, password } = req.body;

  if (!username || !email || !password) {
    return res.status(400).json({ error: "Username, email and password required" });
  }

  let admins = loadAdmins();
  if (admins.find((a) => a.username === username)) {
    return res.status(400).json({ error: "Admin already exists" });
  }

  admins.push({
    id: Date.now(),
    username,
    email,
    password,
    createdAt: new Date().toISOString(),
  });

  saveAdmins(admins);
  res.json({ message: "Admin registered successfully", admins });
});

// 🧩 Unified login for both Admin & Collector
app.post("/api/login", (req, res) => {
  const { username, password, role } = req.body;

  if (!username || !password) {
  return res.status(400).json({ success: false, message: "Missing credentials" });
}

// Check admin first
const admins = loadAdmins();
const admin = admins.find((a) => a.username === username && a.password === password);
if (admin)
  return res.json({
    success: true,
    role: "admin",
    data: { username: admin.username, email: admin.email },
  });

// Then check collector
const collectors = loadCollectors();
const collector = collectors.find(
  (c) => c.name === username && c.password === password
);
if (collector)
  return res.json({
    success: true,
    role: "collector",
    data: { name: collector.name, town: collector.town },
  });

res.status(401).json({ success: false, message: "Invalid credentials" });
});

// 🧩 Fetch live devices
app.get("/api/devices", async (req, res) => {
  try {
    const { data } = await axios.get(`${GENIEACS_API}/devices`);
    res.json(Object.values(data));
  } catch (err) {
    console.error("Error fetching devices:", err.message);
    res.status(500).json({ error: "Failed to fetch GenieACS devices" });
  }
});

// 🧩 Merge subscribers + devices
app.get("/api/merged", async (req, res) => {
  try {
    const subs = loadSubs();
    const { data } = await axios.get(`${GENIEACS_API}/devices`);
    const devices = Object.values(data);

    const merged = subs.map((sub) => {
      const dev = devices.find(
        (d) => d._id === sub.serial.toString() || d._id.endsWith(sub.serial)
      );
      return {
        ...sub,
        lastInform: dev?.lastInform || null,
        model: dev?.summary?.match(/ModelName\s=\s([^\s]+)/)?.[1] || "Unknown",
        online: !!dev,
      };
    });

    res.json(merged);
  } catch (err) {
    console.error("Merge error:", err.message);
    res.status(500).json({ error: "Failed to merge data" });
  }
});

// 🧩 Serve index.html
app.get("/", (req, res) => {
  res.sendFile(__dirname + "/public/index.html");
});

app.listen(PORT, () => {
  console.log(`🚀 ISP backend running at http://localhost:${PORT}`);
});
