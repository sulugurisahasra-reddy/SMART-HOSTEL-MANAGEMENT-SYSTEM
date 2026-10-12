const express = require("express");
const {
  getAllocations,
  allocateRoom,
  vacateRoom,
} = require("../controllers/allocationController");
const {
  authenticate,
  authorize,
} = require("../middleware/auth");

const router = express.Router();

router.get("/", authenticate, authorize("admin", "warden", "university"), getAllocations);

router.post(
  "/",
  authenticate,
  authorize("admin", "warden"),
  allocateRoom
);

router.put(
  "/:id/vacate",
  authenticate,
  authorize("admin", "warden"),
  vacateRoom
);

module.exports = router;
