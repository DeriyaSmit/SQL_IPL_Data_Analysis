/* 1-> Top 10 Batsman with highest strike_rate */
SELECT batsmanName,
       round((sum(runs)/sum(balls))*100,2) as Strike_rate  FROM ipl_data.fact_bating_summary
group by 1
having sum(balls)>=60
order by Strike_rate desc
limit 10


/* 2-> Batsman with the highest strike rate at every position */
with highest_stike_position as(
SELECT battingPos,
       batsmanName, 
       round((sum(runs)/sum(balls))*100,2) as Strike_rate,
       row_number() over(partition by battingPos order by round((sum(runs)/sum(balls))*100,2) desc) as player_batting_rank
FROM ipl_data.fact_bating_summary
group by 1,2
having sum(balls)>=60)

select battingPos,
       batsmanName,
       Strike_rate
from highest_stike_position
where player_batting_rank=1


/* 3-> Top 2 batsmn from each team in a match */
with Runs_Batting_positions as(
SELECT fact_bating_summary.match,
       teamInnings,
       battingPos,
       sum(runs) as Total_Runs,
       row_number() 
           over(partition by fact_bating_summary.match,teamInnings order by sum(runs) desc)  as rk
FROM ipl_data.fact_bating_summary
group by 1,2,3)

select rbp.match,
       rbp.teamInnings as TeamInning ,
	   rbp.battingPos,
       fbs.batsmanName,
       rbp.Total_Runs
From Runs_Batting_positions as rbp
join fact_bating_summary fbs
on rbp.match=fbs.match and
   rbp.teamInnings=fbs.teamInnings and
   rbp.battingPos=fbs.battingPos
where rk<=2


/* 4-> Top 10 Bowler with most number of wicket */
select BowlerName,Total_wickets from(
SELECT BowlerName,sum(wickets) as Total_wickets,
       rank() over(order by  sum(wickets) desc)   as rn
FROM fact_bowling_summary
group by BowlerName
having sum(overs)>=5) as Top_10_bowler
where rn<=10


/* 5-> Top10 Bowlers with the lowest and the higest economy rate */
select bowlerName,Economy 
from (select bowlerName,round(sum(runs)/sum(overs),2) as Economy,
row_number() over(order by round(sum(runs)/sum(overs),2) desc) as rn
FROM ipl_data.fact_bowling_summary
group by 1
having sum(overs)>=5) as Highest_Economy
where rn<=10

select bowlerName,Economy 
from (select bowlerName,round(sum(runs)/sum(overs),2) as Economy,
row_number() over(order by round(sum(runs)/sum(overs),2) asc) as rn
FROM ipl_data.fact_bowling_summary
group by 1
having sum(overs)>=5) as Highest_Economy
where rn<=10


/* 6-> Best 2 Bowler from each team in a match with less economy and most wicket */
with cte as(SELECT fact_bowling_summary.match,bowlingTeam,bowlerName,
       sum(wickets) as total_wicket,
       round(sum(runs)/sum(overs),2) as Economy,
       row_number() over(partition by fact_bowling_summary.match,bowlingTeam
                    order by sum(wickets) desc,round(sum(runs)/sum(overs),2) asc) as rn
FROM fact_bowling_summary
group by 1,2,3)

select cte.match,bowlingTeam,bowlerName,total_wicket,Economy
from cte
where rn<=2


/* 7-> Total Wicket By the Bowling Style */
SELECT bowlingStyle,sum(wickets) as Total_Wickets FROM ipl_data.dim_players
join fact_bowling_summary
on name=bowlerName
group by 1
order by Total_Wickets desc


/* 8-> Team winning percentage while Bowling_1 and Batting_1 */
with cte as(
select team1 as team,count(team1) as T_match from dim_match_summary
group by team1
union all
select team2 as team , count(team2) as T_match from dim_match_summary
group by team2
),

bowl_1 as(
select team2 as Teamm, 
	   count(case when margin like "%wickets" then 1 else null end ) as TW_Bowling_1
from dim_match_summary
group by 1 ),

bat_1 as(
select team1 as Teamm,
       count(case when margin like "%runs" then 1 else null end ) as TW_Batting_1  
from dim_match_summary
group by 1 )

select team,
       round((max(TW_Bowling_1)+max(TW_Batting_1 ))/sum(T_match)*100) as 'Winning%',
       round(max(TW_Bowling_1)/sum(T_match)*100) as 'Bowling_1_Winning%',
       round(max(TW_Batting_1 )/sum(T_match)*100) as 'Batting_1_Winning%'
from cte 
join bowl_1 on cte.team=bowl_1.teamm
join bat_1 on cte.team=bat_1.teamm
group by 1


/* 9-> Top 10 bowlers based on past 3 years bowling average */
select BowlerName,Bowling_average from(
SELECT BowlerName,
       sum(runs)/sum(wickets) as Bowling_average,
       rank() over(order by sum(runs)/sum(wickets) asc)   as rn
FROM fact_bowling_summary
where wickets>=1
group by BowlerName
having sum(overs)>=10) as Top_10_bowler
where rn<=10


/* 10-> Top 10 Batsman with highest Batting average */
SELECT batsmanName,
       (sum(runs)/
       count(case when outt_not_out="out" then 1 else null end)) as batting_average
FROM ipl_data.fact_bating_summary
group by 1
having sum(balls)>=60
order by batting_average desc
limit 10





