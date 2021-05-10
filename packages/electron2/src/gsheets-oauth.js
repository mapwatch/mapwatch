// https://www.npmjs.com/package/google-auth-library
//
// Expects env variables:
// * GOOGLE_SHEETS_CLIENT_ID
// * GOOGLE_SHEETS_CLIENT_SECRET
// * GOOGLE_SHEETS_API_KEY
// https://console.cloud.google.com/apis/credentials?project=poe-mapwatch

// TODO: add above to github secrets
// TODO: random oauth server port
// TODO: caller must (somehow) use AuthenticatedClient's auth with google js api library
// TODO: gsheets.js refactor to use mapwatch's backends:
//   * www must use the existing js client, loaded through a <script> tag. https://github.com/google/google-api-javascript-client/issues/432
//   * electron must use googleapis, loaded through npm: https://www.npmjs.com/package/googleapis, https://www.npmjs.com/package/@googleapis/sheets, https://www.npmjs.com/package/google-auth-library
//   why? because auth is very different/incompatible for each of these.

const {auth, OAuth2Client} = require('google-auth-library');
const http = require('http');
const url = require('url');
const destroyer = require('server-destroy');

/**
 * Create a new OAuth2Client, and go through the OAuth2 content
 * workflow.  Return the full client to the callback.
 */
function getAuthenticatedClient({open, redirect_uri}) {
  return new Promise((resolve, reject) => {
    // create an oAuth client to authorize the API call.  Secrets are kept in `.env`
    const client_id = process.env.GOOGLE_SHEETS_CLIENT_ID
    const client_secret = process.env.GOOGLE_SHEETS_CLIENT_SECRET
    const oAuth2Client = new OAuth2Client(client_id, client_secret, redirect_uri);

    // Generate the url that will be used for the consent dialog.
    const authorizeUrl = oAuth2Client.generateAuthUrl({
      access_type: 'offline',
      scope: 'https://www.googleapis.com/auth/userinfo.profile',
    });

    // Open an http server to accept the oauth callback. In this simple example, the
    // only request to our webserver is to /oauth2callback?code=<code>
    const server = http
      .createServer(async (req, res) => {
        try {
          if (req.url.indexOf('/oauth2callback') > -1) {
            // acquire the code from the querystring, and close the web server.
            const qs = new url.URL(req.url, `http://localhost:${server.address().port}`).searchParams;
            const code = qs.get('code');
            console.log(`Code is ${code}`);
            res.end('Authentication successful! Please return to the console.');
            server.destroy();

            // Now that we have the code, use that to acquire tokens.
            const r = await oAuth2Client.getToken(code);
            // Make sure to set the credentials on the OAuth2 client.
            oAuth2Client.setCredentials(r.tokens);
            console.info('Tokens acquired.');
            resolve(oAuth2Client);
          }
        } catch (e) {
          reject(e);
        }
      })
      .listen(3001, () => {
        // open the browser to the authorize url to start the workflow
        open(authorizeUrl, {wait: false}).then(cp => cp && cp.unref());
      });
    destroyer(server);
  });
}

module.exports = {getAuthenticatedClient}

async function main() {
  require('dotenv').config()
  const oAuth2Client = await getAuthenticatedClient({
    open: require('open'),
    redirect_uri: 'http://localhost:3000/electron-login-redirect.html',
  });
  // Make a simple request to the People API using our pre-authenticated client. The `request()` method
  // takes an GaxiosOptions object.  Visit https://github.com/JustinBeckwith/gaxios.
  const url = 'https://people.googleapis.com/v1/people/me?personFields=names';
  const res = await oAuth2Client.request({url});
  console.log(res.data);

  // After acquiring an access_token, you may want to check on the audience, expiration,
  // or original scopes requested.  You can do that with the `getTokenInfo` method.
  const tokenInfo = await oAuth2Client.getTokenInfo(
    oAuth2Client.credentials.access_token
  );
  console.log(tokenInfo);
}
if (require.main === module) {
  main().catch(err => {
    console.error(err)
    process.exit(1)
  })
}
