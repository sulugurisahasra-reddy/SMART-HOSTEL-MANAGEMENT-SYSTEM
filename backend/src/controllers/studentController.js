const bcrypt = require("bcryptjs");
const pool = require("../config/postgres");
const { logActivity } = require("../services/activityService");

async function getStudents(req, res) {
  try {
    let query = `
      SELECT
        s.*,
        u.username,
        u.role,
        h.hostel_name,
        r.room_number,
        a.status AS allocation_status
      FROM students s
      LEFT JOIN users u ON u.user_id = s.user_id
      LEFT JOIN allocations a
        ON a.student_id = s.student_id
        AND a.status = 'active'
      LEFT JOIN rooms r ON r.room_id = a.room_id
      LEFT JOIN hostels h ON h.hostel_id = r.hostel_id
    `;

    const params = [];

    if (req.user.role === "student") {
      query += ` WHERE s.user_id = $1`;
      params.push(req.user.userId);
    }

    query += ` ORDER BY s.student_id DESC`;

    const result = await pool.query(query, params);

    res.json({
      success: true,
      count: result.rows.length,
      students: result.rows,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch students",
      error: error.message,
    });
  }
}

async function getStudents(req, res) {
  try {
    const result = await pool.query(`
      SELECT
        s.*,
        u.username,
        u.role,
        h.hostel_name,
        r.room_number,
        a.status AS allocation_status
      FROM students s
      LEFT JOIN users u ON u.user_id = s.user_id
      LEFT JOIN allocations a
        ON a.student_id = s.student_id
        AND a.status = 'active'
      LEFT JOIN rooms r ON r.room_id = a.room_id
      LEFT JOIN hostels h ON h.hostel_id = r.hostel_id
      ORDER BY s.student_id DESC
    `);

    res.json({
      success: true,
      count: result.rows.length,
      students: result.rows,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch students",
      error: error.message,
    });
  }
}

async function getStudent(req, res) {
  try {
    if (req.user.role === "student") {
      const ownStudent = await pool.query(
        `SELECT student_id FROM students WHERE user_id = $1`,
        [req.user.userId]
      );

      if (
        ownStudent.rows.length === 0 ||
        Number(ownStudent.rows[0].student_id) !== Number(req.params.id)
      ) {
        return res.status(403).json({
          success: false,
          message: "You can only access your own student profile",
        });
      }
    }
    const result = await pool.query(
      `SELECT
        s.*,
        u.username,
        u.role,
        h.hostel_name,
        r.room_number,
        r.room_type,
        r.capacity,
        r.current_occupancy,
        a.status AS allocation_status,
        a.allocation_date,
        a.vacated_date
      FROM students s
      LEFT JOIN users u ON u.user_id = s.user_id
      LEFT JOIN allocations a
        ON a.student_id = s.student_id
        AND a.status = 'active'
      LEFT JOIN rooms r ON r.room_id = a.room_id
      LEFT JOIN hostels h ON h.hostel_id = r.hostel_id
      WHERE s.student_id = $1`,
      [req.params.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Student not found",
      });
    }

    res.json({
      success: true,
      student: result.rows[0],
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch student",
      error: error.message,
    });
  }
}

async function createStudent(req, res) {
  const client = await pool.connect();

  try {
    const {
      username,
      password,
      studentNumber,
      name,
      department,
      year,
      contact,
      email,
      preferences = {},
    } = req.body;

    if (!username || !password || !studentNumber || !name || !department) {
      return res.status(400).json({
        success: false,
        message: "Username, password, student number, name and department are required",
      });
    }

    if (password.length < 6) {
      return res.status(400).json({
        success: false,
        message: "Password must be at least 6 characters",
      });
    }

    await client.query("BEGIN");

    const existing = await client.query(
      "SELECT user_id FROM users WHERE username = $1",
      [username]
    );

    if (existing.rows.length > 0) {
      await client.query("ROLLBACK");
      return res.status(409).json({
        success: false,
        message: "Username already exists",
      });
    }

    const passwordHash = await bcrypt.hash(password, 12);

    const userResult = await client.query(
      `INSERT INTO users (username, password_hash, role)
       VALUES ($1, $2, 'student')
       RETURNING user_id, username, role`,
      [username, passwordHash]
    );

    const result = await client.query(
      `INSERT INTO students
       (user_id, student_number, name, department, year, contact, email, preferences)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
       RETURNING *`,
      [
        userResult.rows[0].user_id,
        studentNumber,
        name,
        department,
        year || null,
        contact || null,
        email || null,
        preferences,
      ]
    );

    await client.query("COMMIT");

    try {
      await logActivity({
        userId: req.user.userId,
        action: "CREATE",
        entity: "student",
        entityId: result.rows[0].student_id,
      });
    } catch (logError) {
      console.error(
        "Student created but activity logging failed:",
        logError.message
      );
    }

    res.status(201).json({
      success: true,
      message: "Student created successfully",
      student: {
        ...result.rows[0],
        username: userResult.rows[0].username,
        role: userResult.rows[0].role,
      },
    });
  } catch (error) {
    try {
      await client.query("ROLLBACK");
    } catch {}

    if (error.code === "23505") {
      return res.status(409).json({
        success: false,
        message: "Username, student number or email already exists",
      });
    }

    res.status(500).json({
      success: false,
      message: "Failed to create student",
      error: error.message,
    });
  } finally {
    client.release();
  }
}

module.exports = {
  getStudents,
  getStudent,
  createStudent,
};
