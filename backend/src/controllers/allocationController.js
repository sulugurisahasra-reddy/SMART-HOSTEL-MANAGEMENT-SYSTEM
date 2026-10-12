const pool = require("../config/postgres");
const { logActivity } = require("../services/activityService");

async function getAllocations(req, res) {
  try {
    const result = await pool.query(`
      SELECT
        a.*,
        s.student_number,
        s.name AS student_name,
        s.department,
        r.room_number,
        h.hostel_name
      FROM allocations a
      JOIN students s ON s.student_id = a.student_id
      JOIN rooms r ON r.room_id = a.room_id
      JOIN hostels h ON h.hostel_id = r.hostel_id
      ORDER BY a.allocation_id DESC
    `);

    res.json({
      success: true,
      allocations: result.rows,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch allocations",
      error: error.message,
    });
  }
}

async function allocateRoom(req, res) {
  const client = await pool.connect();

  try {
    const { studentId, roomId, reason = "Manual allocation" } = req.body;

    if (!studentId || !roomId) {
      return res.status(400).json({
        success: false,
        message: "studentId and roomId are required",
      });
    }

    await client.query("BEGIN");

    const student = await client.query(
      `SELECT student_id
       FROM students
       WHERE student_id = $1`,
      [studentId]
    );

    if (student.rows.length === 0) {
      await client.query("ROLLBACK");

      return res.status(404).json({
        success: false,
        message: "Student not found",
      });
    }

    const existing = await client.query(
      `SELECT allocation_id
       FROM allocations
       WHERE student_id = $1
       AND status = 'active'`,
      [studentId]
    );

    if (existing.rows.length > 0) {
      await client.query("ROLLBACK");

      return res.status(409).json({
        success: false,
        message: "Student already has an active room",
      });
    }

    const room = await client.query(
      `SELECT *
       FROM rooms
       WHERE room_id = $1
       FOR UPDATE`,
      [roomId]
    );

    if (room.rows.length === 0) {
      await client.query("ROLLBACK");

      return res.status(404).json({
        success: false,
        message: "Room not found",
      });
    }

    const selectedRoom = room.rows[0];

    if (selectedRoom.status === "maintenance") {
      await client.query("ROLLBACK");

      return res.status(409).json({
        success: false,
        message: "Room is under maintenance",
      });
    }

    if (selectedRoom.current_occupancy >= selectedRoom.capacity) {
      await client.query("ROLLBACK");

      return res.status(409).json({
        success: false,
        message: "Room is full",
      });
    }

    const allocation = await client.query(
      `INSERT INTO allocations
       (student_id, room_id, allocation_reason)
       VALUES ($1,$2,$3)
       RETURNING *`,
      [studentId, roomId, reason]
    );

    await client.query("COMMIT");

    await logActivity({
      userId: req.user.userId,
      action: "ALLOCATE_ROOM",
      entity: "allocation",
      entityId: allocation.rows[0].allocation_id,
      details: {
        studentId,
        roomId,
      },
    });

    res.status(201).json({
      success: true,
      message: "Room allocated successfully",
      allocation: allocation.rows[0],
    });
  } catch (error) {
    await client.query("ROLLBACK");

    res.status(500).json({
      success: false,
      message: "Room allocation failed",
      error: error.message,
    });
  } finally {
    client.release();
  }
}

async function vacateRoom(req, res) {
  try {
    const result = await pool.query(
      `UPDATE allocations
       SET status = 'vacated',
           vacated_date = CURRENT_DATE
       WHERE allocation_id = $1
       AND status = 'active'
       RETURNING *`,
      [req.params.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Active allocation not found",
      });
    }

    await logActivity({
      userId: req.user.userId,
      action: "VACATE_ROOM",
      entity: "allocation",
      entityId: result.rows[0].allocation_id,
    });

    res.json({
      success: true,
      message: "Room vacated successfully",
      allocation: result.rows[0],
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to vacate room",
      error: error.message,
    });
  }
}

module.exports = {
  getAllocations,
  allocateRoom,
  vacateRoom,
};
