-- 1. What are the top 5 best-selling products by quantity and revenue?

-- by quantity
with sorted_quantity as (
	select
	p.name,
	sum(oi.quantity) as quantity
	from orders o
	left join order_items oi
	on o.id = oi.order_id
	left join products p
	on oi.product_id = p.id
	group by p.id
	order by 2 desc
),
sorted_rank as (
	select
	name,
	quantity,
	dense_rank() over (order by quantity desc) as quantity_ranking
	from sorted_quantity
)
select
*
from sorted_rank
where quantity_ranking <= 5;

-- by revenue

with order_quantity as (
	select
	p.id,
	p.name,
	sum(oi.quantity) as quantity_order
	from orders o
	left join order_items oi
	on o.id=oi.order_id
	left join products p
	on oi.product_id = p.id
	group by 1
),
revenue_ranking as (
	select
	oq.name,
	oq.quantity_order*p.price*(1-p.discount_percent/100) as revenue,
	dense_rank() over ( order by oq.quantity_order*p.price*(1-p.discount_percent/100) desc) as rev_ranking
	from order_quantity as oq
	left join products p
	on oq.id = p.id
)
select
name,
round(revenue) as revenue
from revenue_ranking
where rev_ranking <= 5;

-- 2. Which customers placed the most orders?

with order_count as (
	select
	customer_id,
	c.full_name,
	count(customer_id) as total_order_placed
	from orders o
	left join customers c
	on o.customer_id = c.id
	group by 1
)
select
*
from order_count
where total_order_placed = (
	select max(total_order_placed) from order_count
);

-- 3. Who are the top customers based on total spending?

with customer_total_spending as ( 
	select
	o.customer_id,
    c.full_name as name,
	round(sum(oi.quantity*p.price*(1-p.discount_percent/100))) as total_spend
	from orders o
	left join order_items oi
	on o.id = oi.order_id
	left join products p
	on oi.product_id = p.id
    left join customers c
    on o.customer_id = c.id
	group by 1
)
select
name,
total_spend
from customer_total_spending
where total_spend = (
	select max(total_spend) from customer_total_spending
);

-- 4. Compare online vs. offline sales for each store. 

select
	o.store_id,
	s.store_name,
	round(
	sum(
		 case when o.order_type = 'online'
		 then oi.quantity*p.price*(1-p.discount_percent/100) else 0 end
	)) as online_sales,
	round(
	sum(
		 case when o.order_type = 'offline'
		 then oi.quantity*p.price*(1-p.discount_percent/100) else 0 end
	)) as offline_sales
from orders o
left join order_items oi
on o.id = oi.order_id
left join products p
on oi.product_id = p.id
left join stores s
on o.store_id = s.id
group by 1
order by 1;

-- 5. Which product categories generate the highest and lowest revenue?
-- max
with category_revenue as(
	select
	c.category_name,
	round(sum(oi.quantity*p.price*(1-p.discount_percent/100))) as revenue
	from order_items oi
	left join products p
	on oi.product_id = p.id
	left join categories c
	on p.category_id = c.id
	group by 1
	order by 2 desc
)
select
*
from category_revenue
where revenue = (
	select max(revenue) from category_revenue
);

-- min
with category_revenue as(
	select
	c.category_name,
	round(sum(oi.quantity*p.price*(1-p.discount_percent/100))) as revenue
	from order_items oi
	left join products p
	on oi.product_id = p.id
	left join categories c
	on p.category_id = c.id
	group by 1
	order by 2 desc
)
select
*
from category_revenue
where revenue = (
	select min(revenue) from category_revenue
);


-- 6. Which marketing campaign brought in the most orders? 

-- Most Profitable Campaign
select
	mc.campaign_name,
	round(sum(oi.quantity*p.price*(1-p.discount_percent/100))) as revenue,
    round(sum(mc.budget)) as total_cost,
    round(sum(oi.quantity*p.price*(1-p.discount_percent/100)))-round(sum(mc.budget)) as total_profit
from orders o
left join order_items oi
on o.id = oi.order_id
left join products p
on oi.product_id = p.id
join marketing_campaigns mc
on o.marketing_id = mc.id
group by 1
order by 2;

-- Most Orders
with order_count as(
	select
		mc.campaign_name,
		count(o.id) as orders
	from orders o
	join marketing_campaigns mc
	on o.marketing_id = mc.id
	group by 1
)
select
*
from order_count
where orders = (
	select max(orders) from order_count
);

-- 7. What is the revenue trend over days or months? 

-- revenue trend over days
select
	date(order_date),
	round(sum(oi.quantity*p.price*(1-p.discount_percent/100))) as revenue
from orders o
left join order_items oi
on o.id = oi.order_id
left join products p
on product_id = p.id
group by 1
order by 1;

-- Under which Promotional Campaign

select
o.marketing_id,
mc.campaign_name
from orders o
left join marketing_campaigns mc
on o.marketing_id = mc.id
where date(o.order_date) = '2025-06-11';

-- revenue trend over months
select
	date_format(date(order_date),'%Y-%m') as `year_month`,
	round(sum(oi.quantity*p.price*(1-p.discount_percent/100))) as revenue
from orders o
left join order_items oi
on o.id = oi.order_id
left join products p
on product_id = p.id
group by 1
order by 1;

-- Under which Promotional Campaign

select
distinct o.marketing_id,
mc.campaign_name
from orders o
join marketing_campaigns mc
on o.marketing_id = mc.id
where date(o.order_date) between '2025-05-01' and '2025-05-31';

-- 8. Which payment method is used most frequently?

select
	payment_method,
	count(id) as no_of_uses
from orders
group by 1
having no_of_uses = (
	select
		count(id) max_uses
	from orders
	group by payment_method
	order by max_uses desc
	limit 1
);

-- 9. What are the current inventory levels per store and product?

-- inventory levels per store

select
s.store_name,
sum(i.quantity) as quantity
from stores s
join inventory i
on s.id = i.store_id
group by 1
order by 2 desc;

-- inventory levels per product

select
p.name,
sum(i.quantity) as quantity
from products p
join inventory i
on p.id = i.product_id
group by 1
order by 2 desc;

-- 10. Add a column last_order_date to the customers table.

alter table customers
add column last_order_date datetime;

-- 11. Update each customer’s last_order_date based on their latest order.

update customers c
join (
	select
	customer_id,
	max(order_date) as last_order_date
	from orders
	group by 1
) od on c.id = od.customer_id
set c.last_order_date = od.last_order_date;

-- 12. Insert a new promotional campaign and assign it to new orders.

INSERT INTO marketing_campaigns (
	id,
    campaign_name,
    platform,
    budget,
    start_date,
    end_date,
    notes,
    created_at,
    updated_at
)
VALUES (
	21,
    'Summer Super Sale',
    'facebook',
    5000.00,
    '2025-06-01',
    '2025-06-30',
    'Promotional campaign targeting young adults during summer.',
    NOW(),
    NOW()
);

-- Assign

UPDATE orders
SET marketing_id = 21
WHERE id IN (
  SELECT id FROM (
    SELECT id
    FROM orders
    WHERE order_date >= '2025-06-01'
      AND marketing_id IS NULL
  ) AS sub
);

-- 13. Delete products that haven’t been sold in the last 6 months.

-- Products
select 
*
from products
where id not in (
  select 
  distinct oi.product_id
  from order_items oi
  join 
  orders o 
  on oi.order_id = o.id
  where o.order_date >= (
    select max(order_date) from orders
  ) - interval 6 month
);

-- Code to delete

delete from products
where id not in (
  select 
  distinct oi.product_id
  from order_items oi
  join orders o 
  on oi.order_id = o.id
  where o.order_date >= (
    select max(order_date) from orders
  ) - interval 6 month
);

-- 14. Rank customers by total amount spent.

with customer_total_spending as ( 
	select
	o.customer_id,
    c.full_name as name,
	round(sum(oi.quantity*p.price*(1-p.discount_percent/100))) as total_spend
	from orders o
	left join order_items oi
	on o.id = oi.order_id
	left join products p
	on oi.product_id = p.id
    left join customers c
    on o.customer_id = c.id
	group by 1
)
-- select
-- 	round(avg(total_spend)) as avg_spend
-- from customer_total_spending;
select
	name,
	total_spend,
    dense_rank() over (order by total_spend desc) as customer_rank
from customer_total_spending;

-- 15. Show the top 3 best-selling products per store.
-- by quantity
with sold_quantity as (
	select
	o.store_id,
	s.store_name,
    p.id,
    p.name as product_name,
	sum(oi.quantity) as total_sold
	from orders o
	left join order_items oi
	on o.id = oi.order_id
    left join products p
    on oi.product_id = p.id
	left join stores s
	on o.store_id = s.id
	group by
	1,3
),
ranking as(
	select
	store_name,
    product_name,
	total_sold,
	dense_rank() over(partition by store_id order by total_sold desc) as product_ranking
    from sold_quantity
)
select
*
from ranking
where product_ranking <= 3;

-- by revenue

with sold_quantity as (
	select
	o.store_id,
	s.store_name,
    p.id,
    p.name as product_name,
	round(sum(oi.quantity*p.price*(1-p.discount_percent/100))) as revenue
	from orders o
	left join order_items oi
	on o.id = oi.order_id
    left join products p
    on oi.product_id = p.id
	left join stores s
	on o.store_id = s.id
	group by
	1,3
),
ranking as(
	select
	store_name,
    product_name,
	revenue,
	dense_rank() over(partition by store_id order by revenue desc) as product_ranking
    from sold_quantity
)
select
*
from ranking
where product_ranking <= 3;

-- 16. Calculate a running total of daily revenue

with daily_revenue as (
	select
	date(order_date) as order_date,
	round(sum(oi.quantity*p.price*(1-p.discount_percent/100))) as revenue
	from orders o
	left join order_items oi
	on o.id = oi.order_id
	left join products p
	on oi.product_id = p.id
	group by 1
	order by 1
)
select
*,
sum(revenue) over (order by date(order_date)) as running_revenue
from daily_revenue;

-- 17. Compute a 7-day rolling average of total order amounts.

with daily_revenue as (
	select
	date(o.order_date) as order_date,
	sum(oi.quantity) as order_amount
	from orders o
	left join order_items oi
	on o.id = oi.order_id
	group by 1
	order by 1
)
select
*,
round(
	avg(order_amount) over(
		order by order_date
		rows between 6 preceding and current row
	), 2 
) as 7_days_rolling_avg
from daily_revenue;

-- 18. Show the time difference between each customer's consecutive orders.

-- customer's avg order date

select
  full_name,
  round(avg(datediff(order_date, previous_order_date))) as avg_order_days
from (
  select
    o.customer_id,
    c.full_name,
    date(o.order_date) as order_date,
    lag(date(o.order_date)) over (
      partition by o.customer_id
      order by o.order_date
    ) as previous_order_date
  from orders o
  join customers c 
  on o.customer_id = c.id
) as sub
where previous_order_date is not null
group by customer_id;

-- Time Difference

select
  o.customer_id,
  c.full_name,
  date(o.order_date) as order_date,
  lag(date(o.order_date)) over (
    partition by o.customer_id
    order by o.order_date
  ) as previous_order_date,
  datediff(
    date(o.order_date),
    lag(date(o.order_date)) over (
      partition by o.customer_id
      order by o.order_date
    )
  ) as days_between_orders
from orders o
join customers c on o.customer_id = c.id
order by o.customer_id, o.order_date;

-- 19. Identify customers who placed two orders on back-to-back days. 

with purchase_dates as (
	select
		o.customer_id,
		c.full_name,
		date(o.order_date) as order_date,
		lag(date(o.order_date)) over(
			partition by customer_id
			order by date(o.order_date)
		) as previous_order_date
	from orders o
	left join customers c
	on o.customer_id = c.id
	order by o.customer_id
)
select
	distinct customer_id,
	full_name
from purchase_dates
where datediff(order_date, previous_order_date) = 1;

-- 20. Classify orders as ‘High’, ‘Medium’, or ‘Low’ value based on amount

with ranked_orders as(
	select
	o.id as order_id,
	sum(oi.quantity) as order_amount,
	ntile(3) over (order by sum(oi.quantity)) as qnt_grp
	from orders o
	left join order_items oi
	on o.id = oi.order_id
	group by o.id
)
select
order_id,
order_amount,
case qnt_grp
	when 1 then 'Low'
    when 2 then 'Medium'
    else 'High'
end as order_class
from ranked_orders;

-- 21. Show whether each day’s sales were higher or lower than the previous day.

with daily_revenue as (
  select
    date(o.order_date) as order_date,
    round(sum(oi.quantity * p.price * (1 - p.discount_percent / 100)), 2) as revenue
  from orders o
  left join order_items oi on o.id = oi.order_id
  left join products p on oi.product_id = p.id
  group by date(o.order_date)
),
revenue_with_lag as (
  select
    order_date,
    revenue,
    lag(revenue) over (order by order_date) as previous_day_revenue
  from daily_revenue
)
select
  order_date,
  revenue,
  previous_day_revenue,
  round(
    (revenue - previous_day_revenue) / previous_day_revenue * 100, 
    2
  ) as day_over_day_percent_change
from revenue_with_lag;

-- 22. Find customers who placed only one order ever.

select
o.customer_id,
c.full_name
from orders o
left join customers c
on o.customer_id = c.id
left join order_items oi
on o.id = oi.order_id
group by 1
having count(oi.quantity) = 1;

-- 23. Find products that were only ordered during marketing campaigns.

with campaign_products as (
	select
	o.id,
	oi.product_id
	from orders o
	left join order_items oi
	on o.id = oi.order_id
	where o.marketing_id is not null
),
non_campaign_products as (
	select
	o.id,
	oi.product_id
	from orders o
	left join order_items oi
	on o.id = oi.order_id
	where o.marketing_id is null
)
select
*
from campaign_products cp
left join non_campaign_products ncp
on cp.product_id = ncp.product_id
where ncp.product_id is null;

-- 24. Find the most popular product among buyers of 'Soybean Oil'.

with soybean_buyers as (
  select distinct o.customer_id
  from orders o
  left join order_items oi 
  on o.id = oi.order_id
  left join products p 
  on oi.product_id = p.id
  where p.name = 'Soybean Oil'
),
order_quantity as (
  select
    oi.product_id,
    p.name,
    sum(oi.quantity) as total_order
  from orders o
  join soybean_buyers sb 
  on o.customer_id = sb.customer_id
  join order_items oi 
  on o.id = oi.order_id
  left join products p
  on oi.product_id = p.id
  group by oi.product_id
)
select
name,
total_order
from order_quantity oq
where oq.total_order = (
	select 
    max(total_order)
    from order_quantity
);

-- 25. Create a trigger to update last_order_date after a new order. 

delimiter $$

create trigger update_last_order_date
after insert on orders
for each row
begin
  update customers
  set last_order_date = new.order_date
  where id = new.customer_id
    and (last_order_date is null or new.order_date > last_order_date);
end$$

delimiter ;

-- 26. Schedule an update to refresh all last_order_date fields once daily.

set global event_scheduler = on;

create event update_last_order_dates_daily
on schedule every 1 day
starts current_timestamp
on completion preserve
do
  update customers c
  set last_order_date = (
    select max(o.order_date)
    from orders o
    where o.customer_id = c.id
  );