const Activity = require("../models/Activity");

async function logActivity({
  userId = null,
  action,
  entity,
  entityId = null,
  details = {},
}) {
  try {
    await Activity.create({
      userId,
      action,
      entity,
      entityId,
      details,
    });
  } catch (error) {
    console.error("Activity log failed:", error.message);
  }
}

module.exports = {
  logActivity,
};
