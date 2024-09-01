-- Bootstrap the database with required settings

-- Enable Write Ahead Logging to increase speed and concurrency
-- See this <https://www.sqlite.org/wal.html> for more info

PRAGMA journal_mode = wal;

-- Create tables

CREATE TABLE users (
    id INTEGER NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    created_at TEXT,
    updated_at TEXT
);

CREATE TABLE profiles (
    id INTEGER NOT NULL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    username TEXT UNIQUE NOT NULL,
	title TEXT,
    colour TEXT,
    bg_colour TEXT,
    image_url TEXT,
    image_alt TEXT,
    is_live INTEGER,
	css TEXT,
    created_at TEXT,
    updated_at TEXT,
    FOREIGN Key (user_id)
        REFERENCES user (id)
);

CREATE TABLE links (
    id INTEGER NOT NULL PRIMARY KEY,
    profile_id INTEGER NOT NULL,
    href TEXT NOT NULL,
    title TEXT NOT NULL,
    created_at TEXT,
    updated_at TEXT,
    FOREIGN KEY (profile_id)
        REFERENCES profile (id)
);

CREATE TABLE integrations (
    id INTEGER NOT NULL PRIMARY KEY,
    profile_id INTEGER NOT NULL,
    mailchimp_subscribe_url TEXT,
    created_at TEXT,
    updated_at TEXT,
    FOREIGN KEY (profile_id)
        REFERENCES profile (id)
);

CREATE TABLE pw_reset_requests (
	id INTEGER NOT NULL PRIMARY KEY,
	uuid TEXT NOT NULL,
	user_id INTEGER NOT NULL,	
    created_at TEXT,
    updated_at TEXT,
    FOREIGN KEY (user_id)
        REFERENCES user (id)
);

-- Start PRIMARY KEY from 1001

INSERT INTO users (id, name, email, password)
VALUES (1000, 'example', 'example', 'example');

INSERT INTO profiles (id, user_id, username)
VALUES (1000, 1000, 'example');

INSERT INTO links (id, profile_id, title, href)
VALUES (1000, 1000, 'example', 'example');

INSERT INTO integrations (id, profile_id)
VALUES (1000, 1000);
