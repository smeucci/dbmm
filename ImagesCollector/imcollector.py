from bs4 import BeautifulSoup
import sys
import requests
import re
import urllib2
import os
import json
from time import time as timer
import Queue
from threading import Thread
import MySQLdb
import math


##########################
## FUNCTIONS DEFINITION ##
##########################


#class for the images
class Image:
    def __init__(self):
        self.href = None
        self.rank = None
        self.im_raw = None
        self.directory = None
        self.query = None
        self.label = None
        
    def set_url(self, href, rank):
        self.href = href
        self.rank = rank
    
    def set_im_raw(self, im_raw):
        self.im_raw = im_raw
        
    def dir_setup(self, directory, query, label):
        self.dir = directory 
        self.query = query
        self.label = label
        
        
#bing image search for a given identity
def bing_search(identity, label, num_of_imgs, DIR):
    search_engine = 'bing'
    print 'Used search engine: ' + search_engine
    
    identity = identity.replace('_', ' ')
    new_identity(identity, label, 'NULL')
    
    #create query
    print 'Identity: ' + identity
    query = identity
    query = query.split()
    query = '+'.join(query)
    
    #add the directory for your image here 
    DIR = (DIR + str(label) + '_' + query + '/').replace('+', '_')  
    if not os.path.exists(DIR):
        os.makedirs(DIR)
        print 'Created new directory: ' + DIR
    
    header = {'User-Agent': 'Mozilla/5.0'} 
    
    #start the time to compute the elapsed time for an identity
    start = timer()
    
    #fetch images url
    images = fetcher(query, num_of_imgs, header, search_engine)

    #start threading for download images given a list of href
    queue = Queue.Queue(maxsize=0)
    #Download_Worker(images, queue)
    print 'Finish downloading.'
    
    #build a list of dictionary with info about images to save on disk
    to_save = []
    while not queue.empty():
        im = queue.get()
        queue.task_done()
        if im.im_raw:
            im.dir_setup(DIR, query, label)
            to_save.append(im)
    
    if to_save:
        print 'Saving..'
        im_save(to_save)
        update_identity_status(identity, label, 'OK')
        print 'Donwload terminated for identity: ' + query.replace('+', ' ') + ' Number of images: ' \
            + str(len(to_save)) + ' - Elapsed time: ' + str((timer() - start))
    else: 
        update_identity_status(identity, label, 'ERR')
        print 'Donwload terminated for identity: ' + query.replace('+', ' ') + ' - Elapsed time: ' + str((timer() - start))       
    
    
#fetch the images url
def fetcher(query, num_of_imgs, header, search_engine):
    
    proxy_url = 'http://anonymouse.org/cgi-bin/anon-www.cgi/'
    
    images = []
    first, count = 1, 28
    num_of_rounds = int(math.ceil((num_of_imgs) / count)) + 1
    print num_of_rounds
    for idx in range(0, num_of_rounds):
        #create the query url       
        url = select_url(search_engine, query, first, count)                    
        try:
            #get html page for the query    
            data = get_html(proxy_url + url, header)
        except UnicodeEncodeError as e:
            print 'Reason: ' + e.reason
            data = get_html(proxy_url + url.encode('utf-8'), header)
        else:
            #retrieve the imgurls for the query by parsing the html page
            images.extend(parser(data, proxy_url, search_engine, count, idx))
                        
            print str(idx + 1) + ' - Number of fetched urls: ' + str(len(images))
            #donwload images for the query
            first = (28*(idx + 1)) + 1
            
    return images


#return the query url for the selected search engine
def select_url(search_engine, query, first, count):
    return {
            #url = 'http://www.bing.com/images/search?q='+query+'&first='+str(first)+'&count='+str(count)+'&qft=+filterui:imagesize-large';
           'bing': 'http://www.bing.com/images/search?q='+query+'&first='+str(first)+'&count='+str(count)+'&form=QBLH',
           'google': 'https://www.google.co.in/search?q='+query+'&source=lnms&tbm=isch',
    }[search_engine]


#download the html page
def get_html(url, header):
    return BeautifulSoup(urllib2.urlopen(urllib2.Request(url, headers=header)))


#parse the html from bing search
def parser_bing(data, proxy_url, count, idx):
    images = []
    rank = 1
    num = 0
    for div in data.find_all('div', class_='item'):
        for a in div.find_all('a', class_='thumb'):
            im_url = re.search('href=[\'"]?([^\'" >]+)', str(a))
            num = num + 1
            if im_url:
                im = Image()
                im_url = im_url.group(0).replace('href="', '').replace(proxy_url, '')
                im.set_url(im_url, rank + (count * idx))
                images.append(im)
                rank = rank + 1
    
    print str(idx + 1 ) + ' + ' + str(len(images)) + ' num: ' + str(num) + ' count: ' + str(count)    
    return images


#parse the html from the google search
def parser_google(data, proxy_url, query, count, idx):
    images = []
    print 'Not implemented'
    
    return images

def parser_flickr(data, proxy_url, query, count, idx):
    images = []
    
    return images

def parser_baidu(data, proxy_url, query, count, idx):
    images= []
    
    return images
    
#parser switch
def parser(data, proxy_url, search_engine, count, idx):
    switcher =  {
            'bing': parser_bing,
            'google': parser_google,
            'flickr' : parser_flickr,
    }
    func = switcher.get(search_engine)
    return func(data, proxy_url, count, idx)


#new download
def downloader(queue, im):
    header = {'User-Agent': 'Mozilla/5.0'} 
    im_raw = None
    try:
        request = urllib2.Request(im.href, headers=header)
        search = urllib2.urlopen(request, timeout=5)
        im_raw = search.read()           
    except:
        return None
    else:
        if len(im_raw) >= 50000:
            print 'Downloaded from: ' + im.href + ' - rank: ' + str(im.rank)
            im.set_im_raw(im_raw)
            queue.put(im)                   


#implement multithread for downloading images
def Download_Worker(images, queue):
    threads = []
    for image in images:
        t = Thread(target=downloader, args=(queue, image))
        threads.append(t)

    for t in threads:
        t.start()
            
    for t in threads:
        t.join()


#save images on disk
def im_save(images):
    #just for test
    if os.path.exists(images[0].dir + str(images[0].label) + '_paths.txt'):
        os.remove(images[0].dir + str(images[0].label) + '_paths.txt')

    for image in images:
        f = open(image.dir + str(image.rank) + '.jpg', 'wb')
        f.write(image.im_raw)
        f.close()
        #save img path to txt
        im_paths = open(image.dir + str(images[0].label) + '_paths.txt', 'ab')
        im_paths.write('img/' + str(image.label) + '_' + image.query.replace('+', '_') + '/' + 
                       str(image.rank) + '.jpg-' + image.query.replace('+', '_') + '-' + str(image.rank) + '\n')
        im_paths.close()
        print 'Saved: ' + image.dir + str(image.rank) + '.jpg'
        

#save identity to db
def new_identity(identity, label, status):    
    db = MySQLdb.connect('127.0.0.1', 'root', 'pwd', 'collector')
    cursor = db.cursor()  
    try:
        cursor.execute("""
            INSERT INTO identities (id, name, status) 
            VALUES (%s, %s, %s)
        """, (str(label), identity, status))       
        db.commit()
        print 'Save to db: ' + identity
    except:
        db.rollback()
        print 'Rollback.'
    
    db.close()
    
    
#update identity status
def update_identity_status(identity, label, status):  
    db = MySQLdb.connect('127.0.0.1', 'root', 'pwd', 'collector')
    cursor = db.cursor()                   
    try:
        cursor.execute("""
            UPDATE identities SET status = %s 
            WHERE id = %s && name = %s
        """, (status, str(label), identity))       
        db.commit()
        print 'Update status for: ' + identity + ' - ' + status
    except:
        db.rollback()
        print 'Rollback.'
    
    db.close()
                    
                    
##################
## SCRIPT START ##
##################


#if statement just for testing
if len(sys.argv) > 1:
    identity = sys.argv[1].encode('utf-8')
    label = sys.argv[2].encode('utf-8')
    DIR = sys.argv[3].encode('utf-8')
    num_of_imgs = int(sys.argv[4])
else:
    identity = 'Leo Messi'
    label = 1
    DIR='/media/saverio/DATA/img/'
    num_of_imgs = 850

#Bing Search
#bing_search(identity, label, num_of_imgs, DIR)

#url = 'http://www.bing.com/images/search?q=Leo+Messi&first='+str(309)+'&count='+str(28)
#url = 'http://image.baidu.com/search/index?tn=baiduimage&word=george%20clooney&pn=1'
url = 'http://anonymouse.org/cgi-bin/anon-www.cgi/http://images.search.yahoo.com/search/images?p=a.j.buckley'
#url = 'https://duckduckgo.com/i.js?q=a.j.+buckley'
#url = 'http://www.freebase.com/celebrities/celebrity?instances='
header = {'User-Agent': 'Mozilla/5.0'} 
data = get_html(url, header)
print data
