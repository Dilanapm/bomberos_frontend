
2026-04-27 22:44:37.296 UTC [27] LOG:  checkpoint complete: wrote 14 buffers (0.1%); 0 WAL file(s) added, 0 removed, 0 recycled; write=1.109 s, sync=0.017 s, total=1.136 s; sync files=13, longest=0.005 s, average=0.002 s; distance=41 kB, estimate=41 kB; lsn=0/59E06C0, redo lsn=0/59E0688

2026-04-27 22:45:32.174 UTC [46] ERROR:  column "detection_type" of relation "epp_step_evaluations" does not exist at character 63

2026-04-27 22:45:32.174 UTC [46] STATEMENT:  insert into "epp_step_evaluations" ("created_at", "detected", "detection_type", "duration", "evaluation_id", "feedback", "peak_confidence", "peak_time", "score", "status", "step_name", "step_number", "time_end", "time_start", "updated_at") values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15), ($16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30), ($31, $32, $33, $34, $35, $36, $37, $38, $39, $40, $41, $42, $43, $44, $45), ($46, $47, $48, $49, $50, $51, $52, $53, $54, $55, $56, $57, $58, $59, $60), ($61, $62, $63, $64, $65, $66, $67, $68, $69, $70, $71, $72, $73, $74, $75), ($76, $77, $78, $79, $80, $81, $82, $83, $84, $85, $86, $87, $88, $89, $90)
app     

172.18.0.7 -  27/Apr/2026:22:45:32 +0000 "POST /index.php" 500
nginx   

172.18.0.1 - - [27/Apr/2026:22:45:32 +0000] "POST /api/v1/evaluations HTTP/1.1" 500 1557 "-" "Dart/3.10 (dart:io)"