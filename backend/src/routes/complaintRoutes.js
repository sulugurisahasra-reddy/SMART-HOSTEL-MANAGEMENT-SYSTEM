const express = require("express");
const {
  getComplaints,
  createComplaint,
  updateComplaint,
} = require("../controllers/complaintController");
const {
  authenticate,
  authorize,
} = require("../middleware/auth");

const router = express.Router();

router.get("/", authenticate, getComplaints);

router.post(
  "/",
  authenticate,
  createComplaint
);

router.put(
  "/:id",
  authenticate,
  authorize("admin", "warden"),
  updateComplaint
);

module.exports = router;
