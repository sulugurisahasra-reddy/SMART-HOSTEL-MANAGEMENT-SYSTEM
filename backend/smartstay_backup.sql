--
-- PostgreSQL database dump
--

\restrict 5dMwyHenaxhd2nxKd9lZ59BT2AbEtxIecQWGdGNNbqwmuV1d4aTQgNOs7KRiLFZ

-- Dumped from database version 17.11 (Homebrew)
-- Dumped by pg_dump version 17.11 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: smartstay; Type: SCHEMA; Schema: -; Owner: sunny
--

CREATE SCHEMA smartstay;


ALTER SCHEMA smartstay OWNER TO sunny;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA smartstay;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: update_room_occupancy(); Type: FUNCTION; Schema: public; Owner: sunny
--

CREATE FUNCTION public.update_room_occupancy() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    -- New active allocation
    IF TG_OP = 'INSERT'
       AND NEW.status = 'active' THEN

        UPDATE rooms
        SET current_occupancy = current_occupancy + 1
        WHERE room_id = NEW.room_id;

    END IF;


    -- Allocation becomes vacated
    IF TG_OP = 'UPDATE'
       AND OLD.status = 'active'
       AND NEW.status = 'vacated' THEN

        UPDATE rooms
        SET current_occupancy =
            GREATEST(current_occupancy - 1, 0)
        WHERE room_id = OLD.room_id;

    END IF;


    -- Allocation changes room
    IF TG_OP = 'UPDATE'
       AND OLD.status = 'active'
       AND NEW.status = 'active'
       AND OLD.room_id <> NEW.room_id THEN

        UPDATE rooms
        SET current_occupancy =
            GREATEST(current_occupancy - 1, 0)
        WHERE room_id = OLD.room_id;

        UPDATE rooms
        SET current_occupancy = current_occupancy + 1
        WHERE room_id = NEW.room_id;

    END IF;


    -- Deleted active allocation
    IF TG_OP = 'DELETE'
       AND OLD.status = 'active' THEN

        UPDATE rooms
        SET current_occupancy =
            GREATEST(current_occupancy - 1, 0)
        WHERE room_id = OLD.room_id;

    END IF;

    RETURN COALESCE(NEW, OLD);

END;
$$;


ALTER FUNCTION public.update_room_occupancy() OWNER TO sunny;

--
-- Name: update_room_status(); Type: FUNCTION; Schema: public; Owner: sunny
--

CREATE FUNCTION public.update_room_status() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    UPDATE rooms
    SET status =
        CASE
            WHEN status = 'maintenance'
                THEN 'maintenance'

            WHEN current_occupancy >= capacity
                THEN 'full'

            ELSE 'available'
        END
    WHERE room_id = NEW.room_id;

    RETURN NEW;

END;
$$;


ALTER FUNCTION public.update_room_status() OWNER TO sunny;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: allocations; Type: TABLE; Schema: public; Owner: sunny
--

CREATE TABLE public.allocations (
    allocation_id integer NOT NULL,
    student_id integer NOT NULL,
    room_id integer NOT NULL,
    allocation_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    vacated_date timestamp without time zone,
    status character varying(30) DEFAULT 'active'::character varying,
    allocation_reason text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.allocations OWNER TO sunny;

--
-- Name: allocations_allocation_id_seq; Type: SEQUENCE; Schema: public; Owner: sunny
--

CREATE SEQUENCE public.allocations_allocation_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.allocations_allocation_id_seq OWNER TO sunny;

--
-- Name: allocations_allocation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sunny
--

ALTER SEQUENCE public.allocations_allocation_id_seq OWNED BY public.allocations.allocation_id;


--
-- Name: attendance; Type: TABLE; Schema: public; Owner: sunny
--

CREATE TABLE public.attendance (
    attendance_id integer NOT NULL,
    student_id integer NOT NULL,
    attendance_date date NOT NULL,
    status character varying(30) NOT NULL,
    marked_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.attendance OWNER TO sunny;

--
-- Name: attendance_attendance_id_seq; Type: SEQUENCE; Schema: public; Owner: sunny
--

CREATE SEQUENCE public.attendance_attendance_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.attendance_attendance_id_seq OWNER TO sunny;

--
-- Name: attendance_attendance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sunny
--

ALTER SEQUENCE public.attendance_attendance_id_seq OWNED BY public.attendance.attendance_id;


--
-- Name: complaints; Type: TABLE; Schema: public; Owner: sunny
--

CREATE TABLE public.complaints (
    complaint_id integer NOT NULL,
    student_id integer NOT NULL,
    title character varying(200) NOT NULL,
    description text,
    category character varying(100),
    status character varying(30) DEFAULT 'open'::character varying,
    priority character varying(30) DEFAULT 'medium'::character varying,
    resolution text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    resolved_at timestamp without time zone
);


ALTER TABLE public.complaints OWNER TO sunny;

--
-- Name: complaints_complaint_id_seq; Type: SEQUENCE; Schema: public; Owner: sunny
--

CREATE SEQUENCE public.complaints_complaint_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.complaints_complaint_id_seq OWNER TO sunny;

--
-- Name: complaints_complaint_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sunny
--

ALTER SEQUENCE public.complaints_complaint_id_seq OWNED BY public.complaints.complaint_id;


--
-- Name: fees; Type: TABLE; Schema: public; Owner: sunny
--

CREATE TABLE public.fees (
    fee_id integer NOT NULL,
    student_id integer NOT NULL,
    amount numeric(12,2) NOT NULL,
    fee_type character varying(100),
    due_date timestamp without time zone,
    payment_date timestamp without time zone,
    payment_status character varying(30) DEFAULT 'pending'::character varying,
    receipt_number character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.fees OWNER TO sunny;

--
-- Name: fees_fee_id_seq; Type: SEQUENCE; Schema: public; Owner: sunny
--

CREATE SEQUENCE public.fees_fee_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fees_fee_id_seq OWNER TO sunny;

--
-- Name: fees_fee_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sunny
--

ALTER SEQUENCE public.fees_fee_id_seq OWNED BY public.fees.fee_id;


--
-- Name: hostels; Type: TABLE; Schema: public; Owner: sunny
--

CREATE TABLE public.hostels (
    hostel_id integer NOT NULL,
    hostel_name character varying(150) NOT NULL,
    hostel_type character varying(30),
    address text,
    total_floors integer DEFAULT 1,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.hostels OWNER TO sunny;

--
-- Name: hostels_hostel_id_seq; Type: SEQUENCE; Schema: public; Owner: sunny
--

CREATE SEQUENCE public.hostels_hostel_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.hostels_hostel_id_seq OWNER TO sunny;

--
-- Name: hostels_hostel_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sunny
--

ALTER SEQUENCE public.hostels_hostel_id_seq OWNED BY public.hostels.hostel_id;


--
-- Name: rooms; Type: TABLE; Schema: public; Owner: sunny
--

CREATE TABLE public.rooms (
    room_id integer NOT NULL,
    hostel_id integer NOT NULL,
    room_number character varying(50) NOT NULL,
    room_type character varying(50) NOT NULL,
    capacity integer NOT NULL,
    current_occupancy integer DEFAULT 0 NOT NULL,
    CONSTRAINT rooms_capacity_check CHECK ((capacity > 0))
);


ALTER TABLE public.rooms OWNER TO sunny;

--
-- Name: students; Type: TABLE; Schema: public; Owner: sunny
--

CREATE TABLE public.students (
    student_id integer NOT NULL,
    user_id integer NOT NULL,
    student_number character varying(50) NOT NULL,
    name character varying(150) NOT NULL,
    department character varying(150),
    year integer,
    contact character varying(30),
    email character varying(150),
    preferences jsonb DEFAULT '{}'::jsonb,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.students OWNER TO sunny;

--
-- Name: room_occupancy_view; Type: VIEW; Schema: public; Owner: sunny
--

CREATE VIEW public.room_occupancy_view AS
 SELECT r.room_id,
    r.hostel_id,
    h.hostel_name,
    h.hostel_type,
    r.room_number,
    r.room_type,
    r.capacity,
    r.current_occupancy,
    COALESCE(json_agg(json_build_object('student_id', s.student_id, 'student_number', s.student_number, 'name', s.name)) FILTER (WHERE (s.student_id IS NOT NULL)), '[]'::json) AS students
   FROM (((public.rooms r
     JOIN public.hostels h ON ((h.hostel_id = r.hostel_id)))
     LEFT JOIN public.allocations a ON ((a.room_id = r.room_id)))
     LEFT JOIN public.students s ON ((s.student_id = a.student_id)))
  GROUP BY r.room_id, r.hostel_id, h.hostel_name, h.hostel_type, r.room_number, r.room_type, r.capacity, r.current_occupancy;


ALTER VIEW public.room_occupancy_view OWNER TO sunny;

--
-- Name: rooms_room_id_seq; Type: SEQUENCE; Schema: public; Owner: sunny
--

CREATE SEQUENCE public.rooms_room_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rooms_room_id_seq OWNER TO sunny;

--
-- Name: rooms_room_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sunny
--

ALTER SEQUENCE public.rooms_room_id_seq OWNED BY public.rooms.room_id;


--
-- Name: students_student_id_seq; Type: SEQUENCE; Schema: public; Owner: sunny
--

CREATE SEQUENCE public.students_student_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.students_student_id_seq OWNER TO sunny;

--
-- Name: students_student_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sunny
--

ALTER SEQUENCE public.students_student_id_seq OWNED BY public.students.student_id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: sunny
--

CREATE TABLE public.users (
    user_id integer NOT NULL,
    username character varying(100) NOT NULL,
    password_hash text NOT NULL,
    role character varying(30) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    is_active boolean DEFAULT true NOT NULL,
    CONSTRAINT users_role_check CHECK (((role)::text = ANY ((ARRAY['student'::character varying, 'warden'::character varying, 'university'::character varying])::text[])))
);


ALTER TABLE public.users OWNER TO sunny;

--
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: public; Owner: sunny
--

CREATE SEQUENCE public.users_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_user_id_seq OWNER TO sunny;

--
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sunny
--

ALTER SEQUENCE public.users_user_id_seq OWNED BY public.users.user_id;


--
-- Name: visitors; Type: TABLE; Schema: public; Owner: sunny
--

CREATE TABLE public.visitors (
    visitor_id integer NOT NULL,
    student_id integer NOT NULL,
    visitor_name character varying(150) NOT NULL,
    visitor_phone character varying(30),
    relationship character varying(100),
    purpose text,
    entry_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    exit_time timestamp without time zone
);


ALTER TABLE public.visitors OWNER TO sunny;

--
-- Name: visitors_visitor_id_seq; Type: SEQUENCE; Schema: public; Owner: sunny
--

CREATE SEQUENCE public.visitors_visitor_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.visitors_visitor_id_seq OWNER TO sunny;

--
-- Name: visitors_visitor_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sunny
--

ALTER SEQUENCE public.visitors_visitor_id_seq OWNED BY public.visitors.visitor_id;


--
-- Name: allocations; Type: TABLE; Schema: smartstay; Owner: sunny
--

CREATE TABLE smartstay.allocations (
    id integer NOT NULL,
    student_id integer NOT NULL,
    room_id integer NOT NULL,
    check_in date DEFAULT CURRENT_DATE NOT NULL,
    check_out date,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT allocations_check CHECK (((check_out IS NULL) OR (check_out >= check_in)))
);


ALTER TABLE smartstay.allocations OWNER TO sunny;

--
-- Name: allocations_id_seq; Type: SEQUENCE; Schema: smartstay; Owner: sunny
--

CREATE SEQUENCE smartstay.allocations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE smartstay.allocations_id_seq OWNER TO sunny;

--
-- Name: allocations_id_seq; Type: SEQUENCE OWNED BY; Schema: smartstay; Owner: sunny
--

ALTER SEQUENCE smartstay.allocations_id_seq OWNED BY smartstay.allocations.id;


--
-- Name: attendance; Type: TABLE; Schema: smartstay; Owner: sunny
--

CREATE TABLE smartstay.attendance (
    id integer NOT NULL,
    student_id integer NOT NULL,
    attendance_date date NOT NULL,
    status text NOT NULL,
    marked_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT attendance_status_check CHECK ((status = ANY (ARRAY['present'::text, 'absent'::text, 'leave'::text])))
);


ALTER TABLE smartstay.attendance OWNER TO sunny;

--
-- Name: attendance_id_seq; Type: SEQUENCE; Schema: smartstay; Owner: sunny
--

CREATE SEQUENCE smartstay.attendance_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE smartstay.attendance_id_seq OWNER TO sunny;

--
-- Name: attendance_id_seq; Type: SEQUENCE OWNED BY; Schema: smartstay; Owner: sunny
--

ALTER SEQUENCE smartstay.attendance_id_seq OWNED BY smartstay.attendance.id;


--
-- Name: complaints; Type: TABLE; Schema: smartstay; Owner: sunny
--

CREATE TABLE smartstay.complaints (
    id integer NOT NULL,
    student_id integer NOT NULL,
    hostel_id integer,
    category text NOT NULL,
    priority text NOT NULL,
    status text DEFAULT 'open'::text NOT NULL,
    description text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    resolved_at timestamp with time zone,
    CONSTRAINT complaints_priority_check CHECK ((priority = ANY (ARRAY['low'::text, 'medium'::text, 'high'::text]))),
    CONSTRAINT complaints_status_check CHECK ((status = ANY (ARRAY['open'::text, 'in_progress'::text, 'resolved'::text])))
);


ALTER TABLE smartstay.complaints OWNER TO sunny;

--
-- Name: complaints_id_seq; Type: SEQUENCE; Schema: smartstay; Owner: sunny
--

CREATE SEQUENCE smartstay.complaints_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE smartstay.complaints_id_seq OWNER TO sunny;

--
-- Name: complaints_id_seq; Type: SEQUENCE OWNED BY; Schema: smartstay; Owner: sunny
--

ALTER SEQUENCE smartstay.complaints_id_seq OWNED BY smartstay.complaints.id;


--
-- Name: fees; Type: TABLE; Schema: smartstay; Owner: sunny
--

CREATE TABLE smartstay.fees (
    id integer NOT NULL,
    student_id integer NOT NULL,
    term text NOT NULL,
    amount_due numeric(10,2) NOT NULL,
    amount_paid numeric(10,2) DEFAULT 0 NOT NULL,
    due_date date NOT NULL,
    status text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT fees_amount_due_check CHECK ((amount_due >= (0)::numeric)),
    CONSTRAINT fees_amount_paid_check CHECK ((amount_paid >= (0)::numeric)),
    CONSTRAINT fees_status_check CHECK ((status = ANY (ARRAY['paid'::text, 'pending'::text, 'overdue'::text, 'partial'::text])))
);


ALTER TABLE smartstay.fees OWNER TO sunny;

--
-- Name: fees_id_seq; Type: SEQUENCE; Schema: smartstay; Owner: sunny
--

CREATE SEQUENCE smartstay.fees_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE smartstay.fees_id_seq OWNER TO sunny;

--
-- Name: fees_id_seq; Type: SEQUENCE OWNED BY; Schema: smartstay; Owner: sunny
--

ALTER SEQUENCE smartstay.fees_id_seq OWNED BY smartstay.fees.id;


--
-- Name: hostels; Type: TABLE; Schema: smartstay; Owner: sunny
--

CREATE TABLE smartstay.hostels (
    id integer NOT NULL,
    university_id integer NOT NULL,
    name text NOT NULL,
    code text NOT NULL,
    gender text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT hostels_gender_check CHECK ((gender = ANY (ARRAY['women'::text, 'men'::text, 'all'::text])))
);


ALTER TABLE smartstay.hostels OWNER TO sunny;

--
-- Name: hostels_id_seq; Type: SEQUENCE; Schema: smartstay; Owner: sunny
--

CREATE SEQUENCE smartstay.hostels_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE smartstay.hostels_id_seq OWNER TO sunny;

--
-- Name: hostels_id_seq; Type: SEQUENCE OWNED BY; Schema: smartstay; Owner: sunny
--

ALTER SEQUENCE smartstay.hostels_id_seq OWNED BY smartstay.hostels.id;


--
-- Name: rooms; Type: TABLE; Schema: smartstay; Owner: sunny
--

CREATE TABLE smartstay.rooms (
    id integer NOT NULL,
    hostel_id integer NOT NULL,
    room_number text NOT NULL,
    floor integer DEFAULT 1 NOT NULL,
    capacity integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT rooms_capacity_check CHECK ((capacity > 0))
);


ALTER TABLE smartstay.rooms OWNER TO sunny;

--
-- Name: rooms_id_seq; Type: SEQUENCE; Schema: smartstay; Owner: sunny
--

CREATE SEQUENCE smartstay.rooms_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE smartstay.rooms_id_seq OWNER TO sunny;

--
-- Name: rooms_id_seq; Type: SEQUENCE OWNED BY; Schema: smartstay; Owner: sunny
--

ALTER SEQUENCE smartstay.rooms_id_seq OWNED BY smartstay.rooms.id;


--
-- Name: students; Type: TABLE; Schema: smartstay; Owner: sunny
--

CREATE TABLE smartstay.students (
    id integer NOT NULL,
    user_id uuid NOT NULL,
    university_id integer NOT NULL,
    enrollment_no text NOT NULL,
    full_name text NOT NULL,
    department text NOT NULL,
    year_of_study integer NOT NULL,
    gender text NOT NULL,
    phone text,
    guardian_name text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT students_gender_check CHECK ((gender = ANY (ARRAY['woman'::text, 'man'::text, 'other'::text]))),
    CONSTRAINT students_year_of_study_check CHECK (((year_of_study >= 1) AND (year_of_study <= 6)))
);


ALTER TABLE smartstay.students OWNER TO sunny;

--
-- Name: students_id_seq; Type: SEQUENCE; Schema: smartstay; Owner: sunny
--

CREATE SEQUENCE smartstay.students_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE smartstay.students_id_seq OWNER TO sunny;

--
-- Name: students_id_seq; Type: SEQUENCE OWNED BY; Schema: smartstay; Owner: sunny
--

ALTER SEQUENCE smartstay.students_id_seq OWNED BY smartstay.students.id;


--
-- Name: universities; Type: TABLE; Schema: smartstay; Owner: sunny
--

CREATE TABLE smartstay.universities (
    id integer NOT NULL,
    name text NOT NULL,
    code text NOT NULL,
    city text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE smartstay.universities OWNER TO sunny;

--
-- Name: universities_id_seq; Type: SEQUENCE; Schema: smartstay; Owner: sunny
--

CREATE SEQUENCE smartstay.universities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE smartstay.universities_id_seq OWNER TO sunny;

--
-- Name: universities_id_seq; Type: SEQUENCE OWNED BY; Schema: smartstay; Owner: sunny
--

ALTER SEQUENCE smartstay.universities_id_seq OWNED BY smartstay.universities.id;


--
-- Name: university_admins; Type: TABLE; Schema: smartstay; Owner: sunny
--

CREATE TABLE smartstay.university_admins (
    id integer NOT NULL,
    user_id uuid NOT NULL,
    university_id integer NOT NULL,
    full_name text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE smartstay.university_admins OWNER TO sunny;

--
-- Name: university_admins_id_seq; Type: SEQUENCE; Schema: smartstay; Owner: sunny
--

CREATE SEQUENCE smartstay.university_admins_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE smartstay.university_admins_id_seq OWNER TO sunny;

--
-- Name: university_admins_id_seq; Type: SEQUENCE OWNED BY; Schema: smartstay; Owner: sunny
--

ALTER SEQUENCE smartstay.university_admins_id_seq OWNED BY smartstay.university_admins.id;


--
-- Name: users; Type: TABLE; Schema: smartstay; Owner: sunny
--

CREATE TABLE smartstay.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email text NOT NULL,
    password_hash text NOT NULL,
    role text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    last_login_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT users_role_check CHECK ((role = ANY (ARRAY['student'::text, 'warden'::text, 'university'::text])))
);


ALTER TABLE smartstay.users OWNER TO sunny;

--
-- Name: visitors; Type: TABLE; Schema: smartstay; Owner: sunny
--

CREATE TABLE smartstay.visitors (
    id integer NOT NULL,
    student_id integer NOT NULL,
    guest_name text NOT NULL,
    relationship text NOT NULL,
    visit_date date NOT NULL,
    status text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT visitors_status_check CHECK ((status = ANY (ARRAY['scheduled'::text, 'approved'::text, 'checked_in'::text, 'completed'::text, 'rejected'::text])))
);


ALTER TABLE smartstay.visitors OWNER TO sunny;

--
-- Name: visitors_id_seq; Type: SEQUENCE; Schema: smartstay; Owner: sunny
--

CREATE SEQUENCE smartstay.visitors_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE smartstay.visitors_id_seq OWNER TO sunny;

--
-- Name: visitors_id_seq; Type: SEQUENCE OWNED BY; Schema: smartstay; Owner: sunny
--

ALTER SEQUENCE smartstay.visitors_id_seq OWNED BY smartstay.visitors.id;


--
-- Name: wardens; Type: TABLE; Schema: smartstay; Owner: sunny
--

CREATE TABLE smartstay.wardens (
    id integer NOT NULL,
    user_id uuid NOT NULL,
    university_id integer NOT NULL,
    hostel_id integer,
    full_name text NOT NULL,
    phone text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE smartstay.wardens OWNER TO sunny;

--
-- Name: wardens_id_seq; Type: SEQUENCE; Schema: smartstay; Owner: sunny
--

CREATE SEQUENCE smartstay.wardens_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE smartstay.wardens_id_seq OWNER TO sunny;

--
-- Name: wardens_id_seq; Type: SEQUENCE OWNED BY; Schema: smartstay; Owner: sunny
--

ALTER SEQUENCE smartstay.wardens_id_seq OWNED BY smartstay.wardens.id;


--
-- Name: allocations allocation_id; Type: DEFAULT; Schema: public; Owner: sunny
--

ALTER TABLE ONLY public.allocations ALTER COLUMN allocation_id SET DEFAULT nextval('public.allocations_allocation_id_seq'::regclass);


--
-- Name: attendance attendance_id; Type: DEFAULT; Schema: public; Owner: sunny
--

ALTER TABLE ONLY public.attendance ALTER COLUMN attendance_id SET DEFAULT nextval('public.attendance_attendance_id_seq'::regclass);


--
-- Name: complaints complaint_id; Type: DEFAULT; Schema: public; Owner: sunny
--

ALTER TABLE ONLY public.complaints ALTER COLUMN complaint_id SET DEFAULT nextval('public.complaints_complaint_id_seq'::regclass);


--
-- Name: fees fee_id; Type: DEFAULT; Schema: public; Owner: sunny
--

ALTER TABLE ONLY public.fees ALTER COLUMN fee_id SET DEFAULT nextval('public.fees_fee_id_seq'::regclass);


--
-- Name: hostels hostel_id; Type: DEFAULT; Schema: public; Owner: sunny
--

ALTER TABLE ONLY public.hostels ALTER COLUMN hostel_id SET DEFAULT nextval('public.hostels_hostel_id_seq'::regclass);


--
-- Name: rooms room_id; Type: DEFAULT; Schema: public; Owner: sunny
--

ALTER TABLE ONLY public.rooms ALTER COLUMN room_id SET DEFAULT nextval('public.rooms_room_id_seq'::regclass);


--
-- Name: students student_id; Type: DEFAULT; Schema: public; Owner: sunny
--

ALTER TABLE ONLY public.students ALTER COLUMN student_id SET DEFAULT nextval('public.students_student_id_seq'::regclass);


--
-- Name: users user_id; Type: DEFAULT; Schema: public; Owner: sunny
--

ALTER TABLE ONLY public.users ALTER COLUMN user_id SET DEFAULT nextval('public.users_user_id_seq'::regclass);


--
-- Name: visitors visitor_id; Type: DEFAULT; Schema: public; Owner: sunny
--

ALTER TABLE ONLY public.visitors ALTER COLUMN visitor_id SET DEFAULT nextval('public.visitors_visitor_id_seq'::regclass);


--
-- Name: allocations id; Type: DEFAULT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.allocations ALTER COLUMN id SET DEFAULT nextval('smartstay.allocations_id_seq'::regclass);


--
-- Name: attendance id; Type: DEFAULT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.attendance ALTER COLUMN id SET DEFAULT nextval('smartstay.attendance_id_seq'::regclass);


--
-- Name: complaints id; Type: DEFAULT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.complaints ALTER COLUMN id SET DEFAULT nextval('smartstay.complaints_id_seq'::regclass);


--
-- Name: fees id; Type: DEFAULT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.fees ALTER COLUMN id SET DEFAULT nextval('smartstay.fees_id_seq'::regclass);


--
-- Name: hostels id; Type: DEFAULT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.hostels ALTER COLUMN id SET DEFAULT nextval('smartstay.hostels_id_seq'::regclass);


--
-- Name: rooms id; Type: DEFAULT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.rooms ALTER COLUMN id SET DEFAULT nextval('smartstay.rooms_id_seq'::regclass);


--
-- Name: students id; Type: DEFAULT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.students ALTER COLUMN id SET DEFAULT nextval('smartstay.students_id_seq'::regclass);


--
-- Name: universities id; Type: DEFAULT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.universities ALTER COLUMN id SET DEFAULT nextval('smartstay.universities_id_seq'::regclass);


--
-- Name: university_admins id; Type: DEFAULT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.university_admins ALTER COLUMN id SET DEFAULT nextval('smartstay.university_admins_id_seq'::regclass);


--
-- Name: visitors id; Type: DEFAULT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.visitors ALTER COLUMN id SET DEFAULT nextval('smartstay.visitors_id_seq'::regclass);


--
-- Name: wardens id; Type: DEFAULT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.wardens ALTER COLUMN id SET DEFAULT nextval('smartstay.wardens_id_seq'::regclass);


--
-- Data for Name: allocations; Type: TABLE DATA; Schema: public; Owner: sunny
--

COPY public.allocations (allocation_id, student_id, room_id, allocation_date, vacated_date, status, allocation_reason, created_at) FROM stdin;
131	1	1	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
132	2	1	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
133	3	2	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
134	4	2	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
135	5	2	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
136	6	3	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
137	7	3	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
138	8	4	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
139	9	4	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
140	10	4	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
141	11	4	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
142	12	5	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
143	13	5	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
144	14	6	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
145	15	6	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
146	16	6	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
147	17	7	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
148	18	7	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
149	19	8	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
150	20	8	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
151	21	8	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
152	22	9	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
153	23	9	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
154	24	10	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
155	25	10	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
156	26	10	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
157	27	10	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
158	28	11	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
159	29	11	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
160	30	12	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
161	31	12	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
162	32	12	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
163	33	13	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
164	34	13	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
165	35	14	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
166	36	14	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
167	37	14	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
168	38	15	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
169	39	15	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
170	40	16	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
171	41	16	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
172	42	16	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
173	43	16	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
174	44	17	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
175	45	17	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
176	46	18	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
177	47	18	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
178	48	18	2026-09-30 23:04:52.295084	\N	active	Demo hostel allocation	2026-09-30 23:04:52.295084
\.


--
-- Data for Name: attendance; Type: TABLE DATA; Schema: public; Owner: sunny
--

COPY public.attendance (attendance_id, student_id, attendance_date, status, marked_at) FROM stdin;
1	1	2026-09-30	present	2026-09-30 21:49:03.962537
2	2	2026-09-30	present	2026-09-30 21:49:03.962537
3	3	2026-09-30	present	2026-09-30 21:49:03.962537
4	4	2026-09-30	present	2026-09-30 21:49:03.962537
5	5	2026-09-30	present	2026-09-30 21:49:03.962537
6	6	2026-09-30	present	2026-09-30 21:49:03.962537
7	7	2026-09-30	present	2026-09-30 21:49:03.962537
8	8	2026-09-30	present	2026-09-30 21:49:03.962537
9	9	2026-09-30	present	2026-09-30 21:49:03.962537
10	10	2026-09-30	absent	2026-09-30 21:49:03.962537
11	11	2026-09-30	present	2026-09-30 21:49:03.962537
12	12	2026-09-30	present	2026-09-30 21:49:03.962537
13	13	2026-09-30	present	2026-09-30 21:49:03.962537
14	14	2026-09-30	present	2026-09-30 21:49:03.962537
15	15	2026-09-30	present	2026-09-30 21:49:03.962537
16	16	2026-09-30	present	2026-09-30 21:49:03.962537
17	17	2026-09-30	present	2026-09-30 21:49:03.962537
18	18	2026-09-30	present	2026-09-30 21:49:03.962537
19	19	2026-09-30	present	2026-09-30 21:49:03.962537
20	20	2026-09-30	absent	2026-09-30 21:49:03.962537
21	21	2026-09-30	present	2026-09-30 21:49:03.962537
22	22	2026-09-30	present	2026-09-30 21:49:03.962537
23	23	2026-09-30	present	2026-09-30 21:49:03.962537
24	24	2026-09-30	present	2026-09-30 21:49:03.962537
25	25	2026-09-30	present	2026-09-30 21:49:03.962537
26	26	2026-09-30	present	2026-09-30 21:49:03.962537
27	27	2026-09-30	present	2026-09-30 21:49:03.962537
28	28	2026-09-30	present	2026-09-30 21:49:03.962537
29	29	2026-09-30	present	2026-09-30 21:49:03.962537
30	30	2026-09-30	absent	2026-09-30 21:49:03.962537
31	31	2026-09-30	present	2026-09-30 21:49:03.962537
32	32	2026-09-30	present	2026-09-30 21:49:03.962537
33	33	2026-09-30	present	2026-09-30 21:49:03.962537
34	34	2026-09-30	present	2026-09-30 21:49:03.962537
35	35	2026-09-30	present	2026-09-30 21:49:03.962537
36	36	2026-09-30	present	2026-09-30 21:49:03.962537
37	37	2026-09-30	present	2026-09-30 21:49:03.962537
38	38	2026-09-30	present	2026-09-30 21:49:03.962537
39	39	2026-09-30	present	2026-09-30 21:49:03.962537
40	40	2026-09-30	absent	2026-09-30 21:49:03.962537
41	41	2026-09-30	present	2026-09-30 21:49:03.962537
42	42	2026-09-30	present	2026-09-30 21:49:03.962537
43	43	2026-09-30	present	2026-09-30 21:49:03.962537
44	44	2026-09-30	present	2026-09-30 21:49:03.962537
45	45	2026-09-30	present	2026-09-30 21:49:03.962537
46	46	2026-09-30	present	2026-09-30 21:49:03.962537
47	47	2026-09-30	present	2026-09-30 21:49:03.962537
48	48	2026-09-30	present	2026-09-30 21:49:03.962537
49	49	2026-09-30	present	2026-09-30 21:49:03.962537
50	50	2026-09-30	absent	2026-09-30 21:49:03.962537
51	51	2026-09-30	present	2026-09-30 21:49:03.962537
52	52	2026-09-30	present	2026-09-30 21:49:03.962537
53	53	2026-09-30	present	2026-09-30 21:49:03.962537
54	54	2026-09-30	present	2026-09-30 21:49:03.962537
55	55	2026-09-30	present	2026-09-30 21:49:03.962537
56	56	2026-09-30	present	2026-09-30 21:49:03.962537
57	57	2026-09-30	present	2026-09-30 21:49:03.962537
58	58	2026-09-30	present	2026-09-30 21:49:03.962537
59	59	2026-09-30	present	2026-09-30 21:49:03.962537
60	60	2026-09-30	absent	2026-09-30 21:49:03.962537
61	61	2026-09-30	present	2026-09-30 21:49:03.962537
62	62	2026-09-30	present	2026-09-30 21:49:03.962537
63	63	2026-09-30	present	2026-09-30 21:49:03.962537
64	64	2026-09-30	present	2026-09-30 21:49:03.962537
65	65	2026-09-30	present	2026-09-30 21:49:03.962537
66	66	2026-09-30	present	2026-09-30 21:49:03.962537
67	67	2026-09-30	present	2026-09-30 21:49:03.962537
68	68	2026-09-30	present	2026-09-30 21:49:03.962537
69	69	2026-09-30	present	2026-09-30 21:49:03.962537
70	70	2026-09-30	absent	2026-09-30 21:49:03.962537
71	71	2026-09-30	present	2026-09-30 21:49:03.962537
72	72	2026-09-30	present	2026-09-30 21:49:03.962537
73	73	2026-09-30	present	2026-09-30 21:49:03.962537
74	74	2026-09-30	present	2026-09-30 21:49:03.962537
75	75	2026-09-30	present	2026-09-30 21:49:03.962537
76	76	2026-09-30	present	2026-09-30 21:49:03.962537
77	77	2026-09-30	present	2026-09-30 21:49:03.962537
78	78	2026-09-30	present	2026-09-30 21:49:03.962537
79	79	2026-09-30	present	2026-09-30 21:49:03.962537
80	80	2026-09-30	absent	2026-09-30 21:49:03.962537
81	81	2026-09-30	present	2026-09-30 21:49:03.962537
82	82	2026-09-30	present	2026-09-30 21:49:03.962537
83	83	2026-09-30	present	2026-09-30 21:49:03.962537
84	84	2026-09-30	present	2026-09-30 21:49:03.962537
85	85	2026-09-30	present	2026-09-30 21:49:03.962537
86	86	2026-09-30	present	2026-09-30 21:49:03.962537
87	87	2026-09-30	present	2026-09-30 21:49:03.962537
88	88	2026-09-30	present	2026-09-30 21:49:03.962537
89	89	2026-09-30	present	2026-09-30 21:49:03.962537
90	90	2026-09-30	absent	2026-09-30 21:49:03.962537
91	91	2026-09-30	present	2026-09-30 21:49:03.962537
92	92	2026-09-30	present	2026-09-30 21:49:03.962537
93	93	2026-09-30	present	2026-09-30 21:49:03.962537
94	94	2026-09-30	present	2026-09-30 21:49:03.962537
95	95	2026-09-30	present	2026-09-30 21:49:03.962537
96	96	2026-09-30	present	2026-09-30 21:49:03.962537
97	97	2026-09-30	present	2026-09-30 21:49:03.962537
98	98	2026-09-30	present	2026-09-30 21:49:03.962537
99	99	2026-09-30	present	2026-09-30 21:49:03.962537
100	100	2026-09-30	absent	2026-09-30 21:49:03.962537
101	101	2026-09-30	present	2026-09-30 21:49:03.962537
102	102	2026-09-30	present	2026-09-30 21:49:03.962537
103	103	2026-09-30	present	2026-09-30 21:49:03.962537
104	104	2026-09-30	present	2026-09-30 21:49:03.962537
105	105	2026-09-30	present	2026-09-30 21:49:03.962537
106	106	2026-09-30	present	2026-09-30 21:49:03.962537
107	107	2026-09-30	present	2026-09-30 21:49:03.962537
108	108	2026-09-30	present	2026-09-30 21:49:03.962537
109	109	2026-09-30	present	2026-09-30 21:49:03.962537
110	110	2026-09-30	absent	2026-09-30 21:49:03.962537
111	111	2026-09-30	present	2026-09-30 21:49:03.962537
112	112	2026-09-30	present	2026-09-30 21:49:03.962537
113	113	2026-09-30	present	2026-09-30 21:49:03.962537
114	114	2026-09-30	present	2026-09-30 21:49:03.962537
115	115	2026-09-30	present	2026-09-30 21:49:03.962537
116	116	2026-09-30	present	2026-09-30 21:49:03.962537
117	117	2026-09-30	present	2026-09-30 21:49:03.962537
118	118	2026-09-30	present	2026-09-30 21:49:03.962537
119	119	2026-09-30	present	2026-09-30 21:49:03.962537
120	120	2026-09-30	absent	2026-09-30 21:49:03.962537
\.


--
-- Data for Name: complaints; Type: TABLE DATA; Schema: public; Owner: sunny
--

COPY public.complaints (complaint_id, student_id, title, description, category, status, priority, resolution, created_at, resolved_at) FROM stdin;
1	1	WiFi Issue	Internet connectivity is unstable.	Internet	resolved	high	\N	2026-09-30 21:49:03.962537	\N
2	2	Water Issue	Water supply interruption.	Maintenance	open	medium	\N	2026-09-30 21:49:03.962537	\N
3	3	Room Cleaning	Room requires cleaning.	Housekeeping	open	low	\N	2026-09-30 21:49:03.962537	\N
4	4	Electricity Issue	Light or power issue reported.	Electrical	open	medium	\N	2026-09-30 21:49:03.962537	\N
5	5	AC Issue	Air conditioning requires inspection.	Maintenance	open	high	\N	2026-09-30 21:49:03.962537	\N
6	6	WiFi Issue	Internet connectivity is unstable.	Internet	resolved	high	\N	2026-09-30 21:49:03.962537	\N
7	7	Water Issue	Water supply interruption.	Maintenance	open	medium	\N	2026-09-30 21:49:03.962537	\N
8	8	Room Cleaning	Room requires cleaning.	Housekeeping	open	low	\N	2026-09-30 21:49:03.962537	\N
9	9	Electricity Issue	Light or power issue reported.	Electrical	open	medium	\N	2026-09-30 21:49:03.962537	\N
10	10	AC Issue	Air conditioning requires inspection.	Maintenance	open	high	\N	2026-09-30 21:49:03.962537	\N
11	11	WiFi Issue	Internet connectivity is unstable.	Internet	resolved	high	\N	2026-09-30 21:49:03.962537	\N
12	12	Water Issue	Water supply interruption.	Maintenance	open	medium	\N	2026-09-30 21:49:03.962537	\N
13	13	Room Cleaning	Room requires cleaning.	Housekeeping	open	low	\N	2026-09-30 21:49:03.962537	\N
14	14	Electricity Issue	Light or power issue reported.	Electrical	open	medium	\N	2026-09-30 21:49:03.962537	\N
15	15	AC Issue	Air conditioning requires inspection.	Maintenance	open	high	\N	2026-09-30 21:49:03.962537	\N
16	16	WiFi Issue	Internet connectivity is unstable.	Internet	resolved	high	\N	2026-09-30 21:49:03.962537	\N
17	17	Water Issue	Water supply interruption.	Maintenance	open	medium	\N	2026-09-30 21:49:03.962537	\N
18	18	Room Cleaning	Room requires cleaning.	Housekeeping	open	low	\N	2026-09-30 21:49:03.962537	\N
19	19	Electricity Issue	Light or power issue reported.	Electrical	open	medium	\N	2026-09-30 21:49:03.962537	\N
20	20	AC Issue	Air conditioning requires inspection.	Maintenance	open	high	\N	2026-09-30 21:49:03.962537	\N
21	21	WiFi Issue	Internet connectivity is unstable.	Internet	resolved	high	\N	2026-09-30 21:49:03.962537	\N
22	22	Water Issue	Water supply interruption.	Maintenance	open	medium	\N	2026-09-30 21:49:03.962537	\N
23	23	Room Cleaning	Room requires cleaning.	Housekeeping	open	low	\N	2026-09-30 21:49:03.962537	\N
24	24	Electricity Issue	Light or power issue reported.	Electrical	open	medium	\N	2026-09-30 21:49:03.962537	\N
25	25	AC Issue	Air conditioning requires inspection.	Maintenance	open	high	\N	2026-09-30 21:49:03.962537	\N
26	26	WiFi Issue	Internet connectivity is unstable.	Internet	resolved	high	\N	2026-09-30 21:49:03.962537	\N
27	27	Water Issue	Water supply interruption.	Maintenance	open	medium	\N	2026-09-30 21:49:03.962537	\N
28	28	Room Cleaning	Room requires cleaning.	Housekeeping	open	low	\N	2026-09-30 21:49:03.962537	\N
29	29	Electricity Issue	Light or power issue reported.	Electrical	open	medium	\N	2026-09-30 21:49:03.962537	\N
30	30	AC Issue	Air conditioning requires inspection.	Maintenance	open	high	\N	2026-09-30 21:49:03.962537	\N
\.


--
-- Data for Name: fees; Type: TABLE DATA; Schema: public; Owner: sunny
--

COPY public.fees (fee_id, student_id, amount, fee_type, due_date, payment_date, payment_status, receipt_number, created_at) FROM stdin;
1	1	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
2	2	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
3	3	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
4	4	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	paid	\N	2026-09-30 21:49:03.962537
5	5	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
6	6	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
7	7	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
8	8	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	paid	\N	2026-09-30 21:49:03.962537
9	9	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
10	10	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
11	11	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
12	12	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	paid	\N	2026-09-30 21:49:03.962537
13	13	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
14	14	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
15	15	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
16	16	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	paid	\N	2026-09-30 21:49:03.962537
17	17	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
18	18	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
19	19	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
20	20	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	paid	\N	2026-09-30 21:49:03.962537
21	21	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
22	22	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
23	23	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
24	24	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	paid	\N	2026-09-30 21:49:03.962537
25	25	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
26	26	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
27	27	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
28	28	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	paid	\N	2026-09-30 21:49:03.962537
29	29	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
30	30	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
31	31	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
32	32	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	paid	\N	2026-09-30 21:49:03.962537
33	33	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
34	34	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
35	35	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
36	36	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	paid	\N	2026-09-30 21:49:03.962537
37	37	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
38	38	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
39	39	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
40	40	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	paid	\N	2026-09-30 21:49:03.962537
41	41	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
42	42	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
43	43	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
44	44	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	paid	\N	2026-09-30 21:49:03.962537
45	45	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
46	46	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
47	47	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
48	48	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	paid	\N	2026-09-30 21:49:03.962537
49	49	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
50	50	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
51	51	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
52	52	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	paid	\N	2026-09-30 21:49:03.962537
53	53	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
54	54	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
55	55	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
56	56	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	paid	\N	2026-09-30 21:49:03.962537
57	57	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
58	58	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
59	59	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
60	60	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	paid	\N	2026-09-30 21:49:03.962537
61	61	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
62	62	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
63	63	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
64	64	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	paid	\N	2026-09-30 21:49:03.962537
65	65	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
66	66	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
67	67	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
68	68	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	paid	\N	2026-09-30 21:49:03.962537
69	69	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
70	70	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
71	71	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
72	72	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	paid	\N	2026-09-30 21:49:03.962537
73	73	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
74	74	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
75	75	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
76	76	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	paid	\N	2026-09-30 21:49:03.962537
77	77	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
78	78	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
79	79	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
80	80	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	paid	\N	2026-09-30 21:49:03.962537
81	81	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
82	82	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
83	83	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
84	84	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	paid	\N	2026-09-30 21:49:03.962537
85	85	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
86	86	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
87	87	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
88	88	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	paid	\N	2026-09-30 21:49:03.962537
89	89	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
90	90	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
91	91	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
92	92	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	paid	\N	2026-09-30 21:49:03.962537
93	93	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
94	94	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
95	95	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
96	96	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	paid	\N	2026-09-30 21:49:03.962537
97	97	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
98	98	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
99	99	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
100	100	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	paid	\N	2026-09-30 21:49:03.962537
101	101	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
102	102	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
103	103	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
104	104	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	paid	\N	2026-09-30 21:49:03.962537
105	105	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
106	106	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
107	107	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
108	108	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	paid	\N	2026-09-30 21:49:03.962537
109	109	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
110	110	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
111	111	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
112	112	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	paid	\N	2026-09-30 21:49:03.962537
113	113	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
114	114	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
115	115	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
116	116	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	paid	\N	2026-09-30 21:49:03.962537
117	117	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
118	118	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
119	119	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	pending	\N	2026-09-30 21:49:03.962537
120	120	45000.00	Hostel Fee	2026-10-30 21:49:03.962537	\N	paid	\N	2026-09-30 21:49:03.962537
121	120	12345.00	hihgc	2026-10-16 00:00:00	\N	pending	\N	2026-10-03 00:04:10.360996
123	119	12345.00	ksdwwww	2026-10-14 00:00:00	\N	pending	\N	2026-10-03 00:04:37.595982
124	119	1254525435.00	sjdhfv	2026-10-05 00:00:00	\N	pending	\N	2026-10-03 00:19:26.412722
135	101	12345.00	akdjvc	2026-10-23 00:00:00	\N	pending	\N	2026-10-03 00:24:53.460798
\.


--
-- Data for Name: hostels; Type: TABLE DATA; Schema: public; Owner: sunny
--

COPY public.hostels (hostel_id, hostel_name, hostel_type, address, total_floors, created_at) FROM stdin;
1	SmartStay Block A	boys	Campus North Wing	4	2026-09-30 21:49:03.962537
2	SmartStay Block B	girls	Campus South Wing	4	2026-09-30 21:49:03.962537
3	SmartStay Block C	boys	Campus East Wing	4	2026-09-30 21:49:03.962537
\.


--
-- Data for Name: rooms; Type: TABLE DATA; Schema: public; Owner: sunny
--

COPY public.rooms (room_id, hostel_id, room_number, room_type, capacity, current_occupancy) FROM stdin;
1	1	A101	double	2	2
2	1	A102	triple	3	3
3	1	A201	double	2	2
4	1	A202	four_sharing	4	4
5	1	A301	double	2	2
6	1	A302	triple	3	3
7	2	B101	double	2	2
8	2	B102	triple	3	3
9	2	B201	double	2	2
10	2	B202	four_sharing	4	4
11	2	B301	double	2	2
12	2	B302	triple	3	3
13	3	C101	double	2	2
14	3	C102	triple	3	3
15	3	C201	double	2	2
16	3	C202	four_sharing	4	4
17	3	C301	double	2	2
18	3	C302	triple	3	3
\.


--
-- Data for Name: students; Type: TABLE DATA; Schema: public; Owner: sunny
--

COPY public.students (student_id, user_id, student_number, name, department, year, contact, email, preferences, created_at) FROM stdin;
1	4	STU0001	Aarav Kumar	Computer Science	1	9100000001	student001@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 2}	2026-09-30 21:49:03.962537
2	5	STU0002	Aditya Sharma	Cyber Security	2	9100000002	student002@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 3}	2026-09-30 21:49:03.962537
3	6	STU0003	Arjun Reddy	Information Technology	3	9100000003	student003@smartstay.edu	{"room_type": "triple", "quiet_room": false, "preferred_floor": 4}	2026-09-30 21:49:03.962537
4	7	STU0004	Rahul Rao	Artificial Intelligence	4	9100000004	student004@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 1}	2026-09-30 21:49:03.962537
5	8	STU0005	Rohan Patel	Electronics and Communication	1	9100000005	student005@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 2}	2026-09-30 21:49:03.962537
6	9	STU0006	Karthik Verma	Computer Science	2	9100000006	student006@smartstay.edu	{"room_type": "triple", "quiet_room": true, "preferred_floor": 3}	2026-09-30 21:49:03.962537
7	10	STU0007	Vikram Singh	Cyber Security	3	9100000007	student007@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 4}	2026-09-30 21:49:03.962537
8	11	STU0008	Sai Mehta	Information Technology	4	9100000008	student008@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 1}	2026-09-30 21:49:03.962537
9	12	STU0009	Nikhil Gupta	Artificial Intelligence	1	9100000009	student009@smartstay.edu	{"room_type": "triple", "quiet_room": false, "preferred_floor": 2}	2026-09-30 21:49:03.962537
10	13	STU0010	Varun Naidu	Electronics and Communication	2	9100000010	student010@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 3}	2026-09-30 21:49:03.962537
11	14	STU0011	Akash Yadav	Computer Science	3	9100000011	student011@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 4}	2026-09-30 21:49:03.962537
12	15	STU0012	Manish Iyer	Cyber Security	4	9100000012	student012@smartstay.edu	{"room_type": "triple", "quiet_room": true, "preferred_floor": 1}	2026-09-30 21:49:03.962537
13	16	STU0013	Harsha Kumar	Information Technology	1	9100000013	student013@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 2}	2026-09-30 21:49:03.962537
14	17	STU0014	Tejas Sharma	Artificial Intelligence	2	9100000014	student014@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 3}	2026-09-30 21:49:03.962537
15	18	STU0015	Pranav Reddy	Electronics and Communication	3	9100000015	student015@smartstay.edu	{"room_type": "triple", "quiet_room": false, "preferred_floor": 4}	2026-09-30 21:49:03.962537
16	19	STU0016	Abhinav Rao	Computer Science	4	9100000016	student016@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 1}	2026-09-30 21:49:03.962537
17	20	STU0017	Ravi Patel	Cyber Security	1	9100000017	student017@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 2}	2026-09-30 21:49:03.962537
18	21	STU0018	Sanjay Verma	Information Technology	2	9100000018	student018@smartstay.edu	{"room_type": "triple", "quiet_room": true, "preferred_floor": 3}	2026-09-30 21:49:03.962537
19	22	STU0019	Surya Singh	Artificial Intelligence	3	9100000019	student019@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 4}	2026-09-30 21:49:03.962537
20	23	STU0020	Vivek Mehta	Electronics and Communication	4	9100000020	student020@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 1}	2026-09-30 21:49:03.962537
21	24	STU0021	Aarav Gupta	Computer Science	1	9100000021	student021@smartstay.edu	{"room_type": "triple", "quiet_room": false, "preferred_floor": 2}	2026-09-30 21:49:03.962537
22	25	STU0022	Aditya Naidu	Cyber Security	2	9100000022	student022@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 3}	2026-09-30 21:49:03.962537
23	26	STU0023	Arjun Yadav	Information Technology	3	9100000023	student023@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 4}	2026-09-30 21:49:03.962537
24	27	STU0024	Rahul Iyer	Artificial Intelligence	4	9100000024	student024@smartstay.edu	{"room_type": "triple", "quiet_room": true, "preferred_floor": 1}	2026-09-30 21:49:03.962537
25	28	STU0025	Rohan Kumar	Electronics and Communication	1	9100000025	student025@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 2}	2026-09-30 21:49:03.962537
26	29	STU0026	Karthik Sharma	Computer Science	2	9100000026	student026@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 3}	2026-09-30 21:49:03.962537
27	30	STU0027	Vikram Reddy	Cyber Security	3	9100000027	student027@smartstay.edu	{"room_type": "triple", "quiet_room": false, "preferred_floor": 4}	2026-09-30 21:49:03.962537
28	31	STU0028	Sai Rao	Information Technology	4	9100000028	student028@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 1}	2026-09-30 21:49:03.962537
29	32	STU0029	Nikhil Patel	Artificial Intelligence	1	9100000029	student029@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 2}	2026-09-30 21:49:03.962537
30	33	STU0030	Varun Verma	Electronics and Communication	2	9100000030	student030@smartstay.edu	{"room_type": "triple", "quiet_room": true, "preferred_floor": 3}	2026-09-30 21:49:03.962537
31	34	STU0031	Akash Singh	Computer Science	3	9100000031	student031@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 4}	2026-09-30 21:49:03.962537
32	35	STU0032	Manish Mehta	Cyber Security	4	9100000032	student032@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 1}	2026-09-30 21:49:03.962537
33	36	STU0033	Harsha Gupta	Information Technology	1	9100000033	student033@smartstay.edu	{"room_type": "triple", "quiet_room": false, "preferred_floor": 2}	2026-09-30 21:49:03.962537
34	37	STU0034	Tejas Naidu	Artificial Intelligence	2	9100000034	student034@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 3}	2026-09-30 21:49:03.962537
35	38	STU0035	Pranav Yadav	Electronics and Communication	3	9100000035	student035@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 4}	2026-09-30 21:49:03.962537
36	39	STU0036	Abhinav Iyer	Computer Science	4	9100000036	student036@smartstay.edu	{"room_type": "triple", "quiet_room": true, "preferred_floor": 1}	2026-09-30 21:49:03.962537
37	40	STU0037	Ravi Kumar	Cyber Security	1	9100000037	student037@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 2}	2026-09-30 21:49:03.962537
38	41	STU0038	Sanjay Sharma	Information Technology	2	9100000038	student038@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 3}	2026-09-30 21:49:03.962537
39	42	STU0039	Surya Reddy	Artificial Intelligence	3	9100000039	student039@smartstay.edu	{"room_type": "triple", "quiet_room": false, "preferred_floor": 4}	2026-09-30 21:49:03.962537
40	43	STU0040	Vivek Rao	Electronics and Communication	4	9100000040	student040@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 1}	2026-09-30 21:49:03.962537
41	44	STU0041	Aarav Patel	Computer Science	1	9100000041	student041@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 2}	2026-09-30 21:49:03.962537
42	45	STU0042	Aditya Verma	Cyber Security	2	9100000042	student042@smartstay.edu	{"room_type": "triple", "quiet_room": true, "preferred_floor": 3}	2026-09-30 21:49:03.962537
43	46	STU0043	Arjun Singh	Information Technology	3	9100000043	student043@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 4}	2026-09-30 21:49:03.962537
44	47	STU0044	Rahul Mehta	Artificial Intelligence	4	9100000044	student044@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 1}	2026-09-30 21:49:03.962537
45	48	STU0045	Rohan Gupta	Electronics and Communication	1	9100000045	student045@smartstay.edu	{"room_type": "triple", "quiet_room": false, "preferred_floor": 2}	2026-09-30 21:49:03.962537
46	49	STU0046	Karthik Naidu	Computer Science	2	9100000046	student046@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 3}	2026-09-30 21:49:03.962537
47	50	STU0047	Vikram Yadav	Cyber Security	3	9100000047	student047@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 4}	2026-09-30 21:49:03.962537
48	51	STU0048	Sai Iyer	Information Technology	4	9100000048	student048@smartstay.edu	{"room_type": "triple", "quiet_room": true, "preferred_floor": 1}	2026-09-30 21:49:03.962537
49	52	STU0049	Nikhil Kumar	Artificial Intelligence	1	9100000049	student049@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 2}	2026-09-30 21:49:03.962537
50	53	STU0050	Varun Sharma	Electronics and Communication	2	9100000050	student050@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 3}	2026-09-30 21:49:03.962537
51	54	STU0051	Akash Reddy	Computer Science	3	9100000051	student051@smartstay.edu	{"room_type": "triple", "quiet_room": false, "preferred_floor": 4}	2026-09-30 21:49:03.962537
52	55	STU0052	Manish Rao	Cyber Security	4	9100000052	student052@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 1}	2026-09-30 21:49:03.962537
53	56	STU0053	Harsha Patel	Information Technology	1	9100000053	student053@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 2}	2026-09-30 21:49:03.962537
54	57	STU0054	Tejas Verma	Artificial Intelligence	2	9100000054	student054@smartstay.edu	{"room_type": "triple", "quiet_room": true, "preferred_floor": 3}	2026-09-30 21:49:03.962537
55	58	STU0055	Pranav Singh	Electronics and Communication	3	9100000055	student055@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 4}	2026-09-30 21:49:03.962537
56	59	STU0056	Abhinav Mehta	Computer Science	4	9100000056	student056@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 1}	2026-09-30 21:49:03.962537
57	60	STU0057	Ravi Gupta	Cyber Security	1	9100000057	student057@smartstay.edu	{"room_type": "triple", "quiet_room": false, "preferred_floor": 2}	2026-09-30 21:49:03.962537
58	61	STU0058	Sanjay Naidu	Information Technology	2	9100000058	student058@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 3}	2026-09-30 21:49:03.962537
59	62	STU0059	Surya Yadav	Artificial Intelligence	3	9100000059	student059@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 4}	2026-09-30 21:49:03.962537
60	63	STU0060	Vivek Iyer	Electronics and Communication	4	9100000060	student060@smartstay.edu	{"room_type": "triple", "quiet_room": true, "preferred_floor": 1}	2026-09-30 21:49:03.962537
61	64	STU0061	Aarav Kumar	Computer Science	1	9100000061	student061@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 2}	2026-09-30 21:49:03.962537
62	65	STU0062	Aditya Sharma	Cyber Security	2	9100000062	student062@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 3}	2026-09-30 21:49:03.962537
63	66	STU0063	Arjun Reddy	Information Technology	3	9100000063	student063@smartstay.edu	{"room_type": "triple", "quiet_room": false, "preferred_floor": 4}	2026-09-30 21:49:03.962537
64	67	STU0064	Rahul Rao	Artificial Intelligence	4	9100000064	student064@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 1}	2026-09-30 21:49:03.962537
65	68	STU0065	Rohan Patel	Electronics and Communication	1	9100000065	student065@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 2}	2026-09-30 21:49:03.962537
66	69	STU0066	Karthik Verma	Computer Science	2	9100000066	student066@smartstay.edu	{"room_type": "triple", "quiet_room": true, "preferred_floor": 3}	2026-09-30 21:49:03.962537
67	70	STU0067	Vikram Singh	Cyber Security	3	9100000067	student067@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 4}	2026-09-30 21:49:03.962537
68	71	STU0068	Sai Mehta	Information Technology	4	9100000068	student068@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 1}	2026-09-30 21:49:03.962537
69	72	STU0069	Nikhil Gupta	Artificial Intelligence	1	9100000069	student069@smartstay.edu	{"room_type": "triple", "quiet_room": false, "preferred_floor": 2}	2026-09-30 21:49:03.962537
70	73	STU0070	Varun Naidu	Electronics and Communication	2	9100000070	student070@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 3}	2026-09-30 21:49:03.962537
71	74	STU0071	Akash Yadav	Computer Science	3	9100000071	student071@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 4}	2026-09-30 21:49:03.962537
72	75	STU0072	Manish Iyer	Cyber Security	4	9100000072	student072@smartstay.edu	{"room_type": "triple", "quiet_room": true, "preferred_floor": 1}	2026-09-30 21:49:03.962537
73	76	STU0073	Harsha Kumar	Information Technology	1	9100000073	student073@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 2}	2026-09-30 21:49:03.962537
74	77	STU0074	Tejas Sharma	Artificial Intelligence	2	9100000074	student074@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 3}	2026-09-30 21:49:03.962537
75	78	STU0075	Pranav Reddy	Electronics and Communication	3	9100000075	student075@smartstay.edu	{"room_type": "triple", "quiet_room": false, "preferred_floor": 4}	2026-09-30 21:49:03.962537
76	79	STU0076	Abhinav Rao	Computer Science	4	9100000076	student076@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 1}	2026-09-30 21:49:03.962537
77	80	STU0077	Ravi Patel	Cyber Security	1	9100000077	student077@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 2}	2026-09-30 21:49:03.962537
78	81	STU0078	Sanjay Verma	Information Technology	2	9100000078	student078@smartstay.edu	{"room_type": "triple", "quiet_room": true, "preferred_floor": 3}	2026-09-30 21:49:03.962537
79	82	STU0079	Surya Singh	Artificial Intelligence	3	9100000079	student079@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 4}	2026-09-30 21:49:03.962537
80	83	STU0080	Vivek Mehta	Electronics and Communication	4	9100000080	student080@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 1}	2026-09-30 21:49:03.962537
81	84	STU0081	Aarav Gupta	Computer Science	1	9100000081	student081@smartstay.edu	{"room_type": "triple", "quiet_room": false, "preferred_floor": 2}	2026-09-30 21:49:03.962537
82	85	STU0082	Aditya Naidu	Cyber Security	2	9100000082	student082@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 3}	2026-09-30 21:49:03.962537
83	86	STU0083	Arjun Yadav	Information Technology	3	9100000083	student083@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 4}	2026-09-30 21:49:03.962537
84	87	STU0084	Rahul Iyer	Artificial Intelligence	4	9100000084	student084@smartstay.edu	{"room_type": "triple", "quiet_room": true, "preferred_floor": 1}	2026-09-30 21:49:03.962537
85	88	STU0085	Rohan Kumar	Electronics and Communication	1	9100000085	student085@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 2}	2026-09-30 21:49:03.962537
86	89	STU0086	Karthik Sharma	Computer Science	2	9100000086	student086@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 3}	2026-09-30 21:49:03.962537
87	90	STU0087	Vikram Reddy	Cyber Security	3	9100000087	student087@smartstay.edu	{"room_type": "triple", "quiet_room": false, "preferred_floor": 4}	2026-09-30 21:49:03.962537
88	91	STU0088	Sai Rao	Information Technology	4	9100000088	student088@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 1}	2026-09-30 21:49:03.962537
89	92	STU0089	Nikhil Patel	Artificial Intelligence	1	9100000089	student089@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 2}	2026-09-30 21:49:03.962537
90	93	STU0090	Varun Verma	Electronics and Communication	2	9100000090	student090@smartstay.edu	{"room_type": "triple", "quiet_room": true, "preferred_floor": 3}	2026-09-30 21:49:03.962537
91	94	STU0091	Akash Singh	Computer Science	3	9100000091	student091@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 4}	2026-09-30 21:49:03.962537
92	95	STU0092	Manish Mehta	Cyber Security	4	9100000092	student092@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 1}	2026-09-30 21:49:03.962537
93	96	STU0093	Harsha Gupta	Information Technology	1	9100000093	student093@smartstay.edu	{"room_type": "triple", "quiet_room": false, "preferred_floor": 2}	2026-09-30 21:49:03.962537
94	97	STU0094	Tejas Naidu	Artificial Intelligence	2	9100000094	student094@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 3}	2026-09-30 21:49:03.962537
95	98	STU0095	Pranav Yadav	Electronics and Communication	3	9100000095	student095@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 4}	2026-09-30 21:49:03.962537
96	99	STU0096	Abhinav Iyer	Computer Science	4	9100000096	student096@smartstay.edu	{"room_type": "triple", "quiet_room": true, "preferred_floor": 1}	2026-09-30 21:49:03.962537
97	100	STU0097	Ravi Kumar	Cyber Security	1	9100000097	student097@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 2}	2026-09-30 21:49:03.962537
98	101	STU0098	Sanjay Sharma	Information Technology	2	9100000098	student098@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 3}	2026-09-30 21:49:03.962537
99	102	STU0099	Surya Reddy	Artificial Intelligence	3	9100000099	student099@smartstay.edu	{"room_type": "triple", "quiet_room": false, "preferred_floor": 4}	2026-09-30 21:49:03.962537
100	103	STU0100	Vivek Rao	Electronics and Communication	4	9100000100	student100@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 1}	2026-09-30 21:49:03.962537
101	104	STU0101	Aarav Patel	Computer Science	1	9100000101	student101@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 2}	2026-09-30 21:49:03.962537
102	105	STU0102	Aditya Verma	Cyber Security	2	9100000102	student102@smartstay.edu	{"room_type": "triple", "quiet_room": true, "preferred_floor": 3}	2026-09-30 21:49:03.962537
103	106	STU0103	Arjun Singh	Information Technology	3	9100000103	student103@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 4}	2026-09-30 21:49:03.962537
104	107	STU0104	Rahul Mehta	Artificial Intelligence	4	9100000104	student104@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 1}	2026-09-30 21:49:03.962537
105	108	STU0105	Rohan Gupta	Electronics and Communication	1	9100000105	student105@smartstay.edu	{"room_type": "triple", "quiet_room": false, "preferred_floor": 2}	2026-09-30 21:49:03.962537
106	109	STU0106	Karthik Naidu	Computer Science	2	9100000106	student106@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 3}	2026-09-30 21:49:03.962537
107	110	STU0107	Vikram Yadav	Cyber Security	3	9100000107	student107@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 4}	2026-09-30 21:49:03.962537
108	111	STU0108	Sai Iyer	Information Technology	4	9100000108	student108@smartstay.edu	{"room_type": "triple", "quiet_room": true, "preferred_floor": 1}	2026-09-30 21:49:03.962537
109	112	STU0109	Nikhil Kumar	Artificial Intelligence	1	9100000109	student109@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 2}	2026-09-30 21:49:03.962537
110	113	STU0110	Varun Sharma	Electronics and Communication	2	9100000110	student110@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 3}	2026-09-30 21:49:03.962537
111	114	STU0111	Akash Reddy	Computer Science	3	9100000111	student111@smartstay.edu	{"room_type": "triple", "quiet_room": false, "preferred_floor": 4}	2026-09-30 21:49:03.962537
112	115	STU0112	Manish Rao	Cyber Security	4	9100000112	student112@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 1}	2026-09-30 21:49:03.962537
113	116	STU0113	Harsha Patel	Information Technology	1	9100000113	student113@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 2}	2026-09-30 21:49:03.962537
114	117	STU0114	Tejas Verma	Artificial Intelligence	2	9100000114	student114@smartstay.edu	{"room_type": "triple", "quiet_room": true, "preferred_floor": 3}	2026-09-30 21:49:03.962537
115	118	STU0115	Pranav Singh	Electronics and Communication	3	9100000115	student115@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 4}	2026-09-30 21:49:03.962537
116	119	STU0116	Abhinav Mehta	Computer Science	4	9100000116	student116@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 1}	2026-09-30 21:49:03.962537
117	120	STU0117	Ravi Gupta	Cyber Security	1	9100000117	student117@smartstay.edu	{"room_type": "triple", "quiet_room": false, "preferred_floor": 2}	2026-09-30 21:49:03.962537
118	121	STU0118	Sanjay Naidu	Information Technology	2	9100000118	student118@smartstay.edu	{"room_type": "double", "quiet_room": true, "preferred_floor": 3}	2026-09-30 21:49:03.962537
119	122	STU0119	Surya Yadav	Artificial Intelligence	3	9100000119	student119@smartstay.edu	{"room_type": "double", "quiet_room": false, "preferred_floor": 4}	2026-09-30 21:49:03.962537
120	123	STU0120	Vivek Iyer	Electronics and Communication	4	9100000120	student120@smartstay.edu	{"room_type": "triple", "quiet_room": true, "preferred_floor": 1}	2026-09-30 21:49:03.962537
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: sunny
--

COPY public.users (user_id, username, password_hash, role, created_at, is_active) FROM stdin;
2	warden02	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	warden	2026-09-30 21:49:03.962537	t
5	student002	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
6	student003	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
7	student004	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
8	student005	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
9	student006	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
10	student007	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
11	student008	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
12	student009	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
13	student010	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
14	student011	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
15	student012	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
16	student013	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
17	student014	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
18	student015	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
19	student016	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
20	student017	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
21	student018	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
22	student019	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
23	student020	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
24	student021	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
25	student022	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
26	student023	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
27	student024	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
28	student025	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
29	student026	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
30	student027	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
31	student028	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
32	student029	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
33	student030	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
34	student031	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
35	student032	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
36	student033	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
37	student034	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
38	student035	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
39	student036	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
40	student037	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
41	student038	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
42	student039	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
43	student040	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
44	student041	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
45	student042	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
46	student043	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
47	student044	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
48	student045	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
49	student046	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
50	student047	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
51	student048	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
52	student049	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
53	student050	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
54	student051	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
55	student052	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
56	student053	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
57	student054	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
58	student055	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
59	student056	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
60	student057	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
61	student058	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
62	student059	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
63	student060	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
64	student061	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
65	student062	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
1	warden01	$2b$12$a.fmS.A/VuvMoJXqtHaxaOsD8SfO8ZZkzzcB/zGHOHGmUNVbrLACq	warden	2026-09-30 21:49:03.962537	t
4	student001	$2b$12$4sCb0wY7IG65FiiWmsTtjuVOrdbl.lF9Xbkpo1zW0LryZNXN3oc8a	student	2026-09-30 21:49:03.962537	t
66	student063	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
67	student064	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
68	student065	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
69	student066	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
70	student067	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
71	student068	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
72	student069	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
73	student070	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
74	student071	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
75	student072	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
76	student073	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
77	student074	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
78	student075	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
79	student076	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
80	student077	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
81	student078	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
82	student079	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
83	student080	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
84	student081	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
85	student082	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
86	student083	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
87	student084	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
88	student085	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
89	student086	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
90	student087	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
91	student088	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
92	student089	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
93	student090	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
94	student091	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
95	student092	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
96	student093	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
97	student094	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
98	student095	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
99	student096	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
100	student097	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
101	student098	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
102	student099	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
103	student100	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
104	student101	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
105	student102	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
106	student103	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
107	student104	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
108	student105	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
109	student106	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
110	student107	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
111	student108	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
112	student109	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
113	student110	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
114	student111	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
115	student112	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
116	student113	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
117	student114	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
118	student115	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
119	student116	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
120	student117	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
121	student118	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
122	student119	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
123	student120	$2b$10$dBwvKuZFjBgvpq9uz81B4Otv7JYetIFU/X8yqPeMvS4PNgUUN2JJi	student	2026-09-30 21:49:03.962537	t
3	university	$2b$12$/6NBGdALbc21qb5Ew48Fv.nmJv.hGOSt3HxiHq/jDDp2aeXvpi8mW	university	2026-09-30 21:49:03.962537	t
\.


--
-- Data for Name: visitors; Type: TABLE DATA; Schema: public; Owner: sunny
--

COPY public.visitors (visitor_id, student_id, visitor_name, visitor_phone, relationship, purpose, entry_time, exit_time) FROM stdin;
1	1	Visitor 1	9988771000	Father	Student visit	2026-09-30 19:49:03.962537	\N
2	2	Visitor 2	9988771001	Mother	Student visit	2026-09-30 19:49:03.962537	2026-09-30 21:49:04.089
3	3	Visitor 3	9988771002	Father	Student visit	2026-09-30 19:49:03.962537	2026-09-30 21:49:04.089
4	4	Visitor 4	9988771003	Mother	Student visit	2026-09-30 19:49:03.962537	\N
5	5	Visitor 5	9988771004	Father	Student visit	2026-09-30 19:49:03.962537	2026-09-30 21:49:04.089
6	6	Visitor 6	9988771005	Mother	Student visit	2026-09-30 19:49:03.962537	2026-09-30 21:49:04.089
7	7	Visitor 7	9988771006	Father	Student visit	2026-09-30 19:49:03.962537	\N
8	8	Visitor 8	9988771007	Mother	Student visit	2026-09-30 19:49:03.962537	2026-09-30 21:49:04.09
9	9	Visitor 9	9988771008	Father	Student visit	2026-09-30 19:49:03.962537	2026-09-30 21:49:04.09
10	10	Visitor 10	9988771009	Mother	Student visit	2026-09-30 19:49:03.962537	\N
11	11	Visitor 11	9988771010	Father	Student visit	2026-09-30 19:49:03.962537	2026-09-30 21:49:04.09
12	12	Visitor 12	9988771011	Mother	Student visit	2026-09-30 19:49:03.962537	2026-09-30 21:49:04.09
13	13	Visitor 13	9988771012	Father	Student visit	2026-09-30 19:49:03.962537	\N
14	14	Visitor 14	9988771013	Mother	Student visit	2026-09-30 19:49:03.962537	2026-09-30 21:49:04.09
15	15	Visitor 15	9988771014	Father	Student visit	2026-09-30 19:49:03.962537	2026-09-30 21:49:04.09
16	1	hjsfvb	\N	\N	w,jhvrcj	2026-10-02 22:24:10.639561	\N
17	1	manoj	\N	\N	friend	2026-10-02 23:33:19.809899	\N
\.


--
-- Data for Name: allocations; Type: TABLE DATA; Schema: smartstay; Owner: sunny
--

COPY smartstay.allocations (id, student_id, room_id, check_in, check_out, created_at) FROM stdin;
1	1	1	2026-08-06	\N	2026-09-30 21:35:21.017498+05:30
2	2	1	2026-08-05	\N	2026-09-30 21:35:21.017498+05:30
3	3	1	2026-08-04	\N	2026-09-30 21:35:21.017498+05:30
4	4	1	2026-08-03	\N	2026-09-30 21:35:21.017498+05:30
5	5	2	2026-08-02	\N	2026-09-30 21:35:21.017498+05:30
6	6	2	2026-08-01	\N	2026-09-30 21:35:21.017498+05:30
7	7	2	2026-07-31	\N	2026-09-30 21:35:21.017498+05:30
8	8	2	2026-07-30	\N	2026-09-30 21:35:21.017498+05:30
9	9	3	2026-07-29	\N	2026-09-30 21:35:21.017498+05:30
10	10	3	2026-07-28	\N	2026-09-30 21:35:21.017498+05:30
11	11	3	2026-07-27	\N	2026-09-30 21:35:21.017498+05:30
12	12	3	2026-07-26	\N	2026-09-30 21:35:21.017498+05:30
13	13	4	2026-07-25	\N	2026-09-30 21:35:21.017498+05:30
14	14	4	2026-07-24	\N	2026-09-30 21:35:21.017498+05:30
15	15	4	2026-07-23	\N	2026-09-30 21:35:21.017498+05:30
16	16	4	2026-07-22	\N	2026-09-30 21:35:21.017498+05:30
17	17	5	2026-07-21	\N	2026-09-30 21:35:21.017498+05:30
18	18	5	2026-07-20	\N	2026-09-30 21:35:21.017498+05:30
19	19	5	2026-07-19	\N	2026-09-30 21:35:21.017498+05:30
20	20	5	2026-07-18	\N	2026-09-30 21:35:21.017498+05:30
21	21	6	2026-07-17	\N	2026-09-30 21:35:21.017498+05:30
22	22	6	2026-08-06	\N	2026-09-30 21:35:21.017498+05:30
23	23	6	2026-08-05	\N	2026-09-30 21:35:21.017498+05:30
24	24	6	2026-08-04	\N	2026-09-30 21:35:21.017498+05:30
25	25	7	2026-08-03	\N	2026-09-30 21:35:21.017498+05:30
26	26	7	2026-08-02	\N	2026-09-30 21:35:21.017498+05:30
27	27	7	2026-08-01	\N	2026-09-30 21:35:21.017498+05:30
28	28	7	2026-07-31	\N	2026-09-30 21:35:21.017498+05:30
29	29	8	2026-07-30	\N	2026-09-30 21:35:21.017498+05:30
30	30	8	2026-07-29	\N	2026-09-30 21:35:21.017498+05:30
31	31	8	2026-07-28	\N	2026-09-30 21:35:21.017498+05:30
32	32	8	2026-07-27	\N	2026-09-30 21:35:21.017498+05:30
33	33	9	2026-07-26	\N	2026-09-30 21:35:21.017498+05:30
34	34	9	2026-07-25	\N	2026-09-30 21:35:21.017498+05:30
35	35	9	2026-07-24	\N	2026-09-30 21:35:21.017498+05:30
36	36	9	2026-07-23	\N	2026-09-30 21:35:21.017498+05:30
37	37	10	2026-07-22	\N	2026-09-30 21:35:21.017498+05:30
38	38	10	2026-07-21	\N	2026-09-30 21:35:21.017498+05:30
39	39	10	2026-07-20	\N	2026-09-30 21:35:21.017498+05:30
40	40	10	2026-07-19	\N	2026-09-30 21:35:21.017498+05:30
41	41	11	2026-07-18	\N	2026-09-30 21:35:21.017498+05:30
42	42	11	2026-07-17	\N	2026-09-30 21:35:21.017498+05:30
43	43	11	2026-08-06	\N	2026-09-30 21:35:21.017498+05:30
44	44	11	2026-08-05	\N	2026-09-30 21:35:21.017498+05:30
45	45	12	2026-08-04	\N	2026-09-30 21:35:21.017498+05:30
46	46	12	2026-08-03	\N	2026-09-30 21:35:21.017498+05:30
47	47	12	2026-08-02	\N	2026-09-30 21:35:21.017498+05:30
48	48	12	2026-08-01	\N	2026-09-30 21:35:21.017498+05:30
49	49	13	2026-07-31	\N	2026-09-30 21:35:21.017498+05:30
50	50	13	2026-07-30	\N	2026-09-30 21:35:21.017498+05:30
51	51	13	2026-07-29	\N	2026-09-30 21:35:21.017498+05:30
52	52	13	2026-07-28	\N	2026-09-30 21:35:21.017498+05:30
53	53	14	2026-07-27	\N	2026-09-30 21:35:21.017498+05:30
54	54	14	2026-07-26	\N	2026-09-30 21:35:21.017498+05:30
55	55	14	2026-07-25	\N	2026-09-30 21:35:21.017498+05:30
56	56	14	2026-07-24	\N	2026-09-30 21:35:21.017498+05:30
57	57	15	2026-07-23	\N	2026-09-30 21:35:21.017498+05:30
58	58	15	2026-07-22	\N	2026-09-30 21:35:21.017498+05:30
59	59	15	2026-07-21	\N	2026-09-30 21:35:21.017498+05:30
60	60	15	2026-07-20	\N	2026-09-30 21:35:21.017498+05:30
61	61	16	2026-07-19	\N	2026-09-30 21:35:21.017498+05:30
62	62	16	2026-07-18	\N	2026-09-30 21:35:21.017498+05:30
63	63	16	2026-07-17	\N	2026-09-30 21:35:21.017498+05:30
64	64	16	2026-08-06	\N	2026-09-30 21:35:21.017498+05:30
65	65	17	2026-08-05	\N	2026-09-30 21:35:21.017498+05:30
66	66	17	2026-08-04	\N	2026-09-30 21:35:21.017498+05:30
67	67	17	2026-08-03	\N	2026-09-30 21:35:21.017498+05:30
68	68	17	2026-08-02	\N	2026-09-30 21:35:21.017498+05:30
69	69	18	2026-08-01	\N	2026-09-30 21:35:21.017498+05:30
70	70	18	2026-07-31	\N	2026-09-30 21:35:21.017498+05:30
71	71	18	2026-07-30	\N	2026-09-30 21:35:21.017498+05:30
72	72	18	2026-07-29	\N	2026-09-30 21:35:21.017498+05:30
73	73	19	2026-07-28	\N	2026-09-30 21:35:21.017498+05:30
74	74	19	2026-07-27	\N	2026-09-30 21:35:21.017498+05:30
75	75	19	2026-07-26	\N	2026-09-30 21:35:21.017498+05:30
76	76	19	2026-07-25	\N	2026-09-30 21:35:21.017498+05:30
77	77	20	2026-07-24	\N	2026-09-30 21:35:21.017498+05:30
78	78	20	2026-07-23	\N	2026-09-30 21:35:21.017498+05:30
79	79	20	2026-07-22	\N	2026-09-30 21:35:21.017498+05:30
80	80	20	2026-07-21	\N	2026-09-30 21:35:21.017498+05:30
81	81	21	2026-07-20	\N	2026-09-30 21:35:21.017498+05:30
82	82	21	2026-07-19	\N	2026-09-30 21:35:21.017498+05:30
83	83	21	2026-07-18	\N	2026-09-30 21:35:21.017498+05:30
84	84	21	2026-07-17	\N	2026-09-30 21:35:21.017498+05:30
85	85	22	2026-08-06	\N	2026-09-30 21:35:21.017498+05:30
86	86	22	2026-08-05	\N	2026-09-30 21:35:21.017498+05:30
87	87	22	2026-08-04	\N	2026-09-30 21:35:21.017498+05:30
88	88	22	2026-08-03	\N	2026-09-30 21:35:21.017498+05:30
89	89	23	2026-08-02	\N	2026-09-30 21:35:21.017498+05:30
90	90	23	2026-08-01	\N	2026-09-30 21:35:21.017498+05:30
91	91	23	2026-07-31	\N	2026-09-30 21:35:21.017498+05:30
92	92	23	2026-07-30	\N	2026-09-30 21:35:21.017498+05:30
93	93	24	2026-07-29	\N	2026-09-30 21:35:21.017498+05:30
94	94	24	2026-07-28	\N	2026-09-30 21:35:21.017498+05:30
95	95	24	2026-07-27	\N	2026-09-30 21:35:21.017498+05:30
96	96	24	2026-07-26	\N	2026-09-30 21:35:21.017498+05:30
97	97	25	2026-07-25	\N	2026-09-30 21:35:21.017498+05:30
98	98	25	2026-07-24	\N	2026-09-30 21:35:21.017498+05:30
99	99	25	2026-07-23	\N	2026-09-30 21:35:21.017498+05:30
100	100	25	2026-07-22	\N	2026-09-30 21:35:21.017498+05:30
101	101	26	2026-07-21	\N	2026-09-30 21:35:21.017498+05:30
102	102	26	2026-07-20	\N	2026-09-30 21:35:21.017498+05:30
103	103	26	2026-07-19	\N	2026-09-30 21:35:21.017498+05:30
104	104	26	2026-07-18	\N	2026-09-30 21:35:21.017498+05:30
\.


--
-- Data for Name: attendance; Type: TABLE DATA; Schema: smartstay; Owner: sunny
--

COPY smartstay.attendance (id, student_id, attendance_date, status, marked_by, created_at) FROM stdin;
1	1	2026-09-30	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
2	1	2026-09-29	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
3	1	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
4	1	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
5	1	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
6	1	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
7	1	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
8	1	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
9	1	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
10	1	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
11	1	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
12	1	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
13	1	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
14	1	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
15	1	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
16	1	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
17	1	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
18	1	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
19	1	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
20	1	2026-09-11	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
21	1	2026-09-10	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
22	1	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
23	1	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
24	1	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
25	1	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
26	1	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
27	1	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
28	1	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
29	1	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
30	1	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
31	2	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
32	2	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
33	2	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
34	2	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
35	2	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
36	2	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
37	2	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
38	2	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
39	2	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
40	2	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
41	2	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
42	2	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
43	2	2026-09-18	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
44	2	2026-09-17	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
45	2	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
46	2	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
47	2	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
48	2	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
49	2	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
50	2	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
51	2	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
52	2	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
53	2	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
54	2	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
55	2	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
56	2	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
57	2	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
58	2	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
59	2	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
60	2	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
61	3	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
62	3	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
63	3	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
64	3	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
65	3	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
66	3	2026-09-25	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
67	3	2026-09-24	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
68	3	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
69	3	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
70	3	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
71	3	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
72	3	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
73	3	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
74	3	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
75	3	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
76	3	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
77	3	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
78	3	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
79	3	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
80	3	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
81	3	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
82	3	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
83	3	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
84	3	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
85	3	2026-09-06	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
86	3	2026-09-05	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
87	3	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
88	3	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
89	3	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
90	3	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
91	4	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
92	4	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
93	4	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
94	4	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
95	4	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
96	4	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
97	4	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
98	4	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
99	4	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
100	4	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
101	4	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
102	4	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
103	4	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
104	4	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
105	4	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
106	4	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
107	4	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
108	4	2026-09-13	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
109	4	2026-09-12	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
110	4	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
111	4	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
112	4	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
113	4	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
114	4	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
115	4	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
116	4	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
117	4	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
118	4	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
119	4	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
120	4	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
121	5	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
122	5	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
123	5	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
124	5	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
125	5	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
126	5	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
127	5	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
128	5	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
129	5	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
130	5	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
131	5	2026-09-20	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
132	5	2026-09-19	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
133	5	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
134	5	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
135	5	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
136	5	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
137	5	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
138	5	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
139	5	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
140	5	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
141	5	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
142	5	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
143	5	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
144	5	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
145	5	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
146	5	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
147	5	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
148	5	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
149	5	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
150	5	2026-09-01	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
151	6	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
152	6	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
153	6	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
154	6	2026-09-27	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
155	6	2026-09-26	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
156	6	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
157	6	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
158	6	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
159	6	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
160	6	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
161	6	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
162	6	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
163	6	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
164	6	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
165	6	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
166	6	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
167	6	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
168	6	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
169	6	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
170	6	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
171	6	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
172	6	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
173	6	2026-09-08	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
174	6	2026-09-07	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
175	6	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
176	6	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
177	6	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
178	6	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
179	6	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
180	6	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
181	7	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
182	7	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
183	7	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
184	7	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
185	7	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
186	7	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
187	7	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
188	7	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
189	7	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
190	7	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
191	7	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
192	7	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
193	7	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
194	7	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
195	7	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
196	7	2026-09-15	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
197	7	2026-09-14	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
198	7	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
199	7	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
200	7	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
201	7	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
202	7	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
203	7	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
204	7	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
205	7	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
206	7	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
207	7	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
208	7	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
209	7	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
210	7	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
211	8	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
212	8	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
213	8	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
214	8	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
215	8	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
216	8	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
217	8	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
218	8	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
219	8	2026-09-22	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
220	8	2026-09-21	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
221	8	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
222	8	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
223	8	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
224	8	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
225	8	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
226	8	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
227	8	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
228	8	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
229	8	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
230	8	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
231	8	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
232	8	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
233	8	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
234	8	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
235	8	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
236	8	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
237	8	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
238	8	2026-09-03	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
239	8	2026-09-02	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
240	8	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
241	9	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
242	9	2026-09-29	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
243	9	2026-09-28	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
244	9	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
245	9	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
246	9	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
247	9	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
248	9	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
249	9	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
250	9	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
251	9	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
252	9	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
253	9	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
254	9	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
255	9	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
256	9	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
257	9	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
258	9	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
259	9	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
260	9	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
261	9	2026-09-10	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
262	9	2026-09-09	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
263	9	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
264	9	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
265	9	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
266	9	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
267	9	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
268	9	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
269	9	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
270	9	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
271	10	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
272	10	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
273	10	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
274	10	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
275	10	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
276	10	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
277	10	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
278	10	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
279	10	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
280	10	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
281	10	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
282	10	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
283	10	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
284	10	2026-09-17	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
285	10	2026-09-16	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
286	10	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
287	10	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
288	10	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
289	10	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
290	10	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
291	10	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
292	10	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
293	10	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
294	10	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
295	10	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
296	10	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
297	10	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
298	10	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
299	10	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
300	10	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
301	11	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
302	11	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
303	11	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
304	11	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
305	11	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
306	11	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
307	11	2026-09-24	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
308	11	2026-09-23	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
309	11	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
310	11	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
311	11	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
312	11	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
313	11	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
314	11	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
315	11	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
316	11	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
317	11	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
318	11	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
319	11	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
320	11	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
321	11	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
322	11	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
323	11	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
324	11	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
325	11	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
326	11	2026-09-05	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
327	11	2026-09-04	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
328	11	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
329	11	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
330	11	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
331	12	2026-09-30	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
332	12	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
333	12	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
334	12	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
335	12	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
336	12	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
337	12	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
338	12	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
339	12	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
340	12	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
341	12	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
342	12	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
343	12	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
344	12	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
345	12	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
346	12	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
347	12	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
348	12	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
349	12	2026-09-12	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
350	12	2026-09-11	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
351	12	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
352	12	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
353	12	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
354	12	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
355	12	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
356	12	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
357	12	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
358	12	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
359	12	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
360	12	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
361	13	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
362	13	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
363	13	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
364	13	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
365	13	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
366	13	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
367	13	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
368	13	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
369	13	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
370	13	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
371	13	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
372	13	2026-09-19	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
373	13	2026-09-18	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
374	13	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
375	13	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
376	13	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
377	13	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
378	13	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
379	13	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
380	13	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
381	13	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
382	13	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
383	13	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
384	13	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
385	13	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
386	13	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
387	13	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
388	13	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
389	13	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
390	13	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
391	14	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
392	14	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
393	14	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
394	14	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
395	14	2026-09-26	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
396	14	2026-09-25	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
397	14	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
398	14	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
399	14	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
400	14	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
401	14	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
402	14	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
403	14	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
404	14	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
405	14	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
406	14	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
407	14	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
408	14	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
409	14	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
410	14	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
411	14	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
412	14	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
413	14	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
414	14	2026-09-07	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
415	14	2026-09-06	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
416	14	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
417	14	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
418	14	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
419	14	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
420	14	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
421	15	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
422	15	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
423	15	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
424	15	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
425	15	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
426	15	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
427	15	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
428	15	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
429	15	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
430	15	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
431	15	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
432	15	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
433	15	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
434	15	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
435	15	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
436	15	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
437	15	2026-09-14	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
438	15	2026-09-13	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
439	15	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
440	15	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
441	15	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
442	15	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
443	15	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
444	15	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
445	15	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
446	15	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
447	15	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
448	15	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
449	15	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
450	15	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
451	16	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
452	16	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
453	16	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
454	16	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
455	16	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
456	16	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
457	16	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
458	16	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
459	16	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
460	16	2026-09-21	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
461	16	2026-09-20	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
462	16	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
463	16	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
464	16	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
465	16	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
466	16	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
467	16	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
468	16	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
469	16	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
470	16	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
471	16	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
472	16	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
473	16	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
474	16	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
475	16	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
476	16	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
477	16	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
478	16	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
479	16	2026-09-02	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
480	16	2026-09-01	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
481	17	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
482	17	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
483	17	2026-09-28	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
484	17	2026-09-27	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
485	17	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
486	17	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
487	17	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
488	17	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
489	17	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
490	17	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
491	17	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
492	17	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
493	17	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
494	17	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
495	17	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
496	17	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
497	17	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
498	17	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
499	17	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
500	17	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
501	17	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
502	17	2026-09-09	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
503	17	2026-09-08	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
504	17	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
505	17	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
506	17	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
507	17	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
508	17	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
509	17	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
510	17	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
511	18	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
512	18	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
513	18	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
514	18	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
515	18	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
516	18	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
517	18	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
518	18	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
519	18	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
520	18	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
521	18	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
522	18	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
523	18	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
524	18	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
525	18	2026-09-16	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
526	18	2026-09-15	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
527	18	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
528	18	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
529	18	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
530	18	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
531	18	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
532	18	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
533	18	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
534	18	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
535	18	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
536	18	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
537	18	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
538	18	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
539	18	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
540	18	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
541	19	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
542	19	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
543	19	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
544	19	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
545	19	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
546	19	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
547	19	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
548	19	2026-09-23	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
549	19	2026-09-22	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
550	19	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
551	19	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
552	19	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
553	19	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
554	19	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
555	19	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
556	19	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
557	19	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
558	19	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
559	19	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
560	19	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
561	19	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
562	19	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
563	19	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
564	19	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
565	19	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
566	19	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
567	19	2026-09-04	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
568	19	2026-09-03	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
569	19	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
570	19	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
571	20	2026-09-30	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
572	20	2026-09-29	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
573	20	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
574	20	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
575	20	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
576	20	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
577	20	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
578	20	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
579	20	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
580	20	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
581	20	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
582	20	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
583	20	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
584	20	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
585	20	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
586	20	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
587	20	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
588	20	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
589	20	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
590	20	2026-09-11	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
591	20	2026-09-10	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
592	20	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
593	20	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
594	20	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
595	20	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
596	20	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
597	20	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
598	20	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
599	20	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
600	20	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
601	21	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
602	21	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
603	21	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
604	21	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
605	21	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
606	21	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
607	21	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
608	21	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
609	21	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
610	21	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
611	21	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
612	21	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
613	21	2026-09-18	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
614	21	2026-09-17	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
615	21	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
616	21	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
617	21	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
618	21	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
619	21	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
620	21	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
621	21	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
622	21	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
623	21	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
624	21	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
625	21	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
626	21	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
627	21	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
628	21	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
629	21	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
630	21	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
631	22	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
632	22	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
633	22	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
634	22	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
635	22	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
636	22	2026-09-25	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
637	22	2026-09-24	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
638	22	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
639	22	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
640	22	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
641	22	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
642	22	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
643	22	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
644	22	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
645	22	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
646	22	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
647	22	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
648	22	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
649	22	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
650	22	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
651	22	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
652	22	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
653	22	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
654	22	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
655	22	2026-09-06	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
656	22	2026-09-05	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
657	22	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
658	22	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
659	22	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
660	22	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
661	23	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
662	23	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
663	23	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
664	23	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
665	23	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
666	23	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
667	23	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
668	23	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
669	23	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
670	23	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
671	23	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
672	23	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
673	23	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
674	23	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
675	23	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
676	23	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
677	23	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
678	23	2026-09-13	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
679	23	2026-09-12	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
680	23	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
681	23	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
682	23	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
683	23	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
684	23	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
685	23	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
686	23	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
687	23	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
688	23	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
689	23	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
690	23	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
691	24	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
692	24	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
693	24	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
694	24	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
695	24	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
696	24	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
697	24	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
698	24	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
699	24	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
700	24	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
701	24	2026-09-20	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
702	24	2026-09-19	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
703	24	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
704	24	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
705	24	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
706	24	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
707	24	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
708	24	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
709	24	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
710	24	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
711	24	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
712	24	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
713	24	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
714	24	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
715	24	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
716	24	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
717	24	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
718	24	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
719	24	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
720	24	2026-09-01	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
721	25	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
722	25	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
723	25	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
724	25	2026-09-27	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
725	25	2026-09-26	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
726	25	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
727	25	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
728	25	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
729	25	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
730	25	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
731	25	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
732	25	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
733	25	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
734	25	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
735	25	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
736	25	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
737	25	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
738	25	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
739	25	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
740	25	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
741	25	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
742	25	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
743	25	2026-09-08	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
744	25	2026-09-07	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
745	25	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
746	25	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
747	25	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
748	25	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
749	25	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
750	25	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
751	26	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
752	26	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
753	26	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
754	26	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
755	26	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
756	26	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
757	26	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
758	26	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
759	26	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
760	26	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
761	26	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
762	26	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
763	26	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
764	26	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
765	26	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
766	26	2026-09-15	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
767	26	2026-09-14	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
768	26	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
769	26	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
770	26	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
771	26	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
772	26	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
773	26	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
774	26	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
775	26	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
776	26	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
777	26	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
778	26	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
779	26	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
780	26	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
781	27	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
782	27	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
783	27	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
784	27	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
785	27	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
786	27	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
787	27	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
788	27	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
789	27	2026-09-22	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
790	27	2026-09-21	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
791	27	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
792	27	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
793	27	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
794	27	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
795	27	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
796	27	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
797	27	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
798	27	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
799	27	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
800	27	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
801	27	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
802	27	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
803	27	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
804	27	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
805	27	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
806	27	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
807	27	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
808	27	2026-09-03	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
809	27	2026-09-02	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
810	27	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
811	28	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
812	28	2026-09-29	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
813	28	2026-09-28	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
814	28	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
815	28	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
816	28	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
817	28	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
818	28	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
819	28	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
820	28	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
821	28	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
822	28	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
823	28	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
824	28	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
825	28	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
826	28	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
827	28	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
828	28	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
829	28	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
830	28	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
831	28	2026-09-10	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
832	28	2026-09-09	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
833	28	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
834	28	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
835	28	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
836	28	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
837	28	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
838	28	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
839	28	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
840	28	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
841	29	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
842	29	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
843	29	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
844	29	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
845	29	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
846	29	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
847	29	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
848	29	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
849	29	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
850	29	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
851	29	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
852	29	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
853	29	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
854	29	2026-09-17	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
855	29	2026-09-16	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
856	29	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
857	29	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
858	29	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
859	29	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
860	29	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
861	29	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
862	29	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
863	29	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
864	29	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
865	29	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
866	29	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
867	29	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
868	29	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
869	29	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
870	29	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
871	30	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
872	30	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
873	30	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
874	30	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
875	30	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
876	30	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
877	30	2026-09-24	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
878	30	2026-09-23	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
879	30	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
880	30	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
881	30	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
882	30	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
883	30	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
884	30	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
885	30	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
886	30	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
887	30	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
888	30	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
889	30	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
890	30	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
891	30	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
892	30	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
893	30	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
894	30	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
895	30	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
896	30	2026-09-05	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
897	30	2026-09-04	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
898	30	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
899	30	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
900	30	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
901	31	2026-09-30	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
902	31	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
903	31	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
904	31	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
905	31	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
906	31	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
907	31	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
908	31	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
909	31	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
910	31	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
911	31	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
912	31	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
913	31	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
914	31	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
915	31	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
916	31	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
917	31	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
918	31	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
919	31	2026-09-12	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
920	31	2026-09-11	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
921	31	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
922	31	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
923	31	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
924	31	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
925	31	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
926	31	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
927	31	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
928	31	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
929	31	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
930	31	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
931	32	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
932	32	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
933	32	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
934	32	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
935	32	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
936	32	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
937	32	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
938	32	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
939	32	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
940	32	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
941	32	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
942	32	2026-09-19	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
943	32	2026-09-18	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
944	32	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
945	32	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
946	32	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
947	32	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
948	32	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
949	32	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
950	32	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
951	32	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
952	32	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
953	32	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
954	32	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
955	32	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
956	32	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
957	32	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
958	32	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
959	32	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
960	32	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
961	33	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
962	33	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
963	33	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
964	33	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
965	33	2026-09-26	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
966	33	2026-09-25	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
967	33	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
968	33	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
969	33	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
970	33	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
971	33	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
972	33	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
973	33	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
974	33	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
975	33	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
976	33	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
977	33	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
978	33	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
979	33	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
980	33	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
981	33	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
982	33	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
983	33	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
984	33	2026-09-07	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
985	33	2026-09-06	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
986	33	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
987	33	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
988	33	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
989	33	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
990	33	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
991	34	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
992	34	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
993	34	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
994	34	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
995	34	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
996	34	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
997	34	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
998	34	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
999	34	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1000	34	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1001	34	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1002	34	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1003	34	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1004	34	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1005	34	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1006	34	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1007	34	2026-09-14	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1008	34	2026-09-13	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1009	34	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1010	34	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1011	34	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1012	34	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1013	34	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1014	34	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1015	34	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1016	34	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1017	34	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1018	34	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1019	34	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1020	34	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1021	35	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1022	35	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1023	35	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1024	35	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1025	35	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1026	35	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1027	35	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1028	35	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1029	35	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1030	35	2026-09-21	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1031	35	2026-09-20	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1032	35	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1033	35	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1034	35	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1035	35	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1036	35	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1037	35	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1038	35	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1039	35	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1040	35	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1041	35	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1042	35	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1043	35	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1044	35	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1045	35	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1046	35	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1047	35	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1048	35	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1049	35	2026-09-02	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1050	35	2026-09-01	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1051	36	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1052	36	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1053	36	2026-09-28	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1054	36	2026-09-27	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1055	36	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1056	36	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1057	36	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1058	36	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1059	36	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1060	36	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1061	36	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1062	36	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1063	36	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1064	36	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1065	36	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1066	36	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1067	36	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1068	36	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1069	36	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1070	36	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1071	36	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1072	36	2026-09-09	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1073	36	2026-09-08	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1074	36	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1075	36	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1076	36	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1077	36	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1078	36	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1079	36	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1080	36	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1081	37	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1082	37	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1083	37	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1084	37	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1085	37	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1086	37	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1087	37	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1088	37	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1089	37	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1090	37	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1091	37	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1092	37	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1093	37	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1094	37	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1095	37	2026-09-16	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1096	37	2026-09-15	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1097	37	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1098	37	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1099	37	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1100	37	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1101	37	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1102	37	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1103	37	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1104	37	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1105	37	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1106	37	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1107	37	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1108	37	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1109	37	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1110	37	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1111	38	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1112	38	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1113	38	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1114	38	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1115	38	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1116	38	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1117	38	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1118	38	2026-09-23	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1119	38	2026-09-22	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1120	38	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1121	38	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1122	38	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1123	38	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1124	38	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1125	38	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1126	38	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1127	38	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1128	38	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1129	38	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1130	38	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1131	38	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1132	38	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1133	38	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1134	38	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1135	38	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1136	38	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1137	38	2026-09-04	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1138	38	2026-09-03	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1139	38	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1140	38	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1141	39	2026-09-30	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1142	39	2026-09-29	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1143	39	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1144	39	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1145	39	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1146	39	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1147	39	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1148	39	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1149	39	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1150	39	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1151	39	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1152	39	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1153	39	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1154	39	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1155	39	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1156	39	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1157	39	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1158	39	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1159	39	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1160	39	2026-09-11	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1161	39	2026-09-10	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1162	39	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1163	39	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1164	39	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1165	39	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1166	39	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1167	39	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1168	39	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1169	39	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1170	39	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1171	40	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1172	40	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1173	40	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1174	40	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1175	40	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1176	40	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1177	40	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1178	40	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1179	40	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1180	40	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1181	40	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1182	40	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1183	40	2026-09-18	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1184	40	2026-09-17	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1185	40	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1186	40	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1187	40	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1188	40	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1189	40	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1190	40	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1191	40	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1192	40	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1193	40	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1194	40	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1195	40	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1196	40	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1197	40	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1198	40	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1199	40	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1200	40	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1201	41	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1202	41	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1203	41	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1204	41	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1205	41	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1206	41	2026-09-25	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1207	41	2026-09-24	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1208	41	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1209	41	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1210	41	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1211	41	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1212	41	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1213	41	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1214	41	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1215	41	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1216	41	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1217	41	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1218	41	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1219	41	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1220	41	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1221	41	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1222	41	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1223	41	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1224	41	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1225	41	2026-09-06	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1226	41	2026-09-05	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1227	41	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1228	41	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1229	41	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1230	41	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1231	42	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1232	42	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1233	42	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1234	42	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1235	42	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1236	42	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1237	42	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1238	42	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1239	42	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1240	42	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1241	42	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1242	42	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1243	42	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1244	42	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1245	42	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1246	42	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1247	42	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1248	42	2026-09-13	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1249	42	2026-09-12	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1250	42	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1251	42	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1252	42	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1253	42	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1254	42	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1255	42	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1256	42	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1257	42	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1258	42	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1259	42	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1260	42	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1261	43	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1262	43	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1263	43	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1264	43	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1265	43	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1266	43	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1267	43	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1268	43	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1269	43	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1270	43	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1271	43	2026-09-20	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1272	43	2026-09-19	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1273	43	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1274	43	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1275	43	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1276	43	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1277	43	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1278	43	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1279	43	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1280	43	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1281	43	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1282	43	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1283	43	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1284	43	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1285	43	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1286	43	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1287	43	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1288	43	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1289	43	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1290	43	2026-09-01	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1291	44	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1292	44	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1293	44	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1294	44	2026-09-27	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1295	44	2026-09-26	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1296	44	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1297	44	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1298	44	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1299	44	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1300	44	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1301	44	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1302	44	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1303	44	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1304	44	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1305	44	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1306	44	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1307	44	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1308	44	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1309	44	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1310	44	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1311	44	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1312	44	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1313	44	2026-09-08	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1314	44	2026-09-07	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1315	44	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1316	44	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1317	44	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1318	44	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1319	44	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1320	44	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1321	45	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1322	45	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1323	45	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1324	45	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1325	45	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1326	45	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1327	45	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1328	45	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1329	45	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1330	45	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1331	45	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1332	45	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1333	45	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1334	45	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1335	45	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1336	45	2026-09-15	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1337	45	2026-09-14	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1338	45	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1339	45	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1340	45	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1341	45	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1342	45	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1343	45	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1344	45	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1345	45	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1346	45	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1347	45	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1348	45	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1349	45	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1350	45	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1351	46	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1352	46	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1353	46	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1354	46	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1355	46	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1356	46	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1357	46	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1358	46	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1359	46	2026-09-22	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1360	46	2026-09-21	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1361	46	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1362	46	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1363	46	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1364	46	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1365	46	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1366	46	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1367	46	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1368	46	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1369	46	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1370	46	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1371	46	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1372	46	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1373	46	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1374	46	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1375	46	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1376	46	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1377	46	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1378	46	2026-09-03	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1379	46	2026-09-02	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1380	46	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1381	47	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1382	47	2026-09-29	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1383	47	2026-09-28	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1384	47	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1385	47	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1386	47	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1387	47	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1388	47	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1389	47	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1390	47	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1391	47	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1392	47	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1393	47	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1394	47	2026-09-17	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1395	47	2026-09-16	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1396	47	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1397	47	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1398	47	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1399	47	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1400	47	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1401	47	2026-09-10	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1402	47	2026-09-09	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1403	47	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1404	47	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1405	47	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1406	47	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1407	47	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1408	47	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1409	47	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1410	47	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1411	48	2026-09-30	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1412	48	2026-09-29	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1413	48	2026-09-28	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1414	48	2026-09-27	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1415	48	2026-09-26	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1416	48	2026-09-25	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1417	48	2026-09-24	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1418	48	2026-09-23	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1419	48	2026-09-22	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1420	48	2026-09-21	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1421	48	2026-09-20	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1422	48	2026-09-19	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1423	48	2026-09-18	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1424	48	2026-09-17	absent	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1425	48	2026-09-16	leave	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1426	48	2026-09-15	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1427	48	2026-09-14	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1428	48	2026-09-13	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1429	48	2026-09-12	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1430	48	2026-09-11	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1431	48	2026-09-10	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1432	48	2026-09-09	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1433	48	2026-09-08	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1434	48	2026-09-07	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1435	48	2026-09-06	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1436	48	2026-09-05	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1437	48	2026-09-04	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1438	48	2026-09-03	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1439	48	2026-09-02	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1440	48	2026-09-01	present	8c52851d-50e6-4a27-843a-e438a8e5f5d8	2026-09-30 21:35:21.017498+05:30
1441	49	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1442	49	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1443	49	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1444	49	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1445	49	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1446	49	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1447	49	2026-09-24	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1448	49	2026-09-23	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1449	49	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1450	49	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1451	49	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1452	49	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1453	49	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1454	49	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1455	49	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1456	49	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1457	49	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1458	49	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1459	49	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1460	49	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1461	49	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1462	49	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1463	49	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1464	49	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1465	49	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1466	49	2026-09-05	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1467	49	2026-09-04	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1468	49	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1469	49	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1470	49	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1471	50	2026-09-30	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1472	50	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1473	50	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1474	50	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1475	50	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1476	50	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1477	50	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1478	50	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1479	50	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1480	50	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1481	50	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1482	50	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1483	50	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1484	50	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1485	50	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1486	50	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1487	50	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1488	50	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1489	50	2026-09-12	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1490	50	2026-09-11	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1491	50	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1492	50	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1493	50	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1494	50	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1495	50	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1496	50	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1497	50	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1498	50	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1499	50	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1500	50	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1501	51	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1502	51	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1503	51	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1504	51	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1505	51	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1506	51	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1507	51	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1508	51	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1509	51	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1510	51	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1511	51	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1512	51	2026-09-19	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1513	51	2026-09-18	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1514	51	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1515	51	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1516	51	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1517	51	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1518	51	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1519	51	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1520	51	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1521	51	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1522	51	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1523	51	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1524	51	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1525	51	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1526	51	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1527	51	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1528	51	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1529	51	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1530	51	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1531	52	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1532	52	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1533	52	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1534	52	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1535	52	2026-09-26	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1536	52	2026-09-25	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1537	52	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1538	52	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1539	52	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1540	52	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1541	52	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1542	52	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1543	52	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1544	52	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1545	52	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1546	52	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1547	52	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1548	52	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1549	52	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1550	52	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1551	52	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1552	52	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1553	52	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1554	52	2026-09-07	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1555	52	2026-09-06	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1556	52	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1557	52	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1558	52	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1559	52	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1560	52	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1561	53	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1562	53	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1563	53	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1564	53	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1565	53	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1566	53	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1567	53	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1568	53	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1569	53	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1570	53	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1571	53	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1572	53	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1573	53	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1574	53	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1575	53	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1576	53	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1577	53	2026-09-14	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1578	53	2026-09-13	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1579	53	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1580	53	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1581	53	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1582	53	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1583	53	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1584	53	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1585	53	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1586	53	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1587	53	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1588	53	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1589	53	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1590	53	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1591	54	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1592	54	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1593	54	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1594	54	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1595	54	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1596	54	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1597	54	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1598	54	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1599	54	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1600	54	2026-09-21	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1601	54	2026-09-20	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1602	54	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1603	54	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1604	54	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1605	54	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1606	54	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1607	54	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1608	54	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1609	54	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1610	54	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1611	54	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1612	54	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1613	54	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1614	54	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1615	54	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1616	54	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1617	54	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1618	54	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1619	54	2026-09-02	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1620	54	2026-09-01	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1621	55	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1622	55	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1623	55	2026-09-28	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1624	55	2026-09-27	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1625	55	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1626	55	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1627	55	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1628	55	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1629	55	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1630	55	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1631	55	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1632	55	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1633	55	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1634	55	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1635	55	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1636	55	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1637	55	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1638	55	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1639	55	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1640	55	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1641	55	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1642	55	2026-09-09	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1643	55	2026-09-08	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1644	55	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1645	55	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1646	55	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1647	55	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1648	55	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1649	55	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1650	55	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1651	56	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1652	56	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1653	56	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1654	56	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1655	56	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1656	56	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1657	56	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1658	56	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1659	56	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1660	56	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1661	56	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1662	56	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1663	56	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1664	56	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1665	56	2026-09-16	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1666	56	2026-09-15	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1667	56	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1668	56	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1669	56	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1670	56	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1671	56	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1672	56	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1673	56	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1674	56	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1675	56	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1676	56	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1677	56	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1678	56	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1679	56	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1680	56	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1681	57	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1682	57	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1683	57	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1684	57	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1685	57	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1686	57	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1687	57	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1688	57	2026-09-23	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1689	57	2026-09-22	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1690	57	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1691	57	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1692	57	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1693	57	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1694	57	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1695	57	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1696	57	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1697	57	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1698	57	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1699	57	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1700	57	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1701	57	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1702	57	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1703	57	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1704	57	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1705	57	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1706	57	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1707	57	2026-09-04	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1708	57	2026-09-03	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1709	57	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1710	57	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1711	58	2026-09-30	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1712	58	2026-09-29	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1713	58	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1714	58	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1715	58	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1716	58	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1717	58	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1718	58	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1719	58	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1720	58	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1721	58	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1722	58	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1723	58	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1724	58	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1725	58	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1726	58	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1727	58	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1728	58	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1729	58	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1730	58	2026-09-11	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1731	58	2026-09-10	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1732	58	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1733	58	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1734	58	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1735	58	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1736	58	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1737	58	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1738	58	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1739	58	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1740	58	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1741	59	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1742	59	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1743	59	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1744	59	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1745	59	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1746	59	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1747	59	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1748	59	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1749	59	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1750	59	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1751	59	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1752	59	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1753	59	2026-09-18	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1754	59	2026-09-17	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1755	59	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1756	59	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1757	59	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1758	59	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1759	59	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1760	59	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1761	59	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1762	59	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1763	59	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1764	59	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1765	59	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1766	59	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1767	59	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1768	59	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1769	59	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1770	59	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1771	60	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1772	60	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1773	60	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1774	60	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1775	60	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1776	60	2026-09-25	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1777	60	2026-09-24	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1778	60	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1779	60	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1780	60	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1781	60	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1782	60	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1783	60	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1784	60	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1785	60	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1786	60	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1787	60	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1788	60	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1789	60	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1790	60	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1791	60	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1792	60	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1793	60	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1794	60	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1795	60	2026-09-06	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1796	60	2026-09-05	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1797	60	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1798	60	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1799	60	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1800	60	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1801	61	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1802	61	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1803	61	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1804	61	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1805	61	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1806	61	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1807	61	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1808	61	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1809	61	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1810	61	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1811	61	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1812	61	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1813	61	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1814	61	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1815	61	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1816	61	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1817	61	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1818	61	2026-09-13	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1819	61	2026-09-12	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1820	61	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1821	61	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1822	61	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1823	61	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1824	61	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1825	61	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1826	61	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1827	61	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1828	61	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1829	61	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1830	61	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1831	62	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1832	62	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1833	62	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1834	62	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1835	62	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1836	62	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1837	62	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1838	62	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1839	62	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1840	62	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1841	62	2026-09-20	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1842	62	2026-09-19	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1843	62	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1844	62	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1845	62	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1846	62	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1847	62	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1848	62	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1849	62	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1850	62	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1851	62	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1852	62	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1853	62	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1854	62	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1855	62	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1856	62	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1857	62	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1858	62	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1859	62	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1860	62	2026-09-01	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1861	63	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1862	63	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1863	63	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1864	63	2026-09-27	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1865	63	2026-09-26	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1866	63	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1867	63	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1868	63	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1869	63	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1870	63	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1871	63	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1872	63	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1873	63	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1874	63	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1875	63	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1876	63	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1877	63	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1878	63	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1879	63	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1880	63	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1881	63	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1882	63	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1883	63	2026-09-08	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1884	63	2026-09-07	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1885	63	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1886	63	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1887	63	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1888	63	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1889	63	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1890	63	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1891	64	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1892	64	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1893	64	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1894	64	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1895	64	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1896	64	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1897	64	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1898	64	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1899	64	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1900	64	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1901	64	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1902	64	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1903	64	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1904	64	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1905	64	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1906	64	2026-09-15	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1907	64	2026-09-14	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1908	64	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1909	64	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1910	64	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1911	64	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1912	64	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1913	64	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1914	64	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1915	64	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1916	64	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1917	64	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1918	64	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1919	64	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1920	64	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1921	65	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1922	65	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1923	65	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1924	65	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1925	65	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1926	65	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1927	65	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1928	65	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1929	65	2026-09-22	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1930	65	2026-09-21	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1931	65	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1932	65	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1933	65	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1934	65	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1935	65	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1936	65	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1937	65	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1938	65	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1939	65	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1940	65	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1941	65	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1942	65	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1943	65	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1944	65	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1945	65	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1946	65	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1947	65	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1948	65	2026-09-03	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1949	65	2026-09-02	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1950	65	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1951	66	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1952	66	2026-09-29	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1953	66	2026-09-28	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1954	66	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1955	66	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1956	66	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1957	66	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1958	66	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1959	66	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1960	66	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1961	66	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1962	66	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1963	66	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1964	66	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1965	66	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1966	66	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1967	66	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1968	66	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1969	66	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1970	66	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1971	66	2026-09-10	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1972	66	2026-09-09	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1973	66	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1974	66	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1975	66	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1976	66	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1977	66	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1978	66	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1979	66	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1980	66	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1981	67	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1982	67	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1983	67	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1984	67	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1985	67	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1986	67	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1987	67	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1988	67	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1989	67	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1990	67	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1991	67	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1992	67	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1993	67	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1994	67	2026-09-17	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1995	67	2026-09-16	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1996	67	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1997	67	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1998	67	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
1999	67	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2000	67	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2001	67	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2002	67	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2003	67	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2004	67	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2005	67	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2006	67	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2007	67	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2008	67	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2009	67	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2010	67	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2011	68	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2012	68	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2013	68	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2014	68	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2015	68	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2016	68	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2017	68	2026-09-24	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2018	68	2026-09-23	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2019	68	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2020	68	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2021	68	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2022	68	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2023	68	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2024	68	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2025	68	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2026	68	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2027	68	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2028	68	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2029	68	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2030	68	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2031	68	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2032	68	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2033	68	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2034	68	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2035	68	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2036	68	2026-09-05	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2037	68	2026-09-04	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2038	68	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2039	68	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2040	68	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2041	69	2026-09-30	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2042	69	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2043	69	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2044	69	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2045	69	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2046	69	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2047	69	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2048	69	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2049	69	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2050	69	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2051	69	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2052	69	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2053	69	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2054	69	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2055	69	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2056	69	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2057	69	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2058	69	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2059	69	2026-09-12	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2060	69	2026-09-11	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2061	69	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2062	69	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2063	69	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2064	69	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2065	69	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2066	69	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2067	69	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2068	69	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2069	69	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2070	69	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2071	70	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2072	70	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2073	70	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2074	70	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2075	70	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2076	70	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2077	70	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2078	70	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2079	70	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2080	70	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2081	70	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2082	70	2026-09-19	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2083	70	2026-09-18	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2084	70	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2085	70	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2086	70	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2087	70	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2088	70	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2089	70	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2090	70	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2091	70	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2092	70	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2093	70	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2094	70	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2095	70	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2096	70	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2097	70	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2098	70	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2099	70	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2100	70	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2101	71	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2102	71	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2103	71	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2104	71	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2105	71	2026-09-26	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2106	71	2026-09-25	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2107	71	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2108	71	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2109	71	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2110	71	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2111	71	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2112	71	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2113	71	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2114	71	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2115	71	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2116	71	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2117	71	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2118	71	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2119	71	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2120	71	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2121	71	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2122	71	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2123	71	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2124	71	2026-09-07	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2125	71	2026-09-06	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2126	71	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2127	71	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2128	71	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2129	71	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2130	71	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2131	72	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2132	72	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2133	72	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2134	72	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2135	72	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2136	72	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2137	72	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2138	72	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2139	72	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2140	72	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2141	72	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2142	72	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2143	72	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2144	72	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2145	72	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2146	72	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2147	72	2026-09-14	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2148	72	2026-09-13	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2149	72	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2150	72	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2151	72	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2152	72	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2153	72	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2154	72	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2155	72	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2156	72	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2157	72	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2158	72	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2159	72	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2160	72	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2161	73	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2162	73	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2163	73	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2164	73	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2165	73	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2166	73	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2167	73	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2168	73	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2169	73	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2170	73	2026-09-21	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2171	73	2026-09-20	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2172	73	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2173	73	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2174	73	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2175	73	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2176	73	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2177	73	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2178	73	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2179	73	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2180	73	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2181	73	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2182	73	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2183	73	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2184	73	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2185	73	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2186	73	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2187	73	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2188	73	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2189	73	2026-09-02	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2190	73	2026-09-01	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2191	74	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2192	74	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2193	74	2026-09-28	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2194	74	2026-09-27	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2195	74	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2196	74	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2197	74	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2198	74	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2199	74	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2200	74	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2201	74	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2202	74	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2203	74	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2204	74	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2205	74	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2206	74	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2207	74	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2208	74	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2209	74	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2210	74	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2211	74	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2212	74	2026-09-09	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2213	74	2026-09-08	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2214	74	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2215	74	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2216	74	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2217	74	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2218	74	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2219	74	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2220	74	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2221	75	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2222	75	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2223	75	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2224	75	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2225	75	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2226	75	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2227	75	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2228	75	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2229	75	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2230	75	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2231	75	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2232	75	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2233	75	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2234	75	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2235	75	2026-09-16	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2236	75	2026-09-15	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2237	75	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2238	75	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2239	75	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2240	75	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2241	75	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2242	75	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2243	75	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2244	75	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2245	75	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2246	75	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2247	75	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2248	75	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2249	75	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2250	75	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2251	76	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2252	76	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2253	76	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2254	76	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2255	76	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2256	76	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2257	76	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2258	76	2026-09-23	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2259	76	2026-09-22	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2260	76	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2261	76	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2262	76	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2263	76	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2264	76	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2265	76	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2266	76	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2267	76	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2268	76	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2269	76	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2270	76	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2271	76	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2272	76	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2273	76	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2274	76	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2275	76	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2276	76	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2277	76	2026-09-04	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2278	76	2026-09-03	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2279	76	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2280	76	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2281	77	2026-09-30	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2282	77	2026-09-29	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2283	77	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2284	77	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2285	77	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2286	77	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2287	77	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2288	77	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2289	77	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2290	77	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2291	77	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2292	77	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2293	77	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2294	77	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2295	77	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2296	77	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2297	77	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2298	77	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2299	77	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2300	77	2026-09-11	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2301	77	2026-09-10	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2302	77	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2303	77	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2304	77	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2305	77	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2306	77	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2307	77	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2308	77	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2309	77	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2310	77	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2311	78	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2312	78	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2313	78	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2314	78	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2315	78	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2316	78	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2317	78	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2318	78	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2319	78	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2320	78	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2321	78	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2322	78	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2323	78	2026-09-18	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2324	78	2026-09-17	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2325	78	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2326	78	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2327	78	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2328	78	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2329	78	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2330	78	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2331	78	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2332	78	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2333	78	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2334	78	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2335	78	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2336	78	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2337	78	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2338	78	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2339	78	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2340	78	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2341	79	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2342	79	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2343	79	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2344	79	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2345	79	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2346	79	2026-09-25	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2347	79	2026-09-24	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2348	79	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2349	79	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2350	79	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2351	79	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2352	79	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2353	79	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2354	79	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2355	79	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2356	79	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2357	79	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2358	79	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2359	79	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2360	79	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2361	79	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2362	79	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2363	79	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2364	79	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2365	79	2026-09-06	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2366	79	2026-09-05	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2367	79	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2368	79	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2369	79	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2370	79	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2371	80	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2372	80	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2373	80	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2374	80	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2375	80	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2376	80	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2377	80	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2378	80	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2379	80	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2380	80	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2381	80	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2382	80	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2383	80	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2384	80	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2385	80	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2386	80	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2387	80	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2388	80	2026-09-13	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2389	80	2026-09-12	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2390	80	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2391	80	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2392	80	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2393	80	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2394	80	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2395	80	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2396	80	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2397	80	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2398	80	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2399	80	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2400	80	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2401	81	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2402	81	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2403	81	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2404	81	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2405	81	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2406	81	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2407	81	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2408	81	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2409	81	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2410	81	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2411	81	2026-09-20	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2412	81	2026-09-19	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2413	81	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2414	81	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2415	81	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2416	81	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2417	81	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2418	81	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2419	81	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2420	81	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2421	81	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2422	81	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2423	81	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2424	81	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2425	81	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2426	81	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2427	81	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2428	81	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2429	81	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2430	81	2026-09-01	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2431	82	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2432	82	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2433	82	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2434	82	2026-09-27	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2435	82	2026-09-26	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2436	82	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2437	82	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2438	82	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2439	82	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2440	82	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2441	82	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2442	82	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2443	82	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2444	82	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2445	82	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2446	82	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2447	82	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2448	82	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2449	82	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2450	82	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2451	82	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2452	82	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2453	82	2026-09-08	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2454	82	2026-09-07	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2455	82	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2456	82	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2457	82	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2458	82	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2459	82	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2460	82	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2461	83	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2462	83	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2463	83	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2464	83	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2465	83	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2466	83	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2467	83	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2468	83	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2469	83	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2470	83	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2471	83	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2472	83	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2473	83	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2474	83	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2475	83	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2476	83	2026-09-15	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2477	83	2026-09-14	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2478	83	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2479	83	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2480	83	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2481	83	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2482	83	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2483	83	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2484	83	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2485	83	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2486	83	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2487	83	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2488	83	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2489	83	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2490	83	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2491	84	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2492	84	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2493	84	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2494	84	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2495	84	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2496	84	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2497	84	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2498	84	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2499	84	2026-09-22	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2500	84	2026-09-21	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2501	84	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2502	84	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2503	84	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2504	84	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2505	84	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2506	84	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2507	84	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2508	84	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2509	84	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2510	84	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2511	84	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2512	84	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2513	84	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2514	84	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2515	84	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2516	84	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2517	84	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2518	84	2026-09-03	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2519	84	2026-09-02	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2520	84	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2521	85	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2522	85	2026-09-29	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2523	85	2026-09-28	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2524	85	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2525	85	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2526	85	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2527	85	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2528	85	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2529	85	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2530	85	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2531	85	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2532	85	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2533	85	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2534	85	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2535	85	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2536	85	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2537	85	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2538	85	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2539	85	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2540	85	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2541	85	2026-09-10	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2542	85	2026-09-09	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2543	85	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2544	85	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2545	85	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2546	85	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2547	85	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2548	85	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2549	85	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2550	85	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2551	86	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2552	86	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2553	86	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2554	86	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2555	86	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2556	86	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2557	86	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2558	86	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2559	86	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2560	86	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2561	86	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2562	86	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2563	86	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2564	86	2026-09-17	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2565	86	2026-09-16	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2566	86	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2567	86	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2568	86	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2569	86	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2570	86	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2571	86	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2572	86	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2573	86	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2574	86	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2575	86	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2576	86	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2577	86	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2578	86	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2579	86	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2580	86	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2581	87	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2582	87	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2583	87	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2584	87	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2585	87	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2586	87	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2587	87	2026-09-24	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2588	87	2026-09-23	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2589	87	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2590	87	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2591	87	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2592	87	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2593	87	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2594	87	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2595	87	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2596	87	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2597	87	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2598	87	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2599	87	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2600	87	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2601	87	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2602	87	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2603	87	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2604	87	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2605	87	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2606	87	2026-09-05	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2607	87	2026-09-04	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2608	87	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2609	87	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2610	87	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2611	88	2026-09-30	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2612	88	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2613	88	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2614	88	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2615	88	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2616	88	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2617	88	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2618	88	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2619	88	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2620	88	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2621	88	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2622	88	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2623	88	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2624	88	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2625	88	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2626	88	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2627	88	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2628	88	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2629	88	2026-09-12	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2630	88	2026-09-11	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2631	88	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2632	88	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2633	88	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2634	88	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2635	88	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2636	88	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2637	88	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2638	88	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2639	88	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2640	88	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2641	89	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2642	89	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2643	89	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2644	89	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2645	89	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2646	89	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2647	89	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2648	89	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2649	89	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2650	89	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2651	89	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2652	89	2026-09-19	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2653	89	2026-09-18	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2654	89	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2655	89	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2656	89	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2657	89	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2658	89	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2659	89	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2660	89	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2661	89	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2662	89	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2663	89	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2664	89	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2665	89	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2666	89	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2667	89	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2668	89	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2669	89	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2670	89	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2671	90	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2672	90	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2673	90	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2674	90	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2675	90	2026-09-26	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2676	90	2026-09-25	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2677	90	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2678	90	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2679	90	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2680	90	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2681	90	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2682	90	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2683	90	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2684	90	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2685	90	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2686	90	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2687	90	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2688	90	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2689	90	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2690	90	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2691	90	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2692	90	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2693	90	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2694	90	2026-09-07	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2695	90	2026-09-06	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2696	90	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2697	90	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2698	90	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2699	90	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2700	90	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2701	91	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2702	91	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2703	91	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2704	91	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2705	91	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2706	91	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2707	91	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2708	91	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2709	91	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2710	91	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2711	91	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2712	91	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2713	91	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2714	91	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2715	91	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2716	91	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2717	91	2026-09-14	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2718	91	2026-09-13	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2719	91	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2720	91	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2721	91	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2722	91	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2723	91	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2724	91	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2725	91	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2726	91	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2727	91	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2728	91	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2729	91	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2730	91	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2731	92	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2732	92	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2733	92	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2734	92	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2735	92	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2736	92	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2737	92	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2738	92	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2739	92	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2740	92	2026-09-21	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2741	92	2026-09-20	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2742	92	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2743	92	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2744	92	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2745	92	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2746	92	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2747	92	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2748	92	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2749	92	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2750	92	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2751	92	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2752	92	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2753	92	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2754	92	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2755	92	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2756	92	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2757	92	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2758	92	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2759	92	2026-09-02	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2760	92	2026-09-01	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2761	93	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2762	93	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2763	93	2026-09-28	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2764	93	2026-09-27	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2765	93	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2766	93	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2767	93	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2768	93	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2769	93	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2770	93	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2771	93	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2772	93	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2773	93	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2774	93	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2775	93	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2776	93	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2777	93	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2778	93	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2779	93	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2780	93	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2781	93	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2782	93	2026-09-09	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2783	93	2026-09-08	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2784	93	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2785	93	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2786	93	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2787	93	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2788	93	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2789	93	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2790	93	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2791	94	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2792	94	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2793	94	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2794	94	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2795	94	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2796	94	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2797	94	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2798	94	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2799	94	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2800	94	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2801	94	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2802	94	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2803	94	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2804	94	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2805	94	2026-09-16	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2806	94	2026-09-15	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2807	94	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2808	94	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2809	94	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2810	94	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2811	94	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2812	94	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2813	94	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2814	94	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2815	94	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2816	94	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2817	94	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2818	94	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2819	94	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2820	94	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2821	95	2026-09-30	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2822	95	2026-09-29	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2823	95	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2824	95	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2825	95	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2826	95	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2827	95	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2828	95	2026-09-23	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2829	95	2026-09-22	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2830	95	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2831	95	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2832	95	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2833	95	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2834	95	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2835	95	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2836	95	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2837	95	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2838	95	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2839	95	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2840	95	2026-09-11	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2841	95	2026-09-10	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2842	95	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2843	95	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2844	95	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2845	95	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2846	95	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2847	95	2026-09-04	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2848	95	2026-09-03	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2849	95	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2850	95	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2851	96	2026-09-30	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2852	96	2026-09-29	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2853	96	2026-09-28	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2854	96	2026-09-27	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2855	96	2026-09-26	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2856	96	2026-09-25	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2857	96	2026-09-24	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2858	96	2026-09-23	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2859	96	2026-09-22	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2860	96	2026-09-21	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2861	96	2026-09-20	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2862	96	2026-09-19	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2863	96	2026-09-18	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2864	96	2026-09-17	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2865	96	2026-09-16	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2866	96	2026-09-15	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2867	96	2026-09-14	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2868	96	2026-09-13	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2869	96	2026-09-12	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2870	96	2026-09-11	absent	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2871	96	2026-09-10	leave	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2872	96	2026-09-09	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2873	96	2026-09-08	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2874	96	2026-09-07	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2875	96	2026-09-06	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2876	96	2026-09-05	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2877	96	2026-09-04	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2878	96	2026-09-03	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2879	96	2026-09-02	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2880	96	2026-09-01	present	7f98f45c-3038-4f53-8476-aa2381d1a7c3	2026-09-30 21:35:21.017498+05:30
2881	97	2026-09-30	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2882	97	2026-09-29	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2883	97	2026-09-28	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2884	97	2026-09-27	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2885	97	2026-09-26	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2886	97	2026-09-25	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2887	97	2026-09-24	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2888	97	2026-09-23	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2889	97	2026-09-22	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2890	97	2026-09-21	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2891	97	2026-09-20	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2892	97	2026-09-19	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2893	97	2026-09-18	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2894	97	2026-09-17	leave	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2895	97	2026-09-16	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2896	97	2026-09-15	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2897	97	2026-09-14	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2898	97	2026-09-13	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2899	97	2026-09-12	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2900	97	2026-09-11	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2901	97	2026-09-10	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2902	97	2026-09-09	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2903	97	2026-09-08	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2904	97	2026-09-07	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2905	97	2026-09-06	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2906	97	2026-09-05	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2907	97	2026-09-04	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2908	97	2026-09-03	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2909	97	2026-09-02	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2910	97	2026-09-01	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2911	98	2026-09-30	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2912	98	2026-09-29	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2913	98	2026-09-28	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2914	98	2026-09-27	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2915	98	2026-09-26	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2916	98	2026-09-25	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2917	98	2026-09-24	leave	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2918	98	2026-09-23	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2919	98	2026-09-22	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2920	98	2026-09-21	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2921	98	2026-09-20	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2922	98	2026-09-19	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2923	98	2026-09-18	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2924	98	2026-09-17	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2925	98	2026-09-16	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2926	98	2026-09-15	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2927	98	2026-09-14	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2928	98	2026-09-13	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2929	98	2026-09-12	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2930	98	2026-09-11	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2931	98	2026-09-10	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2932	98	2026-09-09	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2933	98	2026-09-08	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2934	98	2026-09-07	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2935	98	2026-09-06	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2936	98	2026-09-05	leave	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2937	98	2026-09-04	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2938	98	2026-09-03	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2939	98	2026-09-02	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2940	98	2026-09-01	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2941	99	2026-09-30	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2942	99	2026-09-29	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2943	99	2026-09-28	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2944	99	2026-09-27	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2945	99	2026-09-26	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2946	99	2026-09-25	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2947	99	2026-09-24	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2948	99	2026-09-23	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2949	99	2026-09-22	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2950	99	2026-09-21	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2951	99	2026-09-20	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2952	99	2026-09-19	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2953	99	2026-09-18	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2954	99	2026-09-17	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2955	99	2026-09-16	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2956	99	2026-09-15	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2957	99	2026-09-14	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2958	99	2026-09-13	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2959	99	2026-09-12	leave	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2960	99	2026-09-11	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2961	99	2026-09-10	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2962	99	2026-09-09	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2963	99	2026-09-08	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2964	99	2026-09-07	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2965	99	2026-09-06	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2966	99	2026-09-05	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2967	99	2026-09-04	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2968	99	2026-09-03	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2969	99	2026-09-02	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2970	99	2026-09-01	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2971	100	2026-09-30	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2972	100	2026-09-29	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2973	100	2026-09-28	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2974	100	2026-09-27	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2975	100	2026-09-26	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2976	100	2026-09-25	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2977	100	2026-09-24	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2978	100	2026-09-23	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2979	100	2026-09-22	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2980	100	2026-09-21	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2981	100	2026-09-20	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2982	100	2026-09-19	leave	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2983	100	2026-09-18	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2984	100	2026-09-17	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2985	100	2026-09-16	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2986	100	2026-09-15	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2987	100	2026-09-14	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2988	100	2026-09-13	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2989	100	2026-09-12	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2990	100	2026-09-11	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2991	100	2026-09-10	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2992	100	2026-09-09	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2993	100	2026-09-08	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2994	100	2026-09-07	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2995	100	2026-09-06	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2996	100	2026-09-05	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2997	100	2026-09-04	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2998	100	2026-09-03	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
2999	100	2026-09-02	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3000	100	2026-09-01	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3001	101	2026-09-30	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3002	101	2026-09-29	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3003	101	2026-09-28	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3004	101	2026-09-27	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3005	101	2026-09-26	leave	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3006	101	2026-09-25	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3007	101	2026-09-24	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3008	101	2026-09-23	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3009	101	2026-09-22	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3010	101	2026-09-21	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3011	101	2026-09-20	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3012	101	2026-09-19	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3013	101	2026-09-18	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3014	101	2026-09-17	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3015	101	2026-09-16	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3016	101	2026-09-15	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3017	101	2026-09-14	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3018	101	2026-09-13	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3019	101	2026-09-12	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3020	101	2026-09-11	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3021	101	2026-09-10	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3022	101	2026-09-09	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3023	101	2026-09-08	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3024	101	2026-09-07	leave	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3025	101	2026-09-06	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3026	101	2026-09-05	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3027	101	2026-09-04	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3028	101	2026-09-03	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3029	101	2026-09-02	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3030	101	2026-09-01	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3031	102	2026-09-30	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3032	102	2026-09-29	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3033	102	2026-09-28	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3034	102	2026-09-27	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3035	102	2026-09-26	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3036	102	2026-09-25	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3037	102	2026-09-24	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3038	102	2026-09-23	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3039	102	2026-09-22	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3040	102	2026-09-21	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3041	102	2026-09-20	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3042	102	2026-09-19	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3043	102	2026-09-18	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3044	102	2026-09-17	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3045	102	2026-09-16	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3046	102	2026-09-15	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3047	102	2026-09-14	leave	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3048	102	2026-09-13	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3049	102	2026-09-12	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3050	102	2026-09-11	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3051	102	2026-09-10	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3052	102	2026-09-09	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3053	102	2026-09-08	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3054	102	2026-09-07	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3055	102	2026-09-06	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3056	102	2026-09-05	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3057	102	2026-09-04	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3058	102	2026-09-03	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3059	102	2026-09-02	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3060	102	2026-09-01	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3061	103	2026-09-30	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3062	103	2026-09-29	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3063	103	2026-09-28	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3064	103	2026-09-27	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3065	103	2026-09-26	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3066	103	2026-09-25	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3067	103	2026-09-24	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3068	103	2026-09-23	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3069	103	2026-09-22	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3070	103	2026-09-21	leave	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3071	103	2026-09-20	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3072	103	2026-09-19	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3073	103	2026-09-18	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3074	103	2026-09-17	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3075	103	2026-09-16	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3076	103	2026-09-15	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3077	103	2026-09-14	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3078	103	2026-09-13	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3079	103	2026-09-12	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3080	103	2026-09-11	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3081	103	2026-09-10	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3082	103	2026-09-09	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3083	103	2026-09-08	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3084	103	2026-09-07	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3085	103	2026-09-06	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3086	103	2026-09-05	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3087	103	2026-09-04	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3088	103	2026-09-03	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3089	103	2026-09-02	leave	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3090	103	2026-09-01	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3091	104	2026-09-30	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3092	104	2026-09-29	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3093	104	2026-09-28	leave	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3094	104	2026-09-27	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3095	104	2026-09-26	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3096	104	2026-09-25	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3097	104	2026-09-24	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3098	104	2026-09-23	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3099	104	2026-09-22	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3100	104	2026-09-21	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3101	104	2026-09-20	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3102	104	2026-09-19	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3103	104	2026-09-18	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3104	104	2026-09-17	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3105	104	2026-09-16	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3106	104	2026-09-15	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3107	104	2026-09-14	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3108	104	2026-09-13	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3109	104	2026-09-12	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3110	104	2026-09-11	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3111	104	2026-09-10	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3112	104	2026-09-09	leave	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3113	104	2026-09-08	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3114	104	2026-09-07	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3115	104	2026-09-06	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3116	104	2026-09-05	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3117	104	2026-09-04	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3118	104	2026-09-03	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3119	104	2026-09-02	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3120	104	2026-09-01	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3121	105	2026-09-30	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3122	105	2026-09-29	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3123	105	2026-09-28	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3124	105	2026-09-27	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3125	105	2026-09-26	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3126	105	2026-09-25	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3127	105	2026-09-24	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3128	105	2026-09-23	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3129	105	2026-09-22	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3130	105	2026-09-21	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3131	105	2026-09-20	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3132	105	2026-09-19	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3133	105	2026-09-18	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3134	105	2026-09-17	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3135	105	2026-09-16	leave	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3136	105	2026-09-15	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3137	105	2026-09-14	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3138	105	2026-09-13	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3139	105	2026-09-12	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3140	105	2026-09-11	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3141	105	2026-09-10	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3142	105	2026-09-09	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3143	105	2026-09-08	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3144	105	2026-09-07	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3145	105	2026-09-06	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3146	105	2026-09-05	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3147	105	2026-09-04	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3148	105	2026-09-03	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3149	105	2026-09-02	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3150	105	2026-09-01	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3151	106	2026-09-30	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3152	106	2026-09-29	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3153	106	2026-09-28	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3154	106	2026-09-27	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3155	106	2026-09-26	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3156	106	2026-09-25	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3157	106	2026-09-24	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3158	106	2026-09-23	leave	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3159	106	2026-09-22	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3160	106	2026-09-21	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3161	106	2026-09-20	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3162	106	2026-09-19	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3163	106	2026-09-18	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3164	106	2026-09-17	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3165	106	2026-09-16	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3166	106	2026-09-15	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3167	106	2026-09-14	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3168	106	2026-09-13	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3169	106	2026-09-12	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3170	106	2026-09-11	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3171	106	2026-09-10	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3172	106	2026-09-09	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3173	106	2026-09-08	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3174	106	2026-09-07	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3175	106	2026-09-06	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3176	106	2026-09-05	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3177	106	2026-09-04	leave	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3178	106	2026-09-03	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3179	106	2026-09-02	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3180	106	2026-09-01	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3181	107	2026-09-30	leave	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3182	107	2026-09-29	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3183	107	2026-09-28	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3184	107	2026-09-27	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3185	107	2026-09-26	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3186	107	2026-09-25	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3187	107	2026-09-24	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3188	107	2026-09-23	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3189	107	2026-09-22	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3190	107	2026-09-21	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3191	107	2026-09-20	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3192	107	2026-09-19	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3193	107	2026-09-18	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3194	107	2026-09-17	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3195	107	2026-09-16	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3196	107	2026-09-15	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3197	107	2026-09-14	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3198	107	2026-09-13	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3199	107	2026-09-12	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3200	107	2026-09-11	leave	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3201	107	2026-09-10	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3202	107	2026-09-09	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3203	107	2026-09-08	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3204	107	2026-09-07	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3205	107	2026-09-06	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3206	107	2026-09-05	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3207	107	2026-09-04	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3208	107	2026-09-03	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3209	107	2026-09-02	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3210	107	2026-09-01	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3211	108	2026-09-30	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3212	108	2026-09-29	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3213	108	2026-09-28	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3214	108	2026-09-27	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3215	108	2026-09-26	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3216	108	2026-09-25	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3217	108	2026-09-24	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3218	108	2026-09-23	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3219	108	2026-09-22	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3220	108	2026-09-21	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3221	108	2026-09-20	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3222	108	2026-09-19	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3223	108	2026-09-18	leave	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3224	108	2026-09-17	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3225	108	2026-09-16	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3226	108	2026-09-15	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3227	108	2026-09-14	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3228	108	2026-09-13	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3229	108	2026-09-12	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3230	108	2026-09-11	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3231	108	2026-09-10	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3232	108	2026-09-09	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3233	108	2026-09-08	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3234	108	2026-09-07	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3235	108	2026-09-06	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3236	108	2026-09-05	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3237	108	2026-09-04	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3238	108	2026-09-03	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3239	108	2026-09-02	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3240	108	2026-09-01	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3241	109	2026-09-30	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3242	109	2026-09-29	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3243	109	2026-09-28	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3244	109	2026-09-27	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3245	109	2026-09-26	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3246	109	2026-09-25	leave	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3247	109	2026-09-24	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3248	109	2026-09-23	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3249	109	2026-09-22	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3250	109	2026-09-21	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3251	109	2026-09-20	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3252	109	2026-09-19	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3253	109	2026-09-18	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3254	109	2026-09-17	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3255	109	2026-09-16	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3256	109	2026-09-15	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3257	109	2026-09-14	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3258	109	2026-09-13	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3259	109	2026-09-12	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3260	109	2026-09-11	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3261	109	2026-09-10	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3262	109	2026-09-09	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3263	109	2026-09-08	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3264	109	2026-09-07	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3265	109	2026-09-06	leave	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3266	109	2026-09-05	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3267	109	2026-09-04	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3268	109	2026-09-03	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3269	109	2026-09-02	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3270	109	2026-09-01	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3271	110	2026-09-30	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3272	110	2026-09-29	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3273	110	2026-09-28	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3274	110	2026-09-27	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3275	110	2026-09-26	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3276	110	2026-09-25	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3277	110	2026-09-24	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3278	110	2026-09-23	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3279	110	2026-09-22	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3280	110	2026-09-21	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3281	110	2026-09-20	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3282	110	2026-09-19	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3283	110	2026-09-18	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3284	110	2026-09-17	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3285	110	2026-09-16	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3286	110	2026-09-15	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3287	110	2026-09-14	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3288	110	2026-09-13	leave	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3289	110	2026-09-12	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3290	110	2026-09-11	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3291	110	2026-09-10	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3292	110	2026-09-09	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3293	110	2026-09-08	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3294	110	2026-09-07	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3295	110	2026-09-06	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3296	110	2026-09-05	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3297	110	2026-09-04	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3298	110	2026-09-03	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3299	110	2026-09-02	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3300	110	2026-09-01	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3301	111	2026-09-30	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3302	111	2026-09-29	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3303	111	2026-09-28	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3304	111	2026-09-27	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3305	111	2026-09-26	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3306	111	2026-09-25	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3307	111	2026-09-24	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3308	111	2026-09-23	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3309	111	2026-09-22	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3310	111	2026-09-21	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3311	111	2026-09-20	leave	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3312	111	2026-09-19	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3313	111	2026-09-18	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3314	111	2026-09-17	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3315	111	2026-09-16	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3316	111	2026-09-15	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3317	111	2026-09-14	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3318	111	2026-09-13	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3319	111	2026-09-12	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3320	111	2026-09-11	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3321	111	2026-09-10	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3322	111	2026-09-09	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3323	111	2026-09-08	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3324	111	2026-09-07	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3325	111	2026-09-06	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3326	111	2026-09-05	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3327	111	2026-09-04	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3328	111	2026-09-03	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3329	111	2026-09-02	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3330	111	2026-09-01	leave	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3331	112	2026-09-30	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3332	112	2026-09-29	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3333	112	2026-09-28	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3334	112	2026-09-27	leave	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3335	112	2026-09-26	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3336	112	2026-09-25	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3337	112	2026-09-24	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3338	112	2026-09-23	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3339	112	2026-09-22	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3340	112	2026-09-21	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3341	112	2026-09-20	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3342	112	2026-09-19	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3343	112	2026-09-18	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3344	112	2026-09-17	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3345	112	2026-09-16	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3346	112	2026-09-15	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3347	112	2026-09-14	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3348	112	2026-09-13	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3349	112	2026-09-12	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3350	112	2026-09-11	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3351	112	2026-09-10	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3352	112	2026-09-09	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3353	112	2026-09-08	leave	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3354	112	2026-09-07	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3355	112	2026-09-06	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3356	112	2026-09-05	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3357	112	2026-09-04	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3358	112	2026-09-03	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3359	112	2026-09-02	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3360	112	2026-09-01	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3361	113	2026-09-30	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3362	113	2026-09-29	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3363	113	2026-09-28	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3364	113	2026-09-27	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3365	113	2026-09-26	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3366	113	2026-09-25	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3367	113	2026-09-24	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3368	113	2026-09-23	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3369	113	2026-09-22	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3370	113	2026-09-21	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3371	113	2026-09-20	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3372	113	2026-09-19	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3373	113	2026-09-18	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3374	113	2026-09-17	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3375	113	2026-09-16	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3376	113	2026-09-15	leave	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3377	113	2026-09-14	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3378	113	2026-09-13	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3379	113	2026-09-12	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3380	113	2026-09-11	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3381	113	2026-09-10	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3382	113	2026-09-09	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3383	113	2026-09-08	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3384	113	2026-09-07	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3385	113	2026-09-06	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3386	113	2026-09-05	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3387	113	2026-09-04	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3388	113	2026-09-03	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3389	113	2026-09-02	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3390	113	2026-09-01	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3391	114	2026-09-30	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3392	114	2026-09-29	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3393	114	2026-09-28	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3394	114	2026-09-27	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3395	114	2026-09-26	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3396	114	2026-09-25	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3397	114	2026-09-24	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3398	114	2026-09-23	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3399	114	2026-09-22	leave	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3400	114	2026-09-21	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3401	114	2026-09-20	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3402	114	2026-09-19	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3403	114	2026-09-18	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3404	114	2026-09-17	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3405	114	2026-09-16	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3406	114	2026-09-15	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3407	114	2026-09-14	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3408	114	2026-09-13	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3409	114	2026-09-12	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3410	114	2026-09-11	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3411	114	2026-09-10	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3412	114	2026-09-09	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3413	114	2026-09-08	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3414	114	2026-09-07	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3415	114	2026-09-06	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3416	114	2026-09-05	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3417	114	2026-09-04	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3418	114	2026-09-03	leave	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3419	114	2026-09-02	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3420	114	2026-09-01	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3421	115	2026-09-30	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3422	115	2026-09-29	leave	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3423	115	2026-09-28	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3424	115	2026-09-27	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3425	115	2026-09-26	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3426	115	2026-09-25	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3427	115	2026-09-24	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3428	115	2026-09-23	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3429	115	2026-09-22	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3430	115	2026-09-21	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3431	115	2026-09-20	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3432	115	2026-09-19	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3433	115	2026-09-18	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3434	115	2026-09-17	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3435	115	2026-09-16	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3436	115	2026-09-15	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3437	115	2026-09-14	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3438	115	2026-09-13	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3439	115	2026-09-12	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3440	115	2026-09-11	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3441	115	2026-09-10	leave	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3442	115	2026-09-09	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3443	115	2026-09-08	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3444	115	2026-09-07	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3445	115	2026-09-06	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3446	115	2026-09-05	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3447	115	2026-09-04	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3448	115	2026-09-03	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3449	115	2026-09-02	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3450	115	2026-09-01	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3451	116	2026-09-30	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3452	116	2026-09-29	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3453	116	2026-09-28	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3454	116	2026-09-27	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3455	116	2026-09-26	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3456	116	2026-09-25	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3457	116	2026-09-24	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3458	116	2026-09-23	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3459	116	2026-09-22	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3460	116	2026-09-21	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3461	116	2026-09-20	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3462	116	2026-09-19	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3463	116	2026-09-18	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3464	116	2026-09-17	leave	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3465	116	2026-09-16	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3466	116	2026-09-15	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3467	116	2026-09-14	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3468	116	2026-09-13	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3469	116	2026-09-12	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3470	116	2026-09-11	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3471	116	2026-09-10	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3472	116	2026-09-09	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3473	116	2026-09-08	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3474	116	2026-09-07	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3475	116	2026-09-06	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3476	116	2026-09-05	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3477	116	2026-09-04	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3478	116	2026-09-03	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3479	116	2026-09-02	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3480	116	2026-09-01	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3481	117	2026-09-30	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3482	117	2026-09-29	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3483	117	2026-09-28	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3484	117	2026-09-27	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3485	117	2026-09-26	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3486	117	2026-09-25	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3487	117	2026-09-24	leave	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3488	117	2026-09-23	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3489	117	2026-09-22	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3490	117	2026-09-21	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3491	117	2026-09-20	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3492	117	2026-09-19	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3493	117	2026-09-18	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3494	117	2026-09-17	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3495	117	2026-09-16	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3496	117	2026-09-15	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3497	117	2026-09-14	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3498	117	2026-09-13	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3499	117	2026-09-12	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3500	117	2026-09-11	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3501	117	2026-09-10	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3502	117	2026-09-09	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3503	117	2026-09-08	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3504	117	2026-09-07	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3505	117	2026-09-06	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3506	117	2026-09-05	leave	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3507	117	2026-09-04	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3508	117	2026-09-03	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3509	117	2026-09-02	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3510	117	2026-09-01	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3511	118	2026-09-30	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3512	118	2026-09-29	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3513	118	2026-09-28	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3514	118	2026-09-27	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3515	118	2026-09-26	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3516	118	2026-09-25	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3517	118	2026-09-24	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3518	118	2026-09-23	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3519	118	2026-09-22	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3520	118	2026-09-21	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3521	118	2026-09-20	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3522	118	2026-09-19	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3523	118	2026-09-18	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3524	118	2026-09-17	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3525	118	2026-09-16	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3526	118	2026-09-15	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3527	118	2026-09-14	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3528	118	2026-09-13	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3529	118	2026-09-12	leave	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3530	118	2026-09-11	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3531	118	2026-09-10	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3532	118	2026-09-09	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3533	118	2026-09-08	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3534	118	2026-09-07	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3535	118	2026-09-06	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3536	118	2026-09-05	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3537	118	2026-09-04	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3538	118	2026-09-03	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3539	118	2026-09-02	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3540	118	2026-09-01	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3541	119	2026-09-30	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3542	119	2026-09-29	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3543	119	2026-09-28	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3544	119	2026-09-27	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3545	119	2026-09-26	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3546	119	2026-09-25	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3547	119	2026-09-24	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3548	119	2026-09-23	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3549	119	2026-09-22	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3550	119	2026-09-21	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3551	119	2026-09-20	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3552	119	2026-09-19	leave	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3553	119	2026-09-18	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3554	119	2026-09-17	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3555	119	2026-09-16	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3556	119	2026-09-15	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3557	119	2026-09-14	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3558	119	2026-09-13	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3559	119	2026-09-12	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3560	119	2026-09-11	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3561	119	2026-09-10	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3562	119	2026-09-09	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3563	119	2026-09-08	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3564	119	2026-09-07	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3565	119	2026-09-06	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3566	119	2026-09-05	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3567	119	2026-09-04	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3568	119	2026-09-03	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3569	119	2026-09-02	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3570	119	2026-09-01	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3571	120	2026-09-30	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3572	120	2026-09-29	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3573	120	2026-09-28	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3574	120	2026-09-27	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3575	120	2026-09-26	leave	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3576	120	2026-09-25	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3577	120	2026-09-24	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3578	120	2026-09-23	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3579	120	2026-09-22	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3580	120	2026-09-21	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3581	120	2026-09-20	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3582	120	2026-09-19	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3583	120	2026-09-18	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3584	120	2026-09-17	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3585	120	2026-09-16	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3586	120	2026-09-15	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3587	120	2026-09-14	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3588	120	2026-09-13	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3589	120	2026-09-12	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3590	120	2026-09-11	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3591	120	2026-09-10	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3592	120	2026-09-09	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3593	120	2026-09-08	absent	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3594	120	2026-09-07	leave	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3595	120	2026-09-06	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3596	120	2026-09-05	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3597	120	2026-09-04	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3598	120	2026-09-03	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3599	120	2026-09-02	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
3600	120	2026-09-01	present	91ffcd7b-08dd-4031-8571-ff817d3ab016	2026-09-30 21:35:21.017498+05:30
\.


--
-- Data for Name: complaints; Type: TABLE DATA; Schema: smartstay; Owner: sunny
--

COPY smartstay.complaints (id, student_id, hostel_id, category, priority, status, description, created_at, resolved_at) FROM stdin;
1	1	1	Electrical	high	resolved	Demo electrical request submitted for the assigned accommodation.	2026-09-29 21:35:21.017498+05:30	2026-09-30 21:35:21.017498+05:30
2	5	1	Plumbing	medium	open	Demo plumbing request submitted for the assigned accommodation.	2026-09-28 21:35:21.017498+05:30	\N
3	9	1	Wi-Fi	low	open	Demo wi-fi request submitted for the assigned accommodation.	2026-09-27 21:35:21.017498+05:30	\N
4	13	1	Cleanliness	medium	in_progress	Demo cleanliness request submitted for the assigned accommodation.	2026-09-26 21:35:21.017498+05:30	\N
5	17	1	Security	low	resolved	Demo security request submitted for the assigned accommodation.	2026-09-25 21:35:21.017498+05:30	2026-09-26 21:35:21.017498+05:30
6	21	1	Electrical	medium	open	Demo electrical request submitted for the assigned accommodation.	2026-09-24 21:35:21.017498+05:30	\N
7	25	1	Plumbing	high	in_progress	Demo plumbing request submitted for the assigned accommodation.	2026-09-23 21:35:21.017498+05:30	\N
8	29	1	Wi-Fi	medium	open	Demo wi-fi request submitted for the assigned accommodation.	2026-09-22 21:35:21.017498+05:30	\N
9	33	1	Cleanliness	low	resolved	Demo cleanliness request submitted for the assigned accommodation.	2026-09-21 21:35:21.017498+05:30	2026-09-22 21:35:21.017498+05:30
10	37	1	Security	medium	in_progress	Demo security request submitted for the assigned accommodation.	2026-09-20 21:35:21.017498+05:30	\N
11	41	1	Electrical	low	open	Demo electrical request submitted for the assigned accommodation.	2026-09-19 21:35:21.017498+05:30	\N
12	45	1	Plumbing	medium	open	Demo plumbing request submitted for the assigned accommodation.	2026-09-18 21:35:21.017498+05:30	\N
13	49	2	Wi-Fi	high	resolved	Demo wi-fi request submitted for the assigned accommodation.	2026-09-17 21:35:21.017498+05:30	2026-09-18 21:35:21.017498+05:30
14	53	2	Cleanliness	medium	open	Demo cleanliness request submitted for the assigned accommodation.	2026-09-16 21:35:21.017498+05:30	\N
15	57	2	Security	low	open	Demo security request submitted for the assigned accommodation.	2026-09-15 21:35:21.017498+05:30	\N
16	61	2	Electrical	medium	in_progress	Demo electrical request submitted for the assigned accommodation.	2026-09-14 21:35:21.017498+05:30	\N
17	65	2	Plumbing	low	resolved	Demo plumbing request submitted for the assigned accommodation.	2026-09-13 21:35:21.017498+05:30	2026-09-14 21:35:21.017498+05:30
18	69	2	Wi-Fi	medium	open	Demo wi-fi request submitted for the assigned accommodation.	2026-09-12 21:35:21.017498+05:30	\N
19	73	2	Cleanliness	high	in_progress	Demo cleanliness request submitted for the assigned accommodation.	2026-09-11 21:35:21.017498+05:30	\N
20	77	2	Security	medium	open	Demo security request submitted for the assigned accommodation.	2026-09-10 21:35:21.017498+05:30	\N
21	81	2	Electrical	low	resolved	Demo electrical request submitted for the assigned accommodation.	2026-09-09 21:35:21.017498+05:30	2026-09-10 21:35:21.017498+05:30
22	85	2	Plumbing	medium	in_progress	Demo plumbing request submitted for the assigned accommodation.	2026-09-08 21:35:21.017498+05:30	\N
23	89	2	Wi-Fi	low	open	Demo wi-fi request submitted for the assigned accommodation.	2026-09-07 21:35:21.017498+05:30	\N
24	93	2	Cleanliness	medium	open	Demo cleanliness request submitted for the assigned accommodation.	2026-09-06 21:35:21.017498+05:30	\N
25	97	3	Security	high	resolved	Demo security request submitted for the assigned accommodation.	2026-09-05 21:35:21.017498+05:30	2026-09-06 21:35:21.017498+05:30
26	101	3	Electrical	medium	open	Demo electrical request submitted for the assigned accommodation.	2026-09-04 21:35:21.017498+05:30	\N
27	1	1	Plumbing	low	open	Demo plumbing request submitted for the assigned accommodation.	2026-09-03 21:35:21.017498+05:30	\N
28	5	1	Wi-Fi	medium	in_progress	Demo wi-fi request submitted for the assigned accommodation.	2026-09-02 21:35:21.017498+05:30	\N
\.


--
-- Data for Name: fees; Type: TABLE DATA; Schema: smartstay; Owner: sunny
--

COPY smartstay.fees (id, student_id, term, amount_due, amount_paid, due_date, status, created_at) FROM stdin;
1	1	2026 Spring	48000.00	0.00	2026-09-10	pending	2026-09-30 21:35:21.017498+05:30
2	1	2026 Autumn	52000.00	0.00	2026-11-14	pending	2026-09-30 21:35:21.017498+05:30
3	2	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
4	2	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
5	3	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
6	3	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
7	4	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
8	4	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
9	5	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
10	5	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
11	6	2026 Spring	48000.00	0.00	2026-09-10	pending	2026-09-30 21:35:21.017498+05:30
12	6	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
13	7	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
14	7	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
15	8	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
16	8	2026 Autumn	52000.00	0.00	2026-11-14	pending	2026-09-30 21:35:21.017498+05:30
17	9	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
18	9	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
19	10	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
20	10	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
21	11	2026 Spring	48000.00	0.00	2026-09-10	pending	2026-09-30 21:35:21.017498+05:30
22	11	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
23	12	2026 Spring	48000.00	20000.00	2026-09-10	partial	2026-09-30 21:35:21.017498+05:30
24	12	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
25	13	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
26	13	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
27	14	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
28	14	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
29	15	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
30	15	2026 Autumn	52000.00	0.00	2026-11-14	pending	2026-09-30 21:35:21.017498+05:30
31	16	2026 Spring	48000.00	0.00	2026-09-10	pending	2026-09-30 21:35:21.017498+05:30
32	16	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
33	17	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
34	17	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
35	18	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
36	18	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
37	19	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
38	19	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
39	20	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
40	20	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
41	21	2026 Spring	48000.00	0.00	2026-09-10	pending	2026-09-30 21:35:21.017498+05:30
42	21	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
43	22	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
44	22	2026 Autumn	52000.00	0.00	2026-11-14	pending	2026-09-30 21:35:21.017498+05:30
45	23	2026 Spring	48000.00	20000.00	2026-09-10	partial	2026-09-30 21:35:21.017498+05:30
46	23	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
47	24	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
48	24	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
49	25	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
50	25	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
51	26	2026 Spring	48000.00	0.00	2026-09-10	pending	2026-09-30 21:35:21.017498+05:30
52	26	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
53	27	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
54	27	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
55	28	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
56	28	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
57	29	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
58	29	2026 Autumn	52000.00	0.00	2026-11-14	pending	2026-09-30 21:35:21.017498+05:30
59	30	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
60	30	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
61	31	2026 Spring	48000.00	0.00	2026-09-10	pending	2026-09-30 21:35:21.017498+05:30
62	31	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
63	32	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
64	32	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
65	33	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
66	33	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
67	34	2026 Spring	48000.00	20000.00	2026-09-10	partial	2026-09-30 21:35:21.017498+05:30
68	34	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
69	35	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
70	35	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
71	36	2026 Spring	48000.00	0.00	2026-09-10	pending	2026-09-30 21:35:21.017498+05:30
72	36	2026 Autumn	52000.00	0.00	2026-11-14	pending	2026-09-30 21:35:21.017498+05:30
73	37	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
74	37	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
75	38	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
76	38	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
77	39	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
78	39	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
79	40	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
80	40	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
81	41	2026 Spring	48000.00	0.00	2026-09-10	pending	2026-09-30 21:35:21.017498+05:30
82	41	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
83	42	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
84	42	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
85	43	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
86	43	2026 Autumn	52000.00	0.00	2026-11-14	pending	2026-09-30 21:35:21.017498+05:30
87	44	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
88	44	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
89	45	2026 Spring	48000.00	20000.00	2026-09-10	partial	2026-09-30 21:35:21.017498+05:30
90	45	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
91	46	2026 Spring	48000.00	0.00	2026-09-10	pending	2026-09-30 21:35:21.017498+05:30
92	46	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
93	47	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
94	47	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
95	48	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
96	48	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
97	49	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
98	49	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
99	50	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
100	50	2026 Autumn	52000.00	0.00	2026-11-14	pending	2026-09-30 21:35:21.017498+05:30
101	51	2026 Spring	48000.00	0.00	2026-09-10	pending	2026-09-30 21:35:21.017498+05:30
102	51	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
103	52	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
104	52	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
105	53	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
106	53	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
107	54	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
108	54	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
109	55	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
110	55	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
111	56	2026 Spring	48000.00	0.00	2026-09-10	pending	2026-09-30 21:35:21.017498+05:30
112	56	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
113	57	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
114	57	2026 Autumn	52000.00	0.00	2026-11-14	pending	2026-09-30 21:35:21.017498+05:30
115	58	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
116	58	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
117	59	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
118	59	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
119	60	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
120	60	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
121	61	2026 Spring	48000.00	0.00	2026-09-10	pending	2026-09-30 21:35:21.017498+05:30
122	61	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
123	62	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
124	62	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
125	63	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
126	63	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
127	64	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
128	64	2026 Autumn	52000.00	0.00	2026-11-14	pending	2026-09-30 21:35:21.017498+05:30
129	65	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
130	65	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
131	66	2026 Spring	48000.00	0.00	2026-09-10	pending	2026-09-30 21:35:21.017498+05:30
132	66	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
133	67	2026 Spring	48000.00	20000.00	2026-09-10	partial	2026-09-30 21:35:21.017498+05:30
134	67	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
135	68	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
136	68	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
137	69	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
138	69	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
139	70	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
140	70	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
141	71	2026 Spring	48000.00	0.00	2026-09-10	pending	2026-09-30 21:35:21.017498+05:30
142	71	2026 Autumn	52000.00	0.00	2026-11-14	pending	2026-09-30 21:35:21.017498+05:30
143	72	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
144	72	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
145	73	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
146	73	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
147	74	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
148	74	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
149	75	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
150	75	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
151	76	2026 Spring	48000.00	0.00	2026-09-10	pending	2026-09-30 21:35:21.017498+05:30
152	76	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
153	77	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
154	77	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
155	78	2026 Spring	48000.00	20000.00	2026-09-10	partial	2026-09-30 21:35:21.017498+05:30
156	78	2026 Autumn	52000.00	0.00	2026-11-14	pending	2026-09-30 21:35:21.017498+05:30
157	79	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
158	79	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
159	80	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
160	80	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
161	81	2026 Spring	48000.00	0.00	2026-09-10	pending	2026-09-30 21:35:21.017498+05:30
162	81	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
163	82	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
164	82	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
165	83	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
166	83	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
167	84	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
168	84	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
169	85	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
170	85	2026 Autumn	52000.00	0.00	2026-11-14	pending	2026-09-30 21:35:21.017498+05:30
171	86	2026 Spring	48000.00	0.00	2026-09-10	pending	2026-09-30 21:35:21.017498+05:30
172	86	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
173	87	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
174	87	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
175	88	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
176	88	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
177	89	2026 Spring	48000.00	20000.00	2026-09-10	partial	2026-09-30 21:35:21.017498+05:30
178	89	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
179	90	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
180	90	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
181	91	2026 Spring	48000.00	0.00	2026-09-10	pending	2026-09-30 21:35:21.017498+05:30
182	91	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
183	92	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
184	92	2026 Autumn	52000.00	0.00	2026-11-14	pending	2026-09-30 21:35:21.017498+05:30
185	93	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
186	93	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
187	94	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
188	94	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
189	95	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
190	95	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
191	96	2026 Spring	48000.00	0.00	2026-09-10	pending	2026-09-30 21:35:21.017498+05:30
192	96	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
193	97	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
194	97	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
195	98	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
196	98	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
197	99	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
198	99	2026 Autumn	52000.00	0.00	2026-11-14	pending	2026-09-30 21:35:21.017498+05:30
199	100	2026 Spring	48000.00	20000.00	2026-09-10	partial	2026-09-30 21:35:21.017498+05:30
200	100	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
201	101	2026 Spring	48000.00	0.00	2026-09-10	pending	2026-09-30 21:35:21.017498+05:30
202	101	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
203	102	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
204	102	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
205	103	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
206	103	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
207	104	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
208	104	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
209	105	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
210	105	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
211	106	2026 Spring	48000.00	0.00	2026-09-10	pending	2026-09-30 21:35:21.017498+05:30
212	106	2026 Autumn	52000.00	0.00	2026-11-14	pending	2026-09-30 21:35:21.017498+05:30
213	107	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
214	107	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
215	108	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
216	108	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
217	109	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
218	109	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
219	110	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
220	110	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
221	111	2026 Spring	48000.00	0.00	2026-09-10	pending	2026-09-30 21:35:21.017498+05:30
222	111	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
223	112	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
224	112	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
225	113	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
226	113	2026 Autumn	52000.00	0.00	2026-11-14	pending	2026-09-30 21:35:21.017498+05:30
227	114	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
228	114	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
229	115	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
230	115	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
231	116	2026 Spring	48000.00	0.00	2026-09-10	pending	2026-09-30 21:35:21.017498+05:30
232	116	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
233	117	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
234	117	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
235	118	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
236	118	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
237	119	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
238	119	2026 Autumn	52000.00	52000.00	2026-11-14	paid	2026-09-30 21:35:21.017498+05:30
239	120	2026 Spring	48000.00	48000.00	2026-09-10	paid	2026-09-30 21:35:21.017498+05:30
240	120	2026 Autumn	52000.00	0.00	2026-11-14	pending	2026-09-30 21:35:21.017498+05:30
\.


--
-- Data for Name: hostels; Type: TABLE DATA; Schema: smartstay; Owner: sunny
--

COPY smartstay.hostels (id, university_id, name, code, gender, created_at) FROM stdin;
1	1	Maple Residence	MAP	women	2026-09-30 21:35:21.017498+05:30
2	1	Cedar Residence	CED	men	2026-09-30 21:35:21.017498+05:30
3	1	Horizon Residence	HOR	all	2026-09-30 21:35:21.017498+05:30
\.


--
-- Data for Name: rooms; Type: TABLE DATA; Schema: smartstay; Owner: sunny
--

COPY smartstay.rooms (id, hostel_id, room_number, floor, capacity, created_at) FROM stdin;
1	1	101	1	4	2026-09-30 21:35:21.017498+05:30
2	1	102	1	4	2026-09-30 21:35:21.017498+05:30
3	1	103	1	4	2026-09-30 21:35:21.017498+05:30
4	1	104	1	4	2026-09-30 21:35:21.017498+05:30
5	1	105	1	4	2026-09-30 21:35:21.017498+05:30
6	1	106	1	4	2026-09-30 21:35:21.017498+05:30
7	1	207	2	4	2026-09-30 21:35:21.017498+05:30
8	1	208	2	4	2026-09-30 21:35:21.017498+05:30
9	1	209	2	4	2026-09-30 21:35:21.017498+05:30
10	1	210	2	4	2026-09-30 21:35:21.017498+05:30
11	1	211	2	4	2026-09-30 21:35:21.017498+05:30
12	1	212	2	4	2026-09-30 21:35:21.017498+05:30
13	2	101	1	4	2026-09-30 21:35:21.017498+05:30
14	2	102	1	4	2026-09-30 21:35:21.017498+05:30
15	2	103	1	4	2026-09-30 21:35:21.017498+05:30
16	2	104	1	4	2026-09-30 21:35:21.017498+05:30
17	2	105	1	4	2026-09-30 21:35:21.017498+05:30
18	2	106	1	4	2026-09-30 21:35:21.017498+05:30
19	2	207	2	4	2026-09-30 21:35:21.017498+05:30
20	2	208	2	4	2026-09-30 21:35:21.017498+05:30
21	2	209	2	4	2026-09-30 21:35:21.017498+05:30
22	2	210	2	4	2026-09-30 21:35:21.017498+05:30
23	2	211	2	4	2026-09-30 21:35:21.017498+05:30
24	2	212	2	4	2026-09-30 21:35:21.017498+05:30
25	3	101	1	4	2026-09-30 21:35:21.017498+05:30
26	3	102	1	4	2026-09-30 21:35:21.017498+05:30
27	3	103	1	4	2026-09-30 21:35:21.017498+05:30
28	3	104	1	4	2026-09-30 21:35:21.017498+05:30
29	3	105	1	4	2026-09-30 21:35:21.017498+05:30
30	3	106	1	4	2026-09-30 21:35:21.017498+05:30
31	3	207	2	4	2026-09-30 21:35:21.017498+05:30
32	3	208	2	4	2026-09-30 21:35:21.017498+05:30
33	3	209	2	4	2026-09-30 21:35:21.017498+05:30
34	3	210	2	4	2026-09-30 21:35:21.017498+05:30
35	3	211	2	4	2026-09-30 21:35:21.017498+05:30
36	3	212	2	4	2026-09-30 21:35:21.017498+05:30
\.


--
-- Data for Name: students; Type: TABLE DATA; Schema: smartstay; Owner: sunny
--

COPY smartstay.students (id, user_id, university_id, enrollment_no, full_name, department, year_of_study, gender, phone, guardian_name, created_at) FROM stdin;
1	a1419e44-90bc-4095-84df-417daab32c98	1	STU2026001	Aanya Agarwal	Computer Science	1	woman	+91 9870000000	Agarwal Family	2026-09-30 21:35:21.017498+05:30
2	0be4c731-9209-4413-91f4-93a13d9984ee	1	STU2026002	Anika Agarwal	Electronics	2	woman	+91 9870000001	Bansal Family	2026-09-30 21:35:21.017498+05:30
3	661e652f-dc0b-48f7-b3c5-9b297506af65	1	STU2026003	Aditi Bansal	Mechanical	3	woman	+91 9870000002	Chatterjee Family	2026-09-30 21:35:21.017498+05:30
4	b49122e8-7e72-474e-846e-d4fd077f20dd	1	STU2026004	Aishwarya Bansal	Civil	4	woman	+91 9870000003	Das Family	2026-09-30 21:35:21.017498+05:30
5	81b9830a-8534-4653-81c0-e5a7700aef45	1	STU2026005	Akshara Chatterjee	Business Administration	1	woman	+91 9870000004	Gupta Family	2026-09-30 21:35:21.017498+05:30
6	b8a2299e-865f-456e-a436-8890909da576	1	STU2026006	Amrita Chatterjee	Design	2	woman	+91 9870000005	Iyer Family	2026-09-30 21:35:21.017498+05:30
7	90c84a8e-c009-4f23-85dd-036ad53d03b7	1	STU2026007	Ananya Das	Computer Science	3	woman	+91 9870000006	Jain Family	2026-09-30 21:35:21.017498+05:30
8	ba807921-6166-4b7d-96e0-687fabf9c3da	1	STU2026008	Bhavya Das	Electronics	4	woman	+91 9870000007	Kapoor Family	2026-09-30 21:35:21.017498+05:30
9	0803a83e-a9b1-4e61-a45b-ebfaabfc0043	1	STU2026009	Charvi Gupta	Mechanical	1	woman	+91 9870000008	Mehta Family	2026-09-30 21:35:21.017498+05:30
10	95298834-7eac-46e0-86ee-cb3b5cb88c21	1	STU2026010	Diya Gupta	Civil	2	woman	+91 9870000009	Nair Family	2026-09-30 21:35:21.017498+05:30
11	f00c389b-ef57-41fa-bf87-712a35e408f6	1	STU2026011	Esha Iyer	Business Administration	3	woman	+91 9870000010	Patel Family	2026-09-30 21:35:21.017498+05:30
12	b5c6204f-f3dc-4fab-99de-f6fb29fa8f3a	1	STU2026012	Ishita Iyer	Design	4	woman	+91 9870000011	Rao Family	2026-09-30 21:35:21.017498+05:30
13	6ca01316-57aa-42d3-9d2a-b18b238e25ff	1	STU2026013	Jhanvi Jain	Computer Science	1	woman	+91 9870000012	Sharma Family	2026-09-30 21:35:21.017498+05:30
14	18ee8b9b-8c41-4ba7-8e6a-d919f4dcdde2	1	STU2026014	Kavya Jain	Electronics	2	woman	+91 9870000013	Singh Family	2026-09-30 21:35:21.017498+05:30
15	053f7819-69d7-485c-9375-7c57944c9601	1	STU2026015	Khushi Kapoor	Mechanical	3	woman	+91 9870000014	Verma Family	2026-09-30 21:35:21.017498+05:30
16	0026ed14-0e10-48b8-839a-8d2a3189d908	1	STU2026016	Meera Kapoor	Civil	4	woman	+91 9870000015	Agarwal Family	2026-09-30 21:35:21.017498+05:30
17	f8cb06a2-8ae5-4ec3-903d-1c730eec2d0b	1	STU2026017	Myra Mehta	Business Administration	1	woman	+91 9870000016	Bansal Family	2026-09-30 21:35:21.017498+05:30
18	64ee467c-c716-4670-977f-946dec95a1ae	1	STU2026018	Naina Mehta	Design	2	woman	+91 9870000017	Chatterjee Family	2026-09-30 21:35:21.017498+05:30
19	bddaa2b7-701e-4cd2-a4e4-2a308e19e96f	1	STU2026019	Navya Nair	Computer Science	3	woman	+91 9870000018	Das Family	2026-09-30 21:35:21.017498+05:30
20	cb1042c8-bc2b-45d9-96ff-96f1a65c5cf6	1	STU2026020	Nisha Nair	Electronics	4	woman	+91 9870000019	Gupta Family	2026-09-30 21:35:21.017498+05:30
21	fec90480-7f67-4a1a-83ad-a39998d4c15e	1	STU2026021	Pooja Patel	Mechanical	1	woman	+91 9870000020	Iyer Family	2026-09-30 21:35:21.017498+05:30
22	5c7bbca1-5f01-46b9-8b81-7dffc8161e5a	1	STU2026022	Prisha Patel	Civil	2	woman	+91 9870000021	Jain Family	2026-09-30 21:35:21.017498+05:30
23	2fced502-b3a2-48c4-9c25-219ae2e83575	1	STU2026023	Rhea Rao	Business Administration	3	woman	+91 9870000022	Kapoor Family	2026-09-30 21:35:21.017498+05:30
24	517d3d65-be6d-4edf-b9e6-7e53b88c6099	1	STU2026024	Riya Rao	Design	4	woman	+91 9870000023	Mehta Family	2026-09-30 21:35:21.017498+05:30
25	d165a939-c884-4195-b587-25c7ead4d845	1	STU2026025	Saanvi Sharma	Computer Science	1	woman	+91 9870000024	Nair Family	2026-09-30 21:35:21.017498+05:30
26	8ea1f6af-9a6f-412a-9f2b-af25b7be63cc	1	STU2026026	Sakshi Sharma	Electronics	2	woman	+91 9870000025	Patel Family	2026-09-30 21:35:21.017498+05:30
27	869dd372-96f5-464c-b332-10442b228001	1	STU2026027	Shreya Singh	Mechanical	3	woman	+91 9870000026	Rao Family	2026-09-30 21:35:21.017498+05:30
28	c9c0ae71-81e3-4ee2-8ddb-0fa52ffdf931	1	STU2026028	Siya Singh	Civil	4	woman	+91 9870000027	Sharma Family	2026-09-30 21:35:21.017498+05:30
29	ccdfb6cf-10c3-42f1-aca1-75e5382733b0	1	STU2026029	Sneha Verma	Business Administration	1	woman	+91 9870000028	Singh Family	2026-09-30 21:35:21.017498+05:30
30	6f7e5800-3fa7-4083-809c-13879fc7d96d	1	STU2026030	Tanvi Verma	Design	2	woman	+91 9870000029	Verma Family	2026-09-30 21:35:21.017498+05:30
31	cf8a98e5-ae51-4de2-a689-f340fb7a7852	1	STU2026031	Aanya Agarwal	Computer Science	3	woman	+91 9870000030	Agarwal Family	2026-09-30 21:35:21.017498+05:30
32	bbdbc84f-75cc-4271-9d83-69db171ff56d	1	STU2026032	Anika Agarwal	Electronics	4	woman	+91 9870000031	Bansal Family	2026-09-30 21:35:21.017498+05:30
33	7e72cbb0-7d22-42a3-9f1a-7cf7b592743a	1	STU2026033	Aditi Bansal	Mechanical	1	woman	+91 9870000032	Chatterjee Family	2026-09-30 21:35:21.017498+05:30
34	6965567d-fb5d-4191-a8c9-e027c9566e27	1	STU2026034	Aishwarya Bansal	Civil	2	woman	+91 9870000033	Das Family	2026-09-30 21:35:21.017498+05:30
35	231b2f05-9ba1-48bf-a0e4-0f3da8c29660	1	STU2026035	Akshara Chatterjee	Business Administration	3	woman	+91 9870000034	Gupta Family	2026-09-30 21:35:21.017498+05:30
36	ecddc1bc-cc35-4399-a83d-e77bf8497b25	1	STU2026036	Amrita Chatterjee	Design	4	woman	+91 9870000035	Iyer Family	2026-09-30 21:35:21.017498+05:30
37	965921fe-e518-4564-8cc0-e5dffa68600d	1	STU2026037	Ananya Das	Computer Science	1	woman	+91 9870000036	Jain Family	2026-09-30 21:35:21.017498+05:30
38	49f5dba4-befa-4f69-8a0e-8731d09ac1b5	1	STU2026038	Bhavya Das	Electronics	2	woman	+91 9870000037	Kapoor Family	2026-09-30 21:35:21.017498+05:30
39	a3ee780b-9a5c-46f4-a883-b5db0b557cb7	1	STU2026039	Charvi Gupta	Mechanical	3	woman	+91 9870000038	Mehta Family	2026-09-30 21:35:21.017498+05:30
40	91a6f835-0755-4d95-8c37-cd104b99c8d6	1	STU2026040	Diya Gupta	Civil	4	woman	+91 9870000039	Nair Family	2026-09-30 21:35:21.017498+05:30
41	1806b259-0af0-4c80-b3e8-c54bb1ba21e6	1	STU2026041	Esha Iyer	Business Administration	1	woman	+91 9870000040	Patel Family	2026-09-30 21:35:21.017498+05:30
42	41912b3b-fdaa-47a9-9603-4ee0e8adbd97	1	STU2026042	Ishita Iyer	Design	2	woman	+91 9870000041	Rao Family	2026-09-30 21:35:21.017498+05:30
43	8b13b1cb-87c0-4634-9cbc-c982c994764b	1	STU2026043	Jhanvi Jain	Computer Science	3	woman	+91 9870000042	Sharma Family	2026-09-30 21:35:21.017498+05:30
44	b08e5ca0-a1fa-448d-9585-d92a607c6209	1	STU2026044	Kavya Jain	Electronics	4	woman	+91 9870000043	Singh Family	2026-09-30 21:35:21.017498+05:30
45	9a84d7c9-560c-465a-ac05-0ed7ab1e81f7	1	STU2026045	Khushi Kapoor	Mechanical	1	woman	+91 9870000044	Verma Family	2026-09-30 21:35:21.017498+05:30
46	c8721db3-a2a6-410f-bf9e-9f7a25efeae8	1	STU2026046	Meera Kapoor	Civil	2	woman	+91 9870000045	Agarwal Family	2026-09-30 21:35:21.017498+05:30
47	599b908f-2b9b-45c0-8f8e-c8314a544491	1	STU2026047	Myra Mehta	Business Administration	3	woman	+91 9870000046	Bansal Family	2026-09-30 21:35:21.017498+05:30
48	36811ea7-887b-49da-9519-65ec0a53b46f	1	STU2026048	Naina Mehta	Design	4	woman	+91 9870000047	Chatterjee Family	2026-09-30 21:35:21.017498+05:30
49	c374cf8f-96ec-41fe-b7c3-4b08739381c2	1	STU2026049	Navya Nair	Computer Science	1	woman	+91 9870000048	Das Family	2026-09-30 21:35:21.017498+05:30
50	cf0fa8a6-d7c4-462c-ace3-d0a77c739fcf	1	STU2026050	Nisha Nair	Electronics	2	woman	+91 9870000049	Gupta Family	2026-09-30 21:35:21.017498+05:30
51	efc6d191-0ec5-4d9c-b7b0-d24515550a4f	1	STU2026051	Pooja Patel	Mechanical	3	woman	+91 9870000050	Iyer Family	2026-09-30 21:35:21.017498+05:30
52	0903805a-ec39-4142-93e6-af5fffc0fd61	1	STU2026052	Prisha Patel	Civil	4	woman	+91 9870000051	Jain Family	2026-09-30 21:35:21.017498+05:30
53	8f6857ac-d2ff-42c1-8ff8-f07e2e977684	1	STU2026053	Rhea Rao	Business Administration	1	woman	+91 9870000052	Kapoor Family	2026-09-30 21:35:21.017498+05:30
54	de047c9e-76ae-4aa8-a562-9898f7da9f13	1	STU2026054	Riya Rao	Design	2	woman	+91 9870000053	Mehta Family	2026-09-30 21:35:21.017498+05:30
55	4fc7d659-252f-4bb4-b764-d18e24d01532	1	STU2026055	Saanvi Sharma	Computer Science	3	woman	+91 9870000054	Nair Family	2026-09-30 21:35:21.017498+05:30
56	18469caa-e98b-48a0-b511-19f2f37f58c9	1	STU2026056	Sakshi Sharma	Electronics	4	woman	+91 9870000055	Patel Family	2026-09-30 21:35:21.017498+05:30
57	703c6582-0262-4774-8d12-8ff324eedbdd	1	STU2026057	Shreya Singh	Mechanical	1	woman	+91 9870000056	Rao Family	2026-09-30 21:35:21.017498+05:30
58	b7e78c5f-082b-4cdb-a8e0-059042e437e9	1	STU2026058	Siya Singh	Civil	2	woman	+91 9870000057	Sharma Family	2026-09-30 21:35:21.017498+05:30
59	6fe61ff9-4cd7-44e0-9a87-0e1415c58113	1	STU2026059	Sneha Verma	Business Administration	3	woman	+91 9870000058	Singh Family	2026-09-30 21:35:21.017498+05:30
60	2617b6b6-74ed-4954-8296-5c95e9691e31	1	STU2026060	Tanvi Verma	Design	4	woman	+91 9870000059	Verma Family	2026-09-30 21:35:21.017498+05:30
61	2631f0c2-3d89-408a-a495-365591dfc6f8	1	STU2026061	Aarav Agarwal	Computer Science	1	man	+91 9870000060	Agarwal Family	2026-09-30 21:35:21.017498+05:30
62	02e49dca-3fa3-4407-a92e-fd2cf0dd1588	1	STU2026062	Aditya Agarwal	Electronics	2	man	+91 9870000061	Bansal Family	2026-09-30 21:35:21.017498+05:30
63	0000ddb5-88d4-48bf-a714-6a955880496a	1	STU2026063	Akash Bansal	Mechanical	3	man	+91 9870000062	Chatterjee Family	2026-09-30 21:35:21.017498+05:30
64	89f7cd56-fc50-48e7-8fd7-300a484b6fc4	1	STU2026064	Arjun Bansal	Civil	4	man	+91 9870000063	Das Family	2026-09-30 21:35:21.017498+05:30
65	4d86f2c2-fc23-4c7e-9bc9-070a50a4c0d4	1	STU2026065	Aryan Chatterjee	Business Administration	1	man	+91 9870000064	Gupta Family	2026-09-30 21:35:21.017498+05:30
66	2fd3012b-a516-478e-81fc-d4c5bc993fbe	1	STU2026066	Dev Chatterjee	Design	2	man	+91 9870000065	Iyer Family	2026-09-30 21:35:21.017498+05:30
67	6d66fba9-63da-4e31-b932-77950ec4cecb	1	STU2026067	Dhruv Das	Computer Science	3	man	+91 9870000066	Jain Family	2026-09-30 21:35:21.017498+05:30
68	bef5031c-e885-4540-89b8-7985bc9a9610	1	STU2026068	Harsh Das	Electronics	4	man	+91 9870000067	Kapoor Family	2026-09-30 21:35:21.017498+05:30
69	c1f3f129-7755-4bf9-9a38-7448b336a3db	1	STU2026069	Ishaan Gupta	Mechanical	1	man	+91 9870000068	Mehta Family	2026-09-30 21:35:21.017498+05:30
70	5f48c9d2-7212-4a08-a3d2-b43b609932b5	1	STU2026070	Kabir Gupta	Civil	2	man	+91 9870000069	Nair Family	2026-09-30 21:35:21.017498+05:30
71	7fcee3c0-cb12-40a4-8b31-f09fd90bb1e6	1	STU2026071	Karan Iyer	Business Administration	3	man	+91 9870000070	Patel Family	2026-09-30 21:35:21.017498+05:30
72	8970c25e-a148-4862-a804-7c7e9abb211a	1	STU2026072	Karthik Iyer	Design	4	man	+91 9870000071	Rao Family	2026-09-30 21:35:21.017498+05:30
73	6bea42f4-f865-4fb5-8f65-76089af7952f	1	STU2026073	Manav Jain	Computer Science	1	man	+91 9870000072	Sharma Family	2026-09-30 21:35:21.017498+05:30
74	d8a8e332-d8b6-4309-ae43-d7817ab33b01	1	STU2026074	Mohit Jain	Electronics	2	man	+91 9870000073	Singh Family	2026-09-30 21:35:21.017498+05:30
75	48b013b6-4ba5-4460-a396-b44c20b8763f	1	STU2026075	Nikhil Kapoor	Mechanical	3	man	+91 9870000074	Verma Family	2026-09-30 21:35:21.017498+05:30
76	2abe8b91-0e92-47f1-b716-264248cf7fb1	1	STU2026076	Pranav Kapoor	Civil	4	man	+91 9870000075	Agarwal Family	2026-09-30 21:35:21.017498+05:30
77	20b09d5e-2c49-4419-93a5-4d8ca8581d76	1	STU2026077	Rahul Mehta	Business Administration	1	man	+91 9870000076	Bansal Family	2026-09-30 21:35:21.017498+05:30
78	bbabb6e7-e5fc-4f34-98f0-0581e54a0952	1	STU2026078	Rohan Mehta	Design	2	man	+91 9870000077	Chatterjee Family	2026-09-30 21:35:21.017498+05:30
79	e21ca6a4-2481-4eac-b7e2-6df2e2f914de	1	STU2026079	Sahil Nair	Computer Science	3	man	+91 9870000078	Das Family	2026-09-30 21:35:21.017498+05:30
80	d15f892d-7af2-48c1-924a-bbd420401b90	1	STU2026080	Shaurya Nair	Electronics	4	man	+91 9870000079	Gupta Family	2026-09-30 21:35:21.017498+05:30
81	c3a1006e-c70b-488e-b610-f1a2b3a06cc3	1	STU2026081	Siddharth Patel	Mechanical	1	man	+91 9870000080	Iyer Family	2026-09-30 21:35:21.017498+05:30
82	f998856d-1834-44cd-af20-9e9f585600aa	1	STU2026082	Tanish Patel	Civil	2	man	+91 9870000081	Jain Family	2026-09-30 21:35:21.017498+05:30
83	1148b2b5-153a-46dc-bc73-e11c5f606f4c	1	STU2026083	Uday Rao	Business Administration	3	man	+91 9870000082	Kapoor Family	2026-09-30 21:35:21.017498+05:30
84	63f8c105-3cb2-4779-aee4-459bf2970dba	1	STU2026084	Varun Rao	Design	4	man	+91 9870000083	Mehta Family	2026-09-30 21:35:21.017498+05:30
85	07011679-8488-43a4-9b62-1890745e1e71	1	STU2026085	Ved Sharma	Computer Science	1	man	+91 9870000084	Nair Family	2026-09-30 21:35:21.017498+05:30
86	8be4e95f-d8bc-4f34-a065-03cf7a786768	1	STU2026086	Vihaan Sharma	Electronics	2	man	+91 9870000085	Patel Family	2026-09-30 21:35:21.017498+05:30
87	a5dd01a4-3e6b-4f5c-a716-854b9341a7fd	1	STU2026087	Vikram Singh	Mechanical	3	man	+91 9870000086	Rao Family	2026-09-30 21:35:21.017498+05:30
88	b4290deb-a97f-480d-b808-09f1796cc2ee	1	STU2026088	Yash Singh	Civil	4	man	+91 9870000087	Sharma Family	2026-09-30 21:35:21.017498+05:30
89	9fb852f7-5388-4e94-b314-1d87973b57d6	1	STU2026089	Yuvan Verma	Business Administration	1	man	+91 9870000088	Singh Family	2026-09-30 21:35:21.017498+05:30
90	6584e2f3-e908-480d-b59b-3189b8fcd8fe	1	STU2026090	Zain Verma	Design	2	man	+91 9870000089	Verma Family	2026-09-30 21:35:21.017498+05:30
91	258a8836-a830-49b9-837d-ea2d0a183fe1	1	STU2026091	Aarav Agarwal	Computer Science	3	man	+91 9870000090	Agarwal Family	2026-09-30 21:35:21.017498+05:30
92	d5060e0e-7c8d-42be-84eb-c93188526338	1	STU2026092	Aditya Agarwal	Electronics	4	man	+91 9870000091	Bansal Family	2026-09-30 21:35:21.017498+05:30
93	efdff76c-17a1-4eb1-84ce-efef4a4fed92	1	STU2026093	Akash Bansal	Mechanical	1	man	+91 9870000092	Chatterjee Family	2026-09-30 21:35:21.017498+05:30
94	f2ac74f1-8ac5-49c7-848f-e59bb7a1b980	1	STU2026094	Arjun Bansal	Civil	2	man	+91 9870000093	Das Family	2026-09-30 21:35:21.017498+05:30
95	8cabb553-5eb5-4ceb-b7c3-4f03e8d09d5b	1	STU2026095	Aryan Chatterjee	Business Administration	3	man	+91 9870000094	Gupta Family	2026-09-30 21:35:21.017498+05:30
96	3709c159-7741-4c9b-948f-d2f8be33bbbc	1	STU2026096	Dev Chatterjee	Design	4	man	+91 9870000095	Iyer Family	2026-09-30 21:35:21.017498+05:30
97	fec81e51-3936-42b9-896f-9aadcf4a71c5	1	STU2026097	Dhruv Das	Computer Science	1	man	+91 9870000096	Jain Family	2026-09-30 21:35:21.017498+05:30
98	9ca6eb81-4bf6-4e43-9c68-f6e5db9d33d6	1	STU2026098	Harsh Das	Electronics	2	man	+91 9870000097	Kapoor Family	2026-09-30 21:35:21.017498+05:30
99	372a55cf-f658-4e49-9804-db5bbb049164	1	STU2026099	Ishaan Gupta	Mechanical	3	man	+91 9870000098	Mehta Family	2026-09-30 21:35:21.017498+05:30
100	74bcd124-be66-4824-acef-119234fc1e55	1	STU2026100	Kabir Gupta	Civil	4	man	+91 9870000099	Nair Family	2026-09-30 21:35:21.017498+05:30
101	35106327-8645-42cd-b762-caff9f734d5e	1	STU2026101	Karan Iyer	Business Administration	1	man	+91 9870000100	Patel Family	2026-09-30 21:35:21.017498+05:30
102	7ee01a01-b906-4ae1-89d8-aa9000a03909	1	STU2026102	Karthik Iyer	Design	2	man	+91 9870000101	Rao Family	2026-09-30 21:35:21.017498+05:30
103	0b8efe59-6555-4c8d-86d5-ed11bf51eab1	1	STU2026103	Manav Jain	Computer Science	3	man	+91 9870000102	Sharma Family	2026-09-30 21:35:21.017498+05:30
104	a5c17d08-605b-42b9-b604-b1643446af9d	1	STU2026104	Mohit Jain	Electronics	4	man	+91 9870000103	Singh Family	2026-09-30 21:35:21.017498+05:30
105	243af1c0-6b39-4501-9667-139304b91efb	1	STU2026105	Nikhil Kapoor	Mechanical	1	man	+91 9870000104	Verma Family	2026-09-30 21:35:21.017498+05:30
106	b87aff3c-66ed-4274-9ffa-c04c2100028f	1	STU2026106	Pranav Kapoor	Civil	2	man	+91 9870000105	Agarwal Family	2026-09-30 21:35:21.017498+05:30
107	8f4de238-6f59-435f-9946-e7118a9d64ac	1	STU2026107	Rahul Mehta	Business Administration	3	man	+91 9870000106	Bansal Family	2026-09-30 21:35:21.017498+05:30
108	51693123-9e37-4bf8-8849-1c055fb40b68	1	STU2026108	Rohan Mehta	Design	4	man	+91 9870000107	Chatterjee Family	2026-09-30 21:35:21.017498+05:30
109	46c00b36-47f5-4612-a4d2-bf12ddd30a34	1	STU2026109	Sahil Nair	Computer Science	1	man	+91 9870000108	Das Family	2026-09-30 21:35:21.017498+05:30
110	5eb533ae-59bf-4196-9f80-5eda198bdd51	1	STU2026110	Shaurya Nair	Electronics	2	man	+91 9870000109	Gupta Family	2026-09-30 21:35:21.017498+05:30
111	e7292a93-2a47-41e9-86e2-6b679fb996ab	1	STU2026111	Siddharth Patel	Mechanical	3	man	+91 9870000110	Iyer Family	2026-09-30 21:35:21.017498+05:30
112	29590281-82f6-44dc-b04a-1cf830b280a4	1	STU2026112	Tanish Patel	Civil	4	man	+91 9870000111	Jain Family	2026-09-30 21:35:21.017498+05:30
113	6a3bb426-4da9-4643-a1a4-bcedf14ccf72	1	STU2026113	Uday Rao	Business Administration	1	man	+91 9870000112	Kapoor Family	2026-09-30 21:35:21.017498+05:30
114	d33bdfe6-2d51-4596-b64d-0c9f70e678b3	1	STU2026114	Varun Rao	Design	2	man	+91 9870000113	Mehta Family	2026-09-30 21:35:21.017498+05:30
115	f04d8f1a-0412-4996-bc49-f3c9a6af2c1d	1	STU2026115	Ved Sharma	Computer Science	3	man	+91 9870000114	Nair Family	2026-09-30 21:35:21.017498+05:30
116	ca503c8d-ddbb-42ab-afdd-17e2c7cb98da	1	STU2026116	Vihaan Sharma	Electronics	4	man	+91 9870000115	Patel Family	2026-09-30 21:35:21.017498+05:30
117	68aeefae-af62-4999-bbac-a8941a9e0ac1	1	STU2026117	Vikram Singh	Mechanical	1	man	+91 9870000116	Rao Family	2026-09-30 21:35:21.017498+05:30
118	daedfe9d-a685-4519-8c1c-b05f720deea4	1	STU2026118	Yash Singh	Civil	2	man	+91 9870000117	Sharma Family	2026-09-30 21:35:21.017498+05:30
119	15850d35-cf28-4083-8e4a-afbcddefd03c	1	STU2026119	Yuvan Verma	Business Administration	3	man	+91 9870000118	Singh Family	2026-09-30 21:35:21.017498+05:30
120	8272c4df-3a9f-406a-b861-a08eaccc3e74	1	STU2026120	Zain Verma	Design	4	man	+91 9870000119	Verma Family	2026-09-30 21:35:21.017498+05:30
\.


--
-- Data for Name: universities; Type: TABLE DATA; Schema: smartstay; Owner: sunny
--

COPY smartstay.universities (id, name, code, city, created_at) FROM stdin;
1	SmartStay Demo University	SSDU	Bengaluru	2026-09-30 21:35:21.017498+05:30
\.


--
-- Data for Name: university_admins; Type: TABLE DATA; Schema: smartstay; Owner: sunny
--

COPY smartstay.university_admins (id, user_id, university_id, full_name, created_at) FROM stdin;
1	91ffcd7b-08dd-4031-8571-ff817d3ab016	1	Dr. Nandita Rao	2026-09-30 21:35:21.017498+05:30
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: smartstay; Owner: sunny
--

COPY smartstay.users (id, email, password_hash, role, is_active, last_login_at, created_at) FROM stdin;
91ffcd7b-08dd-4031-8571-ff817d3ab016	admin@smartstay.demo	$2b$12$09lzh4nYEWOXeJEkPg1lpuI3/JgAho3rR1JqRcKeRTEkyDPVNXX1W	university	t	\N	2026-09-30 21:35:21.017498+05:30
8c52851d-50e6-4a27-843a-e438a8e5f5d8	warden.arya@smartstay.demo	$2b$12$hbBw2iuAYkw/hDX12zeS3e99teSmnWjeZneU5LMfctyrF1wpbfmgC	warden	t	\N	2026-09-30 21:35:21.017498+05:30
7f98f45c-3038-4f53-8476-aa2381d1a7c3	warden.khan@smartstay.demo	$2b$12$hbBw2iuAYkw/hDX12zeS3e99teSmnWjeZneU5LMfctyrF1wpbfmgC	warden	t	\N	2026-09-30 21:35:21.017498+05:30
a1419e44-90bc-4095-84df-417daab32c98	student001@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
0be4c731-9209-4413-91f4-93a13d9984ee	student002@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
661e652f-dc0b-48f7-b3c5-9b297506af65	student003@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
b49122e8-7e72-474e-846e-d4fd077f20dd	student004@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
81b9830a-8534-4653-81c0-e5a7700aef45	student005@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
b8a2299e-865f-456e-a436-8890909da576	student006@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
90c84a8e-c009-4f23-85dd-036ad53d03b7	student007@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
ba807921-6166-4b7d-96e0-687fabf9c3da	student008@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
0803a83e-a9b1-4e61-a45b-ebfaabfc0043	student009@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
95298834-7eac-46e0-86ee-cb3b5cb88c21	student010@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
f00c389b-ef57-41fa-bf87-712a35e408f6	student011@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
b5c6204f-f3dc-4fab-99de-f6fb29fa8f3a	student012@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
6ca01316-57aa-42d3-9d2a-b18b238e25ff	student013@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
18ee8b9b-8c41-4ba7-8e6a-d919f4dcdde2	student014@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
053f7819-69d7-485c-9375-7c57944c9601	student015@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
0026ed14-0e10-48b8-839a-8d2a3189d908	student016@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
f8cb06a2-8ae5-4ec3-903d-1c730eec2d0b	student017@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
64ee467c-c716-4670-977f-946dec95a1ae	student018@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
bddaa2b7-701e-4cd2-a4e4-2a308e19e96f	student019@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
cb1042c8-bc2b-45d9-96ff-96f1a65c5cf6	student020@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
fec90480-7f67-4a1a-83ad-a39998d4c15e	student021@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
5c7bbca1-5f01-46b9-8b81-7dffc8161e5a	student022@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
2fced502-b3a2-48c4-9c25-219ae2e83575	student023@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
517d3d65-be6d-4edf-b9e6-7e53b88c6099	student024@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
d165a939-c884-4195-b587-25c7ead4d845	student025@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
8ea1f6af-9a6f-412a-9f2b-af25b7be63cc	student026@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
869dd372-96f5-464c-b332-10442b228001	student027@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
c9c0ae71-81e3-4ee2-8ddb-0fa52ffdf931	student028@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
ccdfb6cf-10c3-42f1-aca1-75e5382733b0	student029@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
6f7e5800-3fa7-4083-809c-13879fc7d96d	student030@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
cf8a98e5-ae51-4de2-a689-f340fb7a7852	student031@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
bbdbc84f-75cc-4271-9d83-69db171ff56d	student032@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
7e72cbb0-7d22-42a3-9f1a-7cf7b592743a	student033@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
6965567d-fb5d-4191-a8c9-e027c9566e27	student034@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
231b2f05-9ba1-48bf-a0e4-0f3da8c29660	student035@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
ecddc1bc-cc35-4399-a83d-e77bf8497b25	student036@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
965921fe-e518-4564-8cc0-e5dffa68600d	student037@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
49f5dba4-befa-4f69-8a0e-8731d09ac1b5	student038@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
a3ee780b-9a5c-46f4-a883-b5db0b557cb7	student039@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
91a6f835-0755-4d95-8c37-cd104b99c8d6	student040@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
1806b259-0af0-4c80-b3e8-c54bb1ba21e6	student041@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
41912b3b-fdaa-47a9-9603-4ee0e8adbd97	student042@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
8b13b1cb-87c0-4634-9cbc-c982c994764b	student043@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
b08e5ca0-a1fa-448d-9585-d92a607c6209	student044@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
9a84d7c9-560c-465a-ac05-0ed7ab1e81f7	student045@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
c8721db3-a2a6-410f-bf9e-9f7a25efeae8	student046@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
599b908f-2b9b-45c0-8f8e-c8314a544491	student047@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
36811ea7-887b-49da-9519-65ec0a53b46f	student048@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
c374cf8f-96ec-41fe-b7c3-4b08739381c2	student049@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
cf0fa8a6-d7c4-462c-ace3-d0a77c739fcf	student050@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
efc6d191-0ec5-4d9c-b7b0-d24515550a4f	student051@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
0903805a-ec39-4142-93e6-af5fffc0fd61	student052@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
8f6857ac-d2ff-42c1-8ff8-f07e2e977684	student053@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
de047c9e-76ae-4aa8-a562-9898f7da9f13	student054@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
4fc7d659-252f-4bb4-b764-d18e24d01532	student055@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
18469caa-e98b-48a0-b511-19f2f37f58c9	student056@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
703c6582-0262-4774-8d12-8ff324eedbdd	student057@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
b7e78c5f-082b-4cdb-a8e0-059042e437e9	student058@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
6fe61ff9-4cd7-44e0-9a87-0e1415c58113	student059@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
2617b6b6-74ed-4954-8296-5c95e9691e31	student060@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
2631f0c2-3d89-408a-a495-365591dfc6f8	student061@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
02e49dca-3fa3-4407-a92e-fd2cf0dd1588	student062@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
0000ddb5-88d4-48bf-a714-6a955880496a	student063@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
89f7cd56-fc50-48e7-8fd7-300a484b6fc4	student064@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
4d86f2c2-fc23-4c7e-9bc9-070a50a4c0d4	student065@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
2fd3012b-a516-478e-81fc-d4c5bc993fbe	student066@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
6d66fba9-63da-4e31-b932-77950ec4cecb	student067@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
bef5031c-e885-4540-89b8-7985bc9a9610	student068@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
c1f3f129-7755-4bf9-9a38-7448b336a3db	student069@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
5f48c9d2-7212-4a08-a3d2-b43b609932b5	student070@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
7fcee3c0-cb12-40a4-8b31-f09fd90bb1e6	student071@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
8970c25e-a148-4862-a804-7c7e9abb211a	student072@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
6bea42f4-f865-4fb5-8f65-76089af7952f	student073@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
d8a8e332-d8b6-4309-ae43-d7817ab33b01	student074@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
48b013b6-4ba5-4460-a396-b44c20b8763f	student075@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
2abe8b91-0e92-47f1-b716-264248cf7fb1	student076@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
20b09d5e-2c49-4419-93a5-4d8ca8581d76	student077@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
bbabb6e7-e5fc-4f34-98f0-0581e54a0952	student078@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
e21ca6a4-2481-4eac-b7e2-6df2e2f914de	student079@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
d15f892d-7af2-48c1-924a-bbd420401b90	student080@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
c3a1006e-c70b-488e-b610-f1a2b3a06cc3	student081@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
f998856d-1834-44cd-af20-9e9f585600aa	student082@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
1148b2b5-153a-46dc-bc73-e11c5f606f4c	student083@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
63f8c105-3cb2-4779-aee4-459bf2970dba	student084@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
07011679-8488-43a4-9b62-1890745e1e71	student085@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
8be4e95f-d8bc-4f34-a065-03cf7a786768	student086@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
a5dd01a4-3e6b-4f5c-a716-854b9341a7fd	student087@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
b4290deb-a97f-480d-b808-09f1796cc2ee	student088@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
9fb852f7-5388-4e94-b314-1d87973b57d6	student089@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
6584e2f3-e908-480d-b59b-3189b8fcd8fe	student090@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
258a8836-a830-49b9-837d-ea2d0a183fe1	student091@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
d5060e0e-7c8d-42be-84eb-c93188526338	student092@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
efdff76c-17a1-4eb1-84ce-efef4a4fed92	student093@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
f2ac74f1-8ac5-49c7-848f-e59bb7a1b980	student094@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
8cabb553-5eb5-4ceb-b7c3-4f03e8d09d5b	student095@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
3709c159-7741-4c9b-948f-d2f8be33bbbc	student096@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
fec81e51-3936-42b9-896f-9aadcf4a71c5	student097@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
9ca6eb81-4bf6-4e43-9c68-f6e5db9d33d6	student098@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
372a55cf-f658-4e49-9804-db5bbb049164	student099@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
74bcd124-be66-4824-acef-119234fc1e55	student100@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
35106327-8645-42cd-b762-caff9f734d5e	student101@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
7ee01a01-b906-4ae1-89d8-aa9000a03909	student102@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
0b8efe59-6555-4c8d-86d5-ed11bf51eab1	student103@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
a5c17d08-605b-42b9-b604-b1643446af9d	student104@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
243af1c0-6b39-4501-9667-139304b91efb	student105@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
b87aff3c-66ed-4274-9ffa-c04c2100028f	student106@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
8f4de238-6f59-435f-9946-e7118a9d64ac	student107@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
51693123-9e37-4bf8-8849-1c055fb40b68	student108@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
46c00b36-47f5-4612-a4d2-bf12ddd30a34	student109@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
5eb533ae-59bf-4196-9f80-5eda198bdd51	student110@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
e7292a93-2a47-41e9-86e2-6b679fb996ab	student111@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
29590281-82f6-44dc-b04a-1cf830b280a4	student112@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
6a3bb426-4da9-4643-a1a4-bcedf14ccf72	student113@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
d33bdfe6-2d51-4596-b64d-0c9f70e678b3	student114@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
f04d8f1a-0412-4996-bc49-f3c9a6af2c1d	student115@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
ca503c8d-ddbb-42ab-afdd-17e2c7cb98da	student116@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
68aeefae-af62-4999-bbac-a8941a9e0ac1	student117@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
daedfe9d-a685-4519-8c1c-b05f720deea4	student118@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
15850d35-cf28-4083-8e4a-afbcddefd03c	student119@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
8272c4df-3a9f-406a-b861-a08eaccc3e74	student120@smartstay.demo	$2b$12$yWLA.iPn16vO3tEojwK3YOHYoL2RGeNb0jBV3HuDQV7zs6pdU/QbC	student	t	\N	2026-09-30 21:35:21.017498+05:30
\.


--
-- Data for Name: visitors; Type: TABLE DATA; Schema: smartstay; Owner: sunny
--

COPY smartstay.visitors (id, student_id, guest_name, relationship, visit_date, status, created_at) FROM stdin;
1	1	Agarwal Visitor	Sibling	2026-09-22	scheduled	2026-09-30 21:35:21.017498+05:30
2	4	Bansal Visitor	Parent	2026-09-23	approved	2026-09-30 21:35:21.017498+05:30
3	7	Chatterjee Visitor	Sibling	2026-09-24	approved	2026-09-30 21:35:21.017498+05:30
4	10	Das Visitor	Parent	2026-09-25	completed	2026-09-30 21:35:21.017498+05:30
5	13	Gupta Visitor	Sibling	2026-09-26	approved	2026-09-30 21:35:21.017498+05:30
6	16	Iyer Visitor	Parent	2026-09-27	scheduled	2026-09-30 21:35:21.017498+05:30
7	19	Jain Visitor	Sibling	2026-09-28	completed	2026-09-30 21:35:21.017498+05:30
8	22	Kapoor Visitor	Parent	2026-09-29	approved	2026-09-30 21:35:21.017498+05:30
9	25	Mehta Visitor	Sibling	2026-09-30	approved	2026-09-30 21:35:21.017498+05:30
10	28	Nair Visitor	Parent	2026-10-01	completed	2026-09-30 21:35:21.017498+05:30
11	31	Patel Visitor	Sibling	2026-10-02	scheduled	2026-09-30 21:35:21.017498+05:30
12	34	Rao Visitor	Parent	2026-10-03	approved	2026-09-30 21:35:21.017498+05:30
13	37	Sharma Visitor	Sibling	2026-10-04	completed	2026-09-30 21:35:21.017498+05:30
14	40	Singh Visitor	Parent	2026-10-05	approved	2026-09-30 21:35:21.017498+05:30
15	43	Verma Visitor	Sibling	2026-10-06	approved	2026-09-30 21:35:21.017498+05:30
16	46	Agarwal Visitor	Parent	2026-10-07	scheduled	2026-09-30 21:35:21.017498+05:30
17	49	Bansal Visitor	Sibling	2026-10-08	approved	2026-09-30 21:35:21.017498+05:30
18	52	Chatterjee Visitor	Parent	2026-10-09	approved	2026-09-30 21:35:21.017498+05:30
19	55	Das Visitor	Sibling	2026-09-22	completed	2026-09-30 21:35:21.017498+05:30
20	58	Gupta Visitor	Parent	2026-09-23	approved	2026-09-30 21:35:21.017498+05:30
21	61	Iyer Visitor	Sibling	2026-09-24	scheduled	2026-09-30 21:35:21.017498+05:30
22	64	Jain Visitor	Parent	2026-09-25	completed	2026-09-30 21:35:21.017498+05:30
23	67	Kapoor Visitor	Sibling	2026-09-26	approved	2026-09-30 21:35:21.017498+05:30
24	70	Mehta Visitor	Parent	2026-09-27	approved	2026-09-30 21:35:21.017498+05:30
25	73	Nair Visitor	Sibling	2026-09-28	completed	2026-09-30 21:35:21.017498+05:30
26	76	Patel Visitor	Parent	2026-09-29	scheduled	2026-09-30 21:35:21.017498+05:30
27	79	Rao Visitor	Sibling	2026-09-30	approved	2026-09-30 21:35:21.017498+05:30
28	82	Sharma Visitor	Parent	2026-10-01	completed	2026-09-30 21:35:21.017498+05:30
29	85	Singh Visitor	Sibling	2026-10-02	approved	2026-09-30 21:35:21.017498+05:30
30	88	Verma Visitor	Parent	2026-10-03	approved	2026-09-30 21:35:21.017498+05:30
31	91	Agarwal Visitor	Sibling	2026-10-04	scheduled	2026-09-30 21:35:21.017498+05:30
32	94	Bansal Visitor	Parent	2026-10-05	approved	2026-09-30 21:35:21.017498+05:30
33	97	Chatterjee Visitor	Sibling	2026-10-06	approved	2026-09-30 21:35:21.017498+05:30
34	100	Das Visitor	Parent	2026-10-07	completed	2026-09-30 21:35:21.017498+05:30
35	103	Gupta Visitor	Sibling	2026-10-08	approved	2026-09-30 21:35:21.017498+05:30
36	2	Iyer Visitor	Parent	2026-10-09	scheduled	2026-09-30 21:35:21.017498+05:30
37	5	Jain Visitor	Sibling	2026-09-22	completed	2026-09-30 21:35:21.017498+05:30
38	8	Kapoor Visitor	Parent	2026-09-23	approved	2026-09-30 21:35:21.017498+05:30
39	11	Mehta Visitor	Sibling	2026-09-24	approved	2026-09-30 21:35:21.017498+05:30
40	14	Nair Visitor	Parent	2026-09-25	completed	2026-09-30 21:35:21.017498+05:30
41	17	Patel Visitor	Sibling	2026-09-26	scheduled	2026-09-30 21:35:21.017498+05:30
42	20	Rao Visitor	Parent	2026-09-27	approved	2026-09-30 21:35:21.017498+05:30
\.


--
-- Data for Name: wardens; Type: TABLE DATA; Schema: smartstay; Owner: sunny
--

COPY smartstay.wardens (id, user_id, university_id, hostel_id, full_name, phone, created_at) FROM stdin;
1	8c52851d-50e6-4a27-843a-e438a8e5f5d8	1	1	Aarushi Arya	+91 98765 01001	2026-09-30 21:35:21.017498+05:30
2	7f98f45c-3038-4f53-8476-aa2381d1a7c3	1	2	Farhan Khan	+91 98765 01002	2026-09-30 21:35:21.017498+05:30
\.


--
-- Name: allocations_allocation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sunny
--

SELECT pg_catalog.setval('public.allocations_allocation_id_seq', 178, true);


--
-- Name: attendance_attendance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sunny
--

SELECT pg_catalog.setval('public.attendance_attendance_id_seq', 120, true);


--
-- Name: complaints_complaint_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sunny
--

SELECT pg_catalog.setval('public.complaints_complaint_id_seq', 30, true);


--
-- Name: fees_fee_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sunny
--

SELECT pg_catalog.setval('public.fees_fee_id_seq', 135, true);


--
-- Name: hostels_hostel_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sunny
--

SELECT pg_catalog.setval('public.hostels_hostel_id_seq', 3, true);


--
-- Name: rooms_room_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sunny
--

SELECT pg_catalog.setval('public.rooms_room_id_seq', 18, true);


--
-- Name: students_student_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sunny
--

SELECT pg_catalog.setval('public.students_student_id_seq', 120, true);


--
-- Name: users_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sunny
--

SELECT pg_catalog.setval('public.users_user_id_seq', 123, true);


--
-- Name: visitors_visitor_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sunny
--

SELECT pg_catalog.setval('public.visitors_visitor_id_seq', 17, true);


--
-- Name: allocations_id_seq; Type: SEQUENCE SET; Schema: smartstay; Owner: sunny
--

SELECT pg_catalog.setval('smartstay.allocations_id_seq', 104, true);


--
-- Name: attendance_id_seq; Type: SEQUENCE SET; Schema: smartstay; Owner: sunny
--

SELECT pg_catalog.setval('smartstay.attendance_id_seq', 3600, true);


--
-- Name: complaints_id_seq; Type: SEQUENCE SET; Schema: smartstay; Owner: sunny
--

SELECT pg_catalog.setval('smartstay.complaints_id_seq', 28, true);


--
-- Name: fees_id_seq; Type: SEQUENCE SET; Schema: smartstay; Owner: sunny
--

SELECT pg_catalog.setval('smartstay.fees_id_seq', 240, true);


--
-- Name: hostels_id_seq; Type: SEQUENCE SET; Schema: smartstay; Owner: sunny
--

SELECT pg_catalog.setval('smartstay.hostels_id_seq', 3, true);


--
-- Name: rooms_id_seq; Type: SEQUENCE SET; Schema: smartstay; Owner: sunny
--

SELECT pg_catalog.setval('smartstay.rooms_id_seq', 36, true);


--
-- Name: students_id_seq; Type: SEQUENCE SET; Schema: smartstay; Owner: sunny
--

SELECT pg_catalog.setval('smartstay.students_id_seq', 120, true);


--
-- Name: universities_id_seq; Type: SEQUENCE SET; Schema: smartstay; Owner: sunny
--

SELECT pg_catalog.setval('smartstay.universities_id_seq', 1, true);


--
-- Name: university_admins_id_seq; Type: SEQUENCE SET; Schema: smartstay; Owner: sunny
--

SELECT pg_catalog.setval('smartstay.university_admins_id_seq', 1, true);


--
-- Name: visitors_id_seq; Type: SEQUENCE SET; Schema: smartstay; Owner: sunny
--

SELECT pg_catalog.setval('smartstay.visitors_id_seq', 42, true);


--
-- Name: wardens_id_seq; Type: SEQUENCE SET; Schema: smartstay; Owner: sunny
--

SELECT pg_catalog.setval('smartstay.wardens_id_seq', 2, true);


--
-- Name: allocations allocations_pkey; Type: CONSTRAINT; Schema: public; Owner: sunny
--

ALTER TABLE ONLY public.allocations
    ADD CONSTRAINT allocations_pkey PRIMARY KEY (allocation_id);


--
-- Name: attendance attendance_pkey; Type: CONSTRAINT; Schema: public; Owner: sunny
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_pkey PRIMARY KEY (attendance_id);


--
-- Name: attendance attendance_student_id_attendance_date_key; Type: CONSTRAINT; Schema: public; Owner: sunny
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_student_id_attendance_date_key UNIQUE (student_id, attendance_date);


--
-- Name: complaints complaints_pkey; Type: CONSTRAINT; Schema: public; Owner: sunny
--

ALTER TABLE ONLY public.complaints
    ADD CONSTRAINT complaints_pkey PRIMARY KEY (complaint_id);


--
-- Name: fees fees_pkey; Type: CONSTRAINT; Schema: public; Owner: sunny
--

ALTER TABLE ONLY public.fees
    ADD CONSTRAINT fees_pkey PRIMARY KEY (fee_id);


--
-- Name: hostels hostels_pkey; Type: CONSTRAINT; Schema: public; Owner: sunny
--

ALTER TABLE ONLY public.hostels
    ADD CONSTRAINT hostels_pkey PRIMARY KEY (hostel_id);


--
-- Name: rooms rooms_hostel_id_room_number_key; Type: CONSTRAINT; Schema: public; Owner: sunny
--

ALTER TABLE ONLY public.rooms
    ADD CONSTRAINT rooms_hostel_id_room_number_key UNIQUE (hostel_id, room_number);


--
-- Name: rooms rooms_pkey; Type: CONSTRAINT; Schema: public; Owner: sunny
--

ALTER TABLE ONLY public.rooms
    ADD CONSTRAINT rooms_pkey PRIMARY KEY (room_id);


--
-- Name: students students_pkey; Type: CONSTRAINT; Schema: public; Owner: sunny
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_pkey PRIMARY KEY (student_id);


--
-- Name: students students_student_number_key; Type: CONSTRAINT; Schema: public; Owner: sunny
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_student_number_key UNIQUE (student_number);


--
-- Name: students students_user_id_key; Type: CONSTRAINT; Schema: public; Owner: sunny
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_user_id_key UNIQUE (user_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: sunny
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: sunny
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: visitors visitors_pkey; Type: CONSTRAINT; Schema: public; Owner: sunny
--

ALTER TABLE ONLY public.visitors
    ADD CONSTRAINT visitors_pkey PRIMARY KEY (visitor_id);


--
-- Name: allocations allocations_pkey; Type: CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.allocations
    ADD CONSTRAINT allocations_pkey PRIMARY KEY (id);


--
-- Name: attendance attendance_pkey; Type: CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.attendance
    ADD CONSTRAINT attendance_pkey PRIMARY KEY (id);


--
-- Name: attendance attendance_student_id_attendance_date_key; Type: CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.attendance
    ADD CONSTRAINT attendance_student_id_attendance_date_key UNIQUE (student_id, attendance_date);


--
-- Name: complaints complaints_pkey; Type: CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.complaints
    ADD CONSTRAINT complaints_pkey PRIMARY KEY (id);


--
-- Name: fees fees_pkey; Type: CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.fees
    ADD CONSTRAINT fees_pkey PRIMARY KEY (id);


--
-- Name: hostels hostels_pkey; Type: CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.hostels
    ADD CONSTRAINT hostels_pkey PRIMARY KEY (id);


--
-- Name: hostels hostels_university_id_code_key; Type: CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.hostels
    ADD CONSTRAINT hostels_university_id_code_key UNIQUE (university_id, code);


--
-- Name: rooms rooms_hostel_id_room_number_key; Type: CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.rooms
    ADD CONSTRAINT rooms_hostel_id_room_number_key UNIQUE (hostel_id, room_number);


--
-- Name: rooms rooms_pkey; Type: CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.rooms
    ADD CONSTRAINT rooms_pkey PRIMARY KEY (id);


--
-- Name: students students_enrollment_no_key; Type: CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.students
    ADD CONSTRAINT students_enrollment_no_key UNIQUE (enrollment_no);


--
-- Name: students students_pkey; Type: CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.students
    ADD CONSTRAINT students_pkey PRIMARY KEY (id);


--
-- Name: students students_user_id_key; Type: CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.students
    ADD CONSTRAINT students_user_id_key UNIQUE (user_id);


--
-- Name: universities universities_code_key; Type: CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.universities
    ADD CONSTRAINT universities_code_key UNIQUE (code);


--
-- Name: universities universities_pkey; Type: CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.universities
    ADD CONSTRAINT universities_pkey PRIMARY KEY (id);


--
-- Name: university_admins university_admins_pkey; Type: CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.university_admins
    ADD CONSTRAINT university_admins_pkey PRIMARY KEY (id);


--
-- Name: university_admins university_admins_user_id_key; Type: CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.university_admins
    ADD CONSTRAINT university_admins_user_id_key UNIQUE (user_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: visitors visitors_pkey; Type: CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.visitors
    ADD CONSTRAINT visitors_pkey PRIMARY KEY (id);


--
-- Name: wardens wardens_pkey; Type: CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.wardens
    ADD CONSTRAINT wardens_pkey PRIMARY KEY (id);


--
-- Name: wardens wardens_user_id_key; Type: CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.wardens
    ADD CONSTRAINT wardens_user_id_key UNIQUE (user_id);


--
-- Name: active_allocation_per_student; Type: INDEX; Schema: smartstay; Owner: sunny
--

CREATE UNIQUE INDEX active_allocation_per_student ON smartstay.allocations USING btree (student_id) WHERE (check_out IS NULL);


--
-- Name: idx_allocations_room_active; Type: INDEX; Schema: smartstay; Owner: sunny
--

CREATE INDEX idx_allocations_room_active ON smartstay.allocations USING btree (room_id) WHERE (check_out IS NULL);


--
-- Name: idx_attendance_student_date; Type: INDEX; Schema: smartstay; Owner: sunny
--

CREATE INDEX idx_attendance_student_date ON smartstay.attendance USING btree (student_id, attendance_date DESC);


--
-- Name: idx_complaints_status; Type: INDEX; Schema: smartstay; Owner: sunny
--

CREATE INDEX idx_complaints_status ON smartstay.complaints USING btree (status);


--
-- Name: idx_students_university; Type: INDEX; Schema: smartstay; Owner: sunny
--

CREATE INDEX idx_students_university ON smartstay.students USING btree (university_id);


--
-- Name: allocations allocations_room_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sunny
--

ALTER TABLE ONLY public.allocations
    ADD CONSTRAINT allocations_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.rooms(room_id) ON DELETE CASCADE;


--
-- Name: allocations allocations_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sunny
--

ALTER TABLE ONLY public.allocations
    ADD CONSTRAINT allocations_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(student_id) ON DELETE CASCADE;


--
-- Name: attendance attendance_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sunny
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(student_id) ON DELETE CASCADE;


--
-- Name: complaints complaints_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sunny
--

ALTER TABLE ONLY public.complaints
    ADD CONSTRAINT complaints_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(student_id) ON DELETE CASCADE;


--
-- Name: fees fees_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sunny
--

ALTER TABLE ONLY public.fees
    ADD CONSTRAINT fees_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(student_id) ON DELETE CASCADE;


--
-- Name: rooms rooms_hostel_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sunny
--

ALTER TABLE ONLY public.rooms
    ADD CONSTRAINT rooms_hostel_id_fkey FOREIGN KEY (hostel_id) REFERENCES public.hostels(hostel_id) ON DELETE CASCADE;


--
-- Name: students students_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sunny
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: visitors visitors_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sunny
--

ALTER TABLE ONLY public.visitors
    ADD CONSTRAINT visitors_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(student_id) ON DELETE CASCADE;


--
-- Name: allocations allocations_room_id_fkey; Type: FK CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.allocations
    ADD CONSTRAINT allocations_room_id_fkey FOREIGN KEY (room_id) REFERENCES smartstay.rooms(id) ON DELETE CASCADE;


--
-- Name: allocations allocations_student_id_fkey; Type: FK CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.allocations
    ADD CONSTRAINT allocations_student_id_fkey FOREIGN KEY (student_id) REFERENCES smartstay.students(id) ON DELETE CASCADE;


--
-- Name: attendance attendance_marked_by_fkey; Type: FK CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.attendance
    ADD CONSTRAINT attendance_marked_by_fkey FOREIGN KEY (marked_by) REFERENCES smartstay.users(id) ON DELETE SET NULL;


--
-- Name: attendance attendance_student_id_fkey; Type: FK CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.attendance
    ADD CONSTRAINT attendance_student_id_fkey FOREIGN KEY (student_id) REFERENCES smartstay.students(id) ON DELETE CASCADE;


--
-- Name: complaints complaints_hostel_id_fkey; Type: FK CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.complaints
    ADD CONSTRAINT complaints_hostel_id_fkey FOREIGN KEY (hostel_id) REFERENCES smartstay.hostels(id) ON DELETE SET NULL;


--
-- Name: complaints complaints_student_id_fkey; Type: FK CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.complaints
    ADD CONSTRAINT complaints_student_id_fkey FOREIGN KEY (student_id) REFERENCES smartstay.students(id) ON DELETE CASCADE;


--
-- Name: fees fees_student_id_fkey; Type: FK CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.fees
    ADD CONSTRAINT fees_student_id_fkey FOREIGN KEY (student_id) REFERENCES smartstay.students(id) ON DELETE CASCADE;


--
-- Name: hostels hostels_university_id_fkey; Type: FK CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.hostels
    ADD CONSTRAINT hostels_university_id_fkey FOREIGN KEY (university_id) REFERENCES smartstay.universities(id) ON DELETE CASCADE;


--
-- Name: rooms rooms_hostel_id_fkey; Type: FK CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.rooms
    ADD CONSTRAINT rooms_hostel_id_fkey FOREIGN KEY (hostel_id) REFERENCES smartstay.hostels(id) ON DELETE CASCADE;


--
-- Name: students students_university_id_fkey; Type: FK CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.students
    ADD CONSTRAINT students_university_id_fkey FOREIGN KEY (university_id) REFERENCES smartstay.universities(id) ON DELETE CASCADE;


--
-- Name: students students_user_id_fkey; Type: FK CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.students
    ADD CONSTRAINT students_user_id_fkey FOREIGN KEY (user_id) REFERENCES smartstay.users(id) ON DELETE CASCADE;


--
-- Name: university_admins university_admins_university_id_fkey; Type: FK CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.university_admins
    ADD CONSTRAINT university_admins_university_id_fkey FOREIGN KEY (university_id) REFERENCES smartstay.universities(id) ON DELETE CASCADE;


--
-- Name: university_admins university_admins_user_id_fkey; Type: FK CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.university_admins
    ADD CONSTRAINT university_admins_user_id_fkey FOREIGN KEY (user_id) REFERENCES smartstay.users(id) ON DELETE CASCADE;


--
-- Name: visitors visitors_student_id_fkey; Type: FK CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.visitors
    ADD CONSTRAINT visitors_student_id_fkey FOREIGN KEY (student_id) REFERENCES smartstay.students(id) ON DELETE CASCADE;


--
-- Name: wardens wardens_hostel_id_fkey; Type: FK CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.wardens
    ADD CONSTRAINT wardens_hostel_id_fkey FOREIGN KEY (hostel_id) REFERENCES smartstay.hostels(id) ON DELETE SET NULL;


--
-- Name: wardens wardens_university_id_fkey; Type: FK CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.wardens
    ADD CONSTRAINT wardens_university_id_fkey FOREIGN KEY (university_id) REFERENCES smartstay.universities(id) ON DELETE CASCADE;


--
-- Name: wardens wardens_user_id_fkey; Type: FK CONSTRAINT; Schema: smartstay; Owner: sunny
--

ALTER TABLE ONLY smartstay.wardens
    ADD CONSTRAINT wardens_user_id_fkey FOREIGN KEY (user_id) REFERENCES smartstay.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict 5dMwyHenaxhd2nxKd9lZ59BT2AbEtxIecQWGdGNNbqwmuV1d4aTQgNOs7KRiLFZ

