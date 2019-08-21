Overlib
-------
```
wget https://github.com/overlib/overlib/archive/4.21.tar.gz
tar xvf 4.21.tar.gz
mv overlib-4.21/overlib.js .
rm -rf *4.21*
```

Font-awesome
------------
```
faversion="5.10.1"
wget https://use.fontawesome.com/releases/v5.10.1/fontawesome-free-${faversion}-web.zip
unzip fontawesome-free-${faversion}-web.zip
rm fontawesome-free-${faversion}-web.zip
ln -s fontawesome-free-${faversion}-web fontawesome
```
