create database if not exists steam_games;

use steam_games;

drop table if exists steam_dataset;

-- creates a table to store the data from the csv file 
CREATE TABLE steam_dataset (
    player_id INT,
    game VARCHAR(255),
    method ENUM('play', 'purchase'),
    num_of_hrs DECIMAL(10 , 1 )
);

-- checking if the data is good 
SELECT 
    *
FROM
    steam_dataset
WHERE
    player_id IS NULL OR game IS NULL
        OR method IS NULL
        OR num_of_hrs IS NULL;


-- checks if dataset was succefully imported 
SELECT 
    *
FROM
    steam_dataset;
    
-- ALL DATA IS INTACT

-- creates a view that shows all the different games in the list
CREATE VIEW Games AS
    SELECT DISTINCT
        game
    FROM
        steam_dataset;
        
        
-- checks the view
SELECT 
    *
FROM
    games;
-- this shows that there are 5155 different games in the list 

-- creates and checks a view that shows all players in the dataset
CREATE OR REPLACE VIEW players AS
    SELECT DISTINCT
        player_id
    FROM
        steam_dataset;
        
SELECT 
    *
FROM
    players; 


-- checks which player has made the most and least amount of purchases 
SELECT 
    player_id, COUNT(game) AS num_of_purchase
FROM
    steam_dataset
WHERE
    method = 'purchase'
GROUP BY player_id
HAVING COUNT(game) = (SELECT 
        COUNT(game)
    FROM
        steam_dataset
    WHERE
        method = 'purchase'
    GROUP BY player_id
    ORDER BY COUNT(game) DESC
    LIMIT 1) 
UNION SELECT 
    player_id, COUNT(game) AS num_of_purchase
FROM
    steam_dataset
WHERE
    method = 'purchase'
GROUP BY player_id
HAVING COUNT(game) = (SELECT 
        COUNT(game)
    FROM
        steam_dataset
    WHERE
        method = 'purchase'
    GROUP BY player_id
    ORDER BY COUNT(game)
    LIMIT 1);
    
    
-- shows top 3 most purchased games on steam
SELECT 
    game, COUNT(player_id) AS num_of_purchase
FROM
    steam_dataset
WHERE
    method = 'purchase'
GROUP BY game
ORDER BY num_of_purchase DESC
limit 3; 

-- shows who has played games for the most amount of hrs 
SELECT 
    player_id, ROUND(AVG(num_of_hrs), 0) AS avg_hrs
FROM
    steam_dataset
WHERE
    method = 'play'
GROUP BY player_id
HAVING AVG(num_of_hrs) = (SELECT 
        AVG(num_of_hrs)
    FROM
        steam_dataset
    WHERE
        method = 'play'
    GROUP BY player_id
    ORDER BY AVG(num_of_hrs) DESC
    LIMIT 1);
    
    
-- check if there is any relation between the avg hrs a game is played to the how much it was bought

-- for this i will start by creating a temp tables that will hold the avg amout of time a game has been played and how many purchases

create temporary table avg_hrs ( game varchar(255), avg_hr int);
create temporary table num_of_purchases (game varchar(255), num_purch int);

-- checking if the temp tables were created 
SELECT 
    *
FROM
    avg_hrs;
    
SELECT 
    *
FROM
    num_of_purchases;

-- inserting values 
insert into avg_hrs 
SELECT 
    game, ROUND(AVG(num_of_hrs), 0) AS avg_hr
FROM
    steam_dataset
WHERE
    method = 'play'
GROUP BY game
ORDER BY avg_hr;

insert into num_of_purchases
SELECT 
    game, COUNT(player_id)
FROM
    steam_dataset
WHERE
    method = 'purchase'
GROUP BY game;

-- checking if there is a relation, beacuse in the orinal dataset not every game had a record for play hrs an outer join will be used
SELECT 
    n.game, n.num_purch, a.avg_hr
FROM
    num_of_purchases n
        LEFT JOIN
    avg_hrs a ON n.game = a.game
ORDER BY n.num_purch DESC;

/* 
but for performing analysis we would only need the one which have both values recorded because i took a look at the table 
that was created when excecuting the upper query and it seems the games with no play hrs recorded are dlc so i will write 
the query to get the table that will be used in the report. the only difference is an inner join will be used.
*/
SELECT 
    n.game, n.num_purch, a.avg_hr
FROM
    num_of_purchases n
        JOIN
    avg_hrs a ON n.game = a.game
ORDER BY n.num_purch DESC;

-- check the difference in purchase between the games 
SELECT *, 
     num_purch - LEAD(num_purch) OVER(ORDER BY num_purch DESC) AS purchase_diff 
FROM num_of_purchases;


-- create a procedure where the person inputs the game and they get the number of purchases

delimiter $$
CREATE PROCEDURE amount_of_purchase (IN game_name varchar(255), OUT purchases int )
BEGIN
SELECT 
    COUNT(player_id)
INTO purchases FROM
    steam_dataset
WHERE
    method IN ('purchase')
        AND game = game_name
GROUP BY game;
END$$

delimiter ;

-- check if the stored procedure works
call amount_of_purchase('fallout 4', @purchase);
select @purchase;

-- check if the avg number of hrs a player games is related to the amount of games he/she has bought 

-- instead of going through the process of creating temp tables i will do this in one select statement this time
SELECT 
    a.*, ROUND(AVG(b.num_of_hrs), 0) AS avg_hrs
FROM
    (SELECT 
        player_id, COUNT(method) AS purchases
    FROM
        steam_dataset
    WHERE
        method = 'purchase'
    GROUP BY player_id) a
        JOIN
    steam_dataset b ON a.player_id = b.player_id
WHERE
    b.method = 'play'
GROUP BY b.player_id
ORDER BY a.purchases DESC;
    

    
    


  
