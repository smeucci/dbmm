import MySQLdb



##############################
#### FUNCTION DEFINITIONS ####
##############################


def create():
    create_db_collector()
    create_db_dataset()


def inizialize():
    inizialize_db_collector()
    inizialize_db_dataset()
    

def create_db_collector():
    db = MySQLdb.connect(location, user, pwd)
    cursor= db.cursor()
    
    try:
        cursor.execute("CREATE DATABASE IF NOT EXISTS " + collector)
        db.commit()
    except:
        print 'Database "' + collector + '" NOT created.'


def create_db_dataset():
    db = MySQLdb.connect(location, user, pwd)
    cursor= db.cursor()
    
    try:
        cursor.execute("CREATE DATABASE IF NOT EXISTS " + dataset)
        db.commit()
    except:
        print 'Database "' + dataset + '" NOT created.'


def inizialize_db_collector():
    db = MySQLdb.connect(location, user, pwd, collector)
    cursor = db.cursor()
    
    try:
        cursor.execute(""" SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO"; """)
        cursor.execute(""" SET time_zone = "+00:00"; """)
        
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS `identities` (
          `id` varchar(50) NOT NULL,
          `name` varchar(100) NOT NULL,
          `status` varchar(20) DEFAULT NULL,
          `urls` int(11) DEFAULT NULL,
          `images` int(11) DEFAULT NULL,
          PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
        """)
        
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS `urls` (
          `id` varchar(50) NOT NULL,
          `label` varchar(50) NOT NULL,
          `identity` varchar(50) NOT NULL,
          `url` varchar(2000) NOT NULL,
          `rank` int(11) NOT NULL,
          `engine` varchar(50) NOT NULL,
          PRIMARY KEY (`id`),
          KEY `label` (`label`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
        """)
        
        cursor.execute("""
        ALTER TABLE `urls`
            ADD CONSTRAINT `identities_fk_urls` FOREIGN KEY (`label`) REFERENCES `identities` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
        """)
        
        db.commit()
        
    except:
        print 'Database "' + collector + '" NOT initialized or ALREADY initialized.'


def inizialize_db_dataset():
    db = MySQLdb.connect(location, user, pwd, dataset)
    cursor = db.cursor()
    
    try:
        cursor.execute(""" SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO"; """)
        cursor.execute(""" SET time_zone = "+00:00"; """)
        
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS `identities` (
          `label` varchar(50) NOT NULL,
          `name` varchar(100) NOT NULL,
          `num_images` int(11) DEFAULT NULL,
          `remove` int(11) DEFAULT NULL,
          PRIMARY KEY (`label`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
        """)
        
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS `images` (
          `id` int(11) NOT NULL AUTO_INCREMENT,
          `image` varchar(100) NOT NULL,
          `identity` varchar(50) NOT NULL,
          `box` varchar(50) NOT NULL,
          `predicted` int(11) NOT NULL,
          `validation` int(11) DEFAULT NULL,
          PRIMARY KEY (`id`),
          KEY `identity` (`identity`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;
        """)
        
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS `images_crop` (
          `id` int(11) NOT NULL AUTO_INCREMENT,
          `image` varchar(100) NOT NULL,
          `old_image` varchar(100) NOT NULL,
          `identity` varchar(50) NOT NULL,
          `box` varchar(50) NOT NULL,
          `predicted` int(11) NOT NULL,
          `validation` int(11) DEFAULT NULL,
          PRIMARY KEY (`id`),
          KEY `identity` (`identity`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;
        """)
        
        cursor.execute("""
        ALTER TABLE `images`
            ADD CONSTRAINT `identity_fk_label` FOREIGN KEY (`identity`) REFERENCES `identities` (`label`) ON DELETE CASCADE ON UPDATE CASCADE;
        """)
        
        cursor.execute("""
        ALTER TABLE `images_crop`
            ADD CONSTRAINT `identity_fk_label_crop` FOREIGN KEY (`identity`) REFERENCES `identities` (`label`) ON DELETE CASCADE ON UPDATE CASCADE;
        """)
        
        db.commit()
        
    except:
        print 'Database "' + dataset + '" NOT initialized or ALREADY initialized.'

#read configuration file
def readconf(fn):
    ret = {}
    with file(fn) as fp:
        for line in fp:
            # Assume whitespace is ignorable
            line = line.strip()
            if not line or line.startswith('#'): continue
 
            boolval = True
            # Assume leading ";" means a false boolean
            if line.startswith(';'):
                # Remove one or more leading semicolons
                line = line.lstrip(';')
                # If more than just one word, not a valid boolean
                if len(line.split()) != 1: continue
                boolval = False
 
            bits = line.split(None, 1)
            if len(bits) == 1:
                # Assume booleans are just one standalone word
                k = bits[0]
                v = boolval
            else:
                # Assume more than one word is a string value
                k, v = bits
            ret[k.lower()] = v
            
    return ret


########################
##### START SCRIPT #####
########################

        
conf = readconf('config/config.conf')

location = conf['db_location']
collector = conf['database_collector']
dataset = conf['database_dataset']
user = conf['db_user']
pwd = conf['db_pwd']


print 'Initializing databases..'
create()
inizialize()




