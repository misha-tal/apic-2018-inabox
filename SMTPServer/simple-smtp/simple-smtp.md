docker run -p 25:25 -e maildomain=yourdomain.com -e smtp_user=webmaster:secretpassword --name postfix -d catatnight/postfix

services:
  smtp:
    image: catatnight/postfix:latest
    ports:
    - "25:25"

