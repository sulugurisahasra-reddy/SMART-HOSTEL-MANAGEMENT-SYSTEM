const express = require("express");
const {
  getVisitors,
  createVisitor,
  checkoutVisitor,
} = require("../controllers/visitorController");
const {
  authenticate,
  authorize,
} = require("../middleware/auth");

const router = express.Router();

router.get("/", authenticate, getVisitors);

router.post(
  "/",
  authenticate,
  createVisitor
);

router.put(
  "/:id/checkout",
  authenticate,
  authorize("admin", "warden"),
  checkoutVisitor
);

module.exports = router;
