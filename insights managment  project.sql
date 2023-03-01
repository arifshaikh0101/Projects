-- 10.Get the Top 3 products in each division that have a high
-- total_sold_quantity in the fiscal_year 2021? The final output contains these fields,
-- division
-- product_code


with rnk as(
  select 
    DENSE_RANK() over(
      partition by division 
      order by 
        sum(fsm.sold_quantity) desc
    ) as "rk", 
    sum(fsm.sold_quantity) as total_sold_quant, 
    dp.division, 
    dp.product_code 
  from 
    dim_product dp 
    join fact_sales_monthly fsm on dp.product_code = fsm.product_code 
  where 
    fsm.fiscal_year = "2021" 
  group by 
    dp.division, 
    dp.product_code
) 
select 
  rnk.rk, 
  rnk.division, 
  rnk.product_code, 
  rnk.total_sold_quant 
from 
  rnk 
where 
  rnk.rk <= 3 
group by 
  rnk.division, 
  rnk.product_code;





-- 9.Which channel helped to bring more gross sales in the fiscal year 2021
-- and the percentage of contribution? The final output contains these fields, channel
-- gross_sales_mln
-- percentage

with gross as (
  select 
    dc.channel, 
    (
      fgp.gross_price * fsm.sold_quantity
    ) as gross_sale_mln 
  from 
    fact_gross_price fgp 
    join fact_sales_monthly fsm on fgp.product_code = fsm.product_code 
    join dim_customer dc on fsm.customer_code = dc.customer_code 
  where 
    fgp.fiscal_year = "2021" 
  group by 
    dc.channel 
  order by 
    (
      fgp.gross_price * fsm.sold_quantity
    ) desc
) 
select 
  gross.channel, 
  gross.gross_sale_mln, 
  round(
    gross.gross_sale_mln /(
      select 
        sum(gross_sale_mln) 
      from 
        gross
    )* 100, 
    2
  ) as perce 
from 
  gross 
group by 
  gross.channel 
order by 
  gross.gross_sale_mln desc;




-- 8.In which quarter of 2020, got the maximum total_sold_quantity?
-- The final output contains these fields sorted by 
-- the total_sold_quantity,Quarter,total_sold_quantity




with quarter_date as (
  select 
    month(date) as month, 
    sum(sold_quantity) as grand_sold_quantity, 
    case when month(date) between "9" 
    and "11" then 1 when month(date) between "3" 
    and "5" then 3 when month(date) between "6" 
    and "8" then 4 else 2 end as quarters 
  from 
    fact_sales_monthly 
  where 
    year(date)= "2020" 
  group by 
    month(date)
) 
select 
  qd.quarters as Quarter, 
  sum(qd.grand_sold_quantity) as Total_sold_quatity 
from 
  quarter_date qd 
group by 
  qd.quarters 
order by 
  sum(qd.grand_sold_quantity) desc;



-- 7.Get the complete report of the Gross sales amount for the customer “AtliqExclusive” for each month. 
-- This analysis helps to get an idea of low andhigh-performing months and take strategic decisions.
-- The final report contains these columns:
-- Month
-- Year
-- Gross sales Amount


SELECT 
  year(date) as Year, 
  month(date) as Month, 
  (
    fsm.sold_quantity * fgp.gross_price
  ) as gross_sales 
FROM 
  fact_gross_price fgp 
  join fact_sales_monthly fsm on fgp.product_code = fsm.product_code 
  join dim_customer dc on fsm.customer_code = dc.customer_code 
where 
  dc.customer = "Atliq Exclusive" 
group by 
  year(date), 
  month(date) 
order by 
  year(date), 
  month(date);



-- 6. Generate a report which contains the top 5 customers who received an
-- average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. 
-- The final output contains these fields,
-- customer_code
-- customer
-- average_discount_percentage

with average_discount as(
  select 
    *, 
    avg(pre_invoice_discount_pct) as average 
  from 
    fact_pre_invoice_deductions
) 
select 
  fpi.customer_code, 
  dc.customer, 
  fpi.pre_invoice_discount_pct 
from 
  fact_pre_invoice_deductions fpi, 
  average_discount ad 
  join dim_customer dc on ad.customer_code = dc.customer_code 
where 
  fpi.fiscal_year = "2021" 
  and fpi.pre_invoice_discount_pct > ad.average 
  and sub_zone = "India" 
group by 
  fpi.customer_code 
order by 
  fpi.pre_invoice_discount_pct desc 
limit 
  5;




-- 5.Get the products that have the highest and lowest manufacturing costs.
-- The final output should contain these fields,
-- product_code
-- product
-- manufacturing_cost

select 
  distinct(fc.product_code), 
  dp.product, 
  fc.cost_year, 
  max(fc.manufacturing_cost) as max_manufacturing_cost, 
  min(fc.manufacturing_cost) as min_manufacturing_cost 
from 
  fact_manufacturing_cost fc 
  join dim_product dp on fc.product_code = dp.product_code 
group by 
  fc.cost_year;


-- 4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? 
-- The final output contains these fields,
-- segment
-- product_count_2020
-- product_count_2021
-- difference 


with total_count as (
  select 
    dp.segment as segment, 
    count(distinct fsm.product_code) as count_2020 
  from 
    fact_sales_monthly fsm 
    join dim_product dp on fsm.product_code = dp.product_code 
  where 
    fsm.fiscal_year = "2020" 
  group by 
    dp.segment 
  order by 
    dp.segment
), 
total_count_2 as (
  select 
    dp.segment as segment2, 
    count(distinct fsm.product_code) as count_2021 
  from 
    fact_sales_monthly fsm 
    join dim_product dp on fsm.product_code = dp.product_code 
  where 
    fsm.fiscal_year = "2021" 
  group by 
    dp.segment 
  order by 
    dp.segment
) 
select 
  dp.segment, 
  tc.count_2020, 
  tc2.count_2021, 
  (tc2.count_2021 - tc.count_2020) as difference 
from 
  total_count tc 
  join total_count_2 tc2 on tc.segment = tc2.segment2 
  join dim_product dp on tc2.segment2 = dp.segment 
group by 
  dp.segment 
order by 
  (tc2.count_2021 - tc.count_2020) desc



-- 3.Provide a report with all the unique product counts for each segment and
-- sort them in descending order of product counts. The final output contains 2 fields,
-- segment
-- product_count

select segment,count(distinct (product_code)) as Product_count from dim_product
group by segment order by count(distinct (product_code)) desc;

-- 2. What is the percentage of unique product increase in 2021 vs. 2020? The
-- final output contains these fields,
-- unique_products_2020
-- unique_products_2021
-- percentage_chg

WITH uniq_count_2020 as (
  select 
    count(distinct product_code) as total_count_2020 from fact_sales_monthly 
  where 
    fiscal_year = '2020'
), 
uniq_count_2021 as (
  select 
    count(distinct product_code) as total_count_2021 from fact_sales_monthly 
  where 
    fiscal_year = '2021'
), 
total_unique as (
  select 
    count(distinct product_code) as prod_count 
  from 
    fact_sales_monthly 
  where 
    fiscal_year = "2020" 
    or fiscal_year = "2021"
) 
select 
  uc.total_count_2020 as unique_products_2020, 
  uc2.total_count_2021 as unique_product_2021, 
  round(
    (
      uc2.total_count_2021 - uc.total_count_2020
    )/ tu.prod_count * 100, 
    2
  ) as percentage_chg from uniq_count_2020 uc, 
  uniq_count_2021 uc2, 
  total_unique tu


-- 1. Provide the list of markets in which customer "Atliq Exclusive" operates 
-- its business in the APAC region.

select distinct customer,market,region  from dim_customer
where customer="Atliq Exclusive" and region="APAC";