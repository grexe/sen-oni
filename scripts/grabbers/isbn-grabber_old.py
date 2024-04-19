#!/usr/bin/env python3.10
import requests
import shutil
import subprocess
import sys
import tempfile
import time
from isbnlib import *
from os import fsync
from pathlib import Path

isbn = sys.argv[1]

print("ISBN Metadata:")
meta=meta(isbn)
print(meta)

print("Classification:")
print((classify(isbn)))

print("DOI:")
print((doi(isbn)))

thumbnail_url = cover(isbn)['thumbnail']
print("Downloading cover from URL: %s..." % thumbnail_url)
response = requests.get(thumbnail_url)
cover = response.content

# write cover image data to temp file, since passing them in directly to subprocess.call doesn't work
cover_file = tempfile.NamedTemporaryFile(prefix="cover-", suffix="jpg", delete=True)
cover_file.write(cover)

# make sure the data is fully written to disk, since we access the file right below
cover_file.flush()
fsync(cover_file)

file_name = meta['Title'].replace("'", "").replace('"', '')
print("Creating/Updating file %s" % file_name)
temp_file = tempfile.NamedTemporaryFile(prefix="book-", delete=False)  # will be moved to destination later
temp_name = temp_file.name

# set filetype
subprocess.call(["addattr", "-t", "mime", "BEOS:TYPE", "application/x-vnd.sen-book", temp_name])

# add book metadata to fs attributes
subprocess.call(["addattr", "isbn", meta['ISBN-13'], temp_name])  # take validated current ISBN-13 from lookup!
subprocess.call(["addattr", "authors", ','.join(meta['Authors']), temp_name])
subprocess.call(["addattr", "language", meta['Language'], temp_name])
subprocess.call(["addattr", "publisher", meta['Publisher'], temp_name])
subprocess.call(["addattr", "-t", "int", "year", meta['Year'], temp_name])

# write thumbnail with cover image
subprocess.call(["addattr", "-f", cover_file.name, "-t", "raw", "Media:Thumbnail", temp_name])

# update time stamp with +1min so Thumbnail is newer than the book file (which is still modified below), 
# so it will be accepted as up to date and used by Tracker (else, thumbnail attributes woud be removed as outdated!)
subprocess.call(["addattr", "-t", "time", "Media:Thumbnail:CreationTime", str(int(time.time()) + 300), temp_name])

# debug
subprocess.call(["listattr", "-l", temp_name])

# finally move file to destination, so Tracker does not update it before its time
shutil.move(temp_name, Path(Path.cwd(), file_name))

""" 
works only on Linux so far

os.setxattr(file_name, 'user.isbn', isbn)
os.setxattr(file_name, 'user.authors', meta['Authors'])
os.setxattr(file_name, 'user.language', meta['Language'])
os.setxattr(file_name, 'user.publisher', meta['Publisher'])
"""
