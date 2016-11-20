#!/bin/bash

cat >'/var/www/html/index.html' <<'END'
<!DOCTYPE html>
<html>
   <head>
      <title>Welcome</title>
      <style>
         body {
            width: 35em;
            margin: 0 auto;
            font-family: Tahoma, Verdana, Arial, sans-serif;
         }
      </style>
   </head>
   <body>
      <h1>Welcome</h1>
      <p>You are the welcome</p>
   </body>
</html>
END
