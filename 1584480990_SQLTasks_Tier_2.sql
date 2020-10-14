/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 2 of the case study, which means that there'll be less guidance for you about how to setup
your local SQLite connection in PART 2 of the case study. This will make the case study more challenging for you: 
you might need to do some digging, aand revise the Working with Relational Databases in Python chapter in the previous resource.

Otherwise, the questions in the case study are exactly the same as with Tier 1. 

PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface. 
Log in by pasting the following URL into your browser, and
using the following Username and Password:

URL: https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */


/* QUESTIONS 
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */

SELECT 
	name 
FROM `Facilities` 
WHERE membercost > 0;

/* Q2: How many facilities do not charge a fee to members? */

SELECT 
	COUNT(facid) 
FROM `Facilities` 
WHERE membercost > 0;

/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */

SELECT 
	facid, 
	name, 
	membercost, 
	monthlymaintenance
FROM `Facilities`
WHERE membercost < 0.2 * monthlymaintenance AND membercost >0;

/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */

SELECT 
	*
FROM `Facilities`
WHERE facid IN ( 1, 5 );


/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */

SELECT 
	name,
	monthlymaintenance,
	CASE WHEN monthlymaintenance > 100 THEN 'expensive'
		ELSE 'cheap' END AS facility_type
FROM `Facilities` ;


/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */

SELECT 
	firstname,
	surname
FROM `Members` 
WHERE joindate = (
		SELECT MAX(joindate)
    		FROM `Members`);

/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */

SELECT DISTINCT
	t.name as facility_name,
	CONCAT(firstname, surname) as name
FROM `Bookings` b
INNER JOIN (
    	SELECT
			facid,
			name
		FROM `Facilities`
		WHERE  name like '%Tennis Court%') t
ON b.facid = t.facid
INNER JOIN `Members` m
ON b.memid = m.memid;
		

/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

SELECT 
	bookid,
	CASE WHEN b.memid = 0 THEN guestcost
		ELSE membercost END * slots as cost
FROM `Bookings` b 
INNER JOIN `Facilities` f 
ON b.facid = f.facid
WHERE b.starttime LIKE '2012-09-14%' 
AND (CASE WHEN b.memid = 0 THEN guestcost
		ELSE membercost END) * slots > 30
ORDER BY cost DESC;

/* Q9: This time, produce the same result as in Q8, but using a subquery. */
SELECT 
	bookid,
	slots * (
			SELECT 
				CASE WHEN b.memid = 0 THEN guestcost
					ELSE membercost END AS COST
			FROM `Facilities` f
			WHERE b.facid = f.facid
			) AS cost
FROM `Bookings` b
WHERE b.starttime LIKE '2012-09-14%' 
AND slots * (
			SELECT 
				CASE WHEN b.memid = 0 THEN guestcost
					ELSE membercost END AS COST
			FROM `Facilities` f
			WHERE b.facid = f.facid
			) > 30
ORDER BY cost DESC;

/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  

QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */

SELECT 
	Facilities.name as name,
	SUM(slots * 
		CASE WHEN Bookings.memid = 0 THEN guestcost
			ELSE membercost END
				) as revenue
FROM Facilities 
INNER JOIN Bookings 
ON Bookings.facid = Facilities.facid
GROUP BY name
ORDER BY revenue;

	

/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */

/*
SELECT 
	m.surname as Member_surname,
	m.firstname as Member_firstname,
	r.surname as Recommender_surname,
	r.firstname as Recommender_firstname
FROM `Members` m
LEFT JOIN `Members` r
ON m.recommendedby = r.memid
WHERE m.memid != 0
AND r.memid != 0
ORDER BY Member_surname,Member_firstname 
*/

-- WHich happens 1st? 
SELECT 
	m.surname as Member_surname,
	m.firstname as Member_firstname,
	r.surname as Recommender_surname,
	r.firstname as Recommender_firstname
FROM (SELECT * FROM`Members` WHERE memid != 0) m
LEFT JOIN (SELECT * FROM`Members` WHERE memid != 0) r
ON m.recommendedby = r.memid
ORDER BY Member_surname,Member_firstname; 

/* Q12: Find the facilities with their usage by member, but not guests */

SELECT 
	name,
	m.memid,
	m.firstname,
	SUM(slots*30) as Minutes_used
FROM
(SELECT * FROM `Members` WHERE memid != 0) m
INNER JOIN (SELECT * FROM `Bookings` WHERE memid != 0) b
ON m.memid = b.memid
INNER JOIN `Facilities` f
ON b.facid = f.facid
GROUP BY name, m.memid, m.firstname
ORDER BY Minutes_used DESC;

/* Q13: Find the facilities usage by month, but not guests */

SELECT 
	name, 
	EXTRACT(month from starttime) as month, 
	SUM(slots*30) as Minutes_used 
FROM 
(SELECT * FROM `Bookings` WHERE memid != 0) b 
INNER JOIN `Facilities` f 
ON b.facid = f.facid 
GROUP BY name, month 
ORDER BY Minutes_used DESC;
