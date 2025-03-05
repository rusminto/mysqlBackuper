# mysql backup
i use this script to scheduling my database backup.  
and this script only can be used at linux.  

To run this program, you need : 
- to execute `./mysql-backup.sh`
- edit file config.txt
- after that, run `./mysql-backup.sh` again

for my case, i use pm2 or systemd to run this script,  
to make sure that the program will be ressurect if something happen.  

## how it works
after you execute the `./mysql-backup.sh`, the program will :  
1. check which dumperTool that you select,
  there are only two options for this, that is `mydumper` and `mysqldump`
2. backup your database, based on your setting at config.txt
3. remove old backup, if it more than that defined at the setting
4. run the scheduler, if it time for backup, then run backup again  

## configuration
for the configuration (config.txt), i use `mydumper`'s config file format.  

if you want to use `mysqldump`, then for the simple configuration is :  
```
[main]
dumperTool = mysqldump

[mysqldump]
options = -uYOUR_USERNAME -pYOUR_PASSWORD --single-transaction --quick --lock-tables=false YOUR_DATABASE

[export]
location = ./tmp
retainFiles = 5
compress = true

[scheduler]
enable = true
backupTime = 23:59:59,04:00:00
```

some notes:  
- for `options` at `[mysqldump]`, i don't know if you want to use it with any other arguments,  
  so yeah, it's up to you
- for `compress` at `[export]`, i use xz
- for `backupTime`, you can have multiple points of time to schedule when the backup will be executed.  
  and the time is based on your system date & time configuration, so make sure check your `date` first.
- `[scheduler]` also can be disable, by set `enable = false`.  
  if you disable it, then the program will only run backup, remove old backup & exit.  
  you can combine it with other third-party program, like crontab.
- oh, and make sure to use the format like above, i still not test any other scenarios  
  but if you find any issue, just create the issue, i'll make sure to fix it

and, if you want to use `mydumper`, then the configuration will be :  
```
[main]
dumperTool = mydumper

[mydumper]
host = 127.0.0.1
user = root
password = p455w0rd
database = db
options =

[myloader]
host = 127.0.0.1
user = root
password = p455w0rd
database = new_db

[export]
location = ./tmp
retainFiles = 5
compress = true

[scheduler]
enable = true
backupTime = 23:59:59,04:00:00
```

some notes again:
- for `options` at `[mydumper]`, you can pass the arguments like at [mydumper docs](https://mydumper.github.io/mydumper/docs/html/mydumper_usage.html)
- for `[myloader]`, i still not create the program yet,
  but, if you want to restore the backup, you can follow [this example](https://mydumper.github.io/mydumper/docs/html/examples.html)
- and if you still doesn't have `mydumper` in your system, you can follow [this instructions](https://mydumper.github.io/mydumper/docs/html/installing.html)  

Good Luck!!!
