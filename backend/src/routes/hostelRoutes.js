const express = require("express");
const {
  getHostels,
  getRooms,
  getRoom,
} = require("../controllers/hostelController");
const { authenticate, authorize } = require("../middleware/auth");

const router = express.Router();

router.get("/", authenticate, authorize("admin", "warden", "university"), getHostels);
router.get("/rooms", authenticate, authorize("admin", "warden", "university"), getRooms);
router.get("/rooms/:id", authenticate, authorize("admin", "warden", "university"), getRoom);

module.exports = router;
