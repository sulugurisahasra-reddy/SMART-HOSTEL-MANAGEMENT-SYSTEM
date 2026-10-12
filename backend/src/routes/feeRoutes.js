const express = require("express");
const {
  getFees,
  createFee,
} = require("../controllers/feeController");
const {
  authenticate,
  authorize,
} = require("../middleware/auth");

const router = express.Router();

router.get("/", authenticate, getFees);

router.post(
  "/",
  authenticate,
  authorize("admin", "warden", "university"),
  createFee
);

module.exports = router;
