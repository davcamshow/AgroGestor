import sqlite3
conn = sqlite3.connect('C:\\Users\\Administrador\\AgroGestor\\backend\\db.sqlite3')
cursor = conn.execute("SELECT name FROM sqlite_master WHERE type='table'")
tables = [row[0] for row in cursor.fetchall()]
print('Tables:', tables)
conn.close()
