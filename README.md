# Netflix Movies and TV Shows Data Analysis using SQL

## Overview
This project involves a comprehensive analysis of Netflix's movies and TV shows data using PostgreSQL. The goal is to extract valuable insights and answer various business questions based on the dataset. The following README provides a detailed account of the project's objectives, problems and solutions.


## Dataset

The data for this project is sourced from the Kaggle dataset:

- **Dataset Link:** [Movies Dataset](https://www.kaggle.com/datasets/shivamb/netflix-shows?resource=download)

## CREATING_TABLE

```sql![logo](https://github.com/user-attachments/assets/2e48bcd2-d6fd-4876-9063-51fc6fb4d5dd)

DROP TABLE if exists netflix;
CREATE TABLE netflix (
	show_id VARCHAR(6),
	type VARCHAR(10),
	title VARCHAR(150),
	director VARCHAR(208),
	casts VARCHAR(1000),
	country VARCHAR(250),
	date_added VARCHAR(50),
	release_year INT,
	rating	VARCHAR(10),
	duration VARCHAR(15),
	listed_in VARCHAR(100),
	description VARCHAR(250)
);
```
--Check column data type
SELECT * FROM netflix;


## Problems and Solutions 

### (1) Finding Movies & TV Shows From 1925 to 2021.

```sql
SELECT *
FROM netflix
WHERE TO_DATE(date_added, 'Month DD, YYYY') >= CURRENT_DATE - INTERVAL '5 years';
```


### (2) Finding TV shows more than 5 seasons.

```sql
SELECT SPLIT_PART(duration, ' ', 1) AS season, *
FROM netflix 
	WHERE type = 'TV Show' 
	AND SPLIT_PART(duration, ' ', 1) :: int > 5;
```


### (3) Counting total movies and TV Shows on each genre.

```sql
SELECT COUNT(show_id) AS total,
    UNNEST(STRING_TO_ARRAY(listed_in, ',')) AS genre
FROM netflix
    GROUP BY genre
    ORDER BY total DESC;
```


### (4) Finding average and yearly contents in japan.

```sql
SELECT 
    EXTRACT (YEAR FROM TO_DATE(date_added, 'Month DD, YYYY')) AS Release_Year,
    COUNT(*) AS yearly_content,
    ROUND (COUNT(*):: numeric / (
                        SELECT COUNT(*)
                        FROM netflix
                        WHERE country = 'Japan'):: numeric * 100 ,2) AS avgcontent_peryear
FROM netflix
    WHERE country = 'Japan'
    GROUP BY 1;
```


### (5) Finding Ryan Reynolds's movies and Tv show (last 10 year from now).

```sql
SELECT * 
FROM netflix 
    WHERE casts ILIKE '%Ryan Reynolds%' 
    AND release_year > EXTRACT(YEAR FROM CURRENT_DATE ) - 10;
```


### (6) Finding all horror series and total count.

```sql
WITH CTE_Horror AS (
SELECT 
   COUNT(*) AS Total,
   TRIM(UNNEST(STRING_TO_ARRAY(listed_in, ','))) AS series
FROM netflix
    WHERE type = 'TV Show' 
    GROUP BY series)
    
SELECT * FROM CTE_Horror
WHERE series = 'TV Horror'; -- COUNT

SELECT * 
FROM netflix
WHERE type = 'TV Show' AND listed_in ILIKE '%TV Horror%'; -- all horror series 
```


### (7) Counting tv shows and movies genre list according to country(hide blank and null value in country).

```sql
WITH CTE_Not_null AS (
SELECT 
    TRIM(UNNEST(STRING_TO_ARRAY(country, ','))) AS listed_country, 
    TRIM(UNNEST(STRING_TO_ARRAY(listed_in, ','))) AS genre,
    COUNT(*) AS total_movies_and_TV_show
FROM netflix
    GROUP BY listed_country,genre
    ORDER BY 1, 3 DESC )

SELECT *
FROM CTE_not_null
    WHERE listed_country IS NOT NULL 
    ORDER BY 1 , 3 DESC
    LIMIT 873 OFFSET 4;
```

### (8) In 2020 which genre is popular?

```sql
WITH CTE_2020_genre AS (
SELECT  
    EXTRACT(YEAR FROM TO_DATE(date_added, 'Month DD, YYYY')) AS year,
    TRIM(UNNEST(STRING_TO_ARRAY(listed_in, ','))) AS genre,
    COUNT(*) AS popularity
FROM netflix
    GROUP BY year, genre
    ORDER BY 1 DESC)
    SELECT * FROM CTE_2020_genre
    WHERE year = 2020
    ORDER BY popularity DESC;
```


### (9) finding movies those length over 90 min and director name is Toshiya Shinohara in japan.

```sql
SELECT *
    FROM netflix
    WHERE (country = 'Japan' AND SPLIT_PART(duration, ' ', 1 ):: numeric >90) 
    AND (type = 'Movie' AND director = 'Toshiya Shinohara');
```


### (10) Finding average length of movies in south africa on all time. 

```sql
SELECT 
    'South Africa' As country,
    ROUND(AVG(SPLIT_PART(duration, ' ', 1):: numeric),2) AS average_minutes
FROM netflix
    WHERE country = 'South Africa' AND type = 'Movie';
```


### (11) Finding morgan freeman's movie about CIA and nuclear.

```sql
SELECT * 
FROM netflix
    WHERE casts ILIKE '%Morgan Freeman%' 
    AND description ILIKE '%CIA%nuclear%';
```

### (12) casts who have highest movies count and rank them

```sql
WITH CTE_Rank_cast AS (
SELECT 
    TRIM(UNNEST(STRING_TO_ARRAY(casts, ','))) AS casts,
    COUNT(*) AS total_movies
FROM netflix
GROUP BY 1
ORDER BY 2 DESC)
SELECT casts,
    total_movies,
    DENSE_RANK() OVER(ORDER BY total_movies DESC) AS Rank
FROM CTE_Rank_cast ;
```


### (13) finding total movies & TV shows according to year and month by country on netflix.

```sql
SELECT 
    EXTRACT(YEAR FROM TO_DATE(date_added, 'Month DD, YYYY')) AS year,
    EXTRACT (MONTH FROM TO_DATE(date_added, 'Month DD, YYYY')) AS month,
    TRIM(UNNEST(STRING_TO_ARRAY(country, ','))) AS Country,
    COUNT(*) AS total_movie
FROM netflix
    GROUP BY 1,2,3
    ORDER BY 1,2 ;
```


### (14) finding total movies & TV shows according to month (by country) on netflix.

```sql
SELECT month, COUNT(total_movie) AS total_movie
FROM (SELECT 
    EXTRACT(YEAR FROM TO_DATE(date_added, 'Month DD, YYYY')) AS year,
    EXTRACT (MONTH FROM TO_DATE(date_added, 'Month DD, YYYY')) AS month,
    TRIM(UNNEST(STRING_TO_ARRAY(country, ','))) AS Country,
    COUNT(*) AS total_movie
    FROM netflix
    GROUP BY 1,2,3
    ORDER BY 1,2 ) AS YMCcount
GROUP BY 1
ORDER BY 1,2 ;
```


### (15) Order by movie_rating(explain) and count them.

```sql
SELECT type,
    CASE 
        WHEN rating = 'NR' THEN 'Not Rated'
        WHEN rating = 'TV-Y' THEN 'All Children'
        WHEN rating = 'TV-Y7' THEN 'Directed to Older Children'
        WHEN rating = 'TV-Y7-FV' THEN 'Directed to Older Children - Fantasy Violence'
        WHEN rating = 'TV-G' THEN 'General Audience'
        WHEN rating = 'TV-14' THEN 'Parents Strongly Cautioned'
        WHEN rating = 'TV-MA' THEN 'Mature Audience Only'
        WHEN rating = 'G' THEN 'General Audience'
        WHEN rating = 'NC-17' THEN 'No One 17 and Under Admitted'
        WHEN rating = 'PG' THEN 'arental Guidance Suggested'
        WHEN rating = 'TV-PG' THEN 'Parental Guidance Suggested'
        WHEN rating = 'PG-13' THEN 'Parents Strongly Cautioned'
        WHEN rating = 'R' THEN 'Restricted'
        WHEN rating = 'UR' THEN 'Unrated'
        ELSE 'N/A'
    END AS Movie_Rating,
    COUNT(*)
FROM netflix
    GROUP BY type, Movie_Rating
    ORDER BY 1, 3 DESC ;
```

## Conclusion

This analysis provides a comprehensive view of Netflix's content and can help inform content strategy and decision-making.

