SELECT * FROM (SELECT q1.time, round(100.0 * ((0.0 + q1.err)/(0.0 + q2.total)), 1) as errors FROM (SELECT time::date, sum(CASE WHEN status != '200 OK' THEN 1 ELSE 0 END) as err FROM log WHERE status != '200 OK' GROUP BY time::date) as q1 JOIN (SELECT log.time::date, count(log.status) as total FROM log GROUP BY time::date) as q2 ON q1.time = q2.time ORDER BY errors DESC) as _ WHERE errors > 1;

                                                                                         QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=3995935.48..4029000.78 rows=13226121 width=20)
   Sort Key: (round((100.0 * ((0.0 + ((sum(CASE WHEN (log.status <> '200 OK'::text) THEN 1 ELSE 0 END)))::numeric) / (0.0 + ((count(log_1.status)))::numeric))), 1)) DESC
   ->  Merge Join  (cost=277776.42..1934218.25 rows=13226121 width=20)
         Merge Cond: (((log."time")::date) = ((log_1."time")::date))
         Join Filter: (round((100.0 * ((0.0 + ((sum(CASE WHEN (log.status <> '200 OK'::text) THEN 1 ELSE 0 END)))::numeric) / (0.0 + ((count(log_1.status)))::numeric))), 1) > '1'::numeric)
         ->  Sort  (cost=38208.52..38227.41 rows=7559 width=12)
               Sort Key: ((log."time")::date)
               ->  HashAggregate  (cost=37551.49..37645.97 rows=7559 width=15)
                     Group Key: (log."time")::date
                     ->  Seq Scan on log  (cost=0.00..37460.89 rows=12080 width=15)
                           Filter: (status <> '200 OK'::text)
         ->  Materialize  (cost=239567.91..278396.70 rows=1049831 width=12)
               ->  GroupAggregate  (cost=239567.91..265273.81 rows=1049831 width=15)
                     Group Key: ((log_1."time")::date)
                     ->  Sort  (cost=239567.91..243762.25 rows=1677735 width=15)
                           Sort Key: ((log_1."time")::date)
                           ->  Seq Scan on log log_1  (cost=0.00..37430.69 rows=1677735 width=15)
(17 rows)


-----------------
-----------------

SELECT * FROM (SELECT time::date,  ROUND( 100.0 * ( CAST ( SUM(CASE WHEN status != '200 OK' THEN 1 ELSE 0 END) AS NUMERIC) / CAST( COUNT(*) AS NUMERIC ) ), 1) as error_rate FROM log GROUP BY time::date ORDER BY error_rate DESC) as _ WHERE error_rate > 1;

                                                                                         QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=438052.51..440677.08 rows=1049831 width=15)
   Sort Key: (round((100.0 * ((sum(CASE WHEN (log.status <> '200 OK'::text) THEN 1 ELSE 0 END))::numeric / (count(*))::numeric)), 1)) DESC
   ->  GroupAggregate  (cost=239567.91..315115.85 rows=1049831 width=15)
         Group Key: ((log."time")::date)
         Filter: (round((100.0 * ((sum(CASE WHEN (log.status <> '200 OK'::text) THEN 1 ELSE 0 END))::numeric / (count(*))::numeric)), 1) > '1'::numeric)
         ->  Sort  (cost=239567.91..243762.25 rows=1677735 width=15)
               Sort Key: ((log."time")::date)
               ->  Seq Scan on log  (cost=0.00..37430.69 rows=1677735 width=15)
(8 rows)
