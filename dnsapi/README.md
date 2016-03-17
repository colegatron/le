# How to use dns api

## Use AWS Route53 dns api to automatically issue certs

It depends on aws client, python and jq:
```
 $ sudo apt-get install jq python
 $ sudo pip install awscli
```

Credentials can be provided via environment variables or ~/.aws/credentials file

```
export AWS_ACCESS_KEY_ID="AKIAIMI23HYTTBDIIRE35Q"
export AWS_SECRET_ACCESS_KEY="XamcFVrAkfysloGWe6U9tsdflr2PI3H7t4ps2rMAYm"
```

Unlinke other dns plugins this one does not save your credentials in ~/.le/account.conf

Feel free to modify the plugin to do it if you want to shoot yourself in the foot.

Ok, let's issue cert for a single domain:
```
le.sh   issue   dns-aws   my.com  www.my.com,ftp.my.com,demo.my.com
```

Now an example of single certificate with multiple domains. Let's say you have my.dom and their.com domains:

```
le.sh   issue   dns-aws   my.com  their.com,www.my.com,www.their.com,demo.my.com,demo.their.com
```

You can add as much domains/subdomains as you need, keeping the number of them below the limits of LetsEncrypt.com rules. That's all



Now you can upload it to AWS:
```
MAINDOMAIN="my.com"
aws iam upload-server-certificate \
        --server-certificate-name ${MAINDOMAIN} \
        --certificate-body file://${LE_WORKING_DIR}/${MAINDOMAIN}/${MAINDOMAIN}.cer \
        --private-key file://${LE_WORKING_DIR}/${MAINDOMAIN}/${MAINDOMAIN}.key
```

That's all !!


Domains can be hosted on different aws accounts but they all should be hosted on AWS R53.
 Your credentials should have granted permissions to manage the Route53 zones.

#### Acknowledgment:
Based on the job of [mbentley/dns-r53.sh](https://gist.github.com/mbentley/d5da0bf962f050dd07ec)



## Use CloudFlare domain api to automatically issue cert

For now, we support clourflare integeration.

First you need to login to your clourflare account to get your api key.

```
export CF_Key="sdfsdfsdfljlbjkljlkjsdfoiwje"

export CF_Email="xxxx@sss.com"

```

Ok, let's issue cert now:
```
le.sh   issue   dns-cf   aa.com  www.aa.com
```

The `CF_Key` and `CF_Email`  will be saved in `~/.le/account.conf`, when next time you use cloudflare api, it will reuse this key.



## Use Dnspod.cn domain api to automatically issue cert

For now, we support dnspod.cn integeration.

First you need to login to your dnspod.cn account to get your api key and key id.

```
export DP_Id="1234"

export DP_Key="sADDsdasdgdsf"

```

Ok, let's issue cert now:
```
le.sh   issue   dns-dp   aa.com  www.aa.com
```

The `DP_Id` and `DP_Key`  will be saved in `~/.le/account.conf`, when next time you use dnspod.cn api, it will reuse this key.


## Use Cloudxns.com domain api to automatically issue cert

For now, we support Cloudxns.com integeration.

First you need to login to your Cloudxns.com account to get your api key and key secret.

```
export CX_Key="1234"

export CX_Secret="sADDsdasdgdsf"

```

Ok, let's issue cert now:
```
le.sh   issue   dns-cx   aa.com  www.aa.com
```

The `CX_Key` and `CX_Secret`  will be saved in `~/.le/account.conf`, when next time you use Cloudxns.com api, it will reuse this key.



# Use custom api

If your api is not supported yet,  you can write your own dns api.

Let's assume you want to name it 'myapi',

1. Create a bash script named  `~/.le/dns-myapi.sh`,
2. In the scrypt, you must have a function named `dns-myapi-add()`. Which will be called by le.sh to add dns records.
3. Then you can use your api to issue cert like:

```
le.sh  issue  dns-myapi  aa.com  www.aa.com
```

For more details, please check our sample script: [dns-myapi.sh](dns-myapi.sh)




