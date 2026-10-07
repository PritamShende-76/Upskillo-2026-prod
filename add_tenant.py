import pymysql

conn = pymysql.connect(
    host='upskillo-staging-env-mysql.cukwnuzu8fg8.ap-south-1.rds.amazonaws.com',
    user='upskilloadmin',
    password='StagingUpskillo2026Secure',
    database='upskillo_staging',
    port=3306
)
cursor = conn.cursor()

# Check existing tenants
cursor.execute('SELECT * FROM tenants')
tenants = cursor.fetchall()
print('Existing Tenants:', tenants)

# Add opcito.com tenant if not exists
if not any('opcito.com' in str(t) for t in tenants):
    cursor.execute("INSERT INTO tenants (name, domain) VALUES ('Opcito', 'opcito.com')")
    conn.commit()
    print('Tenant opcito.com added successfully!')
else:
    print('Tenant opcito.com already exists')

conn.close()
