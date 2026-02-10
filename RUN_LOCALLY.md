# Run THYROSIM locally (Ubuntu / WSL) 

These are the concrete steps we used to get the original THYROSIM web app running from this repo.

Repo path in this example:

- Repo: `/home/user/m182/pthyrosim-web`
- Parent (DocumentRoot): `/home/user/m182`

Adjust paths if your username or folder is different.

---

## 1. Install packages

```bash
sudo apt update
sudo apt install openjdk-11-jdk perl apache2 libcgi-pm-perl
sudo cpan JSON::Syck   # if JSON::Syck is not already present
sudo a2enmod cgi
```

You don’t need Octave/odepkg unless you plan to use the Octave/Matlab scripts; for the web app (Java solver + CGI), Java + Perl + Apache are enough.

---

## 2. Make sure the repo is under the DocumentRoot

Example used:

- DocumentRoot: `/home/user/m182`
- Repo: `/home/user/m182/pthyrosim-web`

So the app URL is:  
`http://localhost/pthyrosim-web/`

If your repo is elsewhere, either move it or adjust DocumentRoot and paths below accordingly.

Also make sure Apache can traverse into your home directory:

```bash
chmod o+x /home/user /home/user/m182
```

---

## 3. CGI scripts executable

```bash
cd /home/user/m182/pthyrosim-web
chmod +x cgi-bin/*.cgi
```

---

## 4. Apache site config

Create a site file:

```bash
sudo nano /etc/apache2/sites-available/pthyrosim.conf
```

Contents (update paths if needed):

```apache
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /home/user/m182

    <Directory /home/user/m182>
        Options FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

    <Directory /home/user/m182/pthyrosim-web/cgi-bin>
        Options +ExecCGI
        AddHandler cgi-script .cgi
        Require all granted
    </Directory>
</VirtualHost>
```

Enable the site and reload Apache:

```bash
sudo a2ensite pthyrosim.conf
sudo systemctl reload apache2
```

If another site is already using port 80 and causing conflicts, you can either disable it (`sudo a2dissite 000-default.conf`) or change the `<VirtualHost>` line to a different port (e.g. `*:8080`) and visit `http://localhost:8080/pthyrosim-web/`.

---

## 5. Java solver check (optional sanity check)

From the `java/` folder:

```bash
cd /home/user/m182/pthyrosim-web/java
ls commons-math3-3.6.1.jar    # should exist

java -cp .:commons-math3-3.6.1.jar:$(pwd) \
  edu.ucla.distefanolab.thyrosim.algorithm.Thyrosim
```

You should see an error about missing arguments (that’s fine); a `ClassNotFoundException` would mean the classpath or files are wrong.

---

## 6. Run the app

Open in your browser:

- `http://localhost/pthyrosim-web/`  
  (this redirects to `./cgi-bin/Thyrosim.cgi`)

You should see the THYROSIM UI. Run the default simulation (e.g. 5 days) and confirm that plots appear.

---

## 7. If it breaks

Check the Apache error log:

```bash
sudo tail -50 /var/log/apache2/error.log
```

Common issues:

- **Permission denied on `/home/user/m182`** → fixed by `chmod o+x /home/user /home/user/m182`.
- **`Can't locate CGI.pm`** → fixed by `sudo apt install libcgi-pm-perl`.
- **`Can't locate JSON/Syck.pm`** → fixed by `sudo cpan JSON::Syck`.

The older INSTALL file (`docs/INSTALL`) is kept for historical context; use this page for our current Ubuntu/WSL setup.

