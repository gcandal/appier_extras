#!/usr/bin/python
# -*- coding: utf-8 -*-

# Hive Appier Framework
# Copyright (c) 2008-2017 Hive Solutions Lda.
#
# This file is part of Hive Appier Framework.
#
# Hive Appier Framework is free software: you can redistribute it and/or modify
# it under the terms of the Apache License as published by the Apache
# Foundation, either version 2.0 of the License, or (at your option) any
# later version.
#
# Hive Appier Framework is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# Apache License for more details.
#
# You should have received a copy of the Apache License along with
# Hive Appier Framework. If not, see <http://www.apache.org/licenses/>.

__author__ = "João Magalhães <joamag@hive.pt>"
""" The author(s) of the module """

__version__ = "1.0.0"
""" The version of the module """

__revision__ = "$LastChangedRevision$"
""" The revision number of the module """

__date__ = "$LastChangedDate$"
""" The last change date of the module """

__copyright__ = "Copyright (c) 2008-2017 Hive Solutions Lda."
""" The copyright for the module """

__license__ = "Apache License, Version 2.0"
""" The license for the module """

import time

import appier

from appier_extras.parts.admin.models import base

class OAuthToken(base.Base):
    """
    Model class that represent an OAuth 2.0 access token
    that as been in created for a specific user context
    and with a certain duration scope.
    """

    DEFAULT_DURATION = 3600
    """ The default duration of the oauth token, this
    value should not be too long to avoid security issues """

    CODE_DURATION = 600
    """ The authorization code duration (in seconds), to be
    used for proper authorization code validation """

    name = appier.field(
        index = "hashed",
        default = True,
        safe = True,
        immutable = True
    )
    """ Simplified name value, created from the first few
    characters of the access token value """

    access_token = appier.field(
        index = "hashed",
        safe = True,
        immutable = True
    )
    """ The actual string representing an authorization
    issued to the client """

    authorization_code = appier.field(
        index = "hashed",
        safe = True,
        private = True,
        immutable = True
    )
    """ The authorization code generated by the
    authorization server """

    authorization_code_date = appier.field(
        type = float,
        safe = True,
        private = True,
        immutable = True,
        meta = "datetime"
    )
    """ The date when the authorization code was generated """

    username = appier.field(
        index = "hashed",
        safe = True,
        immutable = True
    )
    """ The name of the user that is authorized this
    access token, will be used for custom acl creation """

    scope = appier.field(
        type = list,
        private = True,
        immutable = True
    )
    """ The oauth based scope string that "created" this
    token with its values sorted alphabetically """

    expires_in = appier.field(
        type = int,
        index = "all",
        immutable = True
    )
    """ The duration in seconds of the access token lifetime """

    redirect_uri = appier.field(
        index = "hashed",
        immutable = True,
        meta = "url",
        description = "Redirect URI"
    )
    """ An absolute uri to which the authorization server
    will redirect the user-agent to when the end-user
    authorization step is completed """

    refresh_token = appier.field(
        index = "hashed",
        safe = True,
        private = True,
        immutable = True
    )
    """ A token used by the client to obtain a new access token
    (in addition or as a replacement for an expired access
    token), without having to involve the resource owner. """

    tokens = appier.field(
        type = list,
        safe = True,
        private = True,
        immutable = True
    )
    """ The acl tokens associated with this access token """

    client = appier.field(
        type = appier.reference(
            "OAuthClient",
            name = "id"
        ),
        immutable = True
    )
    """ The reference to the oauth client that has been used
    for the generation of this token """

    @classmethod
    def validate(cls):
        return super(OAuthToken, cls).validate() + [
            appier.not_null("username"),
            appier.not_empty("username"),

            appier.not_null("scope"),
            appier.not_empty("scope"),
            appier.string_gt("scope", 0),

            appier.not_null("redirect_uri"),
            appier.not_empty("redirect_uri"),
            appier.is_url("redirect_uri"),

            appier.not_null("client")
        ]

    @classmethod
    def list_names(cls):
        return ["name", "created", "username"]

    @classmethod
    def order_name(cls):
        return ["id", -1]

    @classmethod
    def login(cls, access_token):
        oauth_token = cls.get(access_token = access_token)
        oauth_token.verify_expired()
        return oauth_token

    @classmethod
    def _underscore(cls, plural = True):
        return "oauth_tokens" if plural else "oauth_token"

    @classmethod
    def _readable(cls, plural = False):
        return "OAuth Tokens" if plural else "OAuth Token"

    def pre_create(self):
        base.Base.pre_create(self)

        cls = self.__class__
        self.access_token = appier.gen_token()
        self.client_secret = appier.gen_token()
        self.authorization_code = appier.gen_token()
        self.authorization_code_date = time.time()
        self.expires_in = cls.DEFAULT_DURATION
        self.refresh_token = appier.gen_token()
        self.tokens = self._filter_scope(self.scope)
        self.name = self.access_token[:8]

        self._verify()

    def get_account(self):
        return self.owner.admin_part.account_c.get(
            username = self.username
        )

    def verify_code(self, code, grant_type = "authorization_code"):
        cls = self.__class__
        appier.verify(self.authorization_code == code)
        appier.verify(time.time() - self.authorization_code_date < cls.CODE_DURATION)
        appier.verify(grant_type, "authorization_code")

    def verify_expired(self):
        appier.verify(time.time() < self.created + self.expires_in)

    def _verify(self):
        self._verify_scope()

    def _verify_scope(self):
        scope_s = set(self.scope)
        appier.verify(len(self.scope) == len(scope_s))

    def _filter_scope(self, scope):
        """
        Filters the provided sequence of tokens for the scope, so
        that only the ones allowed for the requested user are used.

        This avoid security issues like someone requesting values
        for a token that is for which the user is not allowed.

        :type scope: List
        :param scope: The list of tokens to be filtered.
        :rtype: List
        :return: The resulting filtering list containing only the
        tokens for which the impersonated user is capable.
        """

        # builds the list that is going to be used to store the
        # result of the scope filtering (acl verification)
        result = []

        # retrieves the account associated with the oauth token
        # and the (acl) tokens for it converting them into a map
        # to be used for acl verification operations
        account = self.get_account()
        tokens = account.tokens()
        tokens_m = appier.to_tokens_m(tokens)

        # iterates over each token of the scope to validate it
        # according to the acl of the associated account
        for token in scope:
            valid = appier.check_token(None, token, tokens_m = tokens_m)
            if not valid: continue
            result.append(token)

        # returns the final result that contains only the scope
        # tokens for which the account is entitle to register
        return result

    def _set_session(self, unset = True, safes = [], method = "set"):
        cls = self.__class__
        account = self.get_account()
        account._set_session(unset = unset, safes = safes, method = method)
        if unset: return
        set("tokens", self.tokens)