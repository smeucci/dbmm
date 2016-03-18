from bs4 import BeautifulSoup
import sys
import re
import urllib2
import Queue
import MySQLdb
import math
import json
from time import time as timer
from threading import Thread



#############################
##### CLASS DEFINITIONS #####
#############################

#class for the images
class Image:
    def __init__(self):
        self.id = None
        self.label = None
        self.identity = None
        self.url = None
        self.rank = None
        self.engine = None
        
    def set_attr(self, identifier, label, identity, url, rank, engine):
        self.id = identifier
        self.label = label
        self.identity = identity
        self.url = url
        self.rank = rank
        self.engine = engine



###############################
#### FUNCTION DEFINITIONS #####
###############################

#given an identity (name and label) search for images and save them to db
def search(identity, num_of_imgs):
    
    start = timer()
    
    #inizialize the queue for multithreading
    queue = Queue.Queue(maxsize=0)
    
    #create query
    query = identity['name'].replace('_', ' ')
    query = query.split()
    query = '+'.join(query)
    
    #build a dictionary with search info
    data = {
            'query': query,
            'label': identity['label'],
            'num_of_imgs': num_of_imgs,
            'header': {'User-Agent': 'Mozilla/5.0'} 
    }
    
    #start threads
    threads = []
    bing_search = Thread(target=fetcher, args=(queue, 'bing', data))
    aol_search_1 = Thread(target=fetcher, args=(queue, 'aol1', data))
    aol_search_2 = Thread(target=fetcher, args=(queue, 'aol2', data))
    #duck_search = Thread(target=fetcher, args=(queue, 'duck', data))
    yahoo_search = Thread(target=fetcher, args=(queue, 'yahoo', data))
    threads.append(bing_search)
    threads.append(aol_search_1)
    threads.append(aol_search_2)
    #threads.append(duck_search)
    threads.append(yahoo_search)
    
    for t in threads:
        t.start()
    
    for t in threads:
        t.join()
    
    #if queue is not empty, save urls to db (status = OK), else end script (STATUS = ERR_F)
    if not queue.empty():
        queue_size = queue.qsize()
        insert_urls(queue, identity, queue_size)
        print 'Donwload terminated for identity: ' + identity['name'] + ' - Number of images: ' \
            + str(queue_size) + ' - Elapsed time: ' + str((timer() - start))
    else:
        update_identity_status(identity, 'ERR_F')
        print 'Donwload terminated for identity: ' + identity['name'] + ' - Elapsed time: ' + str((timer() - start))     
        

#FETCHER: choose which search engine to use
def fetcher(queue, search_engine, data):
    switcher =  {
            'bing': fetcher_bing,
            'aol1': fetcher_aol_1,
            'aol2': fetcher_aol_2,
            'duck': fetcher_duck,
            'yahoo': fetcher_yahoo
    }
    func = switcher.get(search_engine)
    return func(queue, search_engine, data)


#fetcher the images for a given query from bing
def fetcher_bing(queue, search_engine, data):
    #the proxy to use
    proxy_url = 'http://anonymouse.org/cgi-bin/anon-www.cgi/'
    
    first, count = 1, 28
    rounds = int(math.ceil((data['num_of_imgs']) / count)) + 1
    num = 1000 #needs to be bigger than count
    for rnd in range(0, rounds):
        #check if imgurls returned in previous iteration are not too low; that means angry search engine
        if (num > 10):
            #create the query url       
            url = 'http://www.bing.com/images/search?q='+data['query']+'&first='+str(first)+'&count='+str(count)
                                
            #get html page for the query    
            html = get_html(proxy_url + url.encode('utf-8'), data['header'])
            
            #retrieve the imgurls for the query by parsing the html page
            info = {
                'first': first,
                'count': count,
                'round': rnd,
                'proxy': proxy_url,
                'query': data['query'],
                'label': data['label'],
                'engine': search_engine
            }
            num = parser(html, info, queue)
                        
            first = (count*(rnd + 1)) + 1
    
    
#fetcher the images for a given query from aol, first half
def fetcher_aol_1(queue, search_engine, data):
    #the proxy to use
    proxy_url = 'http://anonymouse.org/cgi-bin/anon-www.cgi/'
    
    count = 20
    rounds = int(math.ceil((data['num_of_imgs']) / count)) + 1
    second_half = int(math.ceil(rounds / 2))
    num = 1000 #needs to be bigger than count
    for rnd in range(0, second_half):
        #check if imgurls returned in previous iteration are not too low; that means angry search engine
        if (num > 10):
            #create the query url       
            url = 'http://search.aol.com/aol/image?q='+data['query']+'&page='+str(rnd+1)
                                
            #get html page for the query    
            html = get_html(proxy_url + url.encode('utf-8'), data['header'])
            
            #retrieve the imgurls for the query by parsing the html page
            info = {
                'count': count,
                'round': rnd,
                'proxy': proxy_url,
                'query': data['query'],
                'label': data['label'],
                'engine': 'aol'
            }
            num = parser(html, info, queue)
        

#fetcher the images for a given query from aol, second half
def fetcher_aol_2(queue, search_engine, data):
    #the proxy to use
    proxy_url = 'http://anonymouse.org/cgi-bin/anon-www.cgi/'
    
    count = 20
    rounds = int(math.ceil((data['num_of_imgs']) / count)) + 1
    second_half = int(math.ceil(rounds / 2))
    num = 1000 #needs to be bigger than count
    for rnd in range(second_half, rounds):
        #check if imgurls returned in previous iteration are not too low; that means angry search engine
        if (num > 10):
            #create the query url       
            url = 'http://search.aol.com/aol/image?q='+data['query']+'&page='+str(rnd+1)
                                
            #get html page for the query    
            html = get_html(proxy_url + url.encode('utf-8'), data['header'])
            
            #retrieve the imgurls for the query by parsing the html page
            info = {
                'count': count,
                'round': rnd,
                'proxy': proxy_url,
                'query': data['query'],
                'label': data['label'],
                'engine': 'aol'
            }
            num = parser(html, info, queue)


def fetcher_duck(queue, search_engine, data):
    #the proxy to use
    proxy_url = 'http://fresh-proxy.appspot.com/'
    
    count = 35
    rounds = int(math.ceil((data['num_of_imgs']) / count)) + 1
    
    num = 1000 #needs to be bigger than count
    for rnd in range(0, rounds):
        #check if imgurls returned in previous iteration are not too low; that means angry search engine
        if (num > 10):
            #create the query url       
            url = proxy_url + 'duckduckgo.com/i.js?q='+data['query']+'&s='+str(rnd)
                                
            #get html page for the query    
            html = get_html(url.encode('utf-8'), data['header'])
            
            #retrieve the imgurls for the query by parsing the html page
            info = {
                'count': count,
                'round': rnd,
                'proxy': proxy_url,
                'query': data['query'],
                'label': data['label'],
                'engine': search_engine
            }
            num = parser(html, info, queue)

    
def fetcher_yahoo(queue, search_engine, data):
    #the proxy to use
    proxy_url = 'http://fresh-proxy.appspot.com/'
    
    first, count = 1, 40
    rounds = int(math.ceil((data['num_of_imgs']) / count)) + 1
    num = 1000 #needs to be bigger than count
    for rnd in range(0, rounds):
        #check if imgurls returned in previous iteration are not too low; that means angry search engine
        if (num > 10):
            #create the query url       
            url = 'images.search.yahoo.com/search/images?p='+data['query']+'&b='+str(first)
                                
            #get html page for the query    
            html = get_html(proxy_url + url.encode('utf-8'), data['header'])
            
            #retrieve the imgurls for the query by parsing the html page
            info = {
                'first': first,
                'count': count,
                'round': rnd,
                'proxy': proxy_url,
                'query': data['query'],
                'label': data['label'],
                'engine': search_engine
            }
            num = parser(html, info, queue)
                        
            first = (count*(rnd + 1)) + 1
    

#PARSER: select the parser based on the search engine to use
def parser(html, info, queue):
    switcher =  {
            'bing': parser_bing,
            'aol': parser_aol,
            'duck': parser_duck,
            'yahoo': parser_yahoo
    }
    func = switcher.get(info['engine'])
    return func(html, info, queue)


#parse the data from a html response from bing 
def parser_bing(html, info, queue):
    #rank base of the current round
    rank = (info['count'] * info['round']) + 1
    num = 0
    #for div in html.find_all('div', class_='item'):
    for a in html.find_all('a', class_='thumb'):
        imgurl = re.search('href=[\'"]?([^\'" >]+)', str(a))
        if imgurl:
            #inizialize object of class Image
            img = Image()
            #parse the url
            url = imgurl.group(0).replace('href="', '').replace(info['proxy'], '')
            #compute the rank of the image
            img_rank = rank
            #build a unique id for the image
            img_id = info['engine'] + str(img_rank) + '_' + info['label']
            #set attributes of the object
            img.set_attr(img_id, info['label'], info['query'].replace('+', '_'), url, img_rank , info['engine'])
            #put into queue
            queue.put(img)
            #update rank
            rank = rank + 1
            num = num + 1 #info, just for testing
    
    print info['query'].replace('+', '_') + ' - Number of fetched urls by bing: ' + str(queue.qsize()) + \
                                             ' - num: ' + str(num)
    return num

#parse the data from a html response from baidu
def parser_aol(html, info, queue):
    rank = (info['count'] * info['round']) + 1
    num = 0
    for p in html.find_all('p', {'property': 'f:url'}):
        imgurl = re.search('http[\'"]?([^\'" <>]+)', str(p))
        if imgurl:
            #inizialize object of class Image
            img = Image()
            #parse the url
            url = imgurl.group(0)
            #compute the rank of the image
            img_rank = rank
            #build a unique id for the image
            img_id = info['engine'] + str(img_rank) + '_' + info['label']
            #set attributes of the object
            img.set_attr(img_id, info['label'], info['query'].replace('+', '_'), url, img_rank , info['engine'])
            #put into queue
            queue.put(img)
            #update rank
            rank = rank + 1
            num = num + 1 #info, just for testing
                
    print info['query'].replace('+', '_') + ' - Number of fetched urls by aol: ' + str(queue.qsize()) + \
                                             ' - num: ' + str(num)
    return num

def parser_duck(html, info, queue):
    rank = (info['count'] * info['round']) + 1
    num = 0
    #parser the html
    imgurls = re.findall('image":[\'"]?([^\'" <>]+)', str(html))
    for imgurl in imgurls:
        if imgurl:
            #inizialize object of class Image
            img = Image()
            #parse the url
            url = imgurl
            #compute the rank of the image
            img_rank = rank
            #build a unique id for the image
            img_id = info['engine'] + str(img_rank) + '_' + info['label']
            #set attributes of the object
            img.set_attr(img_id, info['label'], info['query'].replace('+', '_'), url, img_rank , info['engine'])
            #put into queue
            queue.put(img)
            #update rank
            rank = rank + 1
            num = num + 1 #info, just for testing
    
                
    print info['query'].replace('+', '_') + ' - Number of fetched urls by duckduckgo: ' + str(queue.qsize()) + \
                                             ' - num: ' + str(num)
    return num              
        
                                  
def parser_yahoo(html, info, queue):
    rank = (info['count'] * info['round']) + 1
    num = 0
    #parser the html
    imgurls = re.findall('iurl":[\'"]?([^\'" <>]+)', str(html))
    for imgurl in imgurls:
        if imgurl:
            #inizialize object of class Image
            img = Image()
            #parse the url
            url = imgurl.replace('\/', '/')
            #compute the rank of the image
            img_rank = queue.qsize()
            #build a unique id for the image
            img_id = info['engine'] + str(img_rank) + '_' + info['label']
            #set attributes of the object
            img.set_attr(img_id, info['label'], info['query'].replace('+', '_'), url, img_rank , info['engine'])
            #put into queue
            queue.put(img)
            #update rank
            rank = rank + 1
            num = num + 1 #info, just for testing
            
    print info['query'].replace('+', '_') + ' - Number of fetched urls by yahoo: ' + str(queue.qsize()) + \
                                             ' - num: ' + str(num)
    return num

     
#get the html page for a given url
def get_html(url, header):
    return BeautifulSoup(urllib2.urlopen(urllib2.Request(url, headers=header)))


## DB FUNCTIONS ##

#insert a new identity in the db
def insert_identity(identity):    
    db = MySQLdb.connect('127.0.0.1', 'root', pwd, 'collector')
    cursor = db.cursor()  
    rollback = False
    try:
        cursor.execute("""
            INSERT INTO identities (id, name) 
            VALUES (%s, %s)
        """, (identity['label'], identity['name']))       
        db.commit()
        print 'Save to db: ' + identity['name']
    except:
        db.rollback()
        rollback = True
        
    db.close()
    if rollback == True:
        print 'Rollback: new_identity'
    
    
#update identity status
def update_identity_status(identity, status):  
    db = MySQLdb.connect('127.0.0.1', 'root', pwd, 'collector')
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
        

#update number of urls fetched for an identity
def update_identity_urls(identity, queue_size):
    db = MySQLdb.connect('127.0.0.1', 'root', pwd, 'collector')
    cursor = db.cursor() 
    rollback = False
                      
    try:
        cursor.execute("""
            UPDATE identities SET urls = %s 
            WHERE id = %s && name = %s
        """, (queue_size, identity['label'], identity['name']))       
        db.commit()
        print 'Number of urls fetched for ' + identity['name'] + ' : ' + str(queue_size)
    except:
        db.rollback()
        rollback = True
        
    db.close()
    if rollback == True:
        print 'Rollback: update_identity_status'


#save info (url, etc..) of an image to db
def insert_urls(queue, identity, queue_size):
    print identity['name'] + ' - Saving to db..'
    db = MySQLdb.connect('127.0.0.1', 'root', pwd, 'collector')
    cursor = db.cursor()
    rollback = False
    
    images = []
    while not queue.empty():
        img = queue.get()
        queue.task_done()
        im = (img.id, img.label, img.identity, img.url, img.rank, img.engine)
        images.append(im)
        
    try:
        cursor.executemany("""
            INSERT INTO urls (id, label, identity, url, rank, engine) 
            VALUES (%s, %s, %s, %s, %s, %s)
        """, images)
            
        db.commit()
    except:
        db.rollback()
        rollback = True
    
    db.close()
    if rollback == True:
        print 'Rollback: save_url_to_db'
        update_identity_status(identity, 'ERR_F')
    else:
        update_identity_status(identity, 'OK')
        update_identity_urls(identity, queue_size)
        


########################
##### START SCRIPT #####
########################

if len(sys.argv) > 1:
    identity = {
            'name': sys.argv[1].encode('utf-8'),
            'label': sys.argv[2].encode('utf-8')
    }
    num_of_imgs = int(sys.argv[3])

    pwd = 'pwd'
    insert_identity(identity)
    print 'Identity: ' + identity['name']
    search(identity, num_of_imgs)
    
else:
    print 'No parameters were passed.'
  
        


        
        