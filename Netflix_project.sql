--NETFLIX Project --

-- Create Table by copying excel header
-- Check data Type on CSV and find max length in excel MAX(LEN(Column or cell))

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

--Check column data type
SELECT * FROM netflix;


-- (1) Finding Movies & TV Shows From 1925 to 2021.
SELECT * FROM netflix
    WHERE TO_DATE(date_added, 'Month DD, YYYY') >= CURRENT_DATE - INTERVAL '5 years';


-- (2) Finding TV shows more than 5 seasons.
-- SPLIT_PART is split string into part but it still string. so change type (::) to compare to 5
SELECT SPLIT_PART(duration, ' ', 1) AS season, *
FROM netflix 
WHERE type = 'TV Show' AND SPLIT_PART(duration, ' ', 1) :: int > 5;


-- (3) Counting total movies and TV Shows on each genre.
SELECT COUNT(show_id) AS total,
    UNNEST(STRING_TO_ARRAY(listed_in, ',')) AS genre
FROM netflix
    GROUP BY genre
    ORDER BY total DESC;


--(4) Finding average and yearly contents in japan.
SELECT 
    EXTRACT (YEAR FROM TO_DATE(date_added, 'Month DD, YYYY')) AS Release_Year,
    COUNT(*) AS yearly_content,
    ROUND (COUNT(*):: numeric / (
                        SELECT COUNT(*)
                        FROM netflix
                        WHERE country = 'Japan'):: numeric * 100 ,2) AS avgcontent_peryear
FROM netflix
    WHERE country = 'Japan'
    GROUP BY 1
;

--(5) Finding Ryan Reynolds's movies and Tv show (last 10 year from now).
SELECT * 
FROM netflix 
    WHERE casts ILIKE '%Ryan Reynolds%' 
    AND release_year > EXTRACT(YEAR FROM CURRENT_DATE ) - 10;



-- (6) Finding all horror series and total count.
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


-- (7)  Counting tv shows and movies genre list according to country(hide blank and null value in country).
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


-- (8) In 2020 which genre is popular?
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


-- (9) finding movies those length over 90 min and director name is Toshiya Shinohara in japan.
SELECT *
    FROM netflix
    WHERE (country = 'Japan' AND SPLIT_PART(duration, ' ', 1 ):: numeric >90) 
    AND (type = 'Movie' AND director = 'Toshiya Shinohara');


-- (10) Finding average length of movies in south africa on all time. 
SELECT 
    'South Africa' As country,
    ROUND(AVG(SPLIT_PART(duration, ' ', 1):: numeric),2) AS average_minutes
FROM netflix
    WHERE country = 'South Africa' AND type = 'Movie';


-- (11) Finding morgan freeman's movie about CIA and nuclear.
SELECT * 
FROM netflix
    WHERE casts ILIKE '%Morgan Freeman%' 
    AND description ILIKE '%CIA%nuclear%';


-- (12) casts who have highest movies count and rank them 
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



-- (13)finding total movies & TV shows according to year and month by country on netflix.
SELECT 
    EXTRACT(YEAR FROM TO_DATE(date_added, 'Month DD, YYYY')) AS year,
    EXTRACT (MONTH FROM TO_DATE(date_added, 'Month DD, YYYY')) AS month,
    TRIM(UNNEST(STRING_TO_ARRAY(country, ','))) AS Country,
    COUNT(*) AS total_movie
FROM netflix
    GROUP BY 1,2,3
    ORDER BY 1,2 ;


-- (14) finding total movies & TV shows according to month (by country) on netflix.
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

-- (15) Order by movie_rating(explain) and count them.
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



