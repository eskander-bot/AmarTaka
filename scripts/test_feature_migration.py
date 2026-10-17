"""Execute the real v4 SQL migration on an existing v3 SQLite database."""
from pathlib import Path
import re, sqlite3, unittest
ROOT=Path(__file__).resolve().parents[1]
class FeatureMigrationTest(unittest.TestCase):
    def test_migration_preserves_records_and_defaults(self):
        source=(ROOT/'source/lib/database/db_helper.dart').read_text()
        body=source.split('static Future<void> _features')[1].split('static Future<void> _finance')[0]
        statements=[m.group(2) for m in re.finditer(r'await d.execute\(([\'\"])(.*?)\1\);',body,re.S)]
        self.assertEqual(len(statements),9)
        db=sqlite3.connect(':memory:')
        db.execute('CREATE TABLE transactions(id INTEGER PRIMARY KEY,amount_minor INTEGER,category TEXT,note TEXT,date TEXT,type TEXT)')
        db.execute('CREATE TABLE goals(id INTEGER PRIMARY KEY,title TEXT,target_minor INTEGER,saved_minor INTEGER,note TEXT)')
        db.execute('INSERT INTO transactions VALUES(42,12550,"Bazar","keep","2026-01-01T00:00:00.000","expense")')
        db.execute('INSERT INTO goals VALUES(7,"Laptop",100000,20000,"keep")')
        for statement in statements:db.execute(statement)
        self.assertEqual(db.execute('SELECT id,amount_minor,account_id,receipt FROM transactions').fetchone(),(42,12550,None,''))
        self.assertEqual(db.execute('SELECT id,saved_minor,deadline,plan_start,plan_saved FROM goals').fetchone(),(7,20000,'','',0))
        for table in ['recurring','quick_entries','loan_payments']:self.assertEqual(db.execute(f'SELECT COUNT(*) FROM {table}').fetchone(),(0,))
        db.close()
if __name__=='__main__':unittest.main()
