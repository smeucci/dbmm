import sys
import MySQLdb
import os



##############################
#### FUNCTION DEFINITIONS ####
##############################


def get_identities(status, DATA_DIR):
    db = MySQLdb.connect('127.0.0.1', 'root', pwd, 'collector')
    cursor = db.cursor()  
    
    identities_path = DATA_DIR + 'data/identities.txt'
    if os.path.exists(identities_path):
        os.remove(identities_path)
    
    try:
        if status == 'OK':
            cursor.execute("""
                SELECT id, name from identities
                WHERE status = %s or status = %s
            """, ('OK', 'DONE'))
        elif status == 'DONE':
            cursor.execute("""
                SELECT id, name from identities
                WHERE status = %s
            """, (status))
            
        data = cursor.fetchall()
        
        if data:
            for row in data:
                f = open(identities_path, 'ab')
                string = row[1] + '+' + row[0] + '\n'
                f.write(string)
                f.close()
                
            print 'Selected identities from db with status: ' + status
        else:
            print 'No identities selected with status: ' + status
    except:
        db.rollback()
        print 'Rollback: get_list'
        
    db.close()
        
        

########################
##### START SCRIPT #####
########################
        
        
if len(sys.argv) > 1:
    status = sys.argv[1].encode('utf-8')
    DATA_DIR = sys.argv[2].encode('utf-8')
else:
    status = 'OK'
    DATA_DIR='/media/saverio/DATA/'

pwd = 'pwd'
get_identities(status, DATA_DIR)    
    
        
        
        
        