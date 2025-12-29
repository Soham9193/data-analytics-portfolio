create database walmart;
use walmart;

create table sales(
    invoice_id varchar(30) not null primary key,
    branch varchar(5) not null,
    city varchar(30)not null,
    customer_type varchar(30) not null,
    gender varchar(10) not null ,
    product_line varchar(100) not null,
    unit_price decimal(10,2) not null,
    quantity int not null,
    vat float(6,4) not null,
    total decimal(12,4) not null,
    date datetime not null,
    time time not null,
    payment_method varchar(15) not null,
    cogs decimal(10,2) not null,
    gross_margin_pct float(11,9) not null,
    gross_income decimal(12,4) not null,
    rating float (2,1) not null
);


-- -------------------------------------------------------------------------------------------------------------------------------
-- ------------------------------------------------Feature Engineering-------------------------------------------------------------

-- time_of_Day
select time, 
(case
    when 'time' between "00:00:00" and "12:00:00" then "morning"
    when 'time' between "12:01:00" and "16:00:00" then "afternoon"
    else "evening"
     end 
     ) as time_of_date
from sales;

alter table sales add column time_of_date varchar(20);

update sales
set time_of_date = (
  case
     when time between "00:00:00" and "12:00:00" then "morning"
     when time between "12:01:00" and "16:00:00" then "afternoon"
     else "evening"
   end 
);


-- day_name

select date, dayname(date) as day_name from sales;
alter table sales add column day_name varchar(15);

update sales
set day_name=dayname(date);

-- month_name

select date,monthname(date) as month_name from sales;

alter table sales add column month_name varchar(15);

update sales
set month_name= monthname(date);

-- ---------------------------------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------------------------------

-- ----------------------------------------------------EDA(Exploratory Data Analysis)-------------------------------------------
-- ----------------------------------------------------Generic Question---------------------------------------------------------

-- How many unique cities does the data have?
select distinct city as unique_cities
 from sales;
 
 -- In which city is each branch?
 select distinct branch,city from sales ;
 
-- --------------------------------------------------------Product-------------------------------------------------------------------

-- How many unique product lines does the data have?
select count( distinct product_line) as no_of_upl from sales;

-- What is the most common payment method?
select payment_method ,count( payment_method) as cnt  from sales group by payment_method order by count( payment_method) desc limit 1;

-- What is the most selling product line?

select product_line,count(product_line) as most_selling_product_line from sales group by product_line order by count(product_line) desc limit 1;


-- What is the total revenue by month?
select  month_name,sum(total) as total_revenue from sales group by month_name order by sum(total) desc;

-- What month had the largest COGS?
select month_name, sum(cogs) as largest_cogs from sales group by month_name order by largest_cogs desc limit 1;

-- What product line had the largest revenue?
select product_line,sum(total) as revenue from sales group by product_line order by revenue desc limit 1;

-- What is the city with the largest revenue?
select city,sum(total) as revenue from sales group by city order by revenue desc limit 1;

-- What product line had the largest VAT?
select product_line,sum(vat) sum_vat from sales group by product_line order by sum_vat desc limit 1;

-- Fetch each product line and add a column to those product line showing "Good", "Bad". Good if its greater than average sales
select product_line,sum(total) ,
   case
     when sum(total) > (select  avg(total) from sales) then "good"
     else "bad"
   end as performance
    from sales  group by product_line;

-- Which branch sold more products than average product sold?

SELECT 
    branch,
    SUM(quantity) AS total_products_sold
FROM sales
GROUP BY branch
HAVING total_products_sold > (
    SELECT AVG(quantity) FROM sales
);
-- What is the most common product line by gender?
select gender,product_line,count(*) from sales group by gender,product_line order by  gender,count(*) desc;
-- What is the average rating of each product line?

select product_line,round(avg(rating),2) from sales group by product_line order by avg(rating) desc;

-- -----------------------------------------------------------------------------------------------------------------------------------
-- -----------------------------------------------------------------------------------------------------------------------------------

-- -------------------------------------------------------Sales----------------------------------------------------------------------

-- Number of sales made in each time of the day per weekday
SELECT 
    DAYNAME(date) AS day,
    time_of_date,
    COUNT(*) AS total_sales
FROM sales
GROUP BY DAYNAME(date), time_of_date
ORDER BY FIELD(day,'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday');
-- Which of the customer types brings the most revenue?
select customer_type,round(sum(total),2) as revenue from sales group by customer_type order by revenue desc limit 1;
-- Which city has the largest tax percent/ VAT (Value Added Tax)?
select city, round(sum(vat),2) as vat from  sales group by city order by vat desc limit 1;

-- Which customer type pays the most in VAT?
select customer_type,round(sum(vat),2) as vat from sales group by customer_type order by vat desc limit 1;



-- -----------------------------------------------------------------------------------------------------------------------------------
-- -----------------------------------------------------------------------------------------------------------------------------------

-- --------------------------------------------Customer--------------------------------------------------------------------------------

-- How many unique customer types does the data have?
select count(distinct customer_type) as unique_customer_types from sales;

-- How many unique payment methods does the data have?
select count(distinct payment_method) as unique_payment_methods   from sales;

-- What is the most common customer type?
select customer_type,count(customer_type) from sales group by customer_type order by count(customer_type) desc limit 1;

-- Which customer type buys the most?
select customer_type, sum(quantity) as total_items_bought from sales group by customer_type order by total_items_bought desc limit 1; 

-- What is the gender of most of the customers?
select gender,count(*) from sales group by gender order by count(*) desc limit 1 ;

-- What is the gender distribution per branch?
select branch,gender,count(*) as count from sales group by branch,gender order by branch;
-- Which time of the day do customers give most ratings?
select time_of_date,count(rating ) from sales group by time_of_date order by count(rating) desc ;
-- Which time of the day do customers give most ratings per branch?
select branch,time_of_Date,count(rating) from sales group by branch, time_of_date order by branch , count(rating) desc ;
-- Which day of the week has the best avg ratings?
select day_name,round(avg(rating),2) as avg_rating from sales group by day_name order by avg(rating) desc limit 1; 
-- Which day of the week has the best average ratings per branch?
with branch_day_ratings as  (
  select branch, day_name , round(avg(rating),2) as avg_rating from sales group by branch,day_name),
  ranked_days as (
  select * ,rank() over (partition by branch order by avg_rating desc) as rnk
  from branch_day_ratings )
  select branch,day_name,avg_rating from ranked_days where rnk=1;
  
  -- ------------------------------------------------------------------------------------------------------------------------------------
  -- --------------------------------------------------------VIEW ----------------------------------------------------------------------
  
   create view branch_sales_summary as 
   select branch,city,round(sum(total),2) as revenue,
   sum(quantity) as total_units_sold,
   round(avg(rating),2) as avg_rating
   from sales group by branch,city;
   
   select * from branch_sales_summary;
   -- I created reusable views to simplify analysis and improve query readability.
  
  -- Branch Performance View
  create view branch_performance as
  select branch,city,round(sum(total),2) as total_revenue,
  sum(quantity) as total_units_sold,
  round(avg(rating),2) as avg_rating
 from sales group by branch ,city;
 
 -- Monthly Revenue View
 create view monthly_revenue as 
 select month_name,round(sum(total),2) as revenue
 from sales group by month_name;
 
 -- Product Performance View
 
 create view  product_performance as
 select product_line,
 sum(quantity) as units_sold,
 round(sum(total),2) as revenue,
 round(avg(rating),2) as avg_rating
 from sales group by product_line ;
 
 -- Customer Insights View
 create view customer_insights as
 select customer_type,gender, count(*) as transactions,
 round(sum(total),2) as revenue
 from sales group by customer_type,gender;
 
 SHOW FULL TABLES IN walmart WHERE TABLE_TYPE = 'VIEW';
 use walmart;
 SELECT * FROM branch_performance LIMIT 5;
SELECT * FROM monthly_revenue LIMIT 5;
SELECT * FROM product_performance LIMIT 5;
SELECT * FROM customer_insights LIMIT 5;

SELECT * FROM walmart.branch_performance;
select * from walmart.monthly_revenue;
select * from walmart.customer_insights;
select * from walmart.product_performance;
select * from walmart.branch_sales_summary;


  
  
  
  

-- ---------------------------------------------------------------------------------------------------------------------------------------




