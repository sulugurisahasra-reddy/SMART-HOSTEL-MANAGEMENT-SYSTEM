const express = require("express");
const cors = require("cors");
require("dotenv").config();

const pool = require("./config/postgres");
const connectMongoDB = require("./config/mongodb");

const authRoutes = require("./routes/authRoutes");
const studentRoutes = require("./routes/studentRoutes");
const hostelRoutes = require("./routes/hostelRoutes");
const allocationRoutes = require("./routes/allocationRoutes");
const feeRoutes = require("./routes/feeRoutes");
const complaintRoutes = require("./routes/complaintRoutes");
const attendanceRoutes = require("./routes/attendanceRoutes");
const visitorRoutes = require("./routes/visitorRoutes");
const dashboardRoutes = require("./routes/dashboardRoutes");

const app = express();

const allowedOrigins = (process.env.CORS_ORIGINS || "http://localhost:5173")
  .split(",")
  .map((origin) => origin.trim())
  .filter(Boolean);

app.use(
  cors({
    origin(origin, callback) {
      if (!origin || allowedOrigins.includes(origin)) {
        return callback(null, true);
      }

      return callback(new Error("CORS origin not allowed"));
    },
  })
);
app.use(express.json());

app.get("/", (req, res) => {
  res.json({
    success: true,
    message: "SmartStay AI API is running",
  });
});

app.get("/api/health", async (req, res) => {
  try {
    const result = await pool.query("SELECT NOW()");

    res.json({
      success: true,
      application: "SmartStay AI",
      backend: "online",
      databases: {
        postgresql: "connected",
        mongodb: "connected",
      },
      postgresTime: result.rows[0].now,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Database health check failed",
      error: error.message,
    });
  }
});

app.use("/api/auth", authRoutes);
app.use("/api/students", studentRoutes);
app.use("/api/hostels", hostelRoutes);
app.use("/api/allocations", allocationRoutes);
app.use("/api/fees", feeRoutes);
app.use("/api/complaints", complaintRoutes);
app.use("/api/attendance", attendanceRoutes);
app.use("/api/visitors", visitorRoutes);
app.use("/api/dashboard", dashboardRoutes);

app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: "API endpoint not found",
  });
});

app.use((error, req, res, next) => {
  console.error(error);

  res.status(500).json({
    success: false,
    message: "Internal server error",
  });
});

const PORT = process.env.PORT || 5050;

async function startServer() {
  try {
    await pool.query("SELECT 1");
    console.log("PostgreSQL connected");

    await connectMongoDB();

    app.listen(PORT, () => {
      console.log(`SmartStay API running on http://localhost:${PORT}`);
    });
  } catch (error) {
    console.error("Server startup failed:", error.message);
    process.exit(1);
  }
}

startServer();
