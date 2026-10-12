const pool = require("./config/postgres");
const bcrypt = require("bcryptjs");
const fs = require("fs");

const FIRST_NAMES = [
  "Aarav","Vihaan","Aditya","Arjun","Rohan","Karthik","Rahul","Vivek",
  "Nikhil","Siddharth","Varun","Akshay","Ishaan","Pranav","Ritvik",
  "Ananya","Diya","Ishita","Kavya","Meera","Aadhya","Saanvi","Shreya",
  "Tanvi","Navya","Anika","Myra","Avni","Kiara","Riya"
];

const LAST_NAMES = [
  "Sharma","Reddy","Patel","Verma","Rao","Kumar","Mehta","Iyer",
  "Nair","Joshi","Agarwal","Singh","Malhotra","Gupta","Deshmukh",
  "Chowdhury","Bhat","Mishra","Kapoor","Menon"
];

const DEPARTMENTS = [
  "Computer Science and Engineering",
  "Information Technology",
  "Cyber Security",
  "Artificial Intelligence and Data Science",
  "Electronics and Communication Engineering",
  "Electrical and Electronics Engineering",
  "Mechanical Engineering",
  "Civil Engineering"
];

const RELATIONSHIPS = [
  "Parent","Sibling","Relative","Guardian","Friend"
];

const COMPLAINTS = [
  ["Leaking bathroom tap","Water leakage reported in the attached bathroom.","Maintenance","medium"],
  ["Study room light issue","One of the ceiling lights is not functioning.","Electrical","low"],
  ["Wi-Fi connectivity issue","Internet connectivity is unstable during evening hours.","Internet","medium"],
  ["Room fan not working","Ceiling fan is making noise and stopping intermittently.","Electrical","high"],
  ["Common area cleanliness","Common corridor requires additional cleaning.","Housekeeping","low"],
  ["Hot water interruption","Hot water supply was unavailable during morning hours.","Maintenance","medium"],
  ["Door lock issue","Room door lock requires inspection and repair.","Maintenance","high"],
  ["Water pressure issue","Water pressure in the washroom is lower than usual.","Plumbing","medium"]
];

const VISITOR_FIRST_NAMES = [
  "Rajesh","Sunita","Vikram","Neha","Suresh","Priya","Amit","Pooja",
  "Manish","Kiran","Deepak","Nandini","Rakesh","Sneha","Anil","Swati"
];

const VISITOR_LAST_NAMES = [
  "Sharma","Reddy","Patel","Rao","Kumar","Verma","Nair","Mehta"
];

function dateOnly(daysAgo) {
  const d = new Date();
  d.setDate(d.getDate() - daysAgo);
  return d.toISOString().slice(0, 10);
}

function timestamp(daysAgo, hour, minute = 0) {
  const d = new Date();
  d.setDate(d.getDate() - daysAgo);
  d.setHours(hour, minute, 0, 0);
  return d.toISOString();
}

function studentName(i) {
  const first = FIRST_NAMES[i % FIRST_NAMES.length];
  const last = LAST_NAMES[Math.floor(i / FIRST_NAMES.length) % LAST_NAMES.length];
  const cycle = Math.floor(i / (FIRST_NAMES.length * LAST_NAMES.length));
  return cycle ? `${first} ${last} ${cycle + 1}` : `${first} ${last}`;
}

function usernameFor(name, i) {
  const clean = name.toLowerCase().replace(/[^a-z0-9]+/g, ".");
  return `${clean}.${String(i + 1).padStart(3, "0")}`;
}

async function run() {
  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    console.log("Resetting SmartStay demo database...");

    await client.query(`
      TRUNCATE TABLE
        visitors,
        attendance,
        complaints,
        fees,
        allocations,
        rooms,
        students,
        hostels,
        users
      RESTART IDENTITY CASCADE
    `);

    // ------------------------------------------------------------
    // HOSTELS
    // ------------------------------------------------------------

    const hostels = [
      ["Maple Residency", "boys", "24 Lakeview Avenue, Hyderabad, Telangana", 4],
      ["Cedar Residency", "boys", "18 Green Park Road, Hyderabad, Telangana", 4],
      ["Rosewood Residency", "girls", "42 Sunrise Avenue, Hyderabad, Telangana", 4],
      ["Willow Residency", "mixed", "31 Riverstone Road, Hyderabad, Telangana", 4]
    ];

    const hostelIds = [];

    for (const h of hostels) {
      const r = await client.query(
        `INSERT INTO hostels
         (hostel_name, hostel_type, address, total_floors, created_at)
         VALUES ($1,$2,$3,$4,$5)
         RETURNING hostel_id`,
        [h[0], h[1], h[2], h[3], timestamp(90, 9)]
      );
      hostelIds.push(r.rows[0].hostel_id);
    }

    // ------------------------------------------------------------
    // ROOMS
    // Exactly 68 beds across 24 rooms.
    // Every room will be fully occupied by active allocations.
    // ------------------------------------------------------------

    const roomTypes = [
      ["101", "single", 1],
      ["102", "double", 2],
      ["103", "triple", 3],
      ["104", "triple", 3],
      ["105", "four_sharing", 4],
      ["106", "four_sharing", 4]
    ];

    const roomIds = [];

    for (const hostelId of hostelIds) {
      for (const [number, type, capacity] of roomTypes) {
        const r = await client.query(
          `INSERT INTO rooms
           (hostel_id, room_number, room_type, capacity, current_occupancy)
           VALUES ($1,$2,$3,$4,0)
           RETURNING room_id`,
          [hostelId, number, type, capacity]
        );
        roomIds.push({
          roomId: r.rows[0].room_id,
          capacity
        });
      }
    }

    // ------------------------------------------------------------
    // STAFF
    // ------------------------------------------------------------

    const credentials = [];

    const staff = [
      ["warden.maple", "Maple Warden", "warden", "SmartStay@Warden01"],
      ["warden.cedar", "Cedar Warden", "warden", "SmartStay@Warden02"],
      ["demo.admin", "University Administrator", "university", "SmartStay@Admin01"]
    ];

    for (const [username, name, role, password] of staff) {
      const hash = await bcrypt.hash(password, 12);

      await client.query(
        `INSERT INTO users
         (username,password_hash,role,is_active,created_at)
         VALUES ($1,$2,$3,true,$4)`,
        [username, hash, role, timestamp(90, 9)]
      );

      credentials.push({
        name,
        username,
        password,
        role
      });
    }

    // ------------------------------------------------------------
    // STUDENTS
    // ------------------------------------------------------------

    const studentIds = [];

    for (let i = 0; i < 120; i++) {
      const name = studentName(i);
      const username = usernameFor(name, i);
      const password = `Smart@${String(i + 1).padStart(3, "0")}26`;
      const studentNumber = `STU${String(i + 1).padStart(4, "0")}`;
      const department = DEPARTMENTS[i % DEPARTMENTS.length];
      const year = (i % 4) + 1;
      const contact = `9${String(700000000 + i).padStart(9, "0")}`;
      const email = `${username}@smartstay.demo`;

      const passwordHash = await bcrypt.hash(password, 12);

      const userResult = await client.query(
        `INSERT INTO users
         (username,password_hash,role,is_active,created_at)
         VALUES ($1,$2,'student',true,$3)
         RETURNING user_id`,
        [username, passwordHash, timestamp(80 - (i % 30), 10)]
      );

      const preferences = {
        room_preference: ["single", "double", "triple", "four_sharing"][i % 4],
        food_preference: ["vegetarian", "non_vegetarian"][i % 2],
        quiet_hours: i % 2 === 0 ? "22:00-06:00" : "23:00-06:30",
        emergency_contact: `+91 8${String(900000000 + i).padStart(9, "0")}`
      };

      const studentResult = await client.query(
        `INSERT INTO students
         (user_id,student_number,name,department,year,contact,email,preferences,created_at)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
         RETURNING student_id`,
        [
          userResult.rows[0].user_id,
          studentNumber,
          name,
          department,
          year,
          contact,
          email,
          JSON.stringify(preferences),
          timestamp(75 - (i % 30), 10)
        ]
      );

      studentIds.push(studentResult.rows[0].student_id);

      credentials.push({
        name,
        username,
        password,
        role: "student",
        studentNumber
      });
    }

    // ------------------------------------------------------------
    // ACTIVE ALLOCATIONS
    // Fill every available bed.
    // ------------------------------------------------------------

    let studentCursor = 0;
    let activeAllocationCount = 0;

    for (const room of roomIds) {
      for (let seat = 0; seat < room.capacity; seat++) {
        const studentId = studentIds[studentCursor++];

        await client.query(
          `INSERT INTO allocations
           (student_id,room_id,allocation_date,vacated_date,status,allocation_reason,created_at)
           VALUES ($1,$2,$3,NULL,'active',$4,$5)`,
          [
            studentId,
            room.roomId,
            dateOnly(45 - (activeAllocationCount % 20)),
            "Initial hostel allocation",
            timestamp(45 - (activeAllocationCount % 20), 9)
          ]
        );

        activeAllocationCount++;
      }
    }

    // ------------------------------------------------------------
    // HISTORICAL VACATED ALLOCATIONS
    // Gives the allocation screen realistic history.
    // ------------------------------------------------------------

    for (let i = 0; i < 32; i++) {
      const studentId = studentIds[68 + i];
      const room = roomIds[i % roomIds.length];

      await client.query(
        `INSERT INTO allocations
         (student_id,room_id,allocation_date,vacated_date,status,allocation_reason,created_at)
         VALUES ($1,$2,$3,$4,'vacated',$5,$6)`,
        [
          studentId,
          room.roomId,
          dateOnly(110 + (i % 15)),
          dateOnly(55 + (i % 15)),
          "Previous academic-year allocation",
          timestamp(110 + (i % 15), 9)
        ]
      );
    }

    // Force occupancy to the exact allocation count.
    await client.query(`
      UPDATE rooms r
      SET current_occupancy = (
        SELECT COUNT(*)
        FROM allocations a
        WHERE a.room_id = r.room_id
          AND a.status = 'active'
      )
    `);

    // ------------------------------------------------------------
    // FEES
    // All fields intentionally populated.
    // ------------------------------------------------------------

    for (let i = 0; i < 120; i++) {
      const amount = [45000, 48000, 52000, 55000][i % 4];
      const dueDate = dateOnly(-30 + (i % 10));
      const paymentDate = dateOnly(25 - (i % 12));
      const receipt = `SSR-2026-${String(i + 1).padStart(5, "0")}`;

      await client.query(
        `INSERT INTO fees
         (student_id,amount,fee_type,due_date,payment_date,payment_status,receipt_number,created_at)
         VALUES ($1,$2,$3,$4,$5,'paid',$6,$7)`,
        [
          studentIds[i],
          amount,
          i % 3 === 0 ? "Hostel Fee" : i % 3 === 1 ? "Mess Fee" : "Maintenance Fee",
          dueDate,
          paymentDate,
          receipt,
          timestamp(40 - (i % 20), 11)
        ]
      );
    }

    // ------------------------------------------------------------
    // COMPLAINTS
    // Every complaint is complete and has a resolution.
    // ------------------------------------------------------------

    for (let i = 0; i < 120; i++) {
      const template = COMPLAINTS[i % COMPLAINTS.length];
      const status = i % 4 === 0 ? "closed" : "resolved";

      await client.query(
        `INSERT INTO complaints
         (student_id,title,description,category,status,priority,resolution,created_at,resolved_at)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)`,
        [
          studentIds[i],
          template[0],
          template[1],
          template[2],
          status,
          template[3],
          "Issue inspected and resolved by the hostel maintenance team.",
          timestamp(35 - (i % 25), 10),
          timestamp(30 - (i % 20), 16)
        ]
      );
    }

    // ------------------------------------------------------------
    // ATTENDANCE
    // 3 records per student.
    // ------------------------------------------------------------

    const attendanceStatuses = ["present", "present", "late", "leave", "present"];

    for (let i = 0; i < 120; i++) {
      for (let d = 0; d < 3; d++) {
        await client.query(
          `INSERT INTO attendance
           (student_id,attendance_date,status,marked_at)
           VALUES ($1,$2,$3,$4)`,
          [
            studentIds[i],
            dateOnly(3 - d),
            attendanceStatuses[(i + d) % attendanceStatuses.length],
            timestamp(3 - d, 8, 30)
          ]
        );
      }
    }

    // ------------------------------------------------------------
    // VISITORS
    // Every visitor has complete information and checkout time.
    // ------------------------------------------------------------

    for (let i = 0; i < 120; i++) {
      const first = VISITOR_FIRST_NAMES[i % VISITOR_FIRST_NAMES.length];
      const last = VISITOR_LAST_NAMES[Math.floor(i / VISITOR_FIRST_NAMES.length) % VISITOR_LAST_NAMES.length];
      const visitorName = `${first} ${last}`;
      const phone = `8${String(800000000 + i).padStart(9, "0")}`;

      await client.query(
        `INSERT INTO visitors
         (student_id,visitor_name,visitor_phone,relationship,purpose,entry_time,exit_time)
         VALUES ($1,$2,$3,$4,$5,$6,$7)`,
        [
          studentIds[i],
          visitorName,
          phone,
          RELATIONSHIPS[i % RELATIONSHIPS.length],
          ["Family visit", "Personal meeting", "Document delivery", "Weekend visit"][i % 4],
          timestamp(20 - (i % 18), 10 + (i % 5), 15),
          timestamp(20 - (i % 18), 12 + (i % 5), 15)
        ]
      );
    }

    await client.query("COMMIT");

    // ------------------------------------------------------------
    // WRITE CREDENTIAL REPORT
    // ------------------------------------------------------------

    const report = [
      "# SmartStay Demo Credentials",
      "",
      "## University Administrator",
      ...credentials
        .filter(x => x.role === "university")
        .map(x => `- ${x.username} | ${x.password}`),
      "",
      "## Wardens",
      ...credentials
        .filter(x => x.role === "warden")
        .map(x => `- ${x.username} | ${x.password}`),
      "",
      "## Students",
      ...credentials
        .filter(x => x.role === "student")
        .map(x => `- ${x.studentNumber} | ${x.name} | ${x.username} | ${x.password}`)
    ].join("\n");

    fs.writeFileSync("SMARTSTAY_DEMO_CREDENTIALS.md", report);

    console.log("");
    console.log("==============================================");
    console.log("SMARTSTAY DEMO RESET COMPLETE");
    console.log("==============================================");
    console.log("Students:       120");
    console.log("Staff:            3");
    console.log("Hostels:          4");
    console.log("Rooms:           24");
    console.log("Active beds:     68");
    console.log("Allocations:    100");
    console.log("Fees:           120");
    console.log("Complaints:     120");
    console.log("Attendance:     360");
    console.log("Visitors:       120");
    console.log("");
    console.log("Credentials: SMARTSTAY_DEMO_CREDENTIALS.md");
    console.log("==============================================");

  } catch (error) {
    await client.query("ROLLBACK");
    console.error("DEMO SEED FAILED — DATABASE ROLLED BACK");
    console.error(error.message);
    process.exitCode = 1;
  } finally {
    client.release();
    await pool.end();
  }
}

run();
