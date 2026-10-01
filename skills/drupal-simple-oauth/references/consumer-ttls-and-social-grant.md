# Consumer TTLs and Social Token Grants

Two deploy-time traps around Simple OAuth consumers and custom social login grants.

## Contents

- [Consumer token TTLs are content-entity data, not config](#consumer-token-ttls-are-content-entity-data-not-config)
- [Social/Google token grant: validate aud against an allow-list](#socialgoogle-token-grant-validate-aud-against-an-allow-list)

## Consumer token TTLs are content-entity data, not config

`consumer` entities (from the Consumers module that Simple OAuth builds on) are **content** entities. Their fields, including `access_token_expiration` and `refresh_token_expiration`, live in the database. There is no `consumer.consumer.*.yml` in the config sync directory, so `drush cim` never deploys a TTL change. Editing the value in the UI on your local site changes only your local site.

**Rule:** change consumer settings on deployed environments with a `hook_update_N()` (it runs during `drush updatedb`).

**Look the consumer up by `client_id`.** The OAuth client id is unique and is what your apps send; the label and the numeric entity id are admin-editable or differ between environments.

```php
/**
 * Raise the mobile app consumer's refresh token lifetime to 30 days.
 */
function my_module_update_10001() {
  $consumers = \Drupal::entityTypeManager()
    ->getStorage('consumer')
    ->loadByProperties(['client_id' => 'MOBILE_APP_CLIENT_ID']);

  if (!$consumers) {
    return 'No consumer with that client_id; nothing to do.';
  }

  /** @var \Drupal\consumers\Entity\Consumer $consumer */
  $consumer = reset($consumers);
  if ((int) $consumer->get('refresh_token_expiration')->value === 2592000) {
    return 'Consumer already up to date; nothing to do.';
  }

  $consumer->set('refresh_token_expiration', 2592000);
  $consumer->save();
  return 'Set refresh_token_expiration to 30 days.';
}
```

Make the hook idempotent (compare before writing) so it is safe on every environment, including ones that were already changed by hand.

**Refresh token rotation races.** Simple OAuth rotates the refresh token on every refresh. When an app fires two refreshes at once, or loses the response to the first, the second request presents an already-rotated token and the user is logged out. The contrib module [Simple OAuth Refresh Token Buffer](https://www.drupal.org/project/simple_oauth_refresh_token_buffer) adds a per-consumer grace period during which a repeated refresh gets the same response as the first successful one. Its settings are also fields on the consumer (`refresh_token_buffer_enabled`, `refresh_token_buffer_grace_period`), so they deploy the same way: through an update hook, not config.

## Social/Google token grant: validate aud against an allow-list

A common pattern for native "Sign in with Google" is a custom OAuth grant (for example `grant_type=social`) that accepts a Google token from the app, verifies it with Google (tokeninfo or JWKS), finds or creates the Drupal user, and issues a Simple OAuth token. The grant must check that the Google token was issued for **your** application by validating its audience (`aud`, and `azp` where present).

**The trap:** a project normally has several Google OAuth client ids: one for the website's login button, and separate ones for the Android, iOS and app-web builds. Google reports `aud`/`azp` as whichever client **minted** the token. Tokens from the mobile apps therefore carry the app client ids, not the website client id stored in your social-auth module's settings. An audience check anchored on that single website client id rejects every app login, failing closed with no obvious error on the website.

**Fix:** validate against an allow-list of trusted audiences:

```php
$trusted = $this->config('my_module.settings')->get('google_trusted_audiences') ?: [];
if (!$trusted) {
  // Fail closed to the single web client id rather than accepting anything.
  $trusted = [$this->config('social_auth_google.settings')->get('client_id')];
}
if (!in_array($token_info['aud'], $trusted, TRUE)) {
  $this->logger->error('Google token audience @aud is not trusted.', ['@aud' => $token_info['aud']]);
  throw OAuthServerException::accessDenied('Untrusted token audience.');
}
```

Deployment and observability notes:

- **The allow-list is config, so it needs a config import on every environment.** Shipping the code without the import leaves each environment on the fallback, which still rejects app logins.
- **Log rejections at error level.** If your error tracker ingests watchdog only at error and above, a `->warning()` here never reaches it, and an app-login outage stays invisible.
- **Test with the token the app actually sends.** Native apps often send a Google **access** token rather than an id_token. Exercise the grant with the same token type and client id your app uses; a test that mints through the website client passes while every app login fails.
