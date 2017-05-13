CREATE DATABASE IF NOT EXISTS forest;

USE forest;

CREATE TABLE IF NOT EXISTS Tree_Branch (
    id            int unsigned NOT NULL AUTO_INCREMENT,
    pid           int unsigned,
    name          varchar(100),
    date_updated  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

