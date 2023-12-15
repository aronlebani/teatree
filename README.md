# Teatree

A personal landing page for the web.

## Philosophy and motivation

The project is designed to be simple to deploy and maintain. It uses SQLite as a database, and it can be compiled to a single binary + a directory of public assets. This means it can be trivially built and deployed via a makefile with rsync, and run behind a reverse proxy server such as nginx.

The software focuses on simplicity. It has the minimum features needed to achieve it's purpose. The project dependencies are kept to a minimum.

## Development

Ensure you have the following dependencies installed:

* A Common Lisp implementation (I've only tested it with [SBCL](http://www.sbcl.org/)) [^1]
* The [quicklisp](https://www.quicklisp.org) dependency manager [^2]
* SQLite3

Before running the project, you should create a configuration file called `.config`. An example is provided in `.config.sample`. If running for the first time, you'll also need to create a database file. You can do this with the provided script.

    cat scripts/bootstrap.sql | sqlite3 local.db

To get started with development, open a Lisp REPL and type the following:

    (load "<path/to/repository>/teatree.asd")
    (ql:quickload :teatree)
    (in-package :teatree)
    (main)

Or, if you aren't using a REPL, you can just run it via the makefile.

    make debug

Now point your browser to <http://localhost:4000/admin>, and you should see a login page.

## Testing

I haven't written any unit tests. Maybe I'll get around to it one day. The [test](./t) directory contains a checklist for manual integration testing.

## Deployment

The project can be build and deployed with the provided makefile, you just need to set the required variables.

## Contributing

If you find a bug, or have a suggestion, feel free to open an issue. Or even better, create a PR. Note that in order to maintain the project's philosophy of simplicity, some feature requests might not be implemented.

## Copyright

Copyright (c) 2024 Aron Lebani <aron@lebani.dev>

## License

This software is licensed under the MIT license.

[^1]: I haven't bothered to test for portability since the software is intended to be packaged as an application, not a library. SBCL is a popular, high quality, and open-source implementation.
[^2]: I have no idea why the website still says beta. It's been around for over 10 years. Anyhow, don't be put off by that - it's pretty much the industry standard dependency manager for Common Lisp.
