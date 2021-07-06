## mysql backup

To run this program, you need : 
- mkdir dumps
- chmod 777 my
- chmod 777 run
- chmod 664 cred
- crontab -e : 0 18 * * * /home/admindb/backup/run --> to run it on 01:00 AM in GMT + 7
