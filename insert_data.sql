INSERT INTO system_rules (rule_name, rule_value) VALUES
('max', 4);

INSERT INTO job_title (id, job_title) VALUES
(1, 'Assistant Professor'),
(2, 'Associate Professor'),
(3, 'Department Manager'),
(4, 'Librarian');

INSERT INTO teaching_activity (id, activity_name, factor) VALUES
(1, 'Lecture', 3.6),
(2, 'Lab', 2.4),
(3, 'Tutorial', 2.4),
(4, 'Seminar', 1.8),
(5, 'Examination', 1.0),
(6, 'Administration', 1.0),
(7, 'Others', 1.5);

INSERT INTO study_period_ENUM (study_period_id, study_period) VALUES
(1, 'P1'),
(2, 'P2'),
(3, 'P3'),
(4, 'P4');

INSERT INTO skill_set (id, skill) VALUES
(1, 'Database Systems'),
(2, 'Discrete Mathematics'),
(3, 'Computer Security'),
(4, 'Software Engineering'),
(5, 'Classical Physics'),
(6, 'Quantum Mechanics'),
(7, 'Signal Processing'),
(8, 'Embedded Systems');

INSERT INTO person (id, personal_number, first_name, last_name) VALUES
(101, '750101-1234', 'Anna', 'Svensson'),
(102, '800202-5678', 'Björn', 'Lundgren'),
(103, '780303-9012', 'Carl', 'Magnusson'),
(104, '900404-3456', 'Daniela', 'Olsson'),
(105, '850505-1122', 'Elsa', 'Johansson'),
(106, '920606-3344', 'Fredrik', 'Andersson'),
(107, '830707-5566', 'Gustav', 'Eriksson'),
(108, '790808-7788', 'Helena', 'Karlsson'),
(109, '880909-9900', 'Ivar', 'Nilsson'),
(110, '911010-1133', 'Jenny', 'Lind'),
(111, '861111-2244', 'Klas', 'Månsson'),
(112, '771212-3355', 'Lina', 'Pettersson');

INSERT INTO department (id, department_name) VALUES
(1, 'Computer Science'),
(2, 'Mathematics'),
(3, 'Physics'),
(4, 'Industrial Engineering');

INSERT INTO employee (id_person, employment_id, salary, manager, id_job, id_department) VALUES
(101, 'CS-1001', 75000, 'Carl Magnusson', 2, 1),
(102, 'CS-1002', 60000, 'Anna Svensson', 1, 1),
(103, 'MA-2001', 90000, NULL, 3, 2),
(104, 'MA-2002', 70000, 'Carl Magnusson', 1, 2),
(105, 'CS-1003', 68000, 'Carl Magnusson', 1, 1),
(106, 'PH-3001', 72000, 'Carl Magnusson', 2, 3),
(107, 'IE-4001', 80000, 'Carl Magnusson', 2, 4),
(108, 'CS-1004', 65000, 'Carl Magnusson', 1, 1),
(109, 'MA-2003', 75000, 'Carl Magnusson', 1, 2),
(110, 'PH-3002', 62000, 'Carl Magnusson', 1, 3),
(111, 'IE-4002', 71000, 'Carl Magnusson', 1, 4),
(112, 'CS-1005', 73000, 'Carl Magnusson', 2, 1);

UPDATE department SET id_manager = 103 WHERE id = 1;
UPDATE department SET id_manager = 103 WHERE id = 2;
UPDATE department SET id_manager = 103 WHERE id = 3;
UPDATE department SET id_manager = 103 WHERE id = 4;

INSERT INTO employee_skill (id_skill, id_person) VALUES
(1, 101), (2, 102), (4, 104), (1, 105), (5, 106), (6, 106), (7, 107), (3, 108), (2, 109), (6, 110), (8, 111), (1, 112);

INSERT INTO address (id, street, zip, city) VALUES
(1, 'Sveavägen 10', '111 57', 'Stockholm'),
(2, 'Kungsgatan 50', '111 35', 'Stockholm'),
(3, 'Drottninggatan 25', '111 51', 'Stockholm'),
(4, 'Klarabergsgatan 4', '111 20', 'Stockholm'),
(5, 'Stortorget 1', '111 29', 'Stockholm'),
(6, 'Hamngatan 15', '111 47', 'Stockholm');

INSERT INTO person_address (id_person, id_address) VALUES
(101, 1), (103, 2), (105, 3), (107, 4), (109, 5), (111, 6);

INSERT INTO phone_number (id, phone_num, num_type) VALUES
(1, '070-987 65 43', 'Mobile'),
(2, '08-555 12 34', 'Office'),
(3, '070-111 22 33', 'Mobile'),
(4, '073-444 55 66', 'Mobile'),
(5, '08-777 88 99', 'Office'),
(6, '072-000 99 88', 'Mobile');

INSERT INTO person_phone (id_person, id_phone) VALUES
(101, 1), (103, 2), (105, 3), (107, 4), (109, 5), (111, 6);

INSERT INTO course_layout (id, course_code, course_name, min_students, max_students, hp) VALUES
(1, 'DD1351', 'Logic for CS', 50, 150, 7.5),
(2, 'DD2350', 'Algorithms & Data Structures', 50, 200, 9.5),
(3, 'EQ1110', 'Continuous Signals & Systems', 30, 100, 6.0),
(4, 'IV1350', 'Object Oriented Design', 40, 120, 7.5),
(5, 'ID1214', 'AI and Applied Methods', 50, 150, 7.5),
(6, 'DD2352', 'Algorithms & Complexity', 20, 80, 7.5),
(7, 'II1303', 'Signal Processing', 40, 110, 7.5),
(8, 'IS1300', 'Embedded Systems', 50, 150, 7.5),
(9, 'SF1686', 'Calculus in Several Var', 60, 250, 7.5),
(10, 'SK1118', 'Electromagnetism & Waves', 40, 100, 7.5),
(11, 'IL1333', 'Hardware Security', 30, 90, 7.5),
(12, 'SF1546', 'Numerical Methods', 50, 150, 6.0),
(13, 'ID1217', 'Concurrent Programming', 30, 100, 7.5),
(14, 'IV1351', 'Data Storage Paradigms', 50, 250, 7.5);

INSERT INTO course_instance (instance_id, id_layout, study_year, study_period_id, num_students) VALUES
('DD2350-2025P1P2-A', 2, 2025, 1, 180),
('DD1351-2025P1P2-A', 1, 2025, 1, 150),
('ID1214-2025P1P2-A', 5, 2025, 1, 120),
('IS1300-2025P1P2-A', 8, 2025, 1, 90),
('II1303-2025P3P4-E', 7, 2025, 3, 100),
('IV1351-2025P3P4-E', 14, 2025, 3, 80),
('ID1217-2025P3P4-E', 13, 2025, 3, 75),
('DD2352-2025P3P4-E', 6, 2025, 3, 50),
('SF1686-2025P1-B', 9, 2025, 1, 200),
('SF1546-2025P1-D', 12, 2025, 1, 100),
('IV1350-2025P1-H', 4, 2025, 1, 80),
('EQ1110-2025P1-I', 3, 2025, 1, 90),
('DD2350-2025P1-L', 2, 2025, 1, 50),
('SF1546-2025P2-D', 12, 2025, 2, 100),
('IV1350-2025P2-H', 4, 2025, 2, 80),
('EQ1110-2025P2-I', 3, 2025, 2, 90),
('DD2350-2025P2-L', 2, 2025, 2, 50),
('SK1118-2025P3-F', 10, 2025, 3, 70),
('IL1333-2025P3-J', 11, 2025, 3, 60),
('DD2352-2025P3-K', 6, 2025, 3, 40),
('SK1118-2025P4-F', 10, 2025, 4, 70),
('IL1333-2025P4-J', 11, 2025, 4, 60),
('DD2352-2025P4-K', 6, 2025, 4, 40);

INSERT INTO planned_activity (id_teaching, instance_id, planned_hours) VALUES
(1, 'DD2350-2025P1P2-A', 50), (6, 'DD2350-2025P1P2-A', 100), (5, 'DD2350-2025P1P2-A', 150),
(1, 'DD1351-2025P1P2-A', 40), (6, 'DD1351-2025P1P2-A', 80), (5, 'DD1351-2025P1P2-A', 120),
(1, 'ID1214-2025P1P2-A', 30), (6, 'ID1214-2025P1P2-A', 70), (5, 'ID1214-2025P1P2-A', 100),
(1, 'IS1300-2025P1P2-A', 35), (6, 'IS1300-2025P1P2-A', 85), (5, 'IS1300-2025P1P2-A', 110),
(1, 'II1303-2025P3P4-E', 30), (6, 'II1303-2025P3P4-E', 70), (5, 'II1303-2025P3P4-E', 100),
(1, 'IV1351-2025P3P4-E', 40), (6, 'IV1351-2025P3P4-E', 80), (5, 'IV1351-2025P3P4-E', 120),
(1, 'ID1217-2025P3P4-E', 35), (6, 'ID1217-2025P3P4-E', 75), (5, 'ID1217-2025P3P4-E', 110),
(1, 'DD2352-2025P3P4-E', 25), (6, 'DD2352-2025P3P4-E', 65), (5, 'DD2352-2025P3P4-E', 90),
(1, 'SF1686-2025P1-B', 40),
(2, 'SF1546-2025P1-D', 20),
(3, 'IV1350-2025P1-H', 30),
(4, 'EQ1110-2025P1-I', 25),
(1, 'DD2350-2025P1-L', 20),
(2, 'SF1546-2025P2-D', 20),
(3, 'IV1350-2025P2-H', 30),
(4, 'EQ1110-2025P2-I', 25),
(1, 'DD2350-2025P2-L', 20),
(1, 'SK1118-2025P3-F', 35),
(2, 'IL1333-2025P3-J', 25),
(3, 'DD2352-2025P3-K', 15),
(1, 'SK1118-2025P4-F', 35),
(2, 'IL1333-2025P4-J', 25),
(3, 'DD2352-2025P4-K', 15);

INSERT INTO allocations (id_person, id_teaching, instance_id) VALUES
(101, 1, 'DD2350-2025P1P2-A'),
(101, 1, 'DD1351-2025P1P2-A'),
(101, 5, 'ID1214-2025P1P2-A'),
(101, 1, 'IS1300-2025P1P2-A'),
(102, 1, 'SF1686-2025P1-B'),
(102, 1, 'DD2350-2025P1-L'),
(102, 4, 'EQ1110-2025P1-I'),
(102, 3, 'IV1350-2025P1-H'),
(105, 1, 'II1303-2025P3P4-E'),
(105, 1, 'IV1351-2025P3P4-E'),
(105, 1, 'ID1217-2025P3P4-E'),
(105, 1, 'DD2352-2025P3P4-E'),
(106, 1, 'SK1118-2025P3-F'),
(106, 3, 'DD2352-2025P3-K'),
(106, 1, 'SK1118-2025P4-F'),
(106, 3, 'DD2352-2025P4-K'),
(104, 2, 'SF1546-2025P1-D'),
(104, 3, 'IV1350-2025P1-H'),
(104, 2, 'SF1546-2025P2-D'),
(104, 3, 'IV1350-2025P2-H'),
(107, 1, 'DD1351-2025P1P2-A'),
(108, 3, 'IV1350-2025P2-H'),
(108, 4, 'EQ1110-2025P2-I'),
(109, 2, 'IL1333-2025P3-J'),
(109, 2, 'IL1333-2025P4-J'),
(110, 1, 'SK1118-2025P3-F'),
(110, 2, 'IL1333-2025P3-J'),
(110, 1, 'SK1118-2025P4-F'),
(110, 2, 'IL1333-2025P4-J'),
(111, 1, 'II1303-2025P3P4-E'),
(112, 5, 'ID1214-2025P1P2-A');
