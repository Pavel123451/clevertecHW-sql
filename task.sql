-- Вывести к каждому самолету класс обслуживания и количество мест этого класса

select model, fare_conditions, count(seats.aircraft_code) seats_number
from aircrafts_data
	join seats on seats.aircraft_code = aircrafts_data.aircraft_code
group by model, fare_conditions
order by model;


-- Найти 3 самых вместительных самолета (модель + кол-во мест)

select model, count(seats.aircraft_code) seats_number
from aircrafts_data
	join seats on seats.aircraft_code = aircrafts_data.aircraft_code
group by model
order by seats_number desc
limit 3;


-- Вывести код, модель самолета и места не эконом класса для самолета 'Аэробус A321-200' с сортировкой по местам

select seats.aircraft_code, model, seat_no 
from aircrafts_data
	join seats on seats.aircraft_code = aircrafts_data.aircraft_code
where model->>'ru' = 'Аэробус A321-200' and fare_conditions != 'Economy'
order by seat_no;


-- Вывести города в которых больше 1 аэропорта ( код аэропорта, аэропорт, город)

select airport_code, airport_name, airports.city
from airports
where city in (
	select city
    from airports
    group by city
    having count(airport_code) > 1
)


-- Найти ближайший вылетающий рейс из Екатеринбурга в Москву, на который еще не завершилась регистрация

-- Вариант 1
select * 
from flights 
where departure_airport in (
	select airport_code
	from airports
	where city = 'Екатеринбург'
) 
and arrival_airport in (
	select airport_code
	from airports
	where city = 'Москва'
) 
and (status = 'On time' or status = 'Delayed')
order by scheduled_departure asc
limit 1;

-- Вариант 2
select * 
from flights
where departure_airport in (
    select airport_code
    from airports
    where city = 'Екатеринбург'
) 
and arrival_airport in (
    select airport_code
    from airports
    where city = 'Москва'
) 
and (status = 'On time' or status = 'Delayed')
and scheduled_departure = (
    select min(scheduled_departure)
    from flights
    where departure_airport in (
        select airport_code
        from airports
        where city = 'Екатеринбург'
    ) 
    and arrival_airport in (
        select airport_code
        from airports
        where city = 'Москва'
    ) 
    and (status = 'On time' or status = 'Delayed')
);


-- Вывести самый дешевый и дорогой билет и стоимость ( в одном результирующем ответе)

-- Вариант 1(получаем ВСЕ самые дешевые и самые дорогие билеты)
select ticket_no, tickets.book_ref, passenger_id, passenger_name, contact_data, total_amount
from tickets
	join bookings on bookings.book_ref = tickets.book_ref 
where total_amount = (
	select max(total_amount)
	from bookings
)
or total_amount = (
	select min(total_amount)
	from bookings
)

-- Вариант 2 (получаем 1 самый дорогой и 1 самый дешевый)
(select ticket_no, tickets.book_ref, passenger_id, passenger_name, contact_data, total_amount
from tickets 
	join bookings on tickets.book_ref = bookings.book_ref
where total_amount = (
	select min(total_amount) 
	from bookings
)
limit 1)
union all
(select ticket_no, tickets.book_ref, passenger_id, passenger_name, contact_data, total_amount
from tickets 
	join bookings on tickets.book_ref = bookings.book_ref
where total_amount = (
	select max(total_amount) 
	from bookings
)
limit 1);


-- Вывести информацию о вылете с наибольшей суммарной стоимостью билетов

with flights_total_sum as (
    select flights.flight_id, flight_no, sum(total_amount) as total_sum
    from flights
    	join ticket_flights on ticket_flights.flight_id = flights.flight_id
    	join tickets on tickets.ticket_no = ticket_flights.ticket_no
    	join bookings on bookings.book_ref = tickets.book_ref
    group by flights.flight_id
)
select flights.*, flights_total_sum.total_sum
from flights 
join flights_total_sum on flights.flight_id = flights_total_sum.flight_id
where flights_total_sum.total_sum = (
    select max(total_sum)
    from flights_total_sum
);


-- Найти модель самолета, принесшую наибольшую прибыль (наибольшая суммарная стоимость билетов). Вывести код модели, информацию о модели и общую стоимость

with max_amount_flight as (
	with flights_total_sum as (
	    select flights.flight_id, flight_no, aircraft_code, sum(total_amount) as total_sum
	    from flights
	    	join ticket_flights on ticket_flights.flight_id = flights.flight_id
	    	join tickets on tickets.ticket_no = ticket_flights.ticket_no
	    	join bookings on bookings.book_ref = tickets.book_ref
	    group by flights.flight_id
	)
	select flights.*, flights_total_sum.total_sum max_total_sum
	from flights 
	join flights_total_sum on flights.flight_id = flights_total_sum.flight_id
	where flights_total_sum.total_sum = (
	    select max(total_sum)
	    from flights_total_sum
	)
)
select max_amount_flight.aircraft_code, model, max_total_sum
from max_amount_flight
	join aircrafts on aircrafts.aircraft_code = max_amount_flight.aircraft_code


-- Найти самый частый аэропорт назначения для каждой модели самолета. Вывести количество вылетов, информацию о модели самолета, аэропорт назначения, город

with flight_counts as (
    select model, arrival_airport, city, count(arrival_airport) as aa_count
    from aircrafts
    	join flights on flights.aircraft_code = aircrafts.aircraft_code
    	join airports on airports.airport_code = flights.arrival_airport
    group by model, arrival_airport, city
),
max_flights as (
    select model, max(aa_count) as max_count
    from flight_counts
    group by model
)
select fc.model, fc.arrival_airport, fc.city, fc.aa_count
from flight_counts fc
join max_flights on fc.model = max_flights.model and fc.aa_count = max_flights.max_count;
