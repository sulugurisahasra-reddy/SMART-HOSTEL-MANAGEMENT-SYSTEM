const pool = require("../config/postgres");
const { logActivity } = require("../services/activityService");

async function getFees(req, res) {
  try {
    let query;
    let params = [];

    if (req.user.role === "student") {
      query = `
        SELECT
          f.*,
          s.student_number,
          s.name AS student_name
        FROM fees f
        JOIN students s ON s.student_id = f.student_id
        WHERE s.user_id = $1
        ORDER BY f.fee_id DESC
      `;
      params = [req.user.userId];
    } else {
      query = `
        SELECT
          f.*,
          s.student_number,
          s.name AS student_name
        FROM fees f
        JOIN students s ON s.student_id = f.student_id
        ORDER BY f.fee_id DESC
      `;
    }

    const result = await pool.query(query, params);

    res.json({
      success: true,
      fees: result.rows,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch fees",
      error: error.message,
    });
  }
}

async function createFee(req, res) {
  try {
    if (!["warden", "university"].includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: "Only staff can create fees",
      });
    }
    const {
      studentId,
      amount,
      feeType,
      description,
      dueDate,
    } = req.body;

    const finalFeeType = feeType || description || "Hostel Fee";

    if (!studentId || amount === undefined || !finalFeeType) {
      return res.status(400).json({
        success: false,
        message: "studentId, amount and feeType are required",
      });
    }

    const result = await pool.query(
      `INSERT INTO fees
       (student_id, amount, fee_type, due_date)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [studentId, amount, finalFeeType, dueDate || null]
    );

    await logActivity({
      userId: req.user.userId,
      action: "CREATE_FEE",
      entity: "fee",
      entityId: result.rows[0].fee_id,
    });

    res.status(201).json({
      success: true,
      fee: result.rows[0],
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to create fee",
      error: error.message,
    });
  }
}

module.exports = {
  getFees,
  createFee,
};
