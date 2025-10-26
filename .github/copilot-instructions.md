# Routing app

This is a Terminal Application using the Textual framework that allows managing a library of cycling routes. Users can add, view, edit, and delete routes, as well as search for routes.

Bike routes are stored in JSON files in the `library/` directory. Each route represents a link to the [bikerouter.de](https://bikerouter.de) service with specific parameters.

An example link looks like [this](https://bikerouter.de/#map=14/53.5404/10.0176/standard,Waymarked_Trails-Cycling,gravel-overlay&lonlats=10.007622%2C53.552037%7C10.000498%2C53.55103%7C9.966831%2C53.554375&pois=10.00082%2C53.549386%2CTest+Point&profile=cxb-gravel).

The output json file for this route encapsulates the parameters in a simple dictionary format.


## Tech Stack in use

- Python 3.12+
- Textual framework for building terminal applications
- uv for package management

