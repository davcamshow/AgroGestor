import sqlite3
conn = sqlite3.connect('C:\\Users\\Administrador\\AgroGestor\\backend\\db.sqlite3')
cursor = conn.execute("SELECT name FROM django_migrations WHERE app='api' ORDER BY id")
print('Applied migrations:')
for r in cursor.fetchall():
    print(' ', r[0])
conn.close()
