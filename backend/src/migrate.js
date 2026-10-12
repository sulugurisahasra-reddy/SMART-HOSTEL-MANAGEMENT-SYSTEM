require("dotenv").config();

const pool = require("./config/postgres");

async function migrate() {
  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    await client.query(`
      DROP TABLE IF EXISTS visitors CASCADE;
      DROP TABLE IF EXISTS attendance CASCADE;
      DROP TABLE IF EXISTS complaints CASCADE;
      DROP TABLE IF EXISTS fees CASCADE;
      DROP TABLE IF EXISTS allocations CASCADE;
      DROP TABLE IF EXISTS rooms CASCADE;
      DROP TABLE IF EXISTS hostels CASCADE;
      DROP TABLE IF EXISTS students CASCADE;
      DROP TABLE IF EXISTS users CASCADE;

      DROP TYPE IF EXISTS user_role CASCADE;

      CREATE TABLE users (
        user_id SERIAL PRIMARY KEY,
        username VARCHAR(100) UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        role VARCHAR(30) NOT NULL
          CHECK (role IN ('student', 'warden', 'university')),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE students (
        student_id SERIAL PRIMARY KEY,
        user_id INTEGER UNIQUE NOT NULL
          REFERENCES users(user_id) ON DELETE CASCADE,
        student_number VARCHAR(50) UNIQUE NOT NULL,
        name VARCHAR(150) NOT NULL,
        department VARCHAR(150),
        year INTEGER,
        contact VARCHAR(30),
        email VARCHAR(150),
        preferences JSONB DEFAULT '{}'::jsonb,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE hostels (
        hostel_id SERIAL PRIMARY KEY,
        hostel_name VARCHAR(150) NOT NULL,
        hostel_type VARCHAR(30),
        address TEXT,
        total_floors INTEGER DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE rooms (
        room_id SERIAL PRIMARY KEY,
        hostel_id INTEGER NOT NULL
          REFERENCES hostels(hostel_id) ON DELETE CASCADE,
        room_number VARCHAR(50) NOT NULL,
        room_type VARCHAR(50) NOT NULL,
        capacity INTEGER NOT NULL CHECK (capacity > 0),
        UNIQUE(hostel_id, room_number)
      );

      CREATE TABLE allocations (
        allocation_id SERIAL PRIMARY KEY,
        student_id INTEGER NOT NULL
          REFERENCES students(student_id) ON DELETE CASCADE,
        room_id INTEGER NOT NULL
          REFERENCES rooms(room_id) ON DELETE CASCADE,
        allocation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        vacated_date TIMESTAMP,
        status VARCHAR(30) DEFAULT 'active',
        allocation_reason TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE fees (
        fee_id SERIAL PRIMARY KEY,
        student_id INTEGER NOT NULL
          REFERENCES students(student_id) ON DELETE CASCADE,
        amount NUMERIC(12,2) NOT NULL,
        fee_type VARCHAR(100),
        due_date TIMESTAMP,
        payment_date TIMESTAMP,
        payment_status VARCHAR(30) DEFAULT 'pending',
        receipt_number VARCHAR(100),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE complaints (
        complaint_id SERIAL PRIMARY KEY,
        student_id INTEGER NOT NULL
          REFERENCES students(student_id) ON DELETE CASCADE,
        title VARCHAR(200) NOT NULL,
        description TEXT,
        category VARCHAR(100),
        status VARCHAR(30) DEFAULT 'open',
        priority VARCHAR(30) DEFAULT 'medium',
        resolution TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        resolved_at TIMESTAMP
      );

      CREATE TABLE attendance (
        attendance_id SERIAL PRIMARY KEY,
        student_id INTEGER NOT NULL
          REFERENCES students(student_id) ON DELETE CASCADE,
        attendance_date DATE NOT NULL,
        status VARCHAR(30) NOT NULL,
        marked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(student_id, attendance_date)
      );

      CREATE TABLE visitors (
        visitor_id SERIAL PRIMARY KEY,
        student_id INTEGER NOT NULL
          REFERENCES students(student_id) ON DELETE CASCADE,
        visitor_name VARCHAR(150) NOT NULL,
        visitor_phone VARCHAR(30),
        relationship VARCHAR(100),
        purpose TEXT,
        entry_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        exit_time TIMESTAMP
      );
    `);

    await client.query("COMMIT");

    console.log("Clean SmartStay schema created successfully.");
  } catch (error) {
    await client.query("ROLLBACK");
    console.error("Migration failed:", error.message);
    process.exitCode = 1;
  } finally {
    client.release();
    await pool.end();
  }
}

migrate();
