const express = require("express");
const {
  getAttendance,
  markAttendance,
} = require("../controllers/attendanceController");
const {
  authenticate,
  authorize,
} = require("../middleware/auth");

const router = express.Router();

router.get("/", authenticate, getAttendance);

router.post(
  "/",
  authenticate,
  authorize("admin", "warden"),
  markAttendance
);

module.exports = router;
