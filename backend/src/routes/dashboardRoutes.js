const express = require("express");
const {
  getDashboard,
  getAnalytics,
} = require("../controllers/dashboardController");
const { authenticate } = require("../middleware/auth");

const router = express.Router();

router.get("/", authenticate, getDashboard);
router.get("/analytics", authenticate, getAnalytics);

module.exports = router;
