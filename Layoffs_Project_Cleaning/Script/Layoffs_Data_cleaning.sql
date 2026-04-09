--- Data Cleaning

select *
from layoffs;

-- 1. Drop source column

alter table layoffs
drop column source;

--- Creating a clone dataset

create table layoffs_staging
like layoffs;

insert layoffs_staging
select *
from layoffs;


select *
from layoffs_staging;

--- Remove duplicates

select * ,
row_number () over (
partition by company, industry,total_laid_off,percentage_laid_off,`date`) as row_num

from layoffs_staging;

with duplicate_cte as (

select * ,
row_number () over (
partition by company,  
location,  
total_laid_off,  
`date`,  
percentage_laid_off,  
industry,  
stage,  
funds_raised,  
country, 
date_added) as row_num

from layoffs_staging

)
select *
from duplicate_cte
where row_num > 1;





CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `total_laid_off` double DEFAULT NULL,
  `date` text,
  `percentage_laid_off` text,
  `industry` text,
  `stage` text,
  `funds_raised` text,
  `country` text,
  `date_added` text,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


select *
from layoffs_staging2;

insert into layoffs_staging2
select * ,
row_number () over (
partition by company,  
location,  
total_laid_off,  
`date`,  
percentage_laid_off,  
industry,  
stage,  
funds_raised,  
country, 
date_added) as row_num

from layoffs_staging;


delete
from layoffs_staging2
where row_num > 1;

select * 
from layoffs_staging2;

--- Standardizing data

update layoffs_staging2
set company = trim(company);

select distinct(industry)
from layoffs_staging2;

select distinct country
from layoffs_staging2;


update layoffs_staging2
set `date` = str_to_date(`date`, '%m/%d/%Y');


alter table layoffs_staging2
modify column `date` date;


select t1.industry, t2.industry
from layoffs_staging2 t1
join layoffs_staging2 t2
on t1.company = t2.company
where (t1.industry is null or t1.industry = '')
and t2.industry is not null;

update layoffs_staging2
set industry = null
where industry = ''
;

update layoffs_staging2 t1
join layoffs_staging2 t2
on t1.company = t2.company
set t1.industry = t2.industry
where t1.industry is null
and t2.industry is not null;


delete
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;


alter table layoffs_staging2
drop column row_num;

select * from layoffs_staging2;



--- Exploratory Analysis


select* 
from layoffs_staging2;


select company, sum(total_laid_off) as layoffs
from layoffs_staging2
group by company
order by 2 desc;


select industry, sum(total_laid_off) as layoffs
from layoffs_staging2
group by industry
order by 2 desc;

select industry, country ,sum(total_laid_off) as layoffs
from layoffs_staging2
group by country,industry
order by 3 desc;

select substring(`date`, 1,7) as Month, sum(total_laid_off) as Laid_Offs
from layoffs_staging2
where substring(`date`, 1,7) is not null
group by Month
order by 1 asc
;

with rolling_total as
(
select substring(`date`, 1,7) as Month, sum(total_laid_off) as Laid_Offs
from layoffs_staging2
where substring(`date`, 1,7) is not null
group by Month
order by 1 asc
)
select `Month`,laid_Offs,
 sum(Laid_Offs) over (order by `Month`) as Rolling_Total

From rolling_total;



select company,YEAR (`date`),sum(total_laid_off)
from layoffs_staging2
group by company, year(`date`)
order by 3 desc;

with company_year (company, year, total_laid_off ) as
(
select company,YEAR (`date`),sum(total_laid_off)
from layoffs_staging2
group by company, year(`date`)
), company_rank as
(select *, dense_rank() over (partition by year order by total_laid_off desc) ranking

from company_year
)

select *
from company_rank
where ranking <= 5;