#create database ecommerce;
#use ecommerce;

/* List all unique cities where customers are located.*/

Select distinct customer_city from customers;

/* Count the number of orders placed in 2017.*/

Select count(order_id) from orders 
	where year(order_purchase_timestamp) = 2017;
    
/*  Find the total sales per category.*/

Select upper(products.product_category) category, round(sum(payments.payment_value)) sales
from products join order_items
on products.product_id = order_items.product_id
join payments on payments.order_id = order_items.order_id
group by category;


/*  Calculate the percentage of orders that were paid in installments.*/

Select (sum(case when payment_installments >= 1 then 1 else 0 end ))/count(*)*100 
from payments;

/* Count the number of customers from each state */

Select Customer_state, count(customer_id) as Total_customer
from customers
group by customer_state;

/*  Calculate the number of orders per month in 2018*/

Select monthname(order_purchase_timestamp) as Months , count(order_id) as Oder_count
from orders where year(order_purchase_timestamp) = 2018
group by Months;

/*  Find the average number of products per order, grouped by customer city*/

with count_per_order as 
(select orders.order_id, orders.customer_id, count(order_items.order_id) as count_order
from orders join order_items
on orders.order_id = order_items.order_id
group by orders.order_id, orders.customer_id)

select customers.customer_city, round(avg(count_per_order.count_order),2) average_orders
from customers join count_per_order
on customers.customer_id = count_per_order.customer_id
group by customers.customer_city order by average_orders desc;

/*  Calculate the percentage of total revenue contributed by each product category.*/

select upper(products.product_category) category, 
round((sum(payments.payment_value)/(select sum(payment_value) from payments))*100,2)  revenue_percentage
from products join order_items 
on products.product_id = order_items.product_id
join payments 
on payments.order_id = order_items.order_id
group by category order by revenue_percentage desc;

/*  Identify the correlation between product price and the number of times a product has been purchased.*/

Select  products.product_category, count(order_items.product_id) as count_product,
round(avg(order_items.price),2) as avegare_price
from products join order_items
on products.product_id = order_items.product_id
group by products.product_category;

/*  Calculate the total revenue generated by each seller, and rank them by revenue.*/

Select *, dense_rank() over(order by revenue desc) ranks from
(Select Order_items.seller_id, sum(payments.payment_value) as revenue
from order_items join payments
on order_items.order_id = payments.order_id
group by Order_items.seller_id) as a;

/* Calculate the moving average of order values for each customer over their order history*/

Select customer_id, order_purchase_timestamp, payment,
avg(payment) over(partition by customer_id order by order_purchase_timestamp
rows between 2 preceding and current row) as mov_avg
from
(select orders.customer_id, orders.order_purchase_timestamp, 
payments.payment_value as payment
from payments join orders
on payments.order_id = orders.order_id) as a;

/* Calculate the cumulative sales per month for each year.*/

select years, months , payment, sum(payment)
over(order by years, months) cumulative_sales from 
(select year(orders.order_purchase_timestamp) as years,
month(orders.order_purchase_timestamp) as months,
round(sum(payments.payment_value),2) as payment from orders join payments
on orders.order_id = payments.order_id
group by years, months order by years, months) as a;


/* Calculate the year-over-year growth rate of total sales.*/

with a as(select year(orders.order_purchase_timestamp) as years,
round(sum(payments.payment_value),2) as payment from orders join payments
on orders.order_id = payments.order_id
group by years order by years)

select years, ((payment - lag(payment, 1) over(order by years))/
lag(payment, 1) over(order by years)) * 100 as growth_rate from a;

/* Calculate the retention rate of customers, defined as the percentage of customers who make another purchase within 6 months of their first purchase*/

with a as (select customers.customer_id,
min(orders.order_purchase_timestamp) first_order
from customers join orders
on customers.customer_id = orders.customer_id
group by customers.customer_id),

b as (select a.customer_id, count(distinct orders.order_purchase_timestamp) next_order
from a join orders
on orders.customer_id = a.customer_id
and orders.order_purchase_timestamp > first_order
and orders.order_purchase_timestamp < 
date_add(first_order, interval 6 month)
group by a.customer_id) 

select 100 * (count( distinct a.customer_id)/ count(distinct b.customer_id)) 
from a left join b 
on a.customer_id = b.customer_id;


/* Identify the top 3 customers who spent the most money in each year.*/

select years, customer_id, payment, d_rank
from
(select year(orders.order_purchase_timestamp) years,
orders.customer_id,
sum(payments.payment_value) payment,
dense_rank() over(partition by year(orders.order_purchase_timestamp)
order by sum(payments.payment_value) desc) d_rank
from orders join payments 
on payments.order_id = orders.order_id
group by year(orders.order_purchase_timestamp),
orders.customer_id) as a
where d_rank <= 3 ;
