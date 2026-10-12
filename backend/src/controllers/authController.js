const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const pool = require("../config/postgres");

function createToken(user) {
  return jwt.sign(
    {
      userId: user.user_id,
      username: user.username,
      role: user.role,
    },
    process.env.JWT_SECRET,
    {
      expiresIn: "7d",
    }
  );
}

async function register(req, res) {
  const client = await pool.connect();

  try {
    const {
      username,
      password,
      role = "student",
      studentNumber,
      name,
      department,
      year,
      contact,
      email,
      preferences = {},
    } = req.body;

    if (!username || !password) {
      return res.status(400).json({
        success: false,
        message: "Username and password are required",
      });
    }

    if (password.length < 6) {
      return res.status(400).json({
        success: false,
        message: "Password must contain at least 6 characters",
      });
    }

    // Public registration can only create student accounts.
    // Staff accounts must be provisioned securely by an administrator.
    if (role !== "student") {
      return res.status(403).json({
        success: false,
        message: "Public registration is restricted to student accounts",
      });
    }

    if (role === "student" && (!studentNumber || !name || !department)) {
      return res.status(400).json({
        success: false,
        message: "Student details are required",
      });
    }

    const existing = await pool.query(
      "SELECT user_id FROM users WHERE username = $1",
      [username]
    );

    if (existing.rows.length > 0) {
      return res.status(409).json({
        success: false,
        message: "Username already exists",
      });
    }

    await client.query("BEGIN");

    const passwordHash = await bcrypt.hash(password, 12);

    const userResult = await client.query(
      `INSERT INTO users
       (username, password_hash, role)
       VALUES ($1, $2, $3)
       RETURNING user_id, username, role, created_at`,
      [username, passwordHash, role]
    );

    const user = userResult.rows[0];

    let student = null;

    if (role === "student") {
      const studentResult = await client.query(
        `INSERT INTO students
         (user_id, student_number, name, department, year, contact, email, preferences)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         RETURNING *`,
        [
          user.user_id,
          studentNumber,
          name,
          department,
          year || null,
          contact || null,
          email || null,
          preferences,
        ]
      );

      student = studentResult.rows[0];
    }

    await client.query("COMMIT");

    res.status(201).json({
      success: true,
      message: "Registration successful",
      user,
      student,
      token: createToken(user),
    });
  } catch (error) {
    await client.query("ROLLBACK");

    if (error.code === "23505") {
      return res.status(409).json({
        success: false,
        message: "A unique field already exists",
      });
    }

    res.status(500).json({
      success: false,
      message: "Registration failed",
      error: error.message,
    });
  } finally {
    client.release();
  }
}

async function login(req, res) {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({
        success: false,
        message: "Username and password are required",
      });
    }

    const result = await pool.query(
      `SELECT
        u.*,
        s.student_id,
        s.student_number,
        s.name,
        s.department,
        s.year,
        s.email,
        s.contact
       FROM users u
       LEFT JOIN students s ON s.user_id = u.user_id
       WHERE u.username = $1`,
      [username]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({
        success: false,
        message: "Invalid username or password",
      });
    }

    const user = result.rows[0];

    if (!user.is_active) {
      return res.status(403).json({
        success: false,
        message: "Account is inactive",
      });
    }

    const validPassword = await bcrypt.compare(
      password,
      user.password_hash
    );

    if (!validPassword) {
      return res.status(401).json({
        success: false,
        message: "Invalid username or password",
      });
    }

    const token = createToken(user);

    res.json({
      success: true,
      message: "Login successful",
      token,
      user: {
        userId: user.user_id,
        username: user.username,
        role: user.role,
        studentId: user.student_id,
        studentNumber: user.student_number,
        name: user.name,
        department: user.department,
        year: user.year,
        email: user.email,
        contact: user.contact,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Login failed",
      error: error.message,
    });
  }
}

module.exports = {
  register,
  login,
};
