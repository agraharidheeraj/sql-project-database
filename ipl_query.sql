-- Command To Create a Matches Database

-- Define a table to store information about cricket matches.
CREATE TABLE matches (
    id serial PRIMARY KEY,
    season integer,
    city varchar(50),
    match_date date,
    team1 varchar(50),
    team2 varchar(50),
    toss_winner varchar(50),
    toss_decision varchar(10),
    result varchar(50),
    dl_applied integer, 
    winner varchar(50),
    win_by_runs integer,
    win_by_wickets integer,
    player_of_match varchar(50),
    venue varchar(255),
    umpire1 varchar(50),
    umpire2 varchar(50),
    umpire3 varchar(50)
);


-- Command to copy data from a CSV file into the matches table
COPY matches FROM '/Library/PostgreSQL/matches.csv' DELIMITER ',' CSV HEADER;

-- Command to Create a Deliveries Database

-- Define a table to store information about deliveries in cricket matches.
CREATE TABLE deliveries (
    match_id integer,
    inning integer,
    batting_team varchar(255),
    bowling_team varchar(255),
    over integer,
    ball integer,
    batsman varchar(255),
    non_striker varchar(255),
    bowler varchar(255),
    is_super_over integer,
    wide_runs integer,
    bye_runs integer,
    legbye_runs integer,
    noball_runs integer,
    penalty_runs integer,
    batsman_runs integer,
    extra_runs integer,
    total_runs integer,
    player_dismissed varchar(255),
    dismissal_kind varchar(255),
    fielder varchar(255),
    FOREIGN KEY (match_id) REFERENCES matches(id)
);

-- Command to copy data from a CSV file into the deliveries table
COPY deliveries FROM '/Library/PostgreSQL/deliveries.csv' DELIMITER ',' CSV HEADER;

-- Question 1: Count the number of matches played in each season and order them by season.
SELECT season, COUNT(*) AS matches_played FROM matches
GROUP BY season
ORDER BY season;

-- Question 2: Retrieve the number of matches won by each team in each season.
SELECT season, winner AS team, COUNT(*) AS matches_won
FROM matches
WHERE winner IS NOT NULL
GROUP BY season, winner
ORDER BY season, matches_won DESC;


-- Question 3: Calculate the extra runs conceded by each team in the year 2016 based on data from both 'matches' and 'deliveries' databases.
SELECT matches.season, deliveries.bowling_team AS team,
SUM(deliveries.extra_runs) AS extra_runs_conceded
FROM matches
JOIN deliveries ON matches.id=deliveries.match_id
WHERE matches.season = 2016
GROUP BY matches.season, deliveries.bowling_team
ORDER BY matches.season, extra_runs_conceded DESC;



-- Question 4: Calculate the economy rate for bowlers in the 2015 season.
WITH BowlerStats AS (
SELECT d.bowler,
SUM(CASE
WHEN d.wide_runs = 0 AND d.noball_runs = 0 THEN 1  ELSE 0 END) AS total_balls,
SUM(CASE
WHEN d.bye_runs = 0 AND d.legbye_runs = 0 AND d.penalty_runs = 0 THEN d.total_runs
ELSE 0 END) AS total_runs
FROM  matches m
LEFT JOIN deliveries d ON m.id = d.match_id
WHERE m.season = '2015'
GROUP BY d.bowler)
SELECT bs.bowler,
ROUND(SUM(bs.total_runs * 6.0) / SUM(bs.total_balls), 2) AS economy
FROM BowlerStats bs
GROUP BY bs.bowler
ORDER BY economy ASC
LIMIT 10;


-- Question 5: Count the number of times each team won the toss and also won the match.
SELECT toss_winner AS team, COUNT(*) AS team_won_toss_win_match
FROM matches
WHERE toss_winner=winner
GROUP BY toss_winner
ORDER BY team_won_toss_win_match DESC;

-- Question 6: Find the player with the most 'Player of the Match' awards for each season.
WITH PlayerAwards AS 
(SELECT season, player_of_match, COUNT(*) AS awards_count
FROM matches
GROUP BY season, player_of_match ),
RankedPlayerAwards AS 
( SELECT season, player_of_match, awards_count,
  ROW_NUMBER() OVER (PARTITION BY season ORDER BY awards_count DESC) AS rank
  FROM PlayerAwards
)
SELECT season, player_of_match AS top_player, awards_count
FROM RankedPlayerAwards
WHERE rank =1;



-- Question 7: Calculate the strike rate of batsman 'V Kohli' for each season.
SELECT season,
 round (SUM(d.batsman_runs)*100.00/SUM(CASE WHEN wide_runs=0 THEN 1 else 0 END),2) AS strikeRate
 FROM matches m
 JOIN deliveries d ON m.id = d.match_id
 WHERE batsman='V Kohli'
 GROUP BY season
 ORDER BY season;
 

-- Question 8: Find the bowler who has dismissed the most number of players.
 SELECT bowler,player_dismissed,COUNT(player_dismissed) AS number_of_dissmissed
 FROM deliveries
 GROUP BY bowler,player_dismissed 
 order by number_of_dissmissed DESC LIMIT 1;


-- Question 9: Find the bowler with the best economy rate in Super Overs.
SELECT bowler,
ROUND((SUM(total_runs - wide_runs - noball_runs - penalty_runs) * 6.0) /
        NULLIF(SUM(CASE WHEN wide_runs = 0 AND noball_runs = 0 THEN 1 ELSE 0 END), 0),
      2) AS bowler_economy
FROM deliveries
WHERE is_super_over = '1'
GROUP BY bowler
ORDER BY bowler_economy ASC LIMIT 1;