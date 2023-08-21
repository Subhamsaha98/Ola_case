create database case4;
 use case4;
 
/*1.Find hour of 'pickup' and 'confirmed_at' time, and make a column of weekday as "Sun,Mon, etc"next to pickup_datetime*/
select * from data;

-- Pickup Date column conversion
Alter table data 
add column pickupdate date;

update data
set pickupdate = Str_to_date(pickup_date,"%d-%m-%Y");

set SQL_SAFE_UPDATES = 0;

-- Pickup Date Time column conversion
Alter table data
add column PickupDT datetime;

select STR_TO_DATE(pickup_datetime, '%d-%m-%Y %H:%i:%s') AS pickupDT
from data;

update data
set PickupDT = str_to_date(pickup_datetime, '%d-%m-%Y %H:%i:%s');

-- pickup Time column conversion 
Alter table data
add column PickupTime time;

select Str_to_date(pickup_time, '%H:%i:%s') AS PickupTime
FROM data;

update data
set PickupTime = str_to_date(pickup_time, '%H:%i:%s');

-- Confirmed at column conversion
Alter table data
add column NewConfirmed_at datetime;

select STR_TO_DATE(Confirmed_at, '%d-%m-%Y %H:%i:%s') AS NewConfirmed_at
from data;

update data
set NewConfirmed_at = str_to_date(Confirmed_at, '%d-%m-%Y %H:%i:%s');


select 
    EXTRACT(hour from pickupDT) AS pickup_hour,
    EXTRACT(hour from NewConfirmed_at) AS confirmed_hour,
    case 
        WHEN dayofweek(PickupDT) = 0 THEN 'Sun'
        WHEN dayofweek(PickupDT) = 1 THEN 'Mon'
        WHEN dayofweek(PickupDT) = 2 THEN 'Tue'
        WHEN dayofweek(PickupDT) = 3 THEN 'Wed'
        WHEN dayofweek(PickupDT) = 4 THEN 'Thu'
        WHEN dayofweek(PickupDT) = 5 THEN 'Fri'
        WHEN dayofweek(PickupDT) = 6 THEN 'Sat'
    end as weekday
from data;

/*2	Make a table with count of bookings with booking_type = p2p catgorized by booking mode as 'phone','online','app',etc*/

create table booking_counts (
    booking_mode VARCHAR(20),
    booking_count INT);

Insert into booking_counts (booking_mode, booking_count)
select booking_mode, COUNT(*) AS booking_count
from data
where booking_type = 'p2p'
group by booking_mode;

select * from booking_counts;

/*3	Create columns for pickup and drop ZONES (using Localities data containing Zone IDs against each area)
and fill corresponding values against pick-area and drop_area, using Sheet'Localities'*/
-- PROBLEM
select * from localities;

Alter table data
add column pickup_zone_id INT,
add column drop_zone_id INT;

select data.pickupArea
from data inner join localities on data.PickupArea = localities.Area;

UPDATE data
SET pickup_zone_id = Localities.Zone_ID
WHERE localities.Area = data.PickupArea;

UPDATE data
SET drop_zone_id = Localities.Zone_ID
WHERE data.DropArea = localities.Area;

/*4	Find top 5 drop zones in terms of average revenue*/

SELECT DropArea, AVG(Fare) AS average_revenue
FROM data
GROUP BY DropArea
ORDER BY average_revenue DESC
LIMIT 5;

/*5	Find all unique driver numbers grouped by top 5 pickzones*/

SELECT PickupArea, COUNT(DISTINCT Driver_number) AS unique_driver_count
FROM data
GROUP BY PickupArea
ORDER BY unique_driver_count DESC
LIMIT 5;

/*6	Make a list of top 10 driver by driver numbers in terms of fare collected where service_status is done, done-issue*/

SELECT driver_number, SUM(fare) AS total_fare_collected
FROM data
WHERE service_status IN ('done', 'done-issue')
GROUP BY driver_number
ORDER BY total_fare_collected DESC
LIMIT 10;

/*7	Make a hourwise table of bookings for week between Nov01-Nov-07 and highlight the hours with more than average no.of bookings day wise*/

SELECT subquery.booking_mode, subquery.booking_count, HOUR(PickupDT) AS pickup_hour, DATE(PickupDT) AS pickup_date,
    CASE
        WHEN subquery.booking_count > AVG(subquery.booking_count) OVER (PARTITION BY DATE(PickupDT)) THEN 'High'
        ELSE 'Normal'
        END AS booking_status
FROM (SELECT booking_mode, COUNT(*) AS booking_count, DATE(PickupDT) AS pickup_date
        FROM data
        WHERE booking_type = 'p2p'
            AND PickupDT >= '2013-11-01'
            AND PickupDT < '2013-11-08'
            GROUP BY booking_mode,
            DATE(PickupDT)) AS subquery
INNER JOIN data ON DATE(data.PickupDT) = subquery.pickup_date
ORDER BY pickup_date, pickup_hour;

