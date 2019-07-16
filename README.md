# AnalyseLogs
https://www.udacity.com/course/full-stack-web-developer-nanodegree--nd004


The script can simply be run with
```
$ python analyse_log.py
```
you need to have setted up the vagrant server and the news database like described at the according Udacity course page.

It contains the following functions:

# connect()
- connects to the database 'news'
- returns database object

# run_query(query)
- opens a connection to the database
- fetches the 'query' which simply is a string like "SELECT .. FROM..."
- closes the connection
- returns the result of the query as database object

# popular_articles()
- defines the query to fetch the answer for question 1 of the Udacity task, which is:
> What are the most popular three articles of all time? Which articles have been accessed the most? Present this information as a sorted list with the most popular article at the top.
- Example:
```
"Princess Shellfish Marries Prince Handsome" — 1201 views
"Baltimore Ravens Defeat Rhode Island Shoggoths" — 915 views
"Political Scandal Ends In Political Scandal" — 553 views
```

# popular_authors()
- defines the query to fetch the answer for question 2 of the Udacity task, which is:
> Who are the most popular article authors of all time? That is, when you sum up all of the articles each author has written, which authors get the most page views? Present this as a sorted list with the most popular author at the top.
- Example:
```
Ursula La Multa — 2304 views
Rudolf von Treppenwitz — 1985 views
Markoff Chaney — 1723 views
Anonymous Contributor — 1023 views
```

# error_prone_days()
- defines the query to answer question 3, which is:
> On which days did more than 1% of requests lead to errors?
- Example:
```
July 29, 2016 — 2.5% errors
```

# make_report()
- runs the three functions that return the answers to Question 1-3
- creates a log-file "log_report.log"
- appends the answers nicely formatted to the log-file

# if \_\_name_\_ == \'\_\_main\_\_\'
- ensures that one can just run the script via command line

<hr><hr>

error_prone_days() contains a heavily nested query. Here is a breakdown for better understanding:
###### Q2 gives the total amount of connections per day (times are aggregated to days)
```pgsql
Q2 = "SELECT log.time::date, count(log.status) as total FROM log GROUP BY time::date"
```

###### Q1 gives the amount of "not-200-OK" connections per day (times are aggregated to days)
```pgsql
Q1 = "SELECT time::date, sum(CASE WHEN status != '200 OK' THEN 1 ELSE 0 END) as err FROM log WHERE status != '200 OK' GROUP BY time::date"
```

###### Join Q1 and Q2 to have a table that shows: "day -- error_connections -- total_connections"
- basic idea: "SELECT time, calculate_error_percentage FROM Q1 as q1 JOIN Q2 as q2 ON q1.time = q2.time"
- implemented this is:
```pgsql
A = "SELECT q1.time, round(100.0 * ((0.0 + q1.err)/(0.0 + q2.total)), 1) as errors FROM Q1 as q1 JOIN Q2 as q2 ON q1.time = q2.time ORDER BY errors DESC"
```

###### one can't use an alias in WHERE that is created (later) in SELECT, therefore wrap everything in a new SELECT clause
```pgsql
SELECT * FROM A as _ WHERE errors > 1;
```

###### this results finally in the follwoing query:
```pgsql
SELECT * FROM (SELECT q1.time, round(100.0 * ((0.0 + q1.err)/(0.0 + q2.total)), 1) as errors FROM (SELECT time::date, sum(CASE WHEN status != '200 OK' THEN 1 ELSE 0 END) as err FROM log WHERE status != '200 OK' GROUP BY time::date) as q1 JOIN (SELECT log.time::date, count(log.status) as total FROM log GROUP BY time::date) as q2 ON q1.time = q2.time ORDER BY errors DESC) as _ WHERE errors > 1;
```

### query 3 can be done much faster via:
```pgsql
SELECT * FROM (SELECT time::date,  ROUND(100.0 * SUM(CASE WHEN status != '200 OK' THEN 1 ELSE 0 END)::numeric / COUNT(*)::numeric, 1) as error_rate FROM log GROUP BY time::date ORDER BY error_rate DESC) as _ WHERE error_rate > 1;
```
