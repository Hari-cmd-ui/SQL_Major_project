use major_project_sql;
-- select* from customer_behavior;
-- desc customer_behavior;


-- select* from customers;
-- select count(*) from customers;
-- desc customers;

-- select* from delivery_partners;
-- select count(*) from delivery_partners;
-- desc delivery_partners;

-- select* from orders;
-- select count(*) from orders;
-- desc orders;
-- SELECT *
-- FROM orders
-- WHERE delivered_time IS NULL;

-- select* from payments;
-- desc payments;

-- select* from ratings;
-- desc ratings;

-- select * from restaurants ;
-- select count(*) from restaurants;
-- desc restaurants;


-- customers

create table customers_master(
customer_id int primary key,
customer_name text not null,
age int not null,
gender text not null,
city text not null,
signup_date text not null);

insert into customers_master 
select customer_id ,customer_name, age,gender, city, signup_date from customers;


-- customer_behave
drop table customer_behave;
create table customer_behave(
customer_id int primary key, 
total_orders int not null default 0,
total_spending double not null default 0.00,
avg_order_value double not null default 0.0,
 last_order_days int not null default 0,
 churn_flag tinyint check(churn_flag in(0,1)),
 
 foreign key(customer_id) references customers_master(customer_id)
 );
 
 insert into customer_behave 
select customer_id ,total_orders, total_spending,avg_order_value, last_order_days, churn_flag from customer_behavior;



-- restaurants

create table restaurant_info(
restaurant_id int primary key,
restaurant_name text not null,
cuisine_type text not null,
city text not null,
rating double not null);

insert into restaurant_info 
select  restaurant_id,restaurant_name,cuisine_type,city,rating from restaurants;

-- delivery _partners

create table del_par(
partner_id int primary key,
partner_name text not null,
vehicle_type text not null,
joining_date text not null);

insert into del_par
select partner_id,partner_name,vehicle_type,joining_date from delivery_partners;





 
-- orders
-- drop table  order_details;
select * from orders;
update orders set  delivered_time = null where delivered_time = '';

SET SQL_SAFE_UPDATES=0;


SELECT *
FROM orders
WHERE delivered_time = '';


DROP TABLE ORDER_DETAILS;

 create table order_details(
order_id int primary key,
customer_id int not null ,
restaurant_id int not null ,
partner_id int not null ,
order_time timestamp  ,
delivered_time timestamp  ,
order_amount double not null,
delivery_fee double not null,
status text not null,
foreign key(customer_id) references customers_master(customer_id),
foreign key(restaurant_id) references restaurant_info(restaurant_id),
foreign key(partner_id) references del_par(partner_id));

select* from orders;

insert into order_details
select order_id,customer_id,restaurant_id,partner_id,order_time,delivered_time,order_amount,delivery_fee,status from orders;

-- payments

create table pay(
payment_id int primary key,
order_id int not null,
payment_mode text not null,
amount double not null,
foreign key(order_id) references order_details(order_id)
);

insert into pay
select payment_id,order_id,payment_mode,amount from payments;

-- rating

create table rat(
rating_id int primary key,
order_id int not null,
customer_rating double not null,
feedback text not null,
foreign key(order_id) references order_details(order_id)
);

insert into rat
select rating_id,order_id,customer_rating,feedback from ratings;




-- Q1	Which restaurants are associated with the longest average delivery times?

SELECT
    r.restaurant_name,
    AVG(TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time)) AS avg_delivery_time_minutes
FROM order_details o
JOIN restaurant_info r
    ON o.restaurant_id = r.restaurant_id
GROUP BY r.restaurant_id, r.restaurant_name
ORDER BY avg_delivery_time_minutes DESC
limit 1;	


-- Q2	Which delivery partners have the highest average time per order?

SELECT
    p.partner_id,
    AVG(TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time)) AS avg_time_per_order
FROM order_details o
JOIN del_par p
    ON p.partner_id = o.partner_id
GROUP BY p.partner_id
ORDER BY avg_time_per_order DESC
limit 1;


-- Q3	Which cities experience the most delivery delays?

SELECT
    r.city,
    AVG(TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time)) AS avg_delivery_time_minutes
FROM order_details o
JOIN restaurant_info r
    ON o.restaurant_id = r.restaurant_id
GROUP BY r.city
ORDER BY avg_delivery_time_minutes DESC
limit 1;


-- Q4	Are delivery delays increasing or decreasing over time?

SELECT
    DATE_FORMAT(o.order_time, '%Y-%M') AS month,
    AVG(TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time)) AS avg_delivery_time_minutes
FROM order_details o
GROUP BY month
ORDER BY month;


-- Q5	Which restaurants receive the highest volume of cancellations?

SELECT
    r.restaurant_name,count(*) as count_of_cancellations
FROM order_details o
JOIN restaurant_info r
    ON o.restaurant_id = r.restaurant_id
where o.status='Cancelled'
GROUP BY r.restaurant_name
ORDER BY count_of_cancellations DESC
limit 1;

-- Q6	Which cities have the highest cancellation rates by percentage?

SELECT
    r.city,
    count(case when o.status='Cancelled' then 1 end )*100.0/count(*) as highest_cancellation_percentage
FROM order_details o
JOIN restaurant_info r
    ON o.restaurant_id = r.restaurant_id
GROUP BY r.city
ORDER BY highest_cancellation_percentage DESC
limit 1;

-- Q7	Is there a correlation between delivery delays and cancellations?

SELECT
    restaurant_id,
    AVG(TIMESTAMPDIFF(MINUTE, order_time, delivered_time)) AS avg_delivery_time,
    ROUND(
        100.0 * SUM(CASE WHEN status='Cancelled' THEN 1 ELSE 0 END)
        / COUNT(*), 2
    ) AS cancellation_rate
FROM order_details
GROUP BY restaurant_id;

-- Q8	On which days and at which times do cancellations peak?

SELECT
    DAYNAME(order_time) AS day_of_week,
    HOUR(order_time) AS hour_of_day,
    COUNT(*) AS cancellations
FROM order_details
WHERE status = 'Cancelled'
GROUP BY
    DAYNAME(order_time),
    HOUR(order_time)
ORDER BY cancellations DESC
LIMIT 5;

-- Q9	Which restaurants generate the highest total revenue?


select 
	 r. restaurant_name,
	sum(o.order_amount)as highest_total_revenue
    from order_details o
    JOIN restaurant_info r
    ON o.restaurant_id = r.restaurant_id
    group by r.restaurant_name
    order by highest_total_revenue desc
    limit 1;
    
    -- Q10	Which cities contribute the most to overall company revenue?
    
    select 
	 r. city,
	sum(o.order_amount)as  overall_company_revenue
    from order_details o
    JOIN restaurant_info r
    ON o.restaurant_id = r.restaurant_id
    group by r.city
    order by overall_company_revenue desc
    limit 1;
    
    
    -- Q11	Which payment methods are most popular and most valuable?
    
    select 
		payment_mode, 
        sum(amount) as most_popular_and_valuable from pay
        group by payment_mode
        order by most_popular_and_valuable desc limit 1;
        
-- Q12	What are the monthly revenue trends over the past year?

SELECT
  DATE_FORMAT(order_time, '%Y-%M') AS month,
  SUM(order_amount) AS monthly_revenue
FROM order_details
WHERE order_time >= DATE_SUB('2025-05-20', INTERVAL 1 YEAR)
  AND status = 'Delivered'
GROUP BY month
ORDER BY month;

-- Q13	Who are the top 10 most valuable customers by lifetime spending?

select c.customer_name, sum(o.order_amount) as total_spending
from order_details o
join customers_master c 
on o.customer_id=c.customer_id
group by c.customer_name
order by total_spending desc
limit 10;

-- Q14	Which customers order most frequently, and what is their average order value?

select 
		c.customer_name,avg(o.order_amount) as average_order_value  from customers_master c
        join order_details o
        on c.customer_id=o.customer_id
        group by c.customer_name
        order by count(*) desc limit 1;
        
-- Q15	Which customers have gone inactive in the last 90 days?

select * from  customers_master
where customer_id in
	(select customer_id from customer_behave
    where churn_flag=1);
    
-- Q16	What behavioural patterns signal that a customer is about to churn?

select* from customers_master m
join customer_behave b
on m.customer_id=b.customer_id
where last_order_days > 60 and last_order_days < 90;


-- Q17	Who are the fastest delivery partners based on average delivery time?

SELECT
    d.partner_name,
    AVG(TIMESTAMPDIFF(MINUTE, o.order_time, o.delivered_time)) AS avg_delivery
FROM order_details o
JOIN del_par d
    ON d.partner_id = o.partner_id
group by partner_name
ORDER BY avg_delivery 
limit 1;

-- Q18	Which partners handle the highest volume of successful deliveries?

SELECT
     d.partner_name,count(*) as successful_deliveries
FROM order_details o
JOIN del_par d 
ON d.partner_id = o.partner_id
where o.status='Delivered'
GROUP BY  d.partner_name
ORDER BY successful_deliveries DESC
limit 1;

-- Q19	Which partners are associated with the most cancellations or delays?

SELECT
     d.partner_name,count(*) as successful_deliveries
FROM order_details o
JOIN del_par d 
ON d.partner_id = o.partner_id
where o.status in ('Cancelled' , 'Pending')
GROUP BY  d.partner_name
ORDER BY successful_deliveries DESC
limit 1;

-- Q20	What is the average customer rating received per delivery partner?	

select 
	d.partner_name,
    avg(r.customer_rating)as average_customer_rating
from rat r
JOIN order_details o
on  o.order_id=r.order_id
join del_par d
ON d.partner_id = o.partner_id 
group by d.partner_name
order by average_customer_rating desc
limit 1;