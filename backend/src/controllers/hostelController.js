const pool = require("../config/postgres");

async function getHostels(req, res) {
  try {
    const result = await pool.query(`
      SELECT
        h.*,
        COUNT(r.room_id)::INTEGER AS total_rooms,
        COALESCE(SUM(r.capacity), 0)::INTEGER AS total_capacity,
        COALESCE(SUM(r.current_occupancy), 0)::INTEGER AS occupied_beds
      FROM hostels h
      LEFT JOIN rooms r ON r.hostel_id = h.hostel_id
      GROUP BY h.hostel_id
      ORDER BY h.hostel_id
    `);

    res.json({
      success: true,
      hostels: result.rows,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch hostels",
      error: error.message,
    });
  }
}

async function getRooms(req, res) {
  try {
    const result = await pool.query(`
      SELECT *
      FROM room_occupancy_view
      ORDER BY hostel_name, room_number
    `);

    res.json({
      success: true,
      rooms: result.rows,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch rooms",
      error: error.message,
    });
  }
}

async function getRoom(req, res) {
  try {
    const result = await pool.query(
      `SELECT *
       FROM room_occupancy_view
       WHERE room_id = $1`,
      [req.params.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Room not found",
      });
    }

    res.json({
      success: true,
      room: result.rows[0],
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch room",
      error: error.message,
    });
  }
}

module.exports = {
  getHostels,
  getRooms,
  getRoom,
};
