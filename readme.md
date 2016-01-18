# [![Appier Framework Extras](res/logo.png)](http://appier_extras.hive.pt)

Set of extra elements for [Appier Framework](http://appier.hive.pt) infra-structure.

Here's a basic example:

```python
import appier
import appier_extras

class HelloApp(appier.WebApp):

    def __init__(self):
        appier.WebApp.__init__(
            self,
            parts = (
                appier_extras.AdminPart,
            )
        )

HelloApp().serve()
```

After running the previous examples, go to [http://localhost:8080/admin](http://localhost:8080/admin)
and login with root/root.

## Learn more
* [Models](doc/models.md) - admin interface for the app's models

## License

Appier Extras is currently licensed under the [Apache License, Version 2.0](http://www.apache.org/licenses/).

## Build Automation

[![Build Status](https://travis-ci.org/hivesolutions/appier_extras.svg?branch=master)](https://travis-ci.org/hivesolutions/appier_extras)
[![Coverage Status](https://coveralls.io/repos/hivesolutions/appier_extras/badge.svg?branch=master)](https://coveralls.io/r/hivesolutions/appier_extras?branch=master)
[![PyPi Status](https://img.shields.io/pypi/v/appier_extras.svg)](https://pypi.python.org/pypi/appier_extras)
