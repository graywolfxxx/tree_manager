## Programming Assignment

Your task is to write a web based application that allows the user to view an existing, initially empty,
tree and add nodes to it. Tree nodes should be stored in the MySQL database. Thus, your program should be able
to read them from the database to display the tree, and add new nodes to the tree upon user request.
Each node should be identified by a unique node ID and have a parent P.

Please consult the following UI sketch (feel free to make improvements).

```
                                           Tree Manager

Current Tree

Depth                                       Tree Nodes

                                         ┌───────────────┐
  0                                      │ P: None ID: 1 │
                                         └───────┬───────┘
                          ┌──────────────────────┴───────────────────────┐
                   ┌──────┴─────┐                                 ┌──────┴─────┐
  1                │ P: 1 ID: 2 │                                 │ P: 1 ID: 3 │
                   └──────┬─────┘                                 └──────┬─────┘
               ┌──────────┴──────────┐                                   │
        ┌──────┴─────┐        ┌──────┴─────┐                      ┌──────┴─────┐
  2     │ P: 2 ID: 4 │        │ P: 2 ID: 5 │                      │ P: 3 ID: 6 │
        └────────────┘        └──────┬─────┘                      └──────┬─────┘
               ┌─────────────┬───────┴─────┬─────────────┐               │
        ┌──────┴─────┐┌──────┴─────┐┌──────┴─────┐┌──────┴──────┐ ┌──────┴──────┐
  3     │ P: 5 ID: 7 ││ P: 5 ID: 8 ││ P: 5 ID: 9 ││ P: 5 ID: 10 │ │ P: 6 ID: 11 │
        └────────────┘└────────────┘└────────────┘└─────────────┘ └─────────────┘

             ┌─────────────────┐
Add Node To: │ PID             │
             └─────────────────┘

╔═══════╗
║  Add  ║
╚═══════╝
```

Typing in parent node ID in **PID** box and clicking **Add** button should add a new node to the node
with that ID or produce and an error message in case invalid node ID is entered. Error message should be
displayed immediately above **Add** button.

We are looking for re-usable code. You are strongly encouraged to "over engineer" this in order to show off
your software architecture and designing skills. Assume that this abstract application will be the start of
a large scale application and is intended to serve the basis for other tree-like implementations.

If pressed for time, feel free to use comments to explain what you would do in a real scenario.

Provide all code, schema and build instructions to be able to run application outside your environment.


## How to deploy

### Deploy

1. Install perl 5.10.1 or higher

2. Install and run MySQL

3. Install Mojolicious
    ```bash
    wget -O - https://cpanmin.us | perl - -M https://cpan.metacpan.org -n Mojolicious
    ```

4. Create the project's directory:
    ```bash
    mkdir -p -m 0775 /home/tree_manager/
    cd /home/tree_manager/
    ```

5. Clone repository to this new dir
    ```bash
    git clone "https://github.com/graywolfxxx/tree_manager" ./
    ```

6. Init DB
    ```bash
    mysql < sql/init_db.sql
    ```

### Run application using Morbo development server

1. Run application
    ```bash
    morbo script/tree_mng
    ```

2. Open in browser
    ```bash
    http://<your IP>:3000/
    ```

### Run application using Apache2

1. Install Apache2

2. Do this point If your Linux supports SELinux access control
    ```bash
    chcon -R -t httpd_sys_content_t /home/tree_manager
    ```

3. Add to /etc/hosts of your server following string
    ```bash
    127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4 treemng.com
    ```

4. Open for edit config file of Apache /etc/httpd/conf/httpd.conf. Set or change following:
    ```bash
    Listen 80

    # load modules if they haven't been loaded yet in /etc/httpd/conf/httpd.conf
    LoadModule env_module modules/mod_env.so
    LoadModule cgi_module modules/mod_cgi.so

    ServerName 127.0.0.1:80

    NameVirtualHost *:80

    # In the end of the config file add virtual host treemng.com
    <VirtualHost *:80>
        ServerAdmin root@localhost
        ServerName treemng.com

        DocumentRoot /home/tree_manager
        Options FollowSymLinks
        IndexIgnore *

        RewriteEngine on

        RewriteCond %{DOCUMENT_ROOT}/public/%{REQUEST_URI} -f
        RewriteRule ^(.*)$ /public/$1 [L,NS]

        RewriteCond %{DOCUMENT_ROOT}/public/%{REQUEST_URI} !-f
        RewriteRule ^(.*)$ /script/tree_mng/$1 [L,NS,H=cgi-script]

        SetEnv MOJO_MODE "production"
        <Directory "/home/tree_manager/script/">
            AllowOverride None
            Options ExecCGI
            Order allow,deny
            Allow from all
        </Directory>

        ErrorLog  logs/treemng.com-error_log
        CustomLog logs/treemng.com-access_log common
    </VirtualHost>
    ```

5. Reload Apache
    ```bash
    /etc/init.d/httpd stop
    /etc/init.d/httpd start
    ```
    or
    ```bash
    /etc/init.d/httpd reload
    ```

6. Open in browser http://treemng.com/
