require("dotenv").config();

const bcrypt = require("bcryptjs");
const pool = require("./config/postgres");

async function seed() {
  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    console.log("Clearing demo data...");

    await client.query(`
      TRUNCATE
        visitors,
        attendance,
        complaints,
        fees,
        allocations,
        rooms,
        hostels,
        students,
        users
      RESTART IDENTITY CASCADE
    `);

    const passwordHash = await bcrypt.hash("SmartStay@123", 10);

    // -------------------------
    // WARDENS
    // -------------------------

    const wardens = [
      ["warden01", "Warden One", "warden01@smartstay.edu"],
      ["warden02", "Warden Two", "warden02@smartstay.edu"],
    ];

    for (const [username, name, email] of wardens) {
      const result = await client.query(
        `
        INSERT INTO users (username, password_hash, role)
        VALUES ($1, $2, 'warden')
        RETURNING user_id
        `,
        [username, passwordHash]
      );

      console.log(`Created warden: ${username}`);
    }

    // -------------------------
    // UNIVERSITY
    // -------------------------

    await client.query(
      `
      INSERT INTO users (username, password_hash, role)
      VALUES ($1, $2, 'university')
      `,
      ["university", passwordHash]
    );

    console.log("Created university account");

    // -------------------------
    // HOSTELS
    // -------------------------

    const hostels = [
      ["SmartStay Block A", "boys", "Campus North Wing", 4],
      ["SmartStay Block B", "girls", "Campus South Wing", 4],
      ["SmartStay Block C", "boys", "Campus East Wing", 4],
    ];

    const hostelIds = [];

    for (const hostel of hostels) {
      const result = await client.query(
        `
        INSERT INTO hostels
        (hostel_name, hostel_type, address, total_floors)
        VALUES ($1, $2, $3, $4)
        RETURNING hostel_id
        `,
        hostel
      );

      hostelIds.push(result.rows[0].hostel_id);
    }

    // -------------------------
    // ROOMS
    // -------------------------

    const roomTypes = [
      ["101", "double", 2],
      ["102", "triple", 3],
      ["201", "double", 2],
      ["202", "four_sharing", 4],
      ["301", "double", 2],
      ["302", "triple", 3],
    ];

    const roomIds = [];

    for (const hostelId of hostelIds) {
      for (const [number, type, capacity] of roomTypes) {
        const result = await client.query(
          `
          INSERT INTO rooms
          (hostel_id, room_number, room_type, capacity)
          VALUES ($1, $2, $3, $4)
          RETURNING room_id
          `,
          [hostelId, `${String.fromCharCode(65 + hostelId - 1)}${number}`, type, capacity]
        );

        roomIds.push(result.rows[0].room_id);
      }
    }

    console.log(`Created ${roomIds.length} rooms`);

    // -------------------------
    // STUDENTS
    // -------------------------

    const departments = [
      "Computer Science",
      "Cyber Security",
      "Information Technology",
      "Artificial Intelligence",
      "Electronics and Communication",
    ];

    const firstNames = [
      "Aarav",
      "Aditya",
      "Arjun",
      "Rahul",
      "Rohan",
      "Karthik",
      "Vikram",
      "Sai",
      "Nikhil",
      "Varun",
      "Akash",
      "Manish",
      "Harsha",
      "Tejas",
      "Pranav",
      "Abhinav",
      "Ravi",
      "Sanjay",
      "Surya",
      "Vivek",
    ];

    const lastNames = [
      "Kumar",
      "Sharma",
      "Reddy",
      "Rao",
      "Patel",
      "Verma",
      "Singh",
      "Mehta",
      "Gupta",
      "Naidu",
      "Yadav",
      "Iyer",
    ];

    const studentIds = [];

    for (let i = 1; i <= 120; i++) {
      const username = `student${String(i).padStart(3, "0")}`;
      const studentNumber = `STU${String(i).padStart(4, "0")}`;

      const firstName = firstNames[(i - 1) % firstNames.length];
      const lastName = lastNames[(i - 1) % lastNames.length];

      const name = `${firstName} ${lastName}`;
      const department = departments[(i - 1) % departments.length];
      const year = ((i - 1) % 4) + 1;
      const contact = `9${String(100000000 + i).slice(-9)}`;
      const email = `${username}@smartstay.edu`;

      const userResult = await client.query(
        `
        INSERT INTO users
        (username, password_hash, role)
        VALUES ($1, $2, 'student')
        RETURNING user_id
        `,
        [username, passwordHash]
      );

      const userId = userResult.rows[0].user_id;

      const studentResult = await client.query(
        `
        INSERT INTO students
        (
          user_id,
          student_number,
          name,
          department,
          year,
          contact,
          email,
          preferences
        )
        VALUES
        ($1, $2, $3, $4, $5, $6, $7, $8)
        RETURNING student_id
        `,
        [
          userId,
          studentNumber,
          name,
          department,
          year,
          contact,
          email,
          JSON.stringify({
            room_type: i % 3 === 0 ? "triple" : "double",
            quiet_room: i % 2 === 0,
            preferred_floor: (i % 4) + 1,
          }),
        ]
      );

      studentIds.push(studentResult.rows[0].student_id);

      // Allocate first 80 students
      if (i <= 80) {
        const roomId = roomIds[(i - 1) % roomIds.length];

        await client.query(
          `
          INSERT INTO allocations
          (
            student_id,
            room_id,
            allocation_date,
            status,
            allocation_reason
          )
          VALUES
          ($1, $2, CURRENT_TIMESTAMP, 'active', 'Seed allocation')
          `,
          [studentIds[studentIds.length - 1], roomId]
        );
      }

      // Fee for every student
      await client.query(
        `
        INSERT INTO fees
        (
          student_id,
          amount,
          fee_type,
          due_date,
          payment_status
        )
        VALUES
        ($1, 45000, 'Hostel Fee', CURRENT_TIMESTAMP + INTERVAL '30 days', $2)
        `,
        [
          studentIds[studentIds.length - 1],
          i % 4 === 0 ? "paid" : "pending",
        ]
      );

      // Attendance
      await client.query(
        `
        INSERT INTO attendance
        (
          student_id,
          attendance_date,
          status
        )
        VALUES
        ($1, CURRENT_DATE, $2)
        `,
        [
          studentIds[studentIds.length - 1],
          i % 10 === 0 ? "absent" : "present",
        ]
      );
    }

    console.log("Created 120 students");

    // -------------------------
    // COMPLAINTS
    // -------------------------

    const complaintTitles = [
      ["WiFi Issue", "Internet connectivity is unstable.", "Internet", "high"],
      ["Water Issue", "Water supply interruption.", "Maintenance", "medium"],
      ["Room Cleaning", "Room requires cleaning.", "Housekeeping", "low"],
      ["Electricity Issue", "Light or power issue reported.", "Electrical", "medium"],
      ["AC Issue", "Air conditioning requires inspection.", "Maintenance", "high"],
    ];

    for (let i = 0; i < 30; i++) {
      const studentId = studentIds[i];

      const complaint = complaintTitles[i % complaintTitles.length];

      await client.query(
        `
        INSERT INTO complaints
        (
          student_id,
          title,
          description,
          category,
          status,
          priority
        )
        VALUES
        ($1, $2, $3, $4, $5, $6)
        `,
        [
          studentId,
          complaint[0],
          complaint[1],
          complaint[2],
          i % 5 === 0 ? "resolved" : "open",
          complaint[3],
        ]
      );
    }

    // -------------------------
    // VISITORS
    // -------------------------

    for (let i = 0; i < 15; i++) {
      await client.query(
        `
        INSERT INTO visitors
        (
          student_id,
          visitor_name,
          visitor_phone,
          relationship,
          purpose,
          entry_time,
          exit_time
        )
        VALUES
        ($1, $2, $3, $4, $5, CURRENT_TIMESTAMP - INTERVAL '2 hours', $6)
        `,
        [
          studentIds[i],
          `Visitor ${i + 1}`,
          `998877${String(1000 + i)}`,
          i % 2 === 0 ? "Father" : "Mother",
          "Student visit",
          i % 3 === 0 ? null : new Date(),
        ]
      );
    }

    await client.query("COMMIT");

    console.log("");
    console.log("=================================");
    console.log("SMARTSTAY SEED COMPLETE");
    console.log("=================================");
    console.log("Students   : 120");
    console.log("Wardens    : 2");
    console.log("University : 1");
    console.log(`Rooms      : ${roomIds.length}`);
    console.log("=================================");
    console.log("");
    console.log("LOGIN PASSWORD FOR ALL DEMO USERS:");
    console.log("SmartStay@123");
    console.log("");
    console.log("WARDEN:");
    console.log("warden01");
    console.log("warden02");
    console.log("");
    console.log("UNIVERSITY:");
    console.log("university");
    console.log("");
    console.log("STUDENTS:");
    console.log("student001 ... student120");
    console.log("=================================");
  } catch (error) {
    await client.query("ROLLBACK");
    console.error("SEED FAILED:", error);
    process.exitCode = 1;
  } finally {
    client.release();
    await pool.end();
  }
}

seed();
