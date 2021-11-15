-- Basic drop trigger function
DROP FUNCTION IF EXISTS delete_employee() CASCADE;
DROP FUNCTION IF EXISTS change_manager() CASCADE;
DROP FUNCTION IF EXISTS change_senior() CASCADE;
DROP FUNCTION IF EXISTS change_booker() CASCADE;
DROP FUNCTION IF EXISTS change_junior() CASCADE;
DROP FUNCTION IF EXISTS delete_room() CASCADE;
DROP FUNCTION IF EXISTS removing_employee() CASCADE;
DROP FUNCTION IF EXISTS changing_capacity() CASCADE;
DROP FUNCTION IF EXISTS removing_department() CASCADE;
DROP FUNCTION IF EXISTS check_employee() CASCADE;
DROP FUNCTION IF EXISTS check_room() CASCADE;
DROP FUNCTION IF EXISTS adding_junior() CASCADE;
-- Core&Health drop trigger function
DROP FUNCTION IF EXISTS edit_past_meeting() CASCADE;
DROP FUNCTION IF EXISTS delete_past_join() CASCADE;
DROP FUNCTION IF EXISTS cancel_meeting() CASCADE;
DROP FUNCTION IF EXISTS fever_join() CASCADE;
DROP FUNCTION IF EXISTS same_department() CASCADE;
DROP FUNCTION IF EXISTS alr_approve() CASCADE;
DROP FUNCTION IF EXISTS update_join() CASCADE;
DROP FUNCTION IF EXISTS resign_join() CASCADE;
DROP FUNCTION IF EXISTS exceed_capacity() CASCADE;
DROP FUNCTION IF EXISTS time_overlap() CASCADE;
DROP FUNCTION IF EXISTS fevered_cannot_book() CASCADE;
DROP FUNCTION IF EXISTS join_meeting_immediately() CASCADE;
DROP FUNCTION IF EXISTS remove_sessions_and_joins() CASCADE;
DROP FUNCTION IF EXISTS remove_non_future_session() CASCADE;
DROP FUNCTION IF EXISTS cannot_book_occupied_room() CASCADE;
DROP FUNCTION IF EXISTS cannot_delete_updates() CASCADE;
DROP FUNCTION IF EXISTS resigned_person_cannot_book_or_approve() CASCADE;
DROP FUNCTION IF EXISTS contact_tracing_fevered_staff() CASCADE;
DROP FUNCTION IF EXISTS only_booker_book_session() CASCADE;
DROP FUNCTION IF EXISTS derive_fever() CASCADE;
DROP FUNCTION IF EXISTS delete_hd() CASCADE;
-- Admin drop helper function
DROP FUNCTION IF EXISTS helper2(int, date) CASCADE;
DROP FUNCTION IF EXISTS helper1(int, date, date) CASCADE;

-- Basic drop procedure
DROP PROCEDURE IF EXISTS add_department(int, varchar) CASCADE;
DROP PROCEDURE IF EXISTS remove_department(int) CASCADE;
DROP PROCEDURE IF EXISTS add_room(int, int, varchar, int, int, DATE, int) CASCADE;
DROP PROCEDURE IF EXISTS change_capacity(int, int, int, int, DATE) CASCADE;
DROP PROCEDURE IF EXISTS add_employee(varchar, int, varchar, int) CASCADE;
DROP PROCEDURE IF EXISTS remove_employee(int, DATE) CASCADE;
-- Core drop function
DROP FUNCTION IF EXISTS search_room(INT, DATE, INT, INT) CASCADE;
DROP FUNCTION IF EXISTS book_room(INT, INT, DATE, INT, INT, INT) CASCADE;
DROP FUNCTION IF EXISTS unbook_room(INT, INT, DATE, INT, INT, INT) CASCADE;
DROP FUNCTION IF EXISTS join_meeting(INT, INT, DATE, INT, INT, INT) CASCADE;
DROP FUNCTION IF EXISTS leave_meeting(INT, INT, DATE, INT, INT, INT) CASCADE;
DROP FUNCTION IF EXISTS approve_meeting(INT, INT, DATE, INT, INT, INT) CASCADE;
-- Health drop function
DROP FUNCTION IF EXISTS declare_health(INT, DATE, FLOAT) CASCADE;
DROP FUNCTION IF EXISTS contact_tracing(INT) CASCADE;
-- Admin drop function
DROP FUNCTION IF EXISTS non_compliance(date, date) CASCADE;
DROP FUNCTION IF EXISTS view_booking_report(date, int) CASCADE;
DROP FUNCTION IF EXISTS view_future_meeting(date, int) CASCADE;
DROP FUNCTION IF EXISTS view_manager_report(date, int) CASCADE;


-- Basic
CREATE OR REPLACE FUNCTION adding_junior()
RETURNS TRIGGER AS $$
DECLARE
manager INT;
senior INT;
count INT;
BEGIN
SELECT COUNT(*) INTO manager FROM Managers WHERE eid = NEW.eid;
SELECT COUNT(*) INTO senior FROM Seniors WHERE eid = NEW.eid;
count = manager + senior;
IF (count != 0) THEN RAISE EXCEPTION 'Please put the employee into one and only one kind.';
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER adding_junior
AFTER INSERT ON Juniors
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION adding_junior();


CREATE OR REPLACE FUNCTION removing_department()
RETURNS TRIGGER AS $$
DECLARE
temp INT;
count INT;
id INT := OLD.did;
BEGIN
SELECT MAX(did) INTO temp FROM Departments;
SELECT COUNT(*) INTO count FROM Departments;
IF temp = id THEN 
SELECT MIN(did) INTO temp FROM Departments;
UPDATE Employees SET did = temp WHERE did = id;
ELSE UPDATE Employees SET did = temp WHERE did = id;
END IF;
UPDATE MeetingRooms SET did = temp WHERE did = id;
IF (count = 1) THEN RAISE NOTICE 'Company is closing down...';
END IF;
RETURN OLD;
END; 
$$ LANGUAGE plpgsql;

CREATE TRIGGER removing_department
BEFORE DELETE ON Departments
FOR EACH ROW EXECUTE FUNCTION removing_department();


CREATE OR REPLACE FUNCTION changing_capacity()
RETURNS TRIGGER AS $$
DECLARE
r_no INT := NEW.room;
f_no INT := NEW.storey;
id INT := NEW.eid;
rid INT;
mid INT;
BEGIN
SELECT did INTO rid FROM MeetingRooms WHERE room = r_no AND storey = f_no;
SELECT did INTO mid FROM Employees WHERE eid = id;
IF (rid != mid) THEN RAISE EXCEPTION 'Change_capacity failed, you don’t have permission to do so.';
END IF;
IF NEW.update_date != CURRENT_DATE THEN RAISE EXCEPTION 'update_date should be current date.';
END IF;
DELETE FROM Sessions s 
    WHERE s.book_date > CURRENT_DATE
    AND s.storey = f_no
    AND s.room = r_no
    AND NEW.new_cap < (
        SELECT COUNT(*) FROM Joins j
        WHERE j.book_date = s.book_date
        AND j.start_hour = s.start_hour
        AND j.storey = s.storey
        AND j.room = s.room
    );
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER changing_capacity
BEFORE UPDATE ON Updates
FOR EACH ROW EXECUTE FUNCTION changing_capacity();


CREATE OR REPLACE FUNCTION removing_employee()
RETURNS TRIGGER AS $$
DECLARE
id INT := OLD.eid;
date DATE := NEW.resigned_date;
BEGIN
DELETE FROM Sessions WHERE eid = id AND book_date > date;
DELETE FROM Joins WHERE eid = id AND book_date > date;
RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER removing_employee
BEFORE UPDATE OF resigned_date ON Employees
FOR EACH ROW EXECUTE FUNCTION removing_employee();


CREATE OR REPLACE FUNCTION delete_employee()
RETURNS TRIGGER AS $$
BEGIN
RAISE EXCEPTION 'You are not supposed to delete employees.';
RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER delete_employee
BEFORE DELETE ON Employees
FOR EACH STATEMENT EXECUTE FUNCTION delete_employee();


CREATE OR REPLACE FUNCTION delete_room()
RETURNS TRIGGER AS $$
BEGIN
RAISE EXCEPTION 'You are not supposed to delete rooms.';
RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER delete_room
BEFORE DELETE ON MeetingRooms
FOR EACH STATEMENT EXECUTE FUNCTION delete_room();


CREATE OR REPLACE FUNCTION change_manager()
RETURNS TRIGGER AS $$
BEGIN
RAISE EXCEPTION 'You are not supposed to change managers information.';
RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER change_manager
BEFORE DELETE OR UPDATE ON Managers
FOR EACH STATEMENT EXECUTE FUNCTION change_manager();


CREATE OR REPLACE FUNCTION change_senior()
RETURNS TRIGGER AS $$
BEGIN
RAISE EXCEPTION 'You are not supposed to change seniors information.';
RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER change_senior
BEFORE DELETE OR UPDATE ON Seniors
FOR EACH STATEMENT EXECUTE FUNCTION change_senior();


CREATE OR REPLACE FUNCTION change_booker()
RETURNS TRIGGER AS $$
BEGIN
RAISE EXCEPTION 'You are not supposed to change bookers information.';
RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER change_booker
BEFORE DELETE OR UPDATE ON Bookers
FOR EACH STATEMENT EXECUTE FUNCTION change_booker();


CREATE OR REPLACE FUNCTION change_junior()
RETURNS TRIGGER AS $$
BEGIN
RAISE EXCEPTION 'You are not supposed to change juniors information.';
RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER change_junior
BEFORE DELETE OR UPDATE ON Juniors
FOR EACH STATEMENT EXECUTE FUNCTION change_junior();


CREATE OR REPLACE FUNCTION check_employee()
RETURNS TRIGGER AS $$
DECLARE
manager INT;
senior INT;
junior INT;
booker INT;
count INT;
BEGIN
SELECT COUNT(*) INTO manager FROM Managers WHERE eid = NEW.eid;
SELECT COUNT(*) INTO senior FROM Seniors WHERE eid = NEW.eid;
SELECT COUNT(*) INTO booker FROM Bookers WHERE eid = NEW.eid;
count = manager + senior;
IF (count != booker) THEN RAISE EXCEPTION 'Please check that all managers and seniors are INSERTed into their tables and no junior is in Bookers.';
END IF;
SELECT COUNT(*) INTO junior FROM Juniors WHERE eid = NEW.eid;
count = count + junior;
IF (count != 1) THEN RAISE EXCEPTION 'Please put the employee into one and only one kind.';
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER check_employee
AFTER INSERT ON Employees
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_employee();


CREATE OR REPLACE FUNCTION check_room()
RETURNS TRIGGER AS $$
DECLARE
mid INT; 
department INT;
count INT;
BEGIN
SELECT COUNT(*) INTO count FROM Updates WHERE room = NEW.room AND storey = NEW.storey;
IF (count != 1) THEN RAISE EXCEPTION 'Add room failed, every room must have one capacity record in Updates.';
END IF;
SELECT eid INTO mid FROM Updates WHERE room = NEW.room AND storey = NEW.storey;
SELECT did INTO department FROM Employees WHERE eid = mid;
IF (NEW.did != department) THEN
RAISE EXCEPTION 'Add room failed, you don’t have permission to do so.';
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER check_room
AFTER INSERT ON MeetingRooms
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_room();


CREATE OR REPLACE PROCEDURE add_department
(id INT, name VARCHAR(255))
AS $$
BEGIN
INSERT INTO Departments (did, dname) VALUES (id, name);
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE remove_department (id INT)
AS $$
BEGIN
DELETE FROM Departments WHERE did = id;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE add_room
(f_no INT, r_no INT, name VARCHAR(255), d_id INT, cap INT, date DATE, id INT)
AS $$
DECLARE
mid INT; 
BEGIN
SELECT did INTO mid FROM Employees WHERE eid = id;
IF (d_id = mid) THEN
INSERT INTO MeetingRooms (room, storey, rname, did) VALUES (r_no, f_no, name, d_id);
INSERT INTO Updates (update_date, new_cap, eid, room, storey) VALUES (date, cap, id, r_no, f_no);
ELSE RAISE EXCEPTION 'Add_room failed, you don’t have permission to do so.';
END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE change_capacity
(f_no INT, r_no INT, id INT, cap INT, date DATE)
AS $$
BEGIN
UPDATE Updates SET update_date = date, new_cap = cap, eid = id WHERE room = r_no AND storey = f_no;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE add_employee
(name VARCHAR(255), number INTEGER, kind VARCHAR(255), d INTEGER)
AS $$
DECLARE
id INT;
email VARCHAR(25);
BEGIN
SELECT (MAX(eid) + 1) INTO id FROM Employees;
email = CONCAT (name, id, '@company.com');
INSERT INTO Employees (eid, ename, mobile_phone, email, did) VALUES (id, name, number, email, d);
IF (UPPER(kind) = 'JUNIOR') THEN INSERT INTO Juniors (eid) VALUES (id);
ELSIF (UPPER(kind) = 'SENIOR') THEN 
INSERT INTO Bookers (eid) VALUES (id);
INSERT INTO Seniors (eid) VALUES (id);
ELSIF (UPPER(kind) = 'MANAGER') THEN 
INSERT INTO Bookers (eid) VALUES (id);
	INSERT INTO Managers (eid) VALUES (id);
ELSE RAISE EXCEPTION 'Add_employee failed, wrong format for employee kind.';
END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE remove_employee (id INT, date DATE)
AS $$
BEGIN
UPDATE Employees SET resigned_date = date WHERE eid = id;
END;
$$ LANGUAGE plpgsql;



-- Core&Health
CREATE OR REPLACE FUNCTION fevered_cannot_book() RETURNS TRIGGER AS $$ 
DECLARE 
fevered BOOLEAN;
BEGIN 
  IF NOT EXISTS (SELECT * FROM HealthDeclarations d 
    WHERE d.eid = NEW.eid AND d.declare_date = (SELECT CURRENT_DATE)) THEN 
    RAISE EXCEPTION 'The employee has not declared temperature for today. Cannot book any meeting.';
    RETURN NULL;

  ELSE
    SELECT fever INTO fevered FROM HealthDeclarations 
    WHERE HealthDeclarations.eid = NEW.eid 
    AND HealthDeclarations.declare_date = CURRENT_DATE;

    IF (fevered = true) THEN
        RAISE EXCEPTION 'This person is fevered and cannot book meetings';
        RETURN NULL;
    ELSE RETURN NEW;
    END IF;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER cannot_book 
BEFORE INSERT ON Sessions 
FOR EACH ROW EXECUTE FUNCTION fevered_cannot_book();


CREATE OR REPLACE FUNCTION join_meeting_immediately() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO JOINS VALUES (NEW.eid, NEW.book_date, NEW.start_hour, NEW.room, NEW.storey);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER join_immediately
AFTER INSERT ON Sessions
FOR EACH ROW EXECUTE FUNCTION join_meeting_immediately();


CREATE OR REPLACE FUNCTION remove_sessions_and_joins() RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM Sessions s
    WHERE s.book_date >= NEW.update_date 
           AND s.room = NEW.room AND s.storey = NEW.storey AND (SELECT count(*) FROM Joins j
           WHERE s.book_date = j.book_date AND s.start_hour = j.start_hour AND 
           s.storey = j.storey AND s.room = j.room) > NEW.new_cap;
    RETURN NEW;
END; 
$$ LANGUAGE plpgsql;

CREATE TRIGGER exceed_new_capacity
AFTER UPDATE ON Updates
FOR EACH ROW EXECUTE FUNCTION remove_sessions_and_joins();


CREATE OR REPLACE FUNCTION remove_non_future_session() RETURNS TRIGGER AS $$
DECLARE 
currentDate DATE;
BEGIN
SELECT current_date INTO currentDate;
    IF (OLD.book_date < currentDate) THEN
    RAISE NOTICE 'You can only cancel future meetings.';
    RETURN NULL;
    ELSE 
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER only_future_session
BEFORE DELETE ON Sessions
FOR EACH ROW EXECUTE FUNCTION remove_non_future_session();


CREATE OR REPLACE FUNCTION only_booker_book_session() RETURNS TRIGGER AS $$
DECLARE
count INT;
BEGIN 
    SELECT count(*) INTO count FROM Bookers b WHERE b.eid = NEW.eid;
    IF (count = 0) THEN 
        RAISE NOTICE 'This person cannot book meetings';
        RETURN NULL;
    ELSE
        RETURN NEW;
    END IF; 
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER only_booker_book 
BEFORE INSERT OR UPDATE ON Sessions
FOR EACH ROW EXECUTE FUNCTION only_booker_book_session();


CREATE OR REPLACE FUNCTION cannot_book_occupied_room() RETURNS TRIGGER AS $$
DECLARE 
judge INT;
BEGIN 
    SELECT count(*) INTO judge
    FROM search_room(0, NEW.book_date, NEW.start_hour, NEW.start_hour + 1) AS rooms 
    WHERE rooms.floor_number = NEW.storey AND rooms.room_number = NEW.room;

    IF (judge = 0) THEN 
        RAISE NOTICE 'The meeting room is occupied in that period';
        RETURN NULL;
    ELSE 
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER room_is_occupied 
BEFORE INSERT ON Sessions
FOR EACH ROW EXECUTE FUNCTION cannot_book_occupied_room();


CREATE OR REPLACE FUNCTION cannot_delete_updates() RETURNS TRIGGER AS $$
BEGIN
    RAISE NOTICE 'You cannot delete from Updates';
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER delete_updates
BEFORE DELETE ON Updates
FOR EACH ROW EXECUTE FUNCTION cannot_delete_updates();


CREATE OR REPLACE FUNCTION resigned_person_cannot_book_or_approve() RETURNS TRIGGER AS $$
DECLARE 
count INT;
BEGIN
    SELECT count(*) INTO count FROM Employees e
    WHERE e.eid = NEW.eid AND (e.resigned_date IS DISTINCT FROM NULL AND e.resigned_date >= (SELECT current_date));

    IF (count > 0) THEN 
        RAISE NOTICE 'This person has resigned and cannot book meetings';
        RETURN NULL;
    ELSE 
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER resigned_person_insert
BEFORE INSERT OR UPDATE ON Sessions
FOR EACH ROW EXECUTE FUNCTION resigned_person_cannot_book_or_approve();


CREATE OR REPLACE FUNCTION contact_tracing_fevered_staff() RETURNS TRIGGER AS $$
DECLARE
    currentDate DATE;
BEGIN
    SELECT CURRENT_DATE INTO currentDate;
    IF (NEW.fever = true) THEN 
        DELETE FROM Joins j
        WHERE j.eid = NEW.eid AND j.book_date >= currentDate;

        DELETE FROM Sessions s 
        WHERE s.eid = NEW.eid AND s.book_date >= currentDate; 

        DELETE FROM Joins 
        WHERE Joins.book_date >= currentDate AND Joins.book_date <= currentDate + 7 
        AND NEW.eid IN 
        (SELECT DISTINCT j.eid FROM JOINS j 
        WHERE ROW(j.book_date, j.start_hour, j.room, j.storey) IN 
            (SELECT j1.book_date AS book_date, j1.start_hour AS start_hour, j1.room AS room, j1.storey AS storey FROM Joins j1
             WHERE j1.eid = NEW.eid AND j1.book_date >= currentDate - 3 AND j1.book_date < currentDate));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER fevered_contact_tracing
AFTER INSERT OR UPDATE ON HealthDeclarations
FOR EACH ROW EXECUTE FUNCTION contact_tracing_fevered_staff();



CREATE OR REPLACE FUNCTION search_room
	(capacity_in INT, date DATE, search_start_hour INT, search_end_hour INT)
RETURNS table (
	floor_number INT, 
	room_number INT, 
	department_id INT, 
	capacity INT
) AS $$
BEGIN
	IF search_start_hour >= search_end_hour 
		THEN RAISE NOTICE 'The time of this meeting is invalid'; RETURN;
	ELSE
		return query SELECT * FROM
		((SELECT m.storey AS floor_number, m.room AS room_number, m.did AS department_id, u.new_cap AS capacity
		FROM MeetingRooms m NATURAL JOIN Updates u
		WHERE u.new_cap >= capacity_in)
		EXCEPT ALL
		(SELECT n.storey AS floor_number, n.room AS room_number, n.did AS department_id, u.new_cap AS capacity
		FROM (SELECT * FROM MeetingRooms m NATURAL JOIN Sessions s
		WHERE s.book_date = date AND s.start_hour >= search_start_hour 
            AND s.start_hour < search_end_hour)
			  AS n JOIN Updates u 
		ON n.room = u.room AND n.storey = u.storey AND u.new_cap >= capacity_in)) AS b
		ORDER BY capacity ASC;
	END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION book_room 
	(book_floor_number INT, book_room_number INT, book_date DATE, book_start_hour INT, 
        book_end_hour INT, eidBooker INT)
RETURNS VOID AS $$
DECLARE 
	count INT := 0;
	judge INT := 0;
    startHour INT := 0;
    endHour INT := 0;
BEGIN
	IF book_start_hour >= book_end_hour 
		THEN RAISE NOTICE 'The time of this meeting is invalid'; RETURN;
	END IF;
	startHour := book_start_hour;
    endHour :=  book_end_hour;
    LOOP
        EXIT WHEN startHour = endHour;
        INSERT INTO Sessions VALUES(book_date, startHour, eidBooker, 
        book_room_number, book_floor_number, 
		NULL);
        startHour := startHour + 1;
    END LOOP;
	RETURN;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION unbook_room
    (unbook_floor_number INT, unbook_room_number INT, unbook_date DATE, 
        unbook_start_hour INT, unbook_end_hour INT, unbook_eid INT) 
RETURNS VOID AS $$ 
DECLARE 
    eidBooked INT := -1;
    sessions_number INT;
BEGIN
	IF unbook_start_hour >= unbook_end_hour 
		THEN RAISE EXCEPTION 'The time of this meeting is invalid'; RETURN;
	END IF;

    SELECT count(*) INTO sessions_number FROM Sessions s 
    WHERE s.storey = unbook_floor_number AND s.room = unbook_room_number 
    AND s.book_date = unbook_date AND s.eid = unbook_eid 
    AND s.start_hour >= unbook_start_hour
    AND s.start_hour < unbook_end_hour;
    
    IF (sessions_number < unbook_end_hour - unbook_start_hour) 
    	THEN RAISE EXCEPTION 'The meeting does not exist or the unbooker is not the booker.'; RETURN;
    ELSE
        DELETE FROM Joins j WHERE j.book_date = unbook_date AND j.start_hour >= unbook_start_hour 
        AND j.start_hour < unbook_end_hour AND j.room = unbook_room_number 
        AND j.storey = unbook_floor_number;

        DELETE FROM Sessions s WHERE s.book_date = unbook_date 
        AND s.start_hour >= unbook_start_hour 
        AND s.start_hour < unbook_end_hour 
        AND s.room = unbook_room_number 
        AND s.storey = unbook_floor_number;
    END IF;
    RETURN;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION contact_tracing(targetEid INT)
RETURNS table (
    eid INT
) AS $$
DECLARE 
    hasFever BOOLEAN := false;
    currentDate DATE;
BEGIN
    SELECT CURRENT_DATE INTO currentDate;

    SELECT fever FROM HealthDeclarations INTO hasFever 
    WHERE HealthDeclarations.eid = targetEid AND HealthDeclarations.declare_date = currentDate;

    IF (hasFever = true) THEN    
        RETURN query SELECT DISTINCT j.eid FROM JOINS j 
        WHERE ROW(j.book_date, j.start_hour, j.room, j.storey) IN 
            (SELECT j1.book_date AS book_date, j1.start_hour AS start_hour, j1.room AS room, j1.storey AS storey 
            FROM Joins j1
            WHERE j1.eid = targetEid AND j1.book_date >= currentDate - 3 AND j1.book_date < currentDate);
    END IF;
END;
$$ LANGUAGE plpgsql;




CREATE OR REPLACE FUNCTION derive_fever() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.temperature > 37.5 
    THEN NEW.fever := true;
    ELSE NEW.fever := false;
    END If;
    IF NEW.declare_date != CURRENT_DATE
    THEN RAISE EXCEPTION 'Can only declare for today.';
    RETURN NULL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER fever_derive
BEFORE INSERT OR UPDATE ON HealthDeclarations
FOR EACH ROW EXECUTE FUNCTION derive_fever();


CREATE OR REPLACE FUNCTION delete_hd() RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'You should not delete from health declarations.';
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER hd_delete
BEFORE DELETE ON HealthDeclarations
FOR EACH ROW EXECUTE FUNCTION delete_hd();




-- constraint 26: Employee can only join future meeting 
CREATE OR REPLACE FUNCTION edit_past_meeting()
RETURNS TRIGGER AS $$
DECLARE 
 cur_date DATE;
BEGIN 
 SELECT current_date INTO cur_date;
 IF cur_date > NEW.book_date THEN
  RAISE EXCEPTION 'The meeting has already started/ended. No more modification can be done.';
  RETURN NULL;
 ELSE RETURN NEW;
 END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER not_future_JoinInsert
BEFORE INSERT ON Joins 
FOR EACH ROW EXECUTE FUNCTION edit_past_meeting();

CREATE TRIGGER not_future_SessionUpdate
BEFORE Update ON Sessions
FOR EACH ROW EXECUTE FUNCTION edit_past_meeting();

----------------------------------------------------------------------------------------------------------
-- Joins does not allow deletion for past meeting
CREATE OR REPLACE FUNCTION delete_past_join()
RETURNS TRIGGER AS $$
DECLARE 
 cur_date DATE;
BEGIN 
 SELECT current_date INTO cur_date;
 IF cur_date > OLD.book_date THEN
  RAISE EXCEPTION 'The meeting has already started/ended. No more modification can be done.';
  RETURN NULL;
 ELSE RETURN OLD;
 END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER not_future_JoinDelete 
BEFORE DELETE ON Joins 
FOR EACH ROW EXECUTE FUNCTION delete_past_join();

----------------------------------------------------------------------------------------------------------
-- if booker choose to leave meeting, session cancelled 
CREATE OR REPLACE FUNCTION cancel_meeting()
RETURNS TRIGGER AS $$
BEGIN
	IF EXISTS(SELECT eid FROM Sessions s
			WHERE s.eid = OLD.eid AND s.book_date = OLD.book_date
			AND s.start_hour = OLD.start_hour AND s.room = OLD.room AND s.storey = OLD.storey) THEN
		DELETE FROM Sessions s WHERE s.book_date = OLD.book_date AND s.room = OLD.room 
		AND s.storey = OLD.storey AND s.start_hour = OLD.start_hour AND s.eid = OLD.eid;
		RETURN NULL;
	ELSE RETURN NULL;
	END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER cancel_whole_session
AFTER DELETE ON Joins
FOR EACH ROW EXECUTE FUNCTION cancel_meeting();

----------------------------------------------------------------------------------------------------------
-- constraint 19: employee with fever not allowed to join meeting 
CREATE OR REPLACE FUNCTION fever_join()
RETURNS TRIGGER AS $$
DECLARE
 is_fevered BOOLEAN;
BEGIN
    IF NOT EXISTS (SELECT * FROM HealthDeclarations WHERE HealthDeclarations.eid = NEW.eid AND HealthDeclarations.declare_date = CURRENT_DATE) THEN
        RAISE EXCEPTION 'The employee has not declared temperature for today. Cannot join any meeting.';
        RETURN NULL;
    ELSE
    SELECT fever INTO is_fevered FROM HealthDeclarations 
    WHERE HealthDeclarations.eid = NEW.eid 
    AND HealthDeclarations.declare_date = CURRENT_DATE;

    IF is_fevered THEN
    RAISE EXCEPTION 'The employee is having fever, cannot join the meeting.';
    RETURN NULL;
    ELSE RETURN NEW;
    END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER fever_person_join_meeting
BEFORE INSERT ON Joins 
FOR EACH ROW EXECUTE FUNCTION fever_join();

----------------------------------------------------------------------------------------------------------
-- constraint 21: approver must be a manager and must be from same department 
CREATE OR REPLACE FUNCTION same_department()
RETURNS TRIGGER AS $$
DECLARE 
	is_manager BOOLEAN;
	room_did INT;
	manager_did INT;
BEGIN
	IF EXISTS (SELECT * FROM Managers WHERE Managers.eid = NEW.approve_id) THEN is_manager := TRUE;
	ELSE is_manager := FALSE;
	END IF;

	IF NOT is_manager THEN 
		RAISE EXCEPTION 'Not a manager, cannot approve meeting.';
		RETURN NULL;
	ELSE 
		SELECT did INTO room_did 
		FROM (Sessions NATURAL JOIN MeetingRooms) AS booking
		WHERE booking.room = NEW.room AND booking.storey = NEW.storey 
		AND booking.book_date = NEW.book_date AND booking.start_hour = NEW.start_hour;

		SELECT did INTO manager_did 
		FROM Employees NATURAL JOIN Managers
		WHERE NEW.approve_id = Managers.eid;

		IF (room_did IS DISTINCT FROM manager_did) THEN 
			RAISE EXCEPTION 'Manager not from same department, approval rejected';
			RETURN NULL;
		ELSE RETURN NEW;
		END IF;
	END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER same_dep_approval
BEFORE UPDATE ON Sessions
FOR EACH ROW EXECUTE FUNCTION same_department();

----------------------------------------------------------------------------------------------------------
-- constraint 22: approval can only be done once 
CREATE OR REPLACE FUNCTION alr_approve()
RETURNS TRIGGER AS $$
DECLARE 
	is_approved BOOLEAN;
BEGIN 
	IF (SELECT approve_id FROM Sessions WHERE Sessions.book_date = NEW.book_date AND Sessions.start_hour = NEW.start_hour AND 
			Sessions.room = NEW.room AND Sessions.storey = NEW.storey) IS NOT NULL THEN is_approved := TRUE;
	ELSE is_approved := FALSE;
	END IF;

	IF is_approved THEN 
		RAISE NOTICE 'The meeting is already approved by a manager. No more change can be done.';
		RETURN NULL;
	ELSE RETURN NEW;
	END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER approve_meeting_twice
BEFORE UPDATE ON Sessions
FOR EACH ROW EXECUTE FUNCTION alr_approve();

-- can only join non approved meeting
CREATE TRIGGER join_an_approved_meeting
BEFORE INSERT ON Joins
FOR EACH ROW EXECUTE FUNCTION alr_approve();

----------------------------------------------------------------------------------------------------------
-- schema constraint: joins do not allow update 
CREATE OR REPLACE FUNCTION update_join()
RETURNS TRIGGER AS $$
BEGIN
	RAISE EXCEPTION 'Updating Joins is not allowed.';
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER join_no_update
BEFORE UPDATE ON Joins
FOR EACH STATEMENT EXECUTE FUNCTION update_join();

----------------------------------------------------------------------------------------------------------
-- extra constraint: resigned employee not allow to join meeting
CREATE OR REPLACE FUNCTION resign_join()
RETURNS TRIGGER AS $$
DECLARE 
	is_resigned BOOLEAN;
BEGIN
	IF (SELECT resigned_date FROM Employees WHERE NEW.eid = Employees.eid) < NEW.book_date THEN
		is_resigned := TRUE;
	ELSE is_resigned := FALSE;
	END IF;

	IF is_resigned THEN
		RAISE EXCEPTION 'The employee has resigned. Cannot join meeting.';
		RETURN NULL;
	ELSE RETURN NEW;
	END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER resign_cannot_join
BEFORE INSERT ON Joins
FOR EACH ROW EXECUTE FUNCTION resign_join();

----------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION exceed_capacity()
RETURNS TRIGGER AS $$
DECLARE 
	cur_cap INT;
	max_cap INT; 
BEGIN
	SELECT COUNT(*) INTO cur_cap FROM Joins WHERE Joins.book_date = NEW.book_date AND 
	Joins.start_hour = NEW.start_hour AND Joins.room = NEW.room AND Joins.storey = NEW.storey;
	SELECT new_cap INTO max_cap FROM Updates WHERE Updates.room = NEW.room AND Updates.storey = NEW.storey;

	IF (cur_cap >= max_cap) THEN 
		RAISE EXCEPTION 'Already reached max capacity. Cannot add any more people.';
		RETURN NULL;
	ELSE RETURN NEW;
	END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER exceed_max_capacity
BEFORE INSERT ON Joins 
FOR EACH ROW EXECUTE FUNCTION exceed_capacity();

----------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION time_overlap()
RETURNS TRIGGER AS $$
DECLARE 
	overlap BOOLEAN;
BEGIN
    IF EXISTS (SELECT * FROM Joins WHERE Joins.eid = NEW.eid AND Joins.book_date = NEW.book_date AND Joins.start_hour = NEW.start_hour) THEN
        RAISE NOTICE'You already have a meeting at: %', NEW.start_hour;
        RAISE NOTICE'You are not allow to join other meeting within this duration.';
        RETURN NULL;
    ELSE RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER join_overlapping_session
BEFORE INSERT ON Joins 
FOR EACH ROW EXECUTE FUNCTION time_overlap();



-- FUNCTIONS 
--join_meeting 
CREATE OR REPLACE FUNCTION join_meeting 
(room_num INT, floor INT, meeting_date DATE, meeting_start_hour INT, end_hour INT, employee_id INT)
RETURNS VOID AS $$
DECLARE
	start INT;
BEGIN
	start := meeting_start_hour;
    LOOP
    	EXIT WHEN start = end_hour;
    	INSERT INTO Joins VALUES (employee_id, meeting_date, start, room_num, floor);
    	start := start + 1;
    END LOOP;
END;
$$ LANGUAGE plpgsql; 

-- leaving_meeting 
CREATE OR REPLACE FUNCTION leave_meeting 
(room_num INT, floor INT, meeting_date DATE, meeting_start_hour INT, end_hour INT, employee_id INT)
RETURNS VOID AS $$
DECLARE
 found_record BOOLEAN;
 is_approved BOOLEAN;
BEGIN
 -- check if already inside the meeting 
 IF EXISTS (SELECT * FROM Joins WHERE Joins.eid = employee_id AND Joins.book_date = meeting_date AND Joins.start_hour = meeting_start_hour AND 
  Joins.room = room_num AND Joins.storey = floor) THEN
  found_record := TRUE;
 ELSE found_record := FALSE;
 END IF;

 -- check approve status 
 IF (SELECT approve_id FROM Sessions WHERE Sessions.book_date = meeting_date AND Sessions.start_hour = meeting_start_hour AND 
     Sessions.room = room_num AND Sessions.storey = floor) IS NOT NULL THEN
     is_approved := TRUE;
 ELSE is_approved := FALSE; 
 END IF;

 -- perform leave 
 IF found_record AND NOT is_approved THEN 
  DELETE FROM Joins WHERE Joins.eid = employee_id AND Joins.book_date = meeting_date 
  AND Joins.room = room_num AND Joins.storey = floor
  AND Joins.start_hour >= start_hour AND Joins.start_hour < end_hour;
 ELSE 
  RAISE NOTICE 'Employee is not inside the meeting or the meeting is already approved.';
 END IF; 
END;
$$ LANGUAGE plpgsql;

--approve meeting
CREATE OR REPLACE FUNCTION approve_meeting 
(room_num INT, floor INT, meeting_date DATE, meeting_start_hour INT, end_hour INT, manager_id INT)
RETURNS VOID AS $$
DECLARE
	start INT;
BEGIN
	start := meeting_start_hour;
    LOOP
        EXIT WHEN start = end_hour;
		UPDATE Sessions SET approve_id = manager_id
		WHERE Sessions.book_date = meeting_date AND Sessions.start_hour = start AND Sessions.room = room_num AND Sessions.storey = floor;
		start := start + 1;
	END LOOP;
END;
$$ LANGUAGE plpgsql;

--declare_health
CREATE OR REPLACE FUNCTION declare_health(employee_id INT, declare_date DATE, temperature FLOAT)
RETURNS VOID AS $$
BEGIN 
	INSERT INTO HealthDeclarations VALUES(declare_date, temperature, NULL, employee_id);
END;
$$ LANGUAGE plpgsql;



-- Admin
CREATE OR REPLACE FUNCTION helper2(employee INT, end_date DATE)
RETURNS DATE AS $$
DECLARE
    resign_date DATE;
BEGIN
    SELECT resigned_date INTO resign_date FROM Employees WHERE eid = employee;
    IF resign_date < end_date THEN RETURN resign_date;
    ELSE RETURN end_date;
    END IF;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION helper1(employee INT, start_date DATE, end_date DATE)
RETURNS INT AS $$
    SELECT end_date-start_date+1 - COUNT(*) AS days
    FROM HealthDeclarations
    WHERE declare_date >= start_date AND declare_date <= end_date
    AND eid = employee
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION non_compliance(start_date DATE, end_date DATE)
RETURNS TABLE(eid INT, days INT) AS $$
    WITH temp AS (
        SELECT eid, helper1(eid, start_date, helper2(eid, end_date)) AS days
        FROM Employees)
    SELECT eid, days
    FROM temp
    WHERE days > 0
    ORDER BY days DESC, eid ASC;
$$ LANGUAGE sql;


CREATE OR REPLACE FUNCTION view_booking_report(start_date DATE, employee INT)
RETURNS TABLE(storey INT, room INT, book_date DATE, start_hour INT, approved BOOLEAN) AS $$
    SELECT storey, room, book_date, start_hour, CASE
        WHEN approve_id IS NULL THEN false
        ELSE true END AS approved
    FROM Sessions
    WHERE eid = employee AND book_date >= start_date
    ORDER BY book_date ASC, start_hour ASC;
$$ LANGUAGE sql;


CREATE OR REPLACE FUNCTION view_future_meeting(start_date DATE, employee INT)
RETURNS TABLE(storey INT, room INT, book_date DATE, start_hour INT) AS $$
    SELECT storey, room, book_date, start_hour
    FROM Joins j
    WHERE eid = employee AND book_date >= start_date
    AND (SELECT s.approve_id FROM Sessions s 
        WHERE s.book_date = j.book_date
        AND s.start_hour = j.start_hour
        AND s.storey = j.storey
        AND s.room = j.room) IS NOT NULL 
    ORDER BY book_date ASC, start_hour ASC;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION view_manager_report(start_date DATE, employee INT)
RETURNS TABLE(storey INT, room INT, book_date DATE, start_hour INT, eid INT) AS $$
    SELECT storey, room, book_date, start_hour, eid
    FROM Sessions
    WHERE approve_id IS NULL
    AND book_date >= start_date
    AND (storey, room) IN (
        SELECT storey, room
        FROM MeetingRooms
        WHERE did = (
            SELECT did FROM Employees 
            WHERE eid = employee)
    )
    ORDER BY book_date ASC, start_hour ASC;
$$ LANGUAGE sql;