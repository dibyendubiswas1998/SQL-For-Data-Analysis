use gdb023;
show tables;

# Check how many records are present:
select count(*) from dim_customer; # 209 records
select count(*) from dim_product; # 397 records
select count(*) from fact_gross_price; # 579 records
select count(*) from fact_manufacturing_cost; # 579 records
select count(*) from fact_pre_invoice_deductions; # 418 records
select count(*) from fact_sales_monthly; # 9,71,631 records

# Requests:----------------------------------------------
/**
1. Provide the list of markets in which customer "Atliq Exclusive" operates its
   business in the APAC region.
**/
select distinct market from dim_customer where customer="Atliq Exclusive" and region="APAC";

/**
2. What is the percentage of unique product increase in 2021 vs. 2020? The
   final output contains these fields,
   
   unique_products_2020
   unique_products_2021
   percentage_chg
**/
with
unique_products_2020 as 
	(select count(distinct p.product_code) as unique_products_2020 from dim_product as p
	 join fact_sales_monthly as s
     on p.product_code = s.product_code
     where s.fiscal_year=2020 group by p.product
    ),
unique_products_2021 as 
	(select count(distinct p.product_code) as unique_products_2021 from dim_product as p
	 join fact_sales_monthly as s
     on p.product_code = s.product_code
     where s.fiscal_year=2021 group by p.product
    )
select sum(p1.unique_products_2021) as unique_products_2021, sum(p0.unique_products_2020) as unique_products_2020,
round((unique_products_2020/unique_products_2021)*100, 2) as percentage_chg
from unique_products_2020 as p0
cross join unique_products_2021 as p1;


/**
3. Provide a report with all the unique product counts for each segment and
   sort them in descending order of product counts. The final output contains
   2 fields,
   
   segment
   product_count

**/
select segment, count(distinct product_code) as product_count from dim_product group by segment 
order by product_count desc;

/**
4. Follow-up: Which segment had the most increase in unique products in
   2021 vs 2020? The final output contains these fields,

   segment
   product_count_2020
   product_count_2021
   difference
**/
with 
product_count_2020 as 
	(select p.segment, count(distinct p.product_code) as product_count_2020 from dim_product as p
	 join fact_sales_monthly s 
     on p.product_code = s.product_code
     where s.fiscal_year = 2020 group by p.segment
    ),
product_count_2021 as 
	(select p.segment, count(distinct p.product_code) as product_count_2021 from dim_product as p
	 join fact_sales_monthly s 
     on p.product_code = s.product_code
     where s.fiscal_year = 2021 group by p.segment
    )
select a1.segment, a1.product_count_2021, a0.product_count_2020,(a1.product_count_2021 - a0.product_count_2020) as diference
from product_count_2021 as a1
inner join product_count_2020 as a0 on a1.segment=a0.segment;

/**
5. Get the products that have the highest and lowest manufacturing costs.
   The final output should contain these fields,

   product_code
   product
   manufacturing_cost
**/
select p.product_code, p.product, max(m.manufacturing_cost) as manufacturing_cost from dim_product as p
join fact_manufacturing_cost as m
on p.product_code = m.product_code
union
select p.product_code, p.product, min(m.manufacturing_cost) as manufacturing_cost from dim_product as p
join fact_manufacturing_cost as m
on p.product_code = m.product_code;


/**
6. Generate a report which contains the top 5 customers who received an
   average high pre_invoice_discount_pct for the fiscal year 2021 and in the
   Indian market. The final output contains these fields,

   customer_code
   customer
   average_discount_percentage

**/
select count(customer) from dim_customer; # 209
select count(distinct customer) from dim_customer; # 74

select c.customer_code, c.customer, round(avg(inv.pre_invoice_discount_pct)*100, 1) as average_discount_percentage from dim_customer as c
inner join fact_pre_invoice_deductions as inv
on c.customer_code = inv.customer_code
group by c.customer order by average_discount_percentage desc limit 5;


/**
7. Get the complete report of the Gross sales amount for the customer “Atliq
   Exclusive” for each month. This analysis helps to get an idea of low and
   high-performing months and take strategic decisions.
   The final report contains these columns:

   Month
   Year
   Gross sales Amount
**/
select monthname(s.date)as Month, year(s.date) as Year, round(sum(g.gross_price), 2) as Gross_Sales_Amount from fact_sales_monthly as s
join fact_gross_price as g
on s.product_code = g.product_code 
where s.customer_code in (select customer_code from dim_customer where customer="Atliq Exclusive")
group by Month, Year order by Year asc;


/**
8. In which quarter of 2020, got the maximum total_sold_quantity? The final
   output contains these fields sorted by the total_sold_quantity,
   
   Quarter
   total_sold_quantity
**/
select quarter(date) as Quarter, max(sold_quantity) as Total_sold_quantity
from fact_sales_monthly group by Quarter order by Total_sold_quantity asc;


/**
9. Which channel helped to bring more gross sales in the fiscal year 2021
   and the percentage of contribution? The final output contains these fields,

   channel
   gross_sales_mln
   percentage
**/
with
ss1 as 
	(select c.channel, s.product_code, s.sold_quantity from dim_customer as c
	 join fact_sales_monthly as s
	 on c.customer_code = s.customer_code
	),
ss2 as (select g.product_code, g.gross_price from fact_gross_price as g)
select s1.channel,  round(sum((s1.sold_quantity * s2.gross_price))/1000000, 0) as gross_sales_mln
from ss1 as s1
inner join ss2 as s2
on s1.product_code = s2.product_code group by s1.channel;


/**
10. Get the Top 3 products in each division that have a high
    total_sold_quantity in the fiscal_year 2021? The final output contains these
    fields,

	division
	product_code
    product
	total_sold_quantity
	rank_order
**/
with 
cte1 as (
	select p.division, p.product_code, p.product, sum(s.sold_quantity) as total_sold_quantity
	from dim_product as p
	join fact_sales_monthly as s
	on p.product_code = s.product_code
	where s.fiscal_year = 2021
	group by p.division, p.product, p.product_code
),
cte2 as (
	select *, rank() over(partition by division order by total_sold_quantity) as rank_order
    from cte1
)
select * from cte2
where rank_order <= 3;


