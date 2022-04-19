//*
    Source: PopSQL - Yelp DB
    - Can also use Kaggle - Yelp DataSet keep in mind they do not have covid_features
    SQL Data Exploration
    Glee Truong
*/

/*
    BASIC EXPLORATION
    * Here I will just be going through the db to see all the tables we have and what attributes are in each table.
*/
-- Businesses Table
Select *
From businesses
Limit 20

-- checkins Table
Select *
From checkins
Limit 20

-- covid_features Table
Select *
From covid_features
Limit 20

-- reviews Table
Select *
From reviews
Limit 20

-- tips Table
Select *
From tips
Limit 20

-- users Table
Select *
From users
Limit 20

/*
    Outcome:
    * Businesses, checkins, covid_features, reviews, tips tables are all connected by business_id.
    * Reviews, tips, and users are all connected by user_id

    Ideas:
    * Look at users and their review counts and average stars they give.
    * Look at users who are elites over the last few years
    * Look at businesses with stars and review count.
    * Popular businesses categories
    * Popular businesses in each city
*/

-- User with the most reviews
Select name, review_count, user_id
From users
Order by 2 desc
-- Notice Bruce has over 12000 reviews.


-- Oldest Member on Yelp with review count
Select name, yelping_since, review_count
From users
Order by 2


-- Business with the most review
Select name, city, state, review_count, stars
From businesses
Order by 4 desc
--Notice South Point Hotel, Casino & Spa has 1818 review_count

-- Business with 3 stars or higher
Select name, stars
From businesses
Where stars > 3


-- Reviews per Year
Select
    extract (year from date) as review_years,
    count(*) as num_reviews
From reviews
Group by 1
Order by 1
-- We can see that the number of reviews per year peaked in 2017 and starts to decrease




-- Restaurants with delivery and takeout
Select
    "delivery or takeout",
    count(distinct c.business_id) as restaurants
From covid_features c
Join businesses b on b.business_id = c.business_id and lower(b.categories) like '%restaurant%'
Group by 1




--Each Business First Review
with cte as
(
    Select
        b.name,
        Row_number() Over (partition by r.business_id order by r.date) as rn,
        r.review_id,
        date
    From businesses b
    Join reviews r Using(business_id)
)
Select * 
From cte
Where rn = 1


--Looking at Business Review reactions
with cte as
(
    Select
        business_id,
        name b_Name,
        address,
        city,
        state,
        review_count,
        attributes,
        categories,
        review_id,
        user_id,
        useful,
        funny,
        cool,
        useful + funny + cool as Reaction_Count,
        text
    From businesses b
    Join reviews r Using(business_id)
)
Select
    b_Name,
    city,
    state,
    Reaction_Count,
    user_id,
    name,
    text,
    review_id
From users u
Join cte Using(user_id)
Order by 4 desc


-- Best Yelper with Recency, Frequency, Monetary (RFM) - we will be using stars here as our monetary value

with rfm as
(
    Select
        user_id,
        sum(stars) Total_Stars,
        round(avg(stars),2) Avg_Stars,
        count(user_id) Freq,
        extract()
        max(date) Last_Review_date,
        (select max(date) from reviews) Max_Review_Date,
        DATEDIFF(DD, max(date), (select max(date) from reviews)) Recency 
    From reviews
    Group by 1
)
select r.*,
    ntile(4) Over (order by Recency) rfm_Recency,
    ntile(4) Over (order by Freq) rfm_Freq,
    ntile(4) Over (order by Avg_Stars) rfm_Monetary
From rfm r