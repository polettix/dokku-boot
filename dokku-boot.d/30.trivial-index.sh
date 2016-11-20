#!/bin/bash

cat >'/var/www/html/index.html' <<'END'
<!DOCTYPE html>
<html>
   <head>
      <title>Black</title>
      <style>body { background-color: black } </style>
   </head>
   <body></body>
</html>
END
