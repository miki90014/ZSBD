-- usuwanie bolukjącej transakcji
SELECT 
    s.sid, 
    s.serial#, 
    s.username, 
    s.status, 
    s.machine, 
    l.type, 
    l.id1, 
    l.id2
FROM 
    v$session s 
JOIN 
    v$lock l ON s.sid = l.sid
WHERE 
    l.type = 'TX'; -- blokada transakcji

ALTER SYSTEM KILL SESSION 'sid,serial#';
