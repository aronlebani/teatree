# Teatree

A personal landing page for the web.

## Philosophy and motivation

The project is designed to be simple to deploy and maintain. It uses SQLite as
a database, and just a few source files + a directory of public assets. This
means it can be trivially built and deployed via a makefile with rsync, and run
behind a reverse proxy server such as nginx.

The software focuses on simplicity. It has the minimum features needed to
achieve it's purpose. The project dependencies are kept to a minimum.

## Development

Install the project dependencies. If you are on Debian:

    apt install ruby ruby-dev build-essential pkg-config
    gem install bundler
    bundle install

Or if you are on FreeBSD:

    pkg install ruby rubygem-bundle
    bundle install

Create a `.env` file in the root directory with the following variables:

    HOSTNAME=example.org
    PORT=5000
    DB_URL=db/example.db
    USERDATA_DIR=userdata
    SESSION_SECRET=secret
    SMTP_HOST=smtp.example.org
    SMTP_PORT=587
    SMTP_PASS=secret
    SMTP_USER=hello@example.org
    MAILER=hello@example.org

The `SMTP_*` and `MAILER` variables are only required for the forgot-password
feature. To keep things simple, it connects to a third-pary SMTP service. To
disable this feature, just leave these variables out.

If `SESSION_SECRET` is not provided, it will generate one for you.
However it is recommended to provide one in order to persist sessions across
restarts. To generate a secure random secret, you can use `ruby -e "require
'securerandom'; puts SecureRandom.hex(64)"`. See the [Sinatra
docs](https://sinatrarb.com/intro.html#using-sessions) for more info.

If running for the first time, you'll also need to bootstrap the database.

    sqlite3 db/example.db < scripts/bootstrap.sql

You can then run the app using the provided makefile.

    make debug

Now point your browser to <http://localhost:9292/admin>, and you should see a
login page.

## Testing

I haven't written any unit tests. Maybe I'll get around to it one day. The
[test](./test) directory contains a checklist for manual integration testing.
It's pretty comprehensive and covers all the essential features.

## Deployment

The project can be deployed with the provided makefile, you just need to set
the required environment variables.

## Contributing

If you find a bug, or have a suggestion, feel free to open an issue. Or even
better, create a PR. Note that in order to maintain the project's philosophy of
simplicity, some feature requests might not be implemented.

## License

This software is licensed under the MIT license.
