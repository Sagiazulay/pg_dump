--
-- PostgreSQL database dump
--

-- Dumped from database version 13.1
-- Dumped by pg_dump version 13.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgagent; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA pgagent;


ALTER SCHEMA pgagent OWNER TO postgres;

--
-- Name: SCHEMA pgagent; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA pgagent IS 'pgAgent system tables';


--
-- Name: adminpack; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS adminpack WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION adminpack; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION adminpack IS 'administrative functions for PostgreSQL';


--
-- Name: pgagent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgagent WITH SCHEMA pgagent;


--
-- Name: EXTENSION pgagent; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgagent IS 'A PostgreSQL job scheduler';


--
-- Name: a_sp_count_sum_records(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.a_sp_count_sum_records() RETURNS bigint
    LANGUAGE plpgsql
    AS $$
    DECLARE
        MOVIES_COUNT bigint :=0;
        COUNTRY_COUNT bigint :=0;
    BEGIN
        SELECT COUNT(*) INTO MOVIES_COUNT
        FROM movies;

        SELECT COUNT(*) INTO COUNTRY_COUNT
        FROM country;

        return COUNTRY_COUNT + MOVIES_COUNT;
    END;
    $$;


ALTER FUNCTION public.a_sp_count_sum_records() OWNER TO postgres;

--
-- Name: a_sp_get_movie_price(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.a_sp_get_movie_price(OUT min_price double precision, OUT max_price double precision, OUT avg_price double precision) RETURNS record
    LANGUAGE plpgsql
    AS $$
begin
  select min(price),
         max(price),
		 avg(price)::numeric(5,2)
  into min_price, max_price, avg_price
  from movies;
end;$$;


ALTER FUNCTION public.a_sp_get_movie_price(OUT min_price double precision, OUT max_price double precision, OUT avg_price double precision) OWNER TO postgres;

--
-- Name: a_sp_get_movies_in_range(double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.a_sp_get_movies_in_range(min_price double precision, max_price double precision) RETURNS TABLE(id bigint, title text, release_date timestamp without time zone, price double precision, country_name text)
    LANGUAGE plpgsql
    AS $$
    BEGIN
        RETURN QUERY
        SELECT m.id, m.title, m.release_date, m.price, c.name FROM movies m
        join country c on m.country_id = c.id
        WHERE m.price between min_price and max_price;
    END;
$$;


ALTER FUNCTION public.a_sp_get_movies_in_range(min_price double precision, max_price double precision) OWNER TO postgres;

--
-- Name: a_sp_get_movies_mid(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.a_sp_get_movies_mid() RETURNS TABLE(id bigint, title text, release_date timestamp without time zone, price double precision, country_name text)
    LANGUAGE plpgsql
    AS $$
    BEGIN
        RETURN QUERY
        WITH cheapest_movie AS
            (
                select * from movies
                where movies.price = (select min(movies.price) from movies)
            ),
        expansive_movie AS
            (
                select * from movies
                where movies.price = (select max(movies.price) from movies)
            )
        SELECT m.id, m.title, m.release_date, m.price, c.name FROM movies m
        join country c on m.country_id = c.id
        WHERE m.id <> (select cheapest_movie.id from cheapest_movie) and m.id <> (select expansive_movie.id from expansive_movie);
    END;
$$;


ALTER FUNCTION public.a_sp_get_movies_mid() OWNER TO postgres;

--
-- Name: a_sp_insert_movie(text, timestamp without time zone, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.a_sp_insert_movie(_title text, _release_date timestamp without time zone, _price double precision) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
    DECLARE
        new_id bigint;
    BEGIN
        INSERT INTO movies (title, release_date, price)
        VALUES (_title, _release_date, _price)
        returning id into new_id;

        return new_id;
    END;
    $$;


ALTER FUNCTION public.a_sp_insert_movie(_title text, _release_date timestamp without time zone, _price double precision) OWNER TO postgres;

--
-- Name: a_sp_max_workers(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.a_sp_max_workers() RETURNS TABLE(id integer, name text, number_of_workers integer)
    LANGUAGE plpgsql
    AS $$
    begin
        select count(*) into name from sites;
    end;
    $$;


ALTER FUNCTION public.a_sp_max_workers() OWNER TO postgres;

--
-- Name: a_sp_most_expensive_movie(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.a_sp_most_expensive_movie(OUT movie_name text) RETURNS text
    LANGUAGE plpgsql
    AS $$
    DECLARE
        max_price double precision :=0;
    BEGIN
        SELECT max(price)
        into max_price
        from movies;

        SELECT movies.title
        into movie_name
        from movies where movies.price = max_price;
    END;
    $$;


ALTER FUNCTION public.a_sp_most_expensive_movie(OUT movie_name text) OWNER TO postgres;

--
-- Name: a_sp_plus_salary(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.a_sp_plus_salary() RETURNS integer
    LANGUAGE plpgsql
    AS $$
    begin
    declare
        x int := 500;
    BEGIN
        FOR i IN 1..(select count(*) from workers)
            loop
                x := x + (select salary from workers where salary=i);
            end loop;
        return x;
end ;
    end;
    $$;


ALTER FUNCTION public.a_sp_plus_salary() OWNER TO postgres;

--
-- Name: a_sp_populate_grade(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.a_sp_populate_grade(_classes integer, _students integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
    declare
        counter int := 0;
        _grade double precision := 0;
    BEGIN
        FOR i IN 1.._classes
            loop
                FOR j IN 1.._students
                loop
                    counter := counter + 1;
                    _grade = random() * 100;
                    INSERT INTO grades(class_id, student_id, grade) VALUES
                        (i, j, _grade);
                    end loop;
            end loop;
        return counter;
    END;
$$;


ALTER FUNCTION public.a_sp_populate_grade(_classes integer, _students integer) OWNER TO postgres;

--
-- Name: a_sp_sum_of_numbers(double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.a_sp_sum_of_numbers(m double precision, n double precision) RETURNS double precision
    LANGUAGE plpgsql
    AS $$
        DECLARE
            x integer := 1;
        BEGIN
            RETURN n + m + x;
        END;
    $$;


ALTER FUNCTION public.a_sp_sum_of_numbers(m double precision, n double precision) OWNER TO postgres;

--
-- Name: a_sp_update_movie(bigint, text, timestamp without time zone, double precision, bigint); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.a_sp_update_movie(_id bigint, _title text, _release_date timestamp without time zone, _price double precision, _country_id bigint)
    LANGUAGE plpgsql
    AS $$
    BEGIN
        UPDATE movies
        SET title = _title, release_date = _release_date, price = _price, country_id = _country_id
        where id = _id;
    END;
    $$;


ALTER PROCEDURE public.a_sp_update_movie(_id bigint, _title text, _release_date timestamp without time zone, _price double precision, _country_id bigint) OWNER TO postgres;

--
-- Name: a_sp_workers_position_name(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.a_sp_workers_position_name() RETURNS TABLE(id bigint, text name, phone text, role text)
    LANGUAGE plpgsql
    AS $$
    begin
          select workers.id, workers.name, workers.phone, workers.role_id from workers
        join roles  r on workers.role_id = r.id;
    end;
    $$;


ALTER FUNCTION public.a_sp_workers_position_name() OWNER TO postgres;

--
-- Name: a_sp_workers_salary(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.a_sp_workers_salary() RETURNS TABLE(x integer)
    LANGUAGE plpgsql
    AS $$
    begin
        select role_id from workers w;
        IF ((select role_id from workers) = 1)
            then
            update workers set salary = 30000
            where workers.role_id = role_id;
            else if ((select role_id from workers)!=1)

                then update workers set salary=random(5000,10000)
                where role_id=role_id;
        end if;
    end if;
        end;
    $$;


ALTER FUNCTION public.a_sp_workers_salary() OWNER TO postgres;

--
-- Name: a_sp_workers_salary(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.a_sp_workers_salary(y integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
    begin
        select id from workers w;
        IF (1)
            then
            update workers set salary = 20000
            where workers.role_id = role_id;
            else if
                y > 1
                then update workers set salary=random(5000,10000)
                where role_id=role_id;
        end if;
    end if;
        end;
    $$;


ALTER FUNCTION public.a_sp_workers_salary(y integer) OWNER TO postgres;

--
-- Name: a_sum_n_product(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.a_sum_n_product(x integer, y integer, OUT prod integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
    DECLARE
        sum integer := 0;
BEGIN
 sum := x + y;
 prod := x * y;
END;
$$;


ALTER FUNCTION public.a_sum_n_product(x integer, y integer, OUT prod integer) OWNER TO postgres;

--
-- Name: get_workers_by_site_number(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_workers_by_site_number(number integer) RETURNS TABLE(id integer, name text)
    LANGUAGE plpgsql
    AS $$
    DECLARE
  number int := 0;

    begin
        select workers.name, workers.id, site_id from workers where site_id = number;
    end;
    $$;


ALTER FUNCTION public.get_workers_by_site_number(number integer) OWNER TO postgres;

--
-- Name: hello_world(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hello_world() RETURNS character varying
    LANGUAGE plpgsql
    AS $$
        BEGIN
            RETURN CONCAT('Hello ','World! ', ' ', current_timestamp);
        END;
    $$;


ALTER FUNCTION public.hello_world() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: movies; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.movies (
    id bigint NOT NULL,
    name text,
    release_date date,
    genre_id bigint
);


ALTER TABLE public.movies OWNER TO postgres;

--
-- Name: Movies_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Movies_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Movies_id_seq" OWNER TO postgres;

--
-- Name: Movies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Movies_id_seq" OWNED BY public.movies.id;


--
-- Name: workers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.workers (
    id bigint NOT NULL,
    name text,
    phone text,
    salary integer,
    role_id bigint,
    site_id bigint
);


ALTER TABLE public.workers OWNER TO postgres;

--
-- Name: Workers_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Workers_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Workers_id_seq" OWNER TO postgres;

--
-- Name: Workers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Workers_id_seq" OWNED BY public.workers.id;


--
-- Name: actors; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.actors (
    id bigint NOT NULL,
    name text,
    birthday date
);


ALTER TABLE public.actors OWNER TO postgres;

--
-- Name: actors_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.actors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.actors_id_seq OWNER TO postgres;

--
-- Name: actors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.actors_id_seq OWNED BY public.actors.id;


--
-- Name: genres; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.genres (
    id bigint NOT NULL,
    name text
);


ALTER TABLE public.genres OWNER TO postgres;

--
-- Name: genres_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.genres_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.genres_id_seq OWNER TO postgres;

--
-- Name: genres_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.genres_id_seq OWNED BY public.genres.id;


--
-- Name: grades; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.grades (
    id bigint NOT NULL,
    class_id bigint NOT NULL,
    student_id bigint NOT NULL,
    grade double precision DEFAULT 0 NOT NULL
);


ALTER TABLE public.grades OWNER TO postgres;

--
-- Name: grades_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.grades_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.grades_id_seq OWNER TO postgres;

--
-- Name: grades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.grades_id_seq OWNED BY public.grades.id;


--
-- Name: movies_actors; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.movies_actors (
    id bigint NOT NULL,
    movie_id bigint,
    actor_id bigint
);


ALTER TABLE public.movies_actors OWNER TO postgres;

--
-- Name: name; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.name (
    count bigint
);


ALTER TABLE public.name OWNER TO postgres;

--
-- Name: roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles (
    id bigint NOT NULL,
    name text
);


ALTER TABLE public.roles OWNER TO postgres;

--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.roles_id_seq OWNER TO postgres;

--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: sites; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sites (
    id bigint NOT NULL,
    name text,
    address text
);


ALTER TABLE public.sites OWNER TO postgres;

--
-- Name: sites_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sites_id_seq OWNER TO postgres;

--
-- Name: sites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sites_id_seq OWNED BY public.sites.id;


--
-- Name: actors id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.actors ALTER COLUMN id SET DEFAULT nextval('public.actors_id_seq'::regclass);


--
-- Name: genres id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genres ALTER COLUMN id SET DEFAULT nextval('public.genres_id_seq'::regclass);


--
-- Name: grades id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grades ALTER COLUMN id SET DEFAULT nextval('public.grades_id_seq'::regclass);


--
-- Name: movies id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movies ALTER COLUMN id SET DEFAULT nextval('public."Movies_id_seq"'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: sites id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sites ALTER COLUMN id SET DEFAULT nextval('public.sites_id_seq'::regclass);


--
-- Name: workers id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workers ALTER COLUMN id SET DEFAULT nextval('public."Workers_id_seq"'::regclass);


--
-- Data for Name: pga_jobagent; Type: TABLE DATA; Schema: pgagent; Owner: postgres
--

COPY pgagent.pga_jobagent (jagpid, jaglogintime, jagstation) FROM stdin;
11456	2020-12-23 19:07:13.713256+02	Sagi
\.


--
-- Data for Name: pga_jobclass; Type: TABLE DATA; Schema: pgagent; Owner: postgres
--

COPY pgagent.pga_jobclass (jclid, jclname) FROM stdin;
\.


--
-- Data for Name: pga_job; Type: TABLE DATA; Schema: pgagent; Owner: postgres
--

COPY pgagent.pga_job (jobid, jobjclid, jobname, jobdesc, jobhostagent, jobenabled, jobcreated, jobchanged, jobagentid, jobnextrun, joblastrun) FROM stdin;
\.


--
-- Data for Name: pga_schedule; Type: TABLE DATA; Schema: pgagent; Owner: postgres
--

COPY pgagent.pga_schedule (jscid, jscjobid, jscname, jscdesc, jscenabled, jscstart, jscend, jscminutes, jschours, jscweekdays, jscmonthdays, jscmonths) FROM stdin;
\.


--
-- Data for Name: pga_exception; Type: TABLE DATA; Schema: pgagent; Owner: postgres
--

COPY pgagent.pga_exception (jexid, jexscid, jexdate, jextime) FROM stdin;
\.


--
-- Data for Name: pga_joblog; Type: TABLE DATA; Schema: pgagent; Owner: postgres
--

COPY pgagent.pga_joblog (jlgid, jlgjobid, jlgstatus, jlgstart, jlgduration) FROM stdin;
\.


--
-- Data for Name: pga_jobstep; Type: TABLE DATA; Schema: pgagent; Owner: postgres
--

COPY pgagent.pga_jobstep (jstid, jstjobid, jstname, jstdesc, jstenabled, jstkind, jstcode, jstconnstr, jstdbname, jstonerror, jscnextrun) FROM stdin;
\.


--
-- Data for Name: pga_jobsteplog; Type: TABLE DATA; Schema: pgagent; Owner: postgres
--

COPY pgagent.pga_jobsteplog (jslid, jsljlgid, jsljstid, jslstatus, jslresult, jslstart, jslduration, jsloutput) FROM stdin;
\.


--
-- Data for Name: actors; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.actors (id, name, birthday) FROM stdin;
1	Silvester Stalon	2020-12-20
2	Arnold Shwarzeneger	1930-02-10
3	Jacky Chan	1965-06-17
4	Angelina Juli	1980-01-16
5	Bros Wilis	1973-11-01
6	Sagi	2021-01-09
\.


--
-- Data for Name: genres; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.genres (id, name) FROM stdin;
1	Comedy
2	Horoor
3	Action
4	Sci-Fic
5	Love
\.


--
-- Data for Name: grades; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.grades (id, class_id, student_id, grade) FROM stdin;
1	1	1	38.7992153808046
2	1	2	81.976478886493
3	1	3	76.90010120803059
4	1	4	68.0669868560635
5	1	5	95.34290653997495
6	1	6	72.97922274925384
7	1	7	59.776055666294425
8	1	8	62.85735064094027
9	1	9	88.487230442907
10	1	10	99.33749955263096
11	1	11	74.62011543493325
12	1	12	67.29066619202158
13	1	13	42.74429565230413
14	1	14	72.68952172797754
15	1	15	43.63736061645049
16	1	16	35.279082352608526
17	1	17	0.9543026346921835
18	1	18	41.50335681923849
19	1	19	30.06527546905282
20	1	20	90.30399411678829
21	1	21	76.1499760245389
22	1	22	40.60202905895096
23	1	23	56.69041978481566
24	1	24	88.52268017063878
25	1	25	77.97797493526737
26	1	26	35.00100417874563
27	1	27	65.5865952405545
28	1	28	33.7512603782919
29	1	29	16.27940553133591
30	1	30	98.51332726788655
31	2	1	3.735537490750218
32	2	2	7.618026290553104
33	2	3	53.4764361741896
34	2	4	55.773865744363604
35	2	5	23.785967628321814
36	2	6	21.00689660631403
37	2	7	22.561627881646373
38	2	8	46.821551519653326
39	2	9	12.92395394861039
40	2	10	41.9437237601592
41	2	11	33.604222845163534
42	2	12	46.25487447049039
43	2	13	66.3114979646334
44	2	14	70.57233369335663
45	2	15	76.44906258243829
46	2	16	60.90130962884359
47	2	17	10.758098587488618
48	2	18	13.138924639836347
49	2	19	66.1773162139287
50	2	20	19.13851931476671
51	2	21	35.49129655473244
52	2	22	17.331688673800016
53	2	23	29.22456959113937
54	2	24	56.2592150158963
55	2	25	71.6688888116277
56	2	26	23.348658071268602
57	2	27	57.92433882189876
58	2	28	49.930148412094866
59	2	29	72.5221608753511
60	2	30	25.194723484164427
61	3	1	68.5895083833632
62	3	2	0.7689828040895463
63	3	3	18.94314549057121
64	3	4	30.5049287624378
65	3	5	39.79883573711511
66	3	6	19.823431580933004
67	3	7	18.449109366252614
68	3	8	24.28442423728754
69	3	9	22.871292412481026
70	3	10	38.32019550271468
71	3	11	81.60622771811283
72	3	12	41.03726264668879
73	3	13	52.9509071540776
74	3	14	8.054541732177256
75	3	15	72.31625997885338
76	3	16	3.5804558932305497
77	3	17	26.86472118760186
78	3	18	2.375000971744612
79	3	19	5.322020629106916
80	3	20	7.222782723679444
81	3	21	90.94474019401453
82	3	22	48.604271000944266
83	3	23	44.63907789598771
84	3	24	90.80865345972526
85	3	25	19.12215344652317
86	3	26	40.212161613308695
87	3	27	74.45444131320293
88	3	28	6.3273043400279505
89	3	29	87.42186900715474
90	3	30	59.966953671566614
91	4	1	23.74254808687759
92	4	2	55.370617104974684
93	4	3	26.933366150214866
94	4	4	39.0480299852868
95	4	5	27.141659114566252
96	4	6	21.75534541746984
97	4	7	82.64827352856408
98	4	8	28.67772421611363
99	4	9	67.52935961137005
100	4	10	77.23638481561963
101	4	11	22.286725275398922
102	4	12	43.75918228233502
103	4	13	35.56625785664771
104	4	14	42.618353386337304
105	4	15	37.246708489108826
106	4	16	77.3872950167501
107	4	17	43.88671983750463
108	4	18	34.97706248268386
109	4	19	99.77907563178725
110	4	20	82.59159737965547
111	4	21	79.56159878106455
112	4	22	47.44685683217327
113	4	23	86.90393553310862
114	4	24	76.49609459224536
115	4	25	69.20994798647335
116	4	26	79.49319754831023
117	4	27	35.74253818054025
118	4	28	72.0264253848228
119	4	29	63.27667423965515
120	4	30	40.21365611329273
121	5	1	47.95581254424128
122	5	2	64.70726339894526
123	5	3	36.41552866903588
124	5	4	76.49858859610035
125	5	5	36.78218458050857
126	5	6	54.882545892979806
127	5	7	11.828773428770134
128	5	8	62.401573457103865
129	5	9	90.49147553126211
130	5	10	28.33066052651958
131	5	11	81.33583732745215
132	5	12	20.44812951787023
133	5	13	75.46933993882057
134	5	14	36.77127239071467
135	5	15	37.70531270486224
136	5	16	13.540689293001407
137	5	17	92.98112967510015
138	5	18	51.767690858797266
139	5	19	9.53228074699517
140	5	20	45.35219313963452
141	5	21	41.11104599237798
142	5	22	25.17871550393238
143	5	23	85.13321427043756
144	5	24	74.45639782964477
145	5	25	80.42024738889388
146	5	26	92.3294185200021
147	5	27	94.3331270511063
148	5	28	83.7989654396317
149	5	29	4.316998196822297
150	5	30	42.73647403503276
\.


--
-- Data for Name: movies; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.movies (id, name, release_date, genre_id) FROM stdin;
2	X From Hell	2016-04-21	5
3	Jacky Chan	2004-02-15	2
4	My Life	1991-09-24	4
5	Family	2002-01-29	1
1	Bad Boyz	1999-01-12	3
\.


--
-- Data for Name: movies_actors; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.movies_actors (id, movie_id, actor_id) FROM stdin;
1	1	5
2	2	4
3	3	3
4	4	1
5	5	2
\.


--
-- Data for Name: name; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.name (count) FROM stdin;
3
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.roles (id, name) FROM stdin;
7	secretary
8	worker1
9	worker2
10	worker3
11	worker
12	worker5
2	manager
3	builder
13	manager1
1	ceo
\.


--
-- Data for Name: sites; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sites (id, name, address) FROM stdin;
1	tel aviv	dizengoff 280 tel aviv
2	jerusalem	hakneset 1 jerusalem
3	eilat	dolphins 54 eilat
\.


--
-- Data for Name: workers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workers (id, name, phone, salary, role_id, site_id) FROM stdin;
10	sagi	0547410160	20500	1	1
13	niv	0528681006	20500	1	3
12	daniela	0533345677	5861	3	2
11	yoni	0507787787	7946	2	1
\.


--
-- Name: Movies_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Movies_id_seq"', 1, false);


--
-- Name: Workers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Workers_id_seq"', 13, true);


--
-- Name: actors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.actors_id_seq', 1, true);


--
-- Name: genres_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.genres_id_seq', 1, false);


--
-- Name: grades_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.grades_id_seq', 150, true);


--
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.roles_id_seq', 13, true);


--
-- Name: sites_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sites_id_seq', 1, true);


--
-- Name: actors actors_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.actors
    ADD CONSTRAINT actors_pk PRIMARY KEY (id);


--
-- Name: genres genres_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genres
    ADD CONSTRAINT genres_pk PRIMARY KEY (id);


--
-- Name: grades grades_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grades
    ADD CONSTRAINT grades_pk PRIMARY KEY (id);


--
-- Name: movies_actors movies_actors_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movies_actors
    ADD CONSTRAINT movies_actors_pk PRIMARY KEY (id);


--
-- Name: movies movies_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movies
    ADD CONSTRAINT movies_pk PRIMARY KEY (id);


--
-- Name: roles roles_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pk PRIMARY KEY (id);


--
-- Name: sites sites_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sites
    ADD CONSTRAINT sites_pk PRIMARY KEY (id);


--
-- Name: workers workers_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workers
    ADD CONSTRAINT workers_pk PRIMARY KEY (id);


--
-- Name: movies_name_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX movies_name_uindex ON public.movies USING btree (name);


--
-- Name: movies_actors movies_actors_actors_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movies_actors
    ADD CONSTRAINT movies_actors_actors_id_fk FOREIGN KEY (actor_id) REFERENCES public.actors(id);


--
-- Name: movies_actors movies_actors_movies_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movies_actors
    ADD CONSTRAINT movies_actors_movies_id_fk FOREIGN KEY (movie_id) REFERENCES public.movies(id);


--
-- Name: movies movies_genres_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movies
    ADD CONSTRAINT movies_genres_id_fk FOREIGN KEY (genre_id) REFERENCES public.genres(id);


--
-- Name: workers workers_roles_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workers
    ADD CONSTRAINT workers_roles_id_fk FOREIGN KEY (role_id) REFERENCES public.roles(id);


--
-- PostgreSQL database dump complete
--

