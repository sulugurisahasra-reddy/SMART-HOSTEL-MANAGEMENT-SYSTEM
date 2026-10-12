const pool = require("../config/postgres");

async function getDashboard(req, res) {
  if (req.user.role === "student") {
    try {
      const student = await pool.query(
        `SELECT student_id, student_number, name, department, year
         FROM students
         WHERE user_id = $1`,
        [req.user.userId]
      );

      if (student.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: "Student profile not found",
        });
      }

      const studentId = student.rows[0].student_id;

      const [fees, complaints, visitors, attendance, allocation] =
        await Promise.all([
          pool.query(
            `SELECT *
             FROM fees
             WHERE student_id = $1
             ORDER BY fee_id DESC`,
            [studentId]
          ),
          pool.query(
            `SELECT *
             FROM complaints
             WHERE student_id = $1
             ORDER BY complaint_id DESC`,
            [studentId]
          ),
          pool.query(
            `SELECT *
             FROM visitors
             WHERE student_id = $1
             ORDER BY entry_time DESC`,
            [studentId]
          ),
          pool.query(
            `SELECT *
             FROM attendance
             WHERE student_id = $1
             ORDER BY attendance_date DESC`,
            [studentId]
          ),
          pool.query(
            `SELECT *
             FROM allocations
             WHERE student_id = $1
             ORDER BY allocation_id DESC
             LIMIT 1`,
            [studentId]
          ),
        ]);

      return res.json({
        success: true,
        role: "student",
        student: student.rows[0],
        summary: {
          complaints: complaints.rows.length,
          visitors: visitors.rows.length,
          fees: fees.rows.length,
          attendance: attendance.rows.length,
        },
        fees: fees.rows,
        complaints: complaints.rows,
        visitors: visitors.rows,
        attendance: attendance.rows,
        allocation: allocation.rows[0] || null,
      });
    } catch (error) {
      return res.status(500).json({
        success: false,
        message: "Failed to fetch student dashboard",
      });
    }
  }

  try {
    const [
      students,
      rooms,
      occupied,
      fees,
      complaints,
      visitors,
    ] = await Promise.all([
      pool.query("SELECT COUNT(*)::INTEGER AS count FROM students"),

      pool.query("SELECT COUNT(*)::INTEGER AS count FROM rooms"),

      pool.query(`
        SELECT COALESCE(SUM(current_occupancy), 0)::INTEGER AS count
        FROM rooms
      `),

      pool.query(`
        SELECT
          COALESCE(
            SUM(
              CASE
                WHEN payment_status IN ('pending','overdue')
                THEN amount
                ELSE 0
              END
            ), 0
          ) AS pending
        FROM fees
      `),

      pool.query(`
        SELECT COUNT(*)::INTEGER AS count
        FROM complaints
        WHERE status IN ('open','in_progress')
      `),

      pool.query(`
        SELECT COUNT(*)::INTEGER AS count
        FROM visitors
        WHERE exit_time IS NULL
      `),
    ]);

    res.json({
      success: true,
      dashboard: {
        totalStudents: students.rows[0].count,
        totalRooms: rooms.rows[0].count,
        occupiedBeds: occupied.rows[0].count,
        pendingFees: Number(fees.rows[0].pending),
        openComplaints: complaints.rows[0].count,
        activeVisitors: visitors.rows[0].count,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to load dashboard",
      error: error.message,
    });
  }
}

async function getAnalytics(req, res) {
  try {
    const [
      hostelStats,
      complaintStats,
      feeStats,
      attendanceStats,
    ] = await Promise.all([
      pool.query(`
        SELECT
          hostel_name,
          SUM(capacity)::INTEGER AS capacity,
          SUM(current_occupancy)::INTEGER AS occupied,
          SUM(available_beds)::INTEGER AS available
        FROM room_occupancy_view
        GROUP BY hostel_name
        ORDER BY hostel_name
      `),

      pool.query(`
        SELECT
          status,
          COUNT(*)::INTEGER AS count
        FROM complaints
        GROUP BY status
        ORDER BY status
      `),

      pool.query(`
        SELECT
          payment_status,
          COUNT(*)::INTEGER AS count,
          COALESCE(SUM(amount),0) AS amount
        FROM fees
        GROUP BY payment_status
        ORDER BY payment_status
      `),

      pool.query(`
        SELECT
          status,
          COUNT(*)::INTEGER AS count
        FROM attendance
        GROUP BY status
        ORDER BY status
      `),
    ]);

    res.json({
      success: true,
      analytics: {
        hostels: hostelStats.rows,
        complaints: complaintStats.rows,
        fees: feeStats.rows,
        attendance: attendanceStats.rows,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to load analytics",
      error: error.message,
    });
  }
}

module.exports = {
  getDashboard,
  getAnalytics,
};
