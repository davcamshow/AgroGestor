import sqlite3
conn = sqlite3.connect('C:\\Users\\Administrador\\AgroGestor\\backend\\db.sqlite3')
cursor = conn.execute("SELECT * FROM django_migrations WHERE app='api' AND name LIKE '0014%'")
rows = cursor.fetchall()
if not rows:
    conn.execute("INSERT INTO django_migrations (app, name, applied) VALUES ('api', '0014_fix_missing_tables_and_columns', datetime('now'))")
    conn.commit()
    print('Fake-applied 0014_fix_missing_tables_and_columns')
else:
    print('Already applied:', rows)
conn.close()
