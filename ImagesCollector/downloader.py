from bs4 import BeautifulSoup
import sys
import re
import urllib2
import Queue
import MySQLdb
import math
import os
from time import time as timer
from threading import Thread



###############################
####   CLASS DEFINITIONS   ####
###############################

class Image:
    def __init__(self):
        self.id = None
        self.label = None
        self.identity = None
        self.url = None
        self.rank = None
        self.engine = None
        self.raw = None
        
    def set_attr(self, identifier, label, identity, url, rank, engine):
        self.id = identifier
        self.label = label
        self.identity = identity
        self.url = url
        self.rank = rank
        self.engine = engine

    def set_raw(self, raw):
        self.raw = raw



##############################
#### FUNCTION DEFINITIONS ####
##############################



def downloader(identity):
    
    start = timer()
    #take image urls for an identity from db
    images = select_urls(identity)
    
    #start multithreading
    queue = Queue.Queue(maxsize=0)
    download_master(images, queue)
    
    print 'Finish donwloading images for identity: ' + identity['name']
    
    #if queue is not empty, save images to disk (status = DONE), else end script (STATUS = ERR_D)
    if not queue.empty():
        queue_size = queue.qsize()
        print identity['name'] + ' - Saving..'
        save(queue)
        print 'Donwload terminated for identity: ' + identity['name'] + ' Number of images saved: ' \
            + str(queue_size) + ' - Elapsed time: ' + str((timer() - start))
    else: 
        update_identity_status(identity, 'ERR_D')
        print 'Donwload failed for identity: ' + identity['name'] + ' - Elapsed time: ' + str((timer() - start))  
    

#start the threads
def download_master(images, queue):
    threads = []
    for image in images:
        t = Thread(target=download_slave, args=(queue, image))
        threads.append(t)

    for t in threads:
        t.start()
            
    for t in threads:
        t.join()
        

def download_slave(queue, image):
    header = {'User-Agent': 'Mozilla/5.0'} 
    raw = None
    try:
        request = urllib2.Request(image.href, headers=header)
        search = urllib2.urlopen(request, timeout=5)
        raw = search.read()           
    except:
        return None
    else:
        if len(raw) >= 50000:
            print 'Downloaded from: ' + image.href + ' - rank: ' + str(image.rank)
            image.set_raw(raw)
            queue.put(image)       
    
    

def save(queue, identity, DATA_DIR):
    #create folder for identity    
    identity_dir = DATA_DIR + 'img/' +  identity['label'] + '_' + identity['name'] + '/'
    if not os.path.exists(identity_dir):
        os.makedirs(identity_dir)
        print 'Created new directory: ' + identity_dir
    #remove old (if any) file of image paths
    file_paths = identity_dir + identity['label'] + '_paths.txt'
    if os.path.exists(file_paths):
        os.remove(file_paths)
    #extract list of images from queue
    images = []
    while not queue.empty():
        image = queue.get()
        queue.task_done()
        if image.raw:
            images.append(image)
    #save each image to disk
    if images:
        for image in images:
            #create folder images retrieve from a certain search engine
            images_dir = identity_dir + image.engine + '/'
            if not os.path.exists(identity_dir):
                os.makedirs(identity_dir)
            #save image
            image_dir = images_dir + str(image.rank) + '.jpg'
            f = open(image_dir, 'wb')
            f.write(image.raw)
            f.close()
            #save image path to txt file
            paths = open(identity_dir + identity['label'] + '_paths.txt', 'ab')
            paths.write(image_dir.repr(DATA_DIR, '') + '+' + identity['label'] + '+' + identity['name'] + '+' + image.engine + '+' + image.rank)
            paths.close()
            print 'Saved: ' + image_dir
    
        update_identity_images(identity, len(images))
        update_identity_status(identity, 'DONE')
    else:
        update_identity_status(identity, 'ERR_D')
        
        
## DB FUNCTIONS ##

#select urls from db for a given identity, returns a list of object of class Image
def select_urls(identity):
    db = MySQLdb.connect('127.0.0.1', 'root', 'pwd', 'collector')
    cursor = db.cursor()  
    rollback = False
    images = []
    try:
        cursor.execute("""
            SELEC * from identities
            WHERE label = %s && identity = %s
        """, (identity['label'], identity['name']))       
        data = cursor.fetchall()
        
        for row in data:
            image = Image()
            image.set_attr(row[0], row[1], row[2], row[3], row[4], row[5])
            images.append(image)
            
        print 'Selected images from db: ' + identity['name']
    except:
        db.rollback()
        rollback = True
        
    db.close()
    if rollback == True:
        print 'Rollback: select_urls'
     
#update number of images downloaded for an identity
def update_identity_images(identity, queue_size):
    db = MySQLdb.connect('127.0.0.1', 'root', 'pwd', 'collector')
    cursor = db.cursor() 
    rollback = False
                      
    try:
        cursor.execute("""
            UPDATE identities SET images = %s 
            WHERE id = %s && name = %s
        """, (queue_size, identity['label'], identity['name']))       
        db.commit()
        print 'Number of images downloaded for ' + identity['name'] + ' : ' + str(queue_size)
    except:
        db.rollback()
        rollback = True
        
    db.close()
    if rollback == True:
        print 'Rollback: update_identity_images'


#update status for an identity
def update_identity_status(identity, status):
    db = MySQLdb.connect('127.0.0.1', 'root', 'pwd', 'collector')
    cursor = db.cursor() 
    rollback = False
                      
    try:
        cursor.execute("""
            UPDATE identities SET status = %s 
            WHERE id = %s && name = %s
        """, (status, identity['label'], identity['name']))       
        db.commit()
        print 'Status for ' + identity['name'] + ' : ' + status
    except:
        db.rollback()
        rollback = True
        
    db.close()
    if rollback == True:
        print 'Rollback: update_identity_status'
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    