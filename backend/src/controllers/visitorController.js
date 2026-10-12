const pool = require("../config/postgres");
const { logActivity } = require("../services/activityService");

async function getVisitors(req, res) {
  try {
    let query = `
      SELECT
        v.*,
        s.student_number,
        s.name AS student_name
      FROM visitors v
      JOIN students s ON s.student_id = v.student_id
    `;

    const params = [];

    if (req.user.role === "student") {
      query += ` WHERE s.user_id = $1`;
      params.push(req.user.userId);
    }

    query += ` ORDER BY v.entry_time DESC`;

    const result = await pool.query(query, params);

    res.json({
      success: true,
      visitors: result.rows,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch visitors",
      error: error.message,
    });
  }
}

async function createVisitor(req, res) {
  try {
    const {
      studentId,
      visitorName,
      visitorPhone,
      relationship,
      purpose,
    } = req.body;

    let finalStudentId = studentId;

    if (req.user.role === "student") {
      const ownStudent = await pool.query(
        "SELECT student_id FROM students WHERE user_id = $1",
        [req.user.userId]
      );

      if (ownStudent.rows.length === 0) {
        return res.status(403).json({
          success: false,
          message: "Student profile not found",
        });
      }

      finalStudentId = ownStudent.rows[0].student_id;
    }

    if (!finalStudentId || !visitorName) {
      return res.status(400).json({
        success: false,
        message: "Student ID and visitor name are required",
      });
    }

    const result = await pool.query(
      `INSERT INTO visitors
       (student_id, visitor_name, visitor_phone, relationship, purpose)
       VALUES ($1,$2,$3,$4,$5)
       RETURNING *`,
      [
        finalStudentId,
        visitorName,
        visitorPhone || null,
        relationship || null,
        purpose || null,
      ]
    );

    await logActivity({
      userId: req.user.userId,
      action: "VISITOR_ENTRY",
      entity: "visitor",
      entityId: result.rows[0].visitor_id,
    });

    res.status(201).json({
      success: true,
      visitor: result.rows[0],
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to add visitor",
      error: error.message,
    });
  }
}

async function checkoutVisitor(req, res) {
  try {
    const result = await pool.query(
      `UPDATE visitors
       SET exit_time = CURRENT_TIMESTAMP
       WHERE visitor_id = $1
       AND exit_time IS NULL
       RETURNING *`,
      [req.params.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Active visitor not found",
      });
    }

    await logActivity({
      userId: req.user.userId,
      action: "VISITOR_EXIT",
      entity: "visitor",
      entityId: result.rows[0].visitor_id,
    });

    res.json({
      success: true,
      message: "Visitor checked out",
      visitor: result.rows[0],
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to checkout visitor",
      error: error.message,
    });
  }
}

module.exports = {
  getVisitors,
  createVisitor,
  checkoutVisitor,
};
