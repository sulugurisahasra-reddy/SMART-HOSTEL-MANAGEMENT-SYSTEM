const pool = require("../config/postgres");
const { logActivity } = require("../services/activityService");

async function getComplaints(req, res) {
  try {
    let query = `
      SELECT
        c.*,
        s.student_number,
        s.name AS student_name
      FROM complaints c
      JOIN students s ON s.student_id = c.student_id
    `;

    const params = [];

    if (req.user.role === "student") {
      query += ` WHERE s.user_id = $1`;
      params.push(req.user.userId);
    }

    query += ` ORDER BY c.complaint_id DESC`;

    const result = await pool.query(query, params);

    res.json({
      success: true,
      complaints: result.rows,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch complaints",
      error: error.message,
    });
  }
}

async function createComplaint(req, res) {
  try {
    const {
      studentId: bodyStudentId,
      title,
      description,
      priority = "medium",
    } = req.body;

    let studentId = bodyStudentId;

    if (req.user.role === "student") {
      const studentResult = await pool.query(
        "SELECT student_id FROM students WHERE user_id = $1",
        [req.user.userId]
      );

      if (studentResult.rows.length === 0) {
        return res.status(400).json({
          success: false,
          message: "Student profile not found",
        });
      }

      studentId = studentResult.rows[0].student_id;
    }

    if (!studentId || !title || !description) {
      return res.status(400).json({
        success: false,
        message: "studentId, title and description are required",
      });
    }

    const result = await pool.query(
      `INSERT INTO complaints
       (student_id, title, description, priority)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [studentId, title, description, priority]
    );

    try {
      await logActivity({
        userId: req.user.userId,
        action: "CREATE_COMPLAINT",
        entity: "complaint",
        entityId: result.rows[0].complaint_id,
      });
    } catch (logError) {
      console.error(
        "Complaint created but activity logging failed:",
        logError.message
      );
    }

    res.status(201).json({
      success: true,
      message: "Complaint created successfully",
      complaint: result.rows[0],
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to create complaint",
      error: error.message,
    });
  }
}


async function updateComplaint(req, res) {
  try {
    if (!["warden", "university"].includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: "Only staff can update complaints",
      });
    }
    const { id } = req.params;
    const { status, priority, description } = req.body;

    const result = await pool.query(
      `UPDATE complaints
       SET
         status = COALESCE($1, status),
         priority = COALESCE($2, priority),
         description = COALESCE($3, description),
         updated_at = CURRENT_TIMESTAMP
       WHERE complaint_id = $4
       RETURNING *`,
      [status || null, priority || null, description || null, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Complaint not found",
      });
    }

    try {
      await logActivity({
        userId: req.user.userId,
        action: "UPDATE_COMPLAINT",
        entity: "complaint",
        entityId: result.rows[0].complaint_id,
      });
    } catch (logError) {
      console.error(
        "Complaint updated but activity logging failed:",
        logError.message
      );
    }

    res.json({
      success: true,
      message: "Complaint updated successfully",
      complaint: result.rows[0],
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to update complaint",
      error: error.message,
    });
  }
}

module.exports = {
  getComplaints,
  createComplaint,
  updateComplaint,
};
