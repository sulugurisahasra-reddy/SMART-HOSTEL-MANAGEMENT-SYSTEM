import { useEffect, useMemo, useState } from "react";
import {
  ArrowRight,
  ArrowUpRight,
  Banknote,
  BedDouble,
  Bell,
  Building2,
  Check,
  ChevronDown,
  ChevronRight,
  ClipboardCheck,
  Clock3,
  CreditCard,
  DoorOpen,
  FileText,
  GraduationCap,
  HandCoins,
  Home,
  LayoutDashboard,
  LogOut,
  MapPin,
  Menu,
  MessageSquareText,
  Plus,
  Search,
  Settings,
  ShieldCheck,
  Sparkles,
  TicketCheck,
  UserCheck,
  UsersRound,
  WalletCards,
  X,
} from "lucide-react";
import "./App.css";

const API = "http://localhost:5050/api";

const roles = {
  student: {
    title: "Student",
    eyebrow: "Resident portal",
    icon: GraduationCap,
    nav: [
      ["overview", "Overview", LayoutDashboard],
      ["stay", "My stay", Home],
      ["fees", "Fee centre", WalletCards],
      ["requests", "Requests", MessageSquareText],
      ["visitors", "Visitors", UserCheck],
    ],
  },
  warden: {
    title: "Warden",
    eyebrow: "Residence operations",
    icon: ShieldCheck,
    nav: [
      ["overview", "Command centre", LayoutDashboard],
      ["residents", "Residents", UsersRound],
      ["inventory", "Rooms & beds", BedDouble],
      ["requests", "Service desk", TicketCheck],
      ["visitors", "Visitor log", UserCheck],
      ["attendance", "Attendance", ClipboardCheck],
      ["fees", "Fees", CreditCard],
    ],
  },
  university: {
    title: "University",
    eyebrow: "Campus housing",
    icon: Building2,
    nav: [
      ["overview", "Portfolio", LayoutDashboard],
      ["residences", "Residences", Building2],
      ["students", "Students", GraduationCap],
      ["finance", "Finance", HandCoins],
      ["reports", "Reports", FileText],
    ],
  },
};

const detailText = {
  student: {
    stay: ["My stay", "Everything about your room and residency, in one place."],
    fees: ["Fee centre", "Your upcoming payments and fee records."],
    requests: ["Requests", "Create and track residence requests."],
    visitors: ["Visitors", "Create visitor passes and see visitor activity."],
  },
  warden: {
    residents: ["Residents", "Search residents and manage student records."],
    inventory: ["Rooms & beds", "View available rooms and current occupancy."],
    requests: ["Service desk", "Review and manage resident complaints."],
    visitors: ["Visitor log", "Manage visitors entering the residence."],
    attendance: ["Attendance", "Mark and review student attendance."],
    fees: ["Fees", "Create and review residence fee records."],
  },
  university: {
    residences: ["Residences", "View hostel and room information."],
    students: ["Students", "View student records across residences."],
    finance: ["Finance", "Review fee information and financial activity."],
    reports: ["Reports", "View current housing statistics."],
  },
};

async function apiRequest(path, options = {}, token = "") {
  const headers = {
    "Content-Type": "application/json",
    ...(options.headers || {}),
  };

  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }

  const response = await fetch(`${API}${path}`, {
    ...options,
    headers,
  });

  let data = {};
  try {
    data = await response.json();
  } catch {
    data = {};
  }

  if (!response.ok) {
    throw new Error(data.message || `Request failed (${response.status})`);
  }

  return data;
}

function getArray(data, keys = []) {
  for (const key of keys) {
    if (Array.isArray(data?.[key])) return data[key];
  }

  if (Array.isArray(data)) return data;

  return [];
}

function formatDate(value) {
  if (!value) return "—";

  try {
    return new Date(value).toLocaleDateString("en-IN", {
      day: "2-digit",
      month: "short",
      year: "numeric",
    });
  } catch {
    return value;
  }
}

function money(value) {
  if (value === null || value === undefined || value === "") return "₹0";
  return `₹${Number(value).toLocaleString("en-IN")}`;
}

function App() {
  const [session, setSession] = useState(() => {
    try {
      return JSON.parse(localStorage.getItem("smartstay-session"));
    } catch {
      return null;
    }
  });

  const [selectedRole, setSelectedRole] = useState("student");
  const [activePage, setActivePage] = useState("overview");
  const [menuOpen, setMenuOpen] = useState(false);
  const [notice, setNotice] = useState("");
  const [modal, setModal] = useState(null);
  const [notificationsOpen, setNotificationsOpen] = useState(false);

  const token = session?.token || "";

  useEffect(() => {
    if (!notice) return undefined;

    const timer = window.setTimeout(() => setNotice(""), 3000);

    return () => window.clearTimeout(timer);
  }, [notice]);

  const notify = (message) => setNotice(message);

  const signIn = async (username, password) => {
    try {
      const data = await apiRequest("/auth/login", {
        method: "POST",
        body: JSON.stringify({ username, password }),
      });

      if (!data.token) {
        throw new Error("Login succeeded but no authentication token was returned.");
      }

      const next = {
        token: data.token,
        user: data.user,
      };

      localStorage.setItem("smartstay-session", JSON.stringify(next));
      setSession(next);
      setActivePage("overview");
      notify(`Welcome, ${data.user?.name || data.user?.username || "User"}`);
    } catch (error) {
      throw error;
    }
  };

  const signOut = () => {
    localStorage.removeItem("smartstay-session");
    setSession(null);
    setActivePage("overview");
    setMenuOpen(false);
    setNotificationsOpen(false);
    setModal(null);
  };

  const openModal = (title, message, kind = "info", extra = {}) => {
    setModal({
      title,
      message,
      kind,
      ...extra,
    });

    setNotificationsOpen(false);
  };

  const closeModal = () => setModal(null);

  const role = session?.user?.role || selectedRole;

  const userMeta = useMemo(() => {
    const user = session?.user || {};
    const name = user.name || user.username || "SmartStay User";

    return {
      name,
      initial:
        name
          .split(" ")
          .map((part) => part[0])
          .join("")
          .slice(0, 2)
          .toUpperCase() || "SS",
      title: roles[role]?.title || "User",
      context:
        role === "student"
          ? `${user.studentNumber || "Student"} · ${user.department || "Campus housing"}`
          : role === "warden"
            ? "Residence operations"
            : "Campus housing administration",
    };
  }, [session, role]);

  if (!session) {
    return (
      <SignIn
        role={selectedRole}
        setRole={setSelectedRole}
        onSignIn={signIn}
      />
    );
  }

  return (
    <div className={`product-shell role-${role}`}>
      <Sidebar
        role={role}
        activePage={activePage}
        setActivePage={setActivePage}
        menuOpen={menuOpen}
        setMenuOpen={setMenuOpen}
        signOut={signOut}
        openModal={openModal}
        userMeta={userMeta}
        onHelp={() =>
          openModal(
            "SmartStay Help",
            "Use the sidebar to move between workspaces. Create buttons now connect to the SmartStay API."
          )
        }
      />

      <main className="workspace">
        <Topbar
          role={role}
          onMenu={() => setMenuOpen(true)}
          onRoleChange={() =>
            openModal(
              "Switch workspace",
              "Switch between the available SmartStay demo workspaces.",
              "roles"
            )
          }
          onNotifications={() => setNotificationsOpen((open) => !open)}
          userMeta={userMeta}
        />

        <div className="page-wrap">
          {activePage === "overview" ? (
            <Dashboard
              role={role}
              token={token}
              user={session.user}
              notify={notify}
              openModal={openModal}
            />
          ) : (
            <DetailPage
              role={role}
              page={activePage}
              token={token}
              user={session.user}
              notify={notify}
              openModal={openModal}
            />
          )}
        </div>
      </main>

      {notificationsOpen && (
        <NotificationCenter
          token={token}
          onClose={() => setNotificationsOpen(false)}
          onOpen={(title, message) => openModal(title, message)}
        />
      )}

      {modal && (
        <ActionModal
          modal={modal}
          role={role}
          token={token}
          user={session.user}
          onClose={closeModal}
          onNotify={notify}
        />
      )}

      {notice && (
        <div className="toast">
          <Check size={16} />
          {notice}
        </div>
      )}

      <SmartStayAssistant role={role} token={token} />
    </div>
  );
}

function Brand() {
  return (
    <div className="brand">
      <span className="brand-mark">
        <i />
        <i />
        <i />
        <i />
      </span>
      <span>
        <strong>smartstay</strong>
        <small>campus living, considered</small>
      </span>
    </div>
  );
}

function SignIn({ role, setRole, onSignIn }) {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const submit = async (event) => {
    event.preventDefault();

    setError("");
    setLoading(true);

    try {
      await onSignIn(username.trim(), password);
    } catch (err) {
      setError(err.message || "Unable to sign in.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="signin-page">
      <section className="signin-intro">
        <Brand />

        <div className="intro-copy">
          <p className="micro-label">A better way to belong</p>
          <h1>
            Campus living,
            <br />
            <em>made human.</em>
          </h1>
          <p>
            SmartStay gives students, residence teams, and universities one
            thoughtful home for the everyday work of living on campus.
          </p>
        </div>

        <div className="building-illustration">
          <span className="moon" />
          <div className="illustration-building left-building">
            <b />
            <b />
            <b />
            <b />
          </div>
          <div className="illustration-building main-building">
            <b />
            <b />
            <b />
            <b />
            <b />
            <b />
            <b />
            <b />
            <b />
          </div>
          <div className="ground-line" />
        </div>

        <p className="intro-foot">
          Designed for the small moments that make a stay feel like home.
        </p>
      </section>

      <section className="signin-form-area">
        <div className="signin-panel">
          <div className="signin-panel-top">
            <p className="micro-label">Welcome to SmartStay</p>
            <h2>Sign in to your space.</h2>
            <p>Use your SmartStay account credentials.</p>
          </div>

          <form onSubmit={submit}>
            <label>
              Username
              <input
                value={username}
                onChange={(event) => setUsername(event.target.value)}
                placeholder="student001"
                autoComplete="username"
                required
              />
            </label>

            <label>
              Password
              <span className="password-field">
                <input
                  id="smartstay-password"
                  value={password}
                  onChange={(event) => setPassword(event.target.value)}
                  type="password"
                  placeholder="••••••••"
                  autoComplete="current-password"
                  required
                />
                <button
                  type="button"
                  onClick={() => {
                    const input = document.getElementById(
                      "smartstay-password"
                    );

                    if (!input) return;

                    input.type =
                      input.type === "password" ? "text" : "password";
                  }}
                >
                  Show
                </button>
              </span>
            </label>

            <div className="view-selector">
              <div className="selector-heading">
                <span>Enter as</span>
                <small>Workspace</small>
              </div>

              <div className="role-options">
                {Object.entries(roles).map(([key, option]) => {
                  const Icon = option.icon;

                  return (
                    <button
                      type="button"
                      key={key}
                      onClick={() => setRole(key)}
                      className={`role-option ${
                        role === key ? "chosen" : ""
                      }`}
                    >
                      <Icon size={17} />
                      <span>{option.title}</span>
                      {role === key && <Check size={15} />}
                    </button>
                  );
                })}
              </div>
            </div>

            {error && <div className="form-error">{error}</div>}

            <button
              className="primary-button signin-button"
              disabled={loading}
              type="submit"
            >
              {loading ? "Signing you in…" : "Continue"}
              {!loading && <ArrowRight size={18} />}
            </button>
          </form>

          <div className="signin-note">
            <ShieldCheck size={15} />
            Connected to the SmartStay backend.
          </div>
        </div>
      </section>
    </div>
  );
}

function Sidebar({
  role,
  activePage,
  setActivePage,
  menuOpen,
  setMenuOpen,
  signOut,
  openModal,
  userMeta,
  onHelp,
}) {
  const meta = roles[role];

  return (
    <>
      {menuOpen && (
        <button
          className="menu-scrim"
          onClick={() => setMenuOpen(false)}
          aria-label="Close menu"
        />
      )}

      <aside className={`sidebar ${menuOpen ? "show" : ""}`}>
        <div className="sidebar-top">
          <Brand />
          <button
            className="close-menu"
            onClick={() => setMenuOpen(false)}
          >
            <X size={18} />
          </button>
        </div>

        <div className="sidebar-context">
          <span>{meta.eyebrow}</span>
          <strong>{userMeta.context}</strong>
        </div>

        <nav className="side-nav">
          {meta.nav.map(([id, label, Icon]) => (
            <button
              key={id}
              className={activePage === id ? "active" : ""}
              onClick={() => {
                setActivePage(id);
                setMenuOpen(false);
              }}
            >
              <Icon size={18} />
              <span>{label}</span>
            </button>
          ))}
        </nav>

        <div className="sidebar-bottom">
          <div className="profile-card">
            <button
              type="button"
              className="profile-main"
              onClick={() =>
                openModal(
                  "My Profile",
                  `${userMeta.name} · ${userMeta.title}. Your authenticated SmartStay account details are being used by this workspace.`,
                  "profile"
                )
              }
            >
              <div className="avatar">{userMeta.initial}</div>
              <div>
                <strong>{userMeta.name}</strong>
                <span>{userMeta.title} account</span>
              </div>
            </button>

            <button title="Sign out" onClick={signOut} type="button">
              <LogOut size={17} />
            </button>
          </div>
        </div>
      </aside>
    </>
  );
}

function Topbar({
  role,
  onMenu,
  onRoleChange,
  onNotifications,
  userMeta,
}) {
  const meta = roles[role];

  return (
    <header className="topbar">
      <button className="mobile-menu" onClick={onMenu}>
        <Menu size={20} />
      </button>

      <div className="breadcrumb">
        <span>{meta.eyebrow}</span>
        <ChevronRight size={13} />
        <strong>{meta.title}</strong>
      </div>

      <div className="topbar-actions">
        <button
          className="notification-button"
          onClick={onNotifications}
          aria-label="Open notifications"
        >
          <Bell size={19} />
          <i />
        </button>

        <button className="switch-role" onClick={onRoleChange}>
          <span>
            {userMeta.name} · {meta.title}
          </span>
          <ChevronDown size={15} />
        </button>
      </div>
    </header>
  );
}

function PageHeading({ kicker, title, children, action, onAction }) {
  return (
    <div className="page-heading">
      <div>
        <p className="micro-label">{kicker}</p>
        <h1>{title}</h1>
        {children && <p className="heading-summary">{children}</p>}
      </div>

      {action && (
        <button className="primary-button" onClick={onAction}>
          {action}
          <Plus size={17} />
        </button>
      )}
    </div>
  );
}

function Metric({ label, value, note, icon: Icon, tone = "indigo" }) {
  return (
    <article className="metric">
      <div className={`metric-icon ${tone}`}>
        <Icon size={19} />
      </div>

      <div>
        <span>{label}</span>
        <strong>{value}</strong>
        <small>{note}</small>
      </div>
    </article>
  );
}

function Panel({
  title,
  subtitle,
  action,
  onAction,
  children,
  className = "",
}) {
  return (
    <section className={`panel ${className}`}>
      <div className="panel-head">
        <div>
          <h2>{title}</h2>
          {subtitle && <p>{subtitle}</p>}
        </div>

        {action && (
          <button onClick={onAction}>
            {action}
            <ArrowUpRight size={15} />
          </button>
        )}
      </div>

      {children}
    </section>
  );
}

function Dashboard({ role, token, user, notify, openModal }) {
  if (role === "student") {
    return (
      <StudentDashboard
        token={token}
        user={user}
        notify={notify}
        openModal={openModal}
      />
    );
  }

  if (role === "warden") {
    return (
      <WardenDashboard
        token={token}
        user={user}
        notify={notify}
        openModal={openModal}
      />
    );
  }

  return (
    <UniversityDashboard
      token={token}
      user={user}
      notify={notify}
      openModal={openModal}
    />
  );
}

function StudentDashboard({ token, user, notify, openModal }) {
  const [dashboard, setDashboard] = useState(null);
  const [fees, setFees] = useState([]);
  const [visitors, setVisitors] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let alive = true;

    Promise.all([
      apiRequest("/dashboard", {}, token).catch(() => null),
      apiRequest("/fees", {}, token).catch(() => null),
      apiRequest("/visitors", {}, token).catch(() => null),
    ]).then(([dashboardData, feesData, visitorsData]) => {
      if (!alive) return;

      setDashboard(dashboardData?.dashboard || null);
      setFees(getArray(feesData, ["fees"]));
      setVisitors(getArray(visitorsData, ["visitors"]));
      setLoading(false);
    });

    return () => {
      alive = false;
    };
  }, [token]);

  const latestFee = fees[0];

  return (
    <>
      <PageHeading
        kicker="Northfield University · Campus housing"
        title={`Welcome, ${user?.name || user?.username || "Student"}.`}
      >
        Your SmartStay resident workspace is connected to your account.
      </PageHeading>

      <section className="resident-hero">
        <div className="resident-hero-copy">
          <span className="micro-label">Your stay, at a glance</span>
          <h2>
            {user?.studentNumber || "Student"} <span>·</span>{" "}
            {user?.department || "Campus residence"}
          </h2>
          <p>
            {user?.year ? `Year ${user.year}` : "Student"} ·{" "}
            {user?.email || "Account connected"}
          </p>

          <div className="resident-tags">
            <span>
              <Check size={14} />
              Account active
            </span>
            <span>
              <MapPin size={14} />
              SmartStay connected
            </span>
          </div>
        </div>

        <div className="hero-room">
          <div className="room-window">
            <i />
            <i />
            <i />
            <i />
          </div>
          <div className="room-door" />
          <span>Your space</span>
        </div>
      </section>

      <div className="metric-grid">
        <Metric
          label="Active visitors"
          value={loading ? "…" : visitors.length}
          note="Visitor records"
          icon={UserCheck}
          tone="indigo"
        />
        <Metric
          label="Fee records"
          value={loading ? "…" : fees.length}
          note={latestFee ? `Latest ${money(latestFee.amount)}` : "No records loaded"}
          icon={WalletCards}
          tone="green"
        />
        <Metric
          label="Student ID"
          value={user?.studentNumber || "—"}
          note={user?.department || "Department"}
          icon={GraduationCap}
          tone="rose"
        />
      </div>

      <div className="dashboard-grid">
        <Panel
          title="Quick actions"
          subtitle="Common resident workflows"
          className="quick-panel"
        >
          <div className="quick-actions">
            <button
              onClick={() =>
                openModal(
                  "New complaint",
                  "Create a service request and send it to the residence team.",
                  "createComplaint"
                )
              }
            >
              <MessageSquareText size={19} />
              <span>Create complaint</span>
              <ArrowRight size={15} />
            </button>

            <button
              onClick={() =>
                openModal(
                  "Visitor pass",
                  "Create a visitor entry for your residence.",
                  "createVisitor"
                )
              }
            >
              <UserCheck size={19} />
              <span>Create visitor pass</span>
              <ArrowRight size={15} />
            </button>

            <button
              onClick={() =>
                openModal(
                  "My profile",
                  "Your authenticated student account is connected to this workspace.",
                  "profile"
                )
              }
            >
              <Settings size={19} />
              <span>View profile</span>
              <ArrowRight size={15} />
            </button>
          </div>
        </Panel>

        <Panel
          title="Account overview"
          subtitle="Information returned by the backend"
        >
          <div className="activity-list">
            <div className="activity-row">
              <div className="activity-icon">
                <GraduationCap size={17} />
              </div>
              <div>
                <strong>{user?.name || user?.username}</strong>
                <span>{user?.email || "No email recorded"}</span>
              </div>
            </div>

            <div className="activity-row">
              <div className="activity-icon">
                <Building2 size={17} />
              </div>
              <div>
                <strong>{user?.department || "Department not recorded"}</strong>
                <span>
                  {user?.year ? `Academic year ${user.year}` : "Year not recorded"}
                </span>
              </div>
            </div>

            <div className="activity-row">
              <div className="activity-icon">
                <Clock3 size={17} />
              </div>
              <div>
                <strong>SmartStay account</strong>
                <span>Authenticated with JWT</span>
              </div>
            </div>
          </div>
        </Panel>
      </div>

      {dashboard && (
        <Panel
          title="Residence snapshot"
          subtitle="Current system statistics"
          className="wide-panel"
        >
          <div className="metric-grid compact">
            <Metric
              label="Students"
              value={dashboard.totalStudents ?? 0}
              note="Registered"
              icon={UsersRound}
            />
            <Metric
              label="Rooms"
              value={dashboard.totalRooms ?? 0}
              note="Total rooms"
              icon={BedDouble}
            />
            <Metric
              label="Occupied beds"
              value={dashboard.occupiedBeds ?? 0}
              note="Current"
              icon={DoorOpen}
            />
          </div>
        </Panel>
      )}
    </>
  );
}

function WardenDashboard({ token, user, notify, openModal }) {
  const [dashboard, setDashboard] = useState(null);
  const [students, setStudents] = useState([]);
  const [visitors, setVisitors] = useState([]);
  const [complaints, setComplaints] = useState([]);
  const [loading, setLoading] = useState(true);

  const load = async () => {
    setLoading(true);

    const results = await Promise.all([
      apiRequest("/dashboard", {}, token).catch(() => null),
      apiRequest("/students", {}, token).catch(() => null),
      apiRequest("/visitors", {}, token).catch(() => null),
      apiRequest("/complaints", {}, token).catch(() => null),
    ]);

    setDashboard(results[0]?.dashboard || null);
    setStudents(getArray(results[1], ["students"]));
    setVisitors(getArray(results[2], ["visitors"]));
    setComplaints(getArray(results[3], ["complaints"]));
    setLoading(false);
  };

  useEffect(() => {
    load();
  }, [token]);

  return (
    <>
      <PageHeading
        kicker="Northfield University · Cedar House"
        title="Residence command centre."
        action="Add student"
        onAction={() =>
          openModal(
            "Add student",
            "Create a new student account and resident record.",
            "createStudent",
            { onSuccess: load }
          )
        }
      >
        Manage residents, rooms, requests, visitors and residence activity.
      </PageHeading>

      <div className="metric-grid">
        <Metric
          label="Residents"
          value={loading ? "…" : dashboard?.totalStudents ?? students.length}
          note="Student records"
          icon={UsersRound}
          tone="indigo"
        />
        <Metric
          label="Occupied beds"
          value={loading ? "…" : dashboard?.occupiedBeds ?? "—"}
          note="Current occupancy"
          icon={BedDouble}
          tone="green"
        />
        <Metric
          label="Open complaints"
          value={loading ? "…" : dashboard?.openComplaints ?? complaints.length}
          note="Need attention"
          icon={TicketCheck}
          tone="rose"
        />
        <Metric
          label="Visitors"
          value={loading ? "…" : dashboard?.activeVisitors ?? visitors.length}
          note="Active records"
          icon={UserCheck}
          tone="amber"
        />
      </div>

      <div className="dashboard-grid">
        <Panel
          title="Residents"
          subtitle="Latest student records"
          action="Add student"
          onAction={() =>
            openModal(
              "Add student",
              "Create a new student account and resident record.",
              "createStudent",
              { onSuccess: load }
            )
          }
        >
          <DataTable
            rows={students.slice(0, 6)}
            empty="No student records found."
            columns={[
              ["name", "Name"],
              ["student_number", "Student ID"],
              ["department", "Department"],
              ["year", "Year"],
            ]}
          />
        </Panel>

        <Panel
          title="Service desk"
          subtitle="Recent complaints"
          action="Refresh"
          onAction={load}
        >
          <DataTable
            rows={complaints.slice(0, 6)}
            empty="No complaints found."
            columns={[
              ["complaint_id", "ID"],
              ["title", "Title"],
              ["status", "Status"],
              ["created_at", "Created"],
            ]}
            formatter={(key, value) =>
              key === "created_at" ? formatDate(value) : value
            }
          />
        </Panel>
      </div>
    </>
  );
}

function UniversityDashboard({ token, user, notify, openModal }) {
  const [dashboard, setDashboard] = useState(null);
  const [students, setStudents] = useState([]);
  const [hostels, setHostels] = useState([]);
  const [fees, setFees] = useState([]);
  const [loading, setLoading] = useState(true);

  const load = async () => {
    setLoading(true);

    const results = await Promise.all([
      apiRequest("/dashboard", {}, token).catch(() => null),
      apiRequest("/students", {}, token).catch(() => null),
      apiRequest("/hostels", {}, token).catch(() => null),
      apiRequest("/fees", {}, token).catch(() => null),
    ]);

    setDashboard(results[0]?.dashboard || null);
    setStudents(getArray(results[1], ["students"]));
    setHostels(getArray(results[2], ["hostels"]));
    setFees(getArray(results[3], ["fees"]));
    setLoading(false);
  };

  useEffect(() => {
    load();
  }, [token]);

  return (
    <>
      <PageHeading
        kicker="Northfield University · Campus housing"
        title="Campus housing, in focus."
        action="Add student"
        onAction={() =>
          openModal(
            "Add student",
            "Create a new student record.",
            "createStudent",
            { onSuccess: load }
          )
        }
      >
        One operational view across students, residences and finance.
      </PageHeading>

      <div className="metric-grid">
        <Metric
          label="Students"
          value={loading ? "…" : dashboard?.totalStudents ?? students.length}
          note="Registered residents"
          icon={UsersRound}
          tone="indigo"
        />
        <Metric
          label="Rooms"
          value={loading ? "…" : dashboard?.totalRooms ?? "—"}
          note="Across residences"
          icon={BedDouble}
          tone="green"
        />
        <Metric
          label="Occupied beds"
          value={loading ? "…" : dashboard?.occupiedBeds ?? "—"}
          note="Current allocation"
          icon={DoorOpen}
          tone="rose"
        />
        <Metric
          label="Pending fees"
          value={loading ? "…" : money(dashboard?.pendingFees)}
          note={`${fees.length} fee records loaded`}
          icon={Banknote}
          tone="amber"
        />
      </div>

      <div className="dashboard-grid">
        <Panel
          title="Residences"
          subtitle="Hostels returned by the backend"
          action="Refresh"
          onAction={load}
        >
          <DataTable
            rows={hostels.slice(0, 8)}
            empty="No hostels found."
            columns={[
              ["hostel_name", "Hostel"],
              ["hostel_type", "Type"],
              ["address", "Address"],
            ]}
          />
        </Panel>

        <Panel
          title="Students"
          subtitle="Current resident records"
          action="Add student"
          onAction={() =>
            openModal(
              "Add student",
              "Create a new student record.",
              "createStudent",
              { onSuccess: load }
            )
          }
        >
          <DataTable
            rows={students.slice(0, 8)}
            empty="No students found."
            columns={[
              ["name", "Name"],
              ["student_number", "Student ID"],
              ["department", "Department"],
            ]}
          />
        </Panel>
      </div>
    </>
  );
}

function DetailPage({
  role,
  page,
  token,
  user,
  notify,
  openModal,
}) {
  const values = detailText[role]?.[page] || [
    "SmartStay",
    "Workspace",
  ];

  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);

  const config = {
    stay: { endpoint: "/allocations", keys: ["allocations"], columns: [
      ["room_number", "Room"],
      ["hostel_name", "Hostel"],
      ["status", "Status"],
    ]},
    fees: { endpoint: "/fees", keys: ["fees"], columns: [
      ["fee_id", "ID"],
      ["amount", "Amount"],
      ["status", "Status"],
      ["due_date", "Due"],
    ]},
    requests: { endpoint: "/complaints", keys: ["complaints"], columns: [
      ["complaint_id", "ID"],
      ["title", "Title"],
      ["status", "Status"],
      ["created_at", "Created"],
    ]},
    visitors: { endpoint: "/visitors", keys: ["visitors"], columns: [
      ["visitor_id", "ID"],
      ["visitor_name", "Visitor"],
      ["visit_date", "Date"],
      ["status", "Status"],
    ]},
    residents: { endpoint: "/students", keys: ["students"], columns: [
      ["student_id", "ID"],
      ["name", "Name"],
      ["student_number", "Student ID"],
      ["department", "Department"],
    ]},
    students: { endpoint: "/students", keys: ["students"], columns: [
      ["student_id", "ID"],
      ["name", "Name"],
      ["student_number", "Student ID"],
      ["department", "Department"],
    ]},
    inventory: { endpoint: "/hostels/rooms", keys: ["rooms"], columns: [
      ["room_id", "ID"],
      ["room_number", "Room"],
      ["hostel_name", "Hostel"],
      ["capacity", "Capacity"],
      ["current_occupancy", "Occupied"],
    ]},
    residences: { endpoint: "/hostels", keys: ["hostels"], columns: [
      ["hostel_id", "ID"],
      ["hostel_name", "Hostel"],
      ["hostel_type", "Type"],
      ["address", "Address"],
    ]},
    finance: { endpoint: "/fees", keys: ["fees"], columns: [
      ["fee_id", "ID"],
      ["student_id", "Student"],
      ["amount", "Amount"],
      ["status", "Status"],
    ]},
    attendance: { endpoint: "/attendance", keys: ["attendance"], columns: [
      ["attendance_id", "ID"],
      ["student_id", "Student"],
      ["date", "Date"],
      ["status", "Status"],
    ]},
    reports: { endpoint: "/dashboard", keys: [], columns: [] },
  };

  const pageConfig = config[page];

  const load = async () => {
    setLoading(true);

    try {
      if (page === "reports") {
        const data = await apiRequest("/dashboard", {}, token);
        setRows(data?.dashboard ? [data.dashboard] : []);
      } else if (pageConfig) {
        const data = await apiRequest(pageConfig.endpoint, {}, token);
        setRows(getArray(data, pageConfig.keys));
      } else {
        setRows([]);
      }
    } catch (error) {
      notify(error.message);
      setRows([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, [page, token]);

  const createAction =
    page === "visitors"
      ? () =>
          openModal(
            "Create visitor pass",
            "Enter the visitor details.",
            "createVisitor",
            { onSuccess: load }
          )
      : page === "requests"
        ? () =>
            openModal(
              "Create complaint",
              "Enter the complaint details.",
              "createComplaint",
              { onSuccess: load }
            )
        : page === "residents" || page === "students"
          ? () =>
              openModal(
                "Add student",
                "Create a new student account.",
                "createStudent",
                { onSuccess: load }
              )
          : (page === "finance" || page === "fees") && roleIsStaff(role)
            ? () =>
                openModal(
                  "Create fee",
                  "Enter the fee details.",
                  "createFee",
                  { onSuccess: load }
                )
            : page === "attendance"
              ? () =>
                  openModal(
                    "Mark attendance",
                    "Enter the attendance details.",
                    "markAttendance",
                    { onSuccess: load }
                  )
              : null;

  const actionLabel =
    page === "visitors"
      ? "Create visitor"
      : page === "requests"
        ? "Create complaint"
        : page === "residents" || page === "students"
          ? "Add student"
          : (page === "finance" || page === "fees") && roleIsStaff(role)
            ? "Create fee"
            : page === "attendance"
              ? "Mark attendance"
              : null;

  return (
    <>
      <PageHeading
        kicker={roles[role]?.eyebrow || "SmartStay"}
        title={values[0]}
        action={actionLabel || undefined}
        onAction={createAction}
      >
        {values[1]}
      </PageHeading>

      {page === "reports" ? (
        <ReportsView data={rows[0]} loading={loading} />
      ) : (
        <Panel
          title={values[0]}
          subtitle={loading ? "Loading..." : `${rows.length} record(s)`}
          action="Refresh"
          onAction={load}
        >
          <DataTable
            rows={rows}
            empty={loading ? "Loading SmartStay data..." : "No records found."}
            columns={pageConfig?.columns || []}
            formatter={(key, value) => {
              if (
                key.includes("date") ||
                key.includes("created") ||
                key === "due_date"
              ) {
                return formatDate(value);
              }

              if (key === "amount") return money(value);

              return value;
            }}
          />
        </Panel>
      )}
    </>
  );
}

function ReportsView({ data, loading }) {
  if (loading) {
    return (
      <Panel title="Reports" subtitle="Loading current statistics">
        <div className="empty-state">Loading...</div>
      </Panel>
    );
  }

  return (
    <Panel
      title="Housing report"
      subtitle="Current SmartStay dashboard statistics"
    >
      <div className="metric-grid">
        <Metric
          label="Students"
          value={data?.totalStudents ?? 0}
          note="Registered"
          icon={UsersRound}
        />
        <Metric
          label="Rooms"
          value={data?.totalRooms ?? 0}
          note="Total"
          icon={BedDouble}
        />
        <Metric
          label="Occupied beds"
          value={data?.occupiedBeds ?? 0}
          note="Current"
          icon={DoorOpen}
        />
        <Metric
          label="Open complaints"
          value={data?.openComplaints ?? 0}
          note="Active"
          icon={TicketCheck}
        />
      </div>
    </Panel>
  );
}

function DataTable({ rows, columns, empty, formatter }) {
  if (!rows?.length) {
    return <div className="empty-state">{empty}</div>;
  }

  return (
    <div className="data-table-wrap">
      <table className="data-table">
        <thead>
          <tr>
            {columns.map(([key, label]) => (
              <th key={key}>{label}</th>
            ))}
          </tr>
        </thead>

        <tbody>
          {rows.map((row, index) => (
            <tr key={row.id || row._id || index}>
              {columns.map(([key]) => (
                <td key={key}>
                  {formatter
                    ? formatter(key, row[key])
                    : row[key] ?? "—"}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function NotificationCenter({ onClose, onOpen }) {
  return (
    <div className="notification-popover">
      <div className="notification-head">
        <div>
          <span className="micro-label">SmartStay</span>
          <strong>Notifications</strong>
        </div>

        <button onClick={onClose}>
          <X size={16} />
        </button>
      </div>

      <button
        className="notification-item"
        onClick={() =>
          onOpen(
            "SmartStay connected",
            "Your frontend is connected to the SmartStay API."
          )
        }
      >
        <Bell size={17} />
        <span>
          <strong>Backend connected</strong>
          <small>Authenticated workspace is active.</small>
        </span>
      </button>

      <button
        className="notification-item"
        onClick={() =>
          onOpen(
            "Workspace ready",
            "Use the navigation and action buttons to work with real API data."
          )
        }
      >
        <Check size={17} />
        <span>
          <strong>Workspace ready</strong>
          <small>All major sections are available.</small>
        </span>
      </button>
    </div>
  );
}

function ActionModal({
  modal,
  role,
  token,
  user,
  onClose,
  onNotify,
}) {
  const [form, setForm] = useState({});
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const update = (key, value) => {
    setForm((current) => ({
      ...current,
      [key]: value,
    }));
  };

  const submit = async (event) => {
    event.preventDefault();

    if (!modal.kind || ["info", "profile"].includes(modal.kind)) {
      onClose();
      return;
    }

    setLoading(true);
    setError("");

    try {
      let path = "";
      let method = "POST";
      let body = {};

      if (modal.kind === "createStudent") {
        path = "/students";

        body = {
          username: form.username,
          password: form.password,
          role: "student",
          studentNumber: form.studentNumber,
          name: form.name,
          department: form.department,
          year: Number(form.year),
          contact: form.contact,
          email: form.email,
          preferences: {
            preferred_floor: Number(form.preferredFloor || 0),
            room_type: form.roomType || "double",
          },
        };
      }

      if (modal.kind === "createComplaint") {
        path = "/complaints";

        body = {
          studentId: Number(form.studentId || user?.studentId),
          title: form.title,
          description: form.description,
          priority: form.priority || "medium",
        };
      }

      if (modal.kind === "createVisitor") {
        path = "/visitors";

        body = {
          visitorName: form.visitorName,
          visitorContact: form.visitorContact,
          visitDate: form.visitDate,
          purpose: form.purpose,
          studentId: user?.studentId || form.studentId,
        };
      }

      if (modal.kind === "createFee") {
        path = "/fees";

        body = {
          studentId: Number(form.studentId || user?.studentId),
          amount: Number(form.amount),
          dueDate: form.dueDate,
          description: form.description,
          status: form.status || "pending",
        };
      }

      if (modal.kind === "markAttendance") {
        path = "/attendance";

        body = {
          studentId: Number(form.studentId),
          attendanceDate: form.date,
          status: form.status || "present",
        };
      }

      if (!path) {
        throw new Error("This action is not connected yet.");
      }

      const data = await apiRequest(
        path,
        {
          method,
          body: JSON.stringify(body),
        },
        token
      );

      onNotify(data.message || "Action completed successfully.");

      if (modal.onSuccess) {
        await modal.onSuccess();
      }

      onClose();
    } catch (err) {
      setError(err.message || "Unable to complete this action.");
    } finally {
      setLoading(false);
    }
  };

  if (modal.kind === "roles") {
    return (
      <div
        className="modal-backdrop"
        onMouseDown={(event) => {
          if (event.target === event.currentTarget) onClose();
        }}
      >
        <div className="action-modal" role="dialog" aria-modal="true">
          <div className="modal-head">
            <div>
              <p className="micro-label">SmartStay</p>
              <h2>Switch workspace</h2>
            </div>

            <button onClick={onClose} aria-label="Close">
              <X size={18} />
            </button>
          </div>

          <p className="modal-message">
            Demo workspace switching changes the UI role. For real accounts,
            sign in with the appropriate backend credentials.
          </p>

          <div className="modal-role-grid">
            {Object.entries(roles).map(([key, value]) => {
              const Icon = value.icon;

              return (
                <button
                  key={key}
                  className="role-option"
                  onClick={() => {
                    localStorage.removeItem("smartstay-session");
                    window.location.reload();
                  }}
                >
                  <Icon size={18} />
                  <span>{value.title}</span>
                </button>
              );
            })}
          </div>

          <div className="modal-actions">
            <button className="secondary-button" onClick={onClose}>
              Close
            </button>
          </div>
        </div>
      </div>
    );
  }

  const isForm =
    modal.kind &&
    !["info", "profile"].includes(modal.kind);

  return (
    <div
      className="modal-backdrop"
      onMouseDown={(event) => {
        if (event.target === event.currentTarget) onClose();
      }}
    >
      <div className="action-modal" role="dialog" aria-modal="true">
        <div className="modal-head">
          <div>
            <p className="micro-label">SmartStay</p>
            <h2>{modal.title}</h2>
          </div>

          <button onClick={onClose} aria-label="Close">
            <X size={18} />
          </button>
        </div>

        {!isForm && <p className="modal-message">{modal.message}</p>}

        {modal.kind === "profile" && (
          <div className="profile-details">
            <div>
              <span>Name</span>
              <strong>{user?.name || user?.username || "—"}</strong>
            </div>

            <div>
              <span>Username</span>
              <strong>{user?.username || "—"}</strong>
            </div>

            <div>
              <span>Role</span>
              <strong>{roles[role]?.title || role}</strong>
            </div>

            <div>
              <span>Student ID</span>
              <strong>{user?.studentNumber || "—"}</strong>
            </div>

            <div>
              <span>Department</span>
              <strong>{user?.department || "—"}</strong>
            </div>

            <div>
              <span>Email</span>
              <strong>{user?.email || "—"}</strong>
            </div>
          </div>
        )}

        {modal.kind === "createStudent" && (
          <form className="action-form" onSubmit={submit}>
            <Input
              label="Username"
              value={form.username}
              onChange={(value) => update("username", value)}
              required
            />

            <Input
              label="Temporary password"
              type="password"
              value={form.password}
              onChange={(value) => update("password", value)}
              required
            />

            <Input
              label="Student ID"
              value={form.studentNumber}
              onChange={(value) => update("studentNumber", value)}
              required
            />

            <Input
              label="Full name"
              value={form.name}
              onChange={(value) => update("name", value)}
              required
            />

            <Input
              label="Department"
              value={form.department}
              onChange={(value) => update("department", value)}
              required
            />

            <Input
              label="Year"
              type="number"
              min="1"
              max="5"
              value={form.year}
              onChange={(value) => update("year", value)}
              required
            />

            <Input
              label="Contact"
              value={form.contact}
              onChange={(value) => update("contact", value)}
            />

            <Input
              label="Email"
              type="email"
              value={form.email}
              onChange={(value) => update("email", value)}
            />

            {error && <div className="form-error">{error}</div>}

            <div className="modal-actions">
              <button
                className="secondary-button"
                type="button"
                onClick={onClose}
              >
                Cancel
              </button>

              <button
                className="primary-button"
                type="submit"
                disabled={loading}
              >
                {loading ? "Creating…" : "Create student"}
                {!loading && <Check size={16} />}
              </button>
            </div>
          </form>
        )}

        {modal.kind === "createComplaint" && (
          <form className="action-form" onSubmit={submit}>
            <Input
              label="Title"
              value={form.title}
              onChange={(value) => update("title", value)}
              required
            />

            <Input
              label="Description"
              textarea
              value={form.description}
              onChange={(value) => update("description", value)}
              required
            />

            {roleIsStaff(role) && (
              <Input
                label="Student record ID"
                type="number"
                value={form.studentId}
                onChange={(value) => update("studentId", value)}
                required
              />
            )}

            <Select
              label="Priority"
              value={form.priority || "medium"}
              onChange={(value) => update("priority", value)}
              options={["low", "medium", "high"]}
            />

            {error && <div className="form-error">{error}</div>}

            <div className="modal-actions">
              <button
                className="secondary-button"
                type="button"
                onClick={onClose}
              >
                Cancel
              </button>

              <button
                className="primary-button"
                type="submit"
                disabled={loading}
              >
                {loading ? "Creating…" : "Create complaint"}
                {!loading && <Check size={16} />}
              </button>
            </div>
          </form>
        )}

        {modal.kind === "createVisitor" && (
          <form className="action-form" onSubmit={submit}>
            <Input
              label="Visitor name"
              value={form.visitorName}
              onChange={(value) => update("visitorName", value)}
              required
            />

            <Input
              label="Visitor contact"
              value={form.visitorContact}
              onChange={(value) => update("visitorContact", value)}
              required
            />

            <Input
              label="Visit date"
              type="date"
              value={form.visitDate}
              onChange={(value) => update("visitDate", value)}
              required
            />

            <Input
              label="Purpose"
              value={form.purpose}
              onChange={(value) => update("purpose", value)}
              required
            />

            {roleIsStaff(role) && (
              <Input
                label="Student ID"
                type="number"
                value={form.studentId}
                onChange={(value) => update("studentId", value)}
              />
            )}

            {error && <div className="form-error">{error}</div>}

            <div className="modal-actions">
              <button
                className="secondary-button"
                type="button"
                onClick={onClose}
              >
                Cancel
              </button>

              <button
                className="primary-button"
                type="submit"
                disabled={loading}
              >
                {loading ? "Creating…" : "Create visitor"}
                {!loading && <Check size={16} />}
              </button>
            </div>
          </form>
        )}

        {modal.kind === "createFee" && (
          <form className="action-form" onSubmit={submit}>
            <Input
              label="Student ID"
              type="number"
              value={form.studentId}
              onChange={(value) => update("studentId", value)}
              required
            />

            <Input
              label="Amount"
              type="number"
              value={form.amount}
              onChange={(value) => update("amount", value)}
              required
            />

            <Input
              label="Due date"
              type="date"
              value={form.dueDate}
              onChange={(value) => update("dueDate", value)}
              required
            />

            <Input
              label="Description"
              value={form.description}
              onChange={(value) => update("description", value)}
            />

            {error && <div className="form-error">{error}</div>}

            <div className="modal-actions">
              <button
                className="secondary-button"
                type="button"
                onClick={onClose}
              >
                Cancel
              </button>

              <button
                className="primary-button"
                type="submit"
                disabled={loading}
              >
                {loading ? "Creating…" : "Create fee"}
                {!loading && <Check size={16} />}
              </button>
            </div>
          </form>
        )}

        {modal.kind === "markAttendance" && (
          <form className="action-form" onSubmit={submit}>
            <Input
              label="Student ID"
              type="number"
              value={form.studentId}
              onChange={(value) => update("studentId", value)}
              required
            />

            <Input
              label="Date"
              type="date"
              value={form.date}
              onChange={(value) => update("date", value)}
              required
            />

            <Select
              label="Status"
              value={form.status || "present"}
              onChange={(value) => update("status", value)}
              options={["present", "absent", "late"]}
            />

            {error && <div className="form-error">{error}</div>}

            <div className="modal-actions">
              <button
                className="secondary-button"
                type="button"
                onClick={onClose}
              >
                Cancel
              </button>

              <button
                className="primary-button"
                type="submit"
                disabled={loading}
              >
                {loading ? "Saving…" : "Mark attendance"}
                {!loading && <Check size={16} />}
              </button>
            </div>
          </form>
        )}

        {["info", "profile"].includes(modal.kind) && (
          <div className="modal-actions">
            <button className="secondary-button" onClick={onClose}>
              Close
            </button>

            <button className="primary-button" onClick={onClose}>
              Done
              <Check size={16} />
            </button>
          </div>
        )}
      </div>
    </div>
  );
}

function Input({
  label,
  value,
  onChange,
  type = "text",
  textarea = false,
  required = false,
  min,
  max,
}) {
  return (
    <label>
      {label}
      {textarea ? (
        <textarea
          value={value || ""}
          onChange={(event) => onChange(event.target.value)}
          required={required}
        />
      ) : (
        <input
          value={value || ""}
          onChange={(event) => onChange(event.target.value)}
          type={type}
          required={required}
          min={min}
          max={max}
        />
      )}
    </label>
  );
}

function Select({ label, value, onChange, options }) {
  return (
    <label>
      {label}
      <select
        value={value}
        onChange={(event) => onChange(event.target.value)}
      >
        {options.map((option) => (
          <option key={option} value={option}>
            {option}
          </option>
        ))}
      </select>
    </label>
  );
}


function SmartStayAssistant({ role, token }) {
  const [open, setOpen] = useState(false);
  const [messages, setMessages] = useState([
    {
      from: "bot",
      text: `Hi! I'm SmartStay AI. I can help you with your ${
        role === "student"
          ? "fees, complaints, visitors and stay"
          : role === "warden"
            ? "residents, complaints, visitors, attendance and fees"
            : "students, fees, complaints and housing statistics"
      }.`,
    },
  ]);
  const [input, setInput] = useState("");

  const suggestions =
    role === "student"
      ? ["My fees", "My complaints", "My visitors", "My attendance"]
      : role === "warden"
        ? ["Open complaints", "Today's visitors", "Attendance", "Fees"]
        : ["Students", "Finance", "Complaints", "Reports"];

  const answer = async (question) => {
    const q = question.toLowerCase();

    let reply =
      "I can help with fees, complaints, visitors, attendance, students and hostel information.";

    try {
      if (q.includes("fee") || q.includes("payment")) {
        const data = await apiRequest("/fees", {}, token);
        const fees = data.fees || [];

        if (role === "student") {
          reply = fees.length
            ? `You currently have ${fees.length} fee record(s).`
            : "You currently have no fee records.";
        } else {
          reply = `There are ${fees.length} fee record(s) in SmartStay.`;
        }
      } else if (q.includes("complaint") || q.includes("request")) {
        const data = await apiRequest("/complaints", {}, token);
        const complaints = data.complaints || [];
        reply = `I found ${complaints.length} complaint/request record(s).`;
      } else if (q.includes("visitor")) {
        const data = await apiRequest("/visitors", {}, token);
        const visitors = data.visitors || [];
        reply = `I found ${visitors.length} visitor record(s).`;
      } else if (q.includes("attendance")) {
        reply =
          role === "student"
            ? "You can view your attendance from the attendance section when available."
            : "You can manage attendance from the Attendance section.";
      } else if (q.includes("student")) {
        const data = await apiRequest("/students", {}, token);
        const students = data.students || [];
        reply = `SmartStay currently has ${students.length} student record(s).`;
      } else if (q.includes("hello") || q.includes("hi")) {
        reply = "Hello! 👋 What would you like help with?";
      }
    } catch {
      reply =
        "I couldn't retrieve that information right now. Please try again or use the relevant dashboard section.";
    }

    return reply;
  };

  const send = async (text = input) => {
    const question = text.trim();
    if (!question) return;

    setMessages((current) => [
      ...current,
      { from: "user", text: question },
    ]);
    setInput("");

    const reply = await answer(question);

    setMessages((current) => [
      ...current,
      { from: "bot", text: reply },
    ]);
  };

  return (
    <>
      {open && (
        <div
          style={{
            position: "fixed",
            right: 24,
            bottom: 92,
            width: 360,
            maxWidth: "calc(100vw - 32px)",
            height: 500,
            maxHeight: "70vh",
            background: "#fff",
            border: "1px solid #e5e7eb",
            borderRadius: 20,
            boxShadow: "0 20px 60px rgba(0,0,0,.18)",
            zIndex: 9999,
            display: "flex",
            flexDirection: "column",
            overflow: "hidden",
          }}
        >
          <div
            style={{
              padding: "16px 18px",
              display: "flex",
              alignItems: "center",
              justifyContent: "space-between",
              borderBottom: "1px solid #eee",
            }}
          >
            <div>
              <strong>✨ SmartStay AI</strong>
              <div style={{ fontSize: 12, opacity: 0.6 }}>
                Your hostel assistant
              </div>
            </div>

            <button
              onClick={() => setOpen(false)}
              style={{
                border: 0,
                background: "transparent",
                cursor: "pointer",
              }}
            >
              <X size={18} />
            </button>
          </div>

          <div
            style={{
              flex: 1,
              overflowY: "auto",
              padding: 16,
              background: "#fafafa",
            }}
          >
            {messages.map((message, index) => (
              <div
                key={index}
                style={{
                  display: "flex",
                  justifyContent:
                    message.from === "user" ? "flex-end" : "flex-start",
                  marginBottom: 10,
                }}
              >
                <div
                  style={{
                    maxWidth: "82%",
                    padding: "10px 13px",
                    borderRadius: 14,
                    background:
                      message.from === "user" ? "#111827" : "#fff",
                    color:
                      message.from === "user" ? "#fff" : "#111827",
                    border:
                      message.from === "bot"
                        ? "1px solid #e5e7eb"
                        : "none",
                    fontSize: 14,
                    lineHeight: 1.4,
                  }}
                >
                  {message.text}
                </div>
              </div>
            ))}

            <div
              style={{
                display: "flex",
                gap: 6,
                flexWrap: "wrap",
                marginTop: 8,
              }}
            >
              {suggestions.map((item) => (
                <button
                  key={item}
                  onClick={() => send(item)}
                  style={{
                    border: "1px solid #ddd",
                    background: "#fff",
                    borderRadius: 999,
                    padding: "7px 10px",
                    cursor: "pointer",
                    fontSize: 12,
                  }}
                >
                  {item}
                </button>
              ))}
            </div>
          </div>

          <form
            onSubmit={(event) => {
              event.preventDefault();
              send();
            }}
            style={{
              display: "flex",
              gap: 8,
              padding: 12,
              borderTop: "1px solid #eee",
              background: "#fff",
            }}
          >
            <input
              value={input}
              onChange={(event) => setInput(event.target.value)}
              placeholder="Ask SmartStay AI..."
              style={{
                flex: 1,
                border: "1px solid #ddd",
                borderRadius: 12,
                padding: "10px 12px",
                outline: "none",
              }}
            />

            <button
              type="submit"
              style={{
                border: 0,
                borderRadius: 12,
                padding: "0 13px",
                background: "#111827",
                color: "#fff",
                cursor: "pointer",
              }}
            >
              <ArrowRight size={17} />
            </button>
          </form>
        </div>
      )}

      <button
        onClick={() => setOpen((value) => !value)}
        style={{
          position: "fixed",
          right: 24,
          bottom: 24,
          zIndex: 10000,
          border: 0,
          borderRadius: 999,
          padding: "13px 18px",
          background: "#111827",
          color: "#fff",
          boxShadow: "0 10px 30px rgba(0,0,0,.2)",
          cursor: "pointer",
          display: "flex",
          alignItems: "center",
          gap: 8,
          fontWeight: 600,
        }}
      >
        <Sparkles size={17} />
        SmartStay AI
      </button>

    </>
  );
}

function roleIsStaff(role) {
  return role === "warden" || role === "university";
}

export default App;
