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

select
	mc.campaign_name,
	round(sum(oi.quantity*p.price*(1-p.discount_percent/100))) as revenue
from orders o
left join order_items oi
on o.id = oi.order_id
left join products p
on oi.product_id = p.id
join marketing_campaigns mc
on o.marketing_id = mc.id
group by 1;