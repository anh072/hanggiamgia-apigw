import os

import jwt
from jwt import PyJWKClient


def deny_res():
  return {"isAuthorized": False}

def handler(event, context):
  audience = os.environ.get("AUTH0_AUDIENCE")
  auth0_domain = os.environ.get("AUTH0_DOMAIN")
  claim_namespace = os.environ.get("CLAIM_NAMESPACE")

  auth_header = event["headers"]["authorization"]
  auth_parts = auth_header.split()
  if len(auth_parts) <= 1 or len(auth_parts) > 2:
    print("Token does not have 2 parts")
    return deny_res()
  token_type, token = auth_parts
  if token_type.lower() != "bearer":
    print("Token type is not Bearer")
    return deny_res()

  jwks_client = PyJWKClient(f"{auth0_domain}.well-known/jwks.json")
  try: 
    signing_key = jwks_client.get_signing_key_from_jwt(token)
    claims = jwt.decode(
      token, 
      signing_key.key, 
      algorithms=["RS256"], 
      audience=audience, 
      issuer=auth0_domain,
      options={"verify_exp": True}
    )
    return {
      "isAuthorized": True,
      "context": {
        "userId": claims["sub"],
        "username": claims[f"{claim_namespace}/username"]
      }
    }
  except jwt.ExpiredSignatureError as e:
    print("Token has expired", e)
    return deny_res()
  except jwt.DecodeError as e:
    print("Token fails validation", e)
    return deny_res()
  except jwt.InvalidTokenError as e:
    print("Token is invalid", e)
    return deny_res()
