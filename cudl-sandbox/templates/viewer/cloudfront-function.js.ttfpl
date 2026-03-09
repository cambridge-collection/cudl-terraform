import cf from 'cloudfront';

const kvsHandle = cf.kvs();

const keyPass = "${key_pass}";
const keyUser = "${key_user}";
let user = "Not Found";
let pass = "Not found";

async function handler(event) {
    try {
        pass = await kvsHandle.get(keyPass);
        user = await kvsHandle.get(keyUser);
    } catch (err) {
        console.log(`Kvs key lookup failed: $${err}`);
    }
    const requiredBasicAuth = "Basic " + btoa(`$${user}:$${pass}`);
    let match = false;
    if (event.request.headers.authorization) {
        if (event.request.headers.authorization.value === requiredBasicAuth) {
            match = true;
        }
    }

    if (!match) {
      return {
        statusCode: 401,
        statusDescription: "Unauthorized",
        headers: {
          "www-authenticate": { value: "Basic" },
        },
      };
    } 

    return event.request;
}
