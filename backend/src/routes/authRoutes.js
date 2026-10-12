const express = require("express");
const {
  register,
  login,
} = require("../controllers/authController");

const {
  authenticate,
  authorize,
} = require("../middleware/auth");

const router = express.Router();

router.post("/register", authenticate, authorize("admin", "university"), register);
router.post("/login", login);

module.exports = router;
