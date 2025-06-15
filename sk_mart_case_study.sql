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
left join inventory i
on s.id = i.store_id
group by 1
order by 2 desc;

-- inventory levels per store

select
p.name,
sum(i.quantity) as quantity
from products p
left join inventory i
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

