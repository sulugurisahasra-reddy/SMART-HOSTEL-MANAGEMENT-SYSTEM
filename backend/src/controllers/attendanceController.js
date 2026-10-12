const pool = require("../config/postgres");
const { logActivity } = require("../services/activityService");

async function getAttendance(req, res) {
  try {
    let query = `
      SELECT
        a.*,
        s.student_number,
        s.name AS student_name
      FROM attendance a
      JOIN students s ON s.student_id = a.student_id
    `;

    const params = [];

    if (req.user.role === "student") {
      query += ` WHERE s.user_id = $1`;
      params.push(req.user.userId);
    }

    query += ` ORDER BY a.attendance_date DESC, a.student_id`;

    const result = await pool.query(query, params);

    res.json({
      success: true,
      attendance: result.rows,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch attendance",
      error: error.message,
    });
  }
}

async function markAttendance(req, res) {
  try {
    if (!["warden", "university"].includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: "Only staff can mark attendance",
      });
    }
    const {
      studentId,
      attendanceDate: attendanceDateFromBody,
      date,
      status,
    } = req.body;

    const attendanceDate = attendanceDateFromBody || date;

    if (!studentId || !attendanceDate || !status) {
      return res.status(400).json({
        success: false,
        message: "studentId, attendanceDate and status are required",
      });
    }

    const result = await pool.query(
      `INSERT INTO attendance
       (student_id, attendance_date, status)
       VALUES ($1,$2,$3)
       ON CONFLICT (student_id, attendance_date)
       DO UPDATE SET
         status = EXCLUDED.status,
         marked_at = CURRENT_TIMESTAMP
       RETURNING *`,
      [studentId, attendanceDate, status]
    );

    await logActivity({
      userId: req.user.userId,
      action: "MARK_ATTENDANCE",
      entity: "attendance",
      entityId: result.rows[0].attendance_id,
    });

    res.status(201).json({
      success: true,
      attendance: result.rows[0],
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to mark attendance",
      error: error.message,
    });
  }
}

module.exports = {
  getAttendance,
  markAttendance,
};
