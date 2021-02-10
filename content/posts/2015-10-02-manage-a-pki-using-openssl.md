+++
title = "Manage PKI using OpenSSL"
author = "Victor Dorneanu"
date = "2015-10-02"
tags = ["ssl", "tls", "openssl", "crypto", "python", "ipython", "admin", "pki", "openssl", "x.509"]
category = "blog"
+++

In the previous X.509 related [post](http://blog.dornea.nu/2015/05/24/validating-and-pinning-x509-certificates/) I've had a look at the internals of a X.509 certficate. This time I want to setup my own [PKI](https://en.wikipedia.org/wiki/Public_key_infrastructure) using some *open source* software. This post is a preparation for setting up a VPN using *OpenVPN*. 

Before implementing the PKI let's have a look what a PKI should definitely include (make sure you have a look at the [Wikipedia entry](https://en.wikipedia.org/wiki/Public_key_infrastructure)):

* certificate authority (**CA**)
    + has a public and a private key
    + used to digitally sign *certificates*
* registration authority (**RA**)
    + verify identify of users requesting information from the CA
* certificate management system
    + probably the most important component
    
## Revision

<table class="equalDevide" cellpadding="0" cellspacing="0" width="100%" border="0">
  <tr>
    <th><b>Date</b></th>
    <th><b>Description</b></th>
  </tr>
  <tr>
    <td>2015-10-02</td>
    <td>First release</td>
  </tr>
  <tr>
    <td>2015-11-17</td>
    <td>Added creation of VPN-CA and related certificates.</td>
  </tr>
</table>

## CA types

There are several [types](https://pki-tutorial.readthedocs.org/en/latest/#ca-types) of **CA**s:

* root CA
    + the *root* of the PKI hierarchy
    + issues *CA certificates*
* intermediate CA
    + the CA right below the *root* CA
    + issues *CA certificates*
* signing CA 
    + CA at the bottom of the PKI hierarchy
    + issues only *user certificates*

## Certificates types

There are several [types of certificates](https://pki-tutorial.readthedocs.org/en/latest/#certificate-types) used in real-world:

* root certificate
    + *self-signed* certificate at the root of the PKI hierarchy 
    + has to be kept *secret*
* CA certificate
    + used to sign other certificates and CRLs
* user certificate
    + end-user certificate issues for one purpose: code signing, mail protection etc.
    + user certificates can **not** sign other certificates


## PKI hierarchy

In most modern companies you'll find a **3-tier** PKI hierarchy. 




```python
%%blockdiag
# <!-- collapse=True -->
blockdiag {↔

  // Define class (list of attributes)
  class emphasis [color = pink, style = dashed];
  class blackline [color = black, style = dotted];
  class blue [color = lightblue];

  Root_CA [class = "emphasis", label = "Root CA"];
  Intermediate_CA1 [class = "blue", label = "Intermediate CA"];
  Intermediate_CA2 [class = "blue", label = "Intermediate CA"];
  Intermediate_CA3 [class = "blue", label = " ... "];
  Signing_CA1 [label = "Signing CA"];
  Signing_CA1_0 [label = " ... "];
  
  Signing_CA2 [label = "Signing CA"];
  Signing_CA2_0 [label = " ... "];
  
  Signing_CA3 [label = "Signing CA"];
  Signing_CA3_0 [label = " ... "];

  Root_CA -> Intermediate_CA1;
  Root_CA -> Intermediate_CA2 [class = "blackline"];
  Root_CA -> Intermediate_CA3 [class = "blackline"];
  Intermediate_CA1 -> Signing_CA1;
  Intermediate_CA1 -> Signing_CA1_0 [class = "blackline"];

  Intermediate_CA2 -> Signing_CA2 [class = "blackline"];
  Intermediate_CA2 -> Signing_CA2_0 [class = "blackline"];

  Intermediate_CA3 -> Signing_CA3 [class = "blackline"];
  Intermediate_CA3 -> Signing_CA3_0 [class = "blackline"];
}
```


    
![png](/posts/img/2015/manage-a-pki-using-openssl/output_1_0.png)
    


For my purposes I'll be using only a **2-tier** hierarchy as shown below:


```python
%%blockdiag
# <!-- collapse=True -->
blockdiag {
  // Define orientation
  orientation = portrait;

  // Define class (list of attributes)
  class emphasis [color = pink, style = dashed];
  class blackline [color = black, style = dotted];
  class blue [color = lightblue];

  Root_CA [class = "emphasis", label = "Root CA"];
  Signing_CA1 [label = "Signing CA"];
  Signing_CA2 [label = "Signing CA"];
  Signing_CA3 [label = "Signing CA"];

  Root_CA -> Signing_CA1;
  Root_CA -> Signing_CA2;
  Root_CA -> Signing_CA3;
}
```


    
![png](/posts/img/2015/manage-a-pki-using-openssl/output_3_0.png)
    


The level of security is increased because you separate the root CA from the issuing CAs. The root CA is mostly offline so the private key to sign the certificates should be thus protected from compromise. If one of the *issuing CAs* is being compromised, you can *revoke* the certificate issued for that specific CA and create another one using the *root CA*. You can also have multiple issuing CAs distributed geographically and with different security levels. This increases *flexibility* and *scalability*. 

> Also checkout this [awesome article](http://blogs.technet.com/b/askds/archive/2009/09/01/designing-and-implementing-a-pki-part-i-design-and-planning.aspx) for further details.

### dornea.nu PKI hierarchy

And now let's make this whole hierarchy more personalized:




```python
%%blockdiag
# <!-- collapse=True -->
blockdiag {
  // Define orientation
  orientation = portrait;

  // Define class (list of attributes)
  class emphasis [color = pink, style = dashed];
  class blackline [color = black, style = dotted];
  class blue [color = lightblue];
  class inactive [color = lightgrey];

  Root_CA [class = "emphasis", label = "dornea.nu root CA"];
  Signing_CA2 [label = "dev.dornea.nu CA"];
  Signing_CA3 [label = "vpn.dornea.nu CA"];
  TLS_Server_CA [label = "TLS Server Cert", shape = flowchart.terminator, style = dotted];
  TLS_Client_CA [label = "TLS Client Cert", shape = flowchart.terminator, style = dotted];
  VPN_Server_CA [class = inactive, label = "VPN Server Cert", shape = flowchart.terminator, style = dotted];
  VPN_Client_CA [class = inactive, label = "VPN Client Cert", shape = flowchart.terminator, style = dotted];

  Root_CA -> Signing_CA2 [label = "issues"];
  Root_CA -> Signing_CA3;

  Signing_CA2 -> TLS_Server_CA [label = "issues"];
  Signing_CA2 -> TLS_Client_CA;
    
  Signing_CA3 -> VPN_Server_CA [label = "issues"];
  Signing_CA3 -> VPN_Client_CA;
}
```


    
![png](/posts/img/2015/manage-a-pki-using-openssl/output_5_0.png)
    


We'll have a **root CA** bound to the domain `dornea.nu` followed by 2 intermediate CAs: **dev.dornea.nu CA** and **vpn.dornea.nu CA**. The CAs will be used to issue certificates to *users* and *networks*.

The **TLS Server CA** will be used by a web server like Apache or Nginx to server content over a SSL/TLS connection. The server will only accept connection from clients with a valid **TLS Client CA** which has been signed (and generated) from **dev.dornea.nu CA**. 

The **vpn.dornea.nu CA** will then issue certificates for a **VPN Server CA** and a **VPN Client CA**. 

> In this post the creation of the *VPN Server CA* and *VPN Client CA* will be ommitted. I'll cover this in a related post. 

## OpenSSL

[OpenSSL](https://www.openssl.org) is probably the most known cryptography software and SSL/TLS toolkit. Let's have look how things are done using OpenSSL. First of all I'll setup a directory structure to represent each of the PKI component in a clean way.


```python
%%bash↔

```

Initialize and create cert database:


```bash
%%bash
cd /tmp/pki
touch ca/root-ca/db/root-ca.db
touch ca/root-ca/db/root-ca.db.attr
echo 01 > ca/root-ca/db/root-ca.crt.srl
echo 01 > ca/root-ca/db/root-ca.crl.srl
```


```bash
%%bash
tree /tmp/pki
```

    /tmp/pki
    └── ca
        ├── conf
        └── root-ca
            ├── certs
            ├── crl
            ├── db
            │   ├── root-ca.crl.srl
            │   ├── root-ca.crt.srl
            │   ├── root-ca.db
            │   └── root-ca.db.attr
            └── private
    
    7 directories, 4 files


In order to create the certificates I'll keep track of every CA using OpenSSL **configuration files**. 



### Sub-commands

Below there is an overview of the most used *subcommands* in openssl:

<table class="equalDevide" cellpadding="0" cellspacing="0" width="100%" border="0">
  <tr>
    <th class="tg-yw4l">Subcommand</th>
    <th class="tg-yw4l">Description</th>
    <th>Details</th>
  </tr>
  <tr>
    <td class="tg-yw4l">req</td>
    <td class="tg-yw4l">PKCS#10 X.509 Certificate Signing Request (CSR) Management</td>
    <td>The req command primarily creates and processes certificate requests in PKCS#10 format. It can additionally create self signed certificates for use as root CAs for example.</td>
  </tr>
  <tr>
    <td class="tg-yw4l">ca</td>
    <td class="tg-yw4l">Certificate Authority (CA) Management</td>
    <td>It can be used to sign certificate requests in a variety of forms and generate CRLs it also maintains a text database of issued certificates and their status.</td>
  </tr>
  <tr>
    <td class="tg-yw4l">pkcs12</td>
    <td class="tg-yw4l">PKCS#12 Data Management</td>
    <td>The pkcs12 command allows PKCS#12 files (sometimes referred to as PFX files) to be created and parsed. PKCS#12 files are used by several programs including Netscape, MSIE and MS Outlook.</td>
  </tr>
  <tr>
    <td class="tg-yw4l">x509</td>
    <td class="tg-yw4l">X.509 Certificate Data Management</td>
    <td>It can be used to display certificate information, convert certificates to various forms, sign certificate requests like a "mini CA" or edit certificate trust settings.</td>
  </tr>
</table>

### Create dornea.nu root CA


```python
%%blockdiag
# <!-- collapse=True -->
blockdiag {
  // Define orientation
  orientation = portrait;

  // Define class (list of attributes)
  class emphasis [color = pink, style = dashed];
  class blackline [color = black, style = dotted];
  class blue [color = lightblue];
  class active [color = lightgreen];
  class inactive [color = lightgrey];  

  Root_CA [class = active, label = "dornea.nu root CA"];
  Signing_CA2 [label = "dev.dornea.nu CA"];
  Signing_CA3 [class = inactive, label = "vpn.dornea.nu CA"];
  TLS_Server_CA [label = "TLS Server Cert", shape = flowchart.terminator, style = dotted];
  TLS_Client_CA [label = "TLS Client Cert", shape = flowchart.terminator, style = dotted];
  VPN_Server_CA [class = inactive, label = "VPN Server Cert", shape = flowchart.terminator, style = dotted];
  VPN_Client_CA [class = inactive, label = "VPN Client Cert", shape = flowchart.terminator, style = dotted];

  Root_CA -> Signing_CA2;
  Root_CA -> Signing_CA3;

  Signing_CA2 -> TLS_Server_CA;
  Signing_CA2 -> TLS_Client_CA;
    
  Signing_CA3 -> VPN_Server_CA;
  Signing_CA3 -> VPN_Client_CA;
}
```


    
![png](/posts/img/2015/manage-a-pki-using-openssl/output_14_0.png)
    


The configuration file can be shown here:


```python
%%writefile /tmp/pki/ca/conf/root-ca.conf
# <!-- collapse=True -->

# dornea.nu Root CA
# Adapted from https://pki-tutorial.readthedocs.org/en/latest/expert/root-ca.conf.html

[ default ]
ca                      = root-ca               # CA name
dir                     = .                     # Top dir
base_url                = http://pki.dornea.nu  # CA base URL
aia_url                 = $base_url/$ca.cer     # CA certificate URL
crl_url                 = $base_url/$ca.crl     # CRL distribution point
name_opt                = multiline,-esc_msb,utf8 # Display UTF-8 characters
openssl_conf            = openssl_init          # Library config section

# CA certificate request

[ req ]
default_bits            = 4096                  # RSA key size
encrypt_key             = yes                   # Protect private key
default_md              = sha2                  # MD to use
utf8                    = yes                   # Input is UTF-8
string_mask             = utf8only              # Emit UTF-8 strings
prompt                  = no                    # Don't prompt for DN
distinguished_name      = ca_dn                 # DN section
req_extensions          = ca_reqext             # Desired extensions

[ ca_dn ]
countryName             = "NU"
organizationName        = "dornea.nu"
organizationalUnitName  = "dornea.nu Root CA"
commonName              = "dornea.nu Root CA"

[ ca_reqext ]
keyUsage                = critical,keyCertSign,cRLSign
basicConstraints        = critical,CA:true
subjectKeyIdentifier    = hash

# CA operational settings

[ ca ]
default_ca              = root_ca               # The default CA section

[ root_ca ]
certificate             = $dir/ca/$ca/$ca.crt       # The CA cert
private_key             = $dir/ca/$ca/private/$ca.key # CA private key
new_certs_dir           = $dir/ca/$ca           # Certificate archive
serial                  = $dir/ca/$ca/db/$ca.crt.srl # Serial number file
crlnumber               = $dir/ca/$ca/db/$ca.crl.srl # CRL number file
database                = $dir/ca/$ca/db/$ca.db # Index file
unique_subject          = no                    # Require unique subject
default_days            = 3652                  # How long to certify for
default_md              = sha1                  # MD to use
policy                  = match_pol             # Default naming policy
email_in_dn             = no                    # Add email to cert DN
preserve                = no                    # Keep passed DN ordering
name_opt                = $name_opt             # Subject DN display options
cert_opt                = ca_default            # Certificate display options
copy_extensions         = none                  # Copy extensions from CSR
x509_extensions         = signing_ca_ext        # Default cert extensions
default_crl_days        = 30                    # How long before next CRL
crl_extensions          = crl_ext               # CRL extensions

[ match_pol ]
countryName             = match
stateOrProvinceName     = optional
localityName            = optional
organizationName        = match
organizationalUnitName  = optional
commonName              = supplied

[ any_pol ]
domainComponent         = optional
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = optional
emailAddress            = optional

# Extensions

[ root_ca_ext ]
keyUsage                = critical,keyCertSign,cRLSign
basicConstraints        = critical,CA:true
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always

[ signing_ca_ext ]
keyUsage                = critical,keyCertSign,cRLSign
basicConstraints        = critical,CA:true,pathlen:0
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always
authorityInfoAccess     = @issuer_info
crlDistributionPoints   = @crl_info

[ crl_ext ]
authorityKeyIdentifier  = keyid:always
authorityInfoAccess     = @issuer_info

[ issuer_info ]
caIssuers;URI.0         = $aia_url

[ crl_info ]
URI.0                   = $crl_url

# Policy OIDs

[ openssl_init ]
oid_section             = additional_oids

[ additional_oids ]

```

    Writing /tmp/pki/ca/conf/root-ca.conf


Now let's create the **CA request**. The configuration for the creation of the **CSR** if found in the *configuration* file in the section `[req]`:

~~~.bash
\\( cd /tmp/pki
\\) openssl req -new \
            -config ca/conf/root-ca.conf \
            -out ca/root-ca/root-ca.csr \
            -keyout ca/root-ca/private/root-ca.key
            
Generating a 4096 bit RSA private key
.......................................++
............................++
writing new private key to 'ca/root-ca/private/root-ca.key'
Enter PEM pass phrase:
Verifying - Enter PEM pass phrase:
-----
~~~

Now create the **CA certificate** (will be valid for 10 years):

~~~.bash
\\( cd /tmp/pki
\\) openssl ca -selfsign \
           -config ca/conf/root-ca.conf \
           -in ca/root-ca/root-ca.csr \
           -out ca/root-ca/root-ca.crt \
           -extensions root_ca_ext \
           -days 3650
           
Using configuration from ca/conf/root-ca.conf
Enter pass phrase for ./ca/root-ca/private/root-ca.key:
Check that the request matches the signature
Signature ok
Certificate Details:
        Serial Number: 1 (0x1)
        Validity
            Not Before: Sep 28 17:37:10 2015 GMT
            Not After : Sep 25 17:37:10 2025 GMT
        Subject:
            countryName               = NU
            organizationName          = dornea.nu
            organizationalUnitName    = dornea.nu Root CA
            commonName                = dornea.nu Root CA
        X509v3 extensions:
            X509v3 Key Usage: critical
                Certificate Sign, CRL Sign
            X509v3 Basic Constraints: critical
                CA:TRUE
            X509v3 Subject Key Identifier: 
                72:39:A1:56:5E:9D:09:ED:8D:DE:31:9E:80:9B:C4:5D:62:3B:64:66
            X509v3 Authority Key Identifier: 
                keyid:72:39:A1:56:5E:9D:09:ED:8D:DE:31:9E:80:9B:C4:5D:62:3B:64:66

Certificate is to be certified until Sep 25 17:37:10 2025 GMT (3650 days)
Sign the certificate? [y/n]:Y


1 out of 1 certificate requests certified, commit? [y/n]y
Write out database with 1 new entries
Data Base Updated
          
~~~

Now you can check the **status** of the previously generated certificate (serial number = **1**):

~~~.bash
$ openssl -config ca/conf/root-ca.conf -status 01
Using configuration from ca/conf/root-ca.conf
01=Valid (V)
~~~

### Create dev.dornea.nu CA


```python
%%blockdiag
# <!-- collapse=True -->
blockdiag {
  // Define orientation
  orientation = portrait;

  // Define class (list of attributes)
  class emphasis [color = pink, style = dashed];
  class blackline [color = black, style = dotted];
  class blue [color = lightblue];
  class active [color = lightgreen];
  class inactive [color = lightgrey];    

  Root_CA [label = "dornea.nu root CA"];
  Signing_CA2 [class = active, label = "dev.dornea.nu CA"];
  Signing_CA3 [label = "vpn.dornea.nu CA"];
  TLS_Server_CA [label = "TLS Server Cert", shape = flowchart.terminator, style = dotted];
  TLS_Client_CA [label = "TLS Client Cert", shape = flowchart.terminator, style = dotted];
  VPN_Server_CA [class = inactive, label = "VPN Server Cert", shape = flowchart.terminator, style = dotted];
  VPN_Client_CA [class = inactive, label = "VPN Client Cert", shape = flowchart.terminator, style = dotted];

  Root_CA -> Signing_CA2;
  Root_CA -> Signing_CA3;

  Signing_CA2 -> TLS_Server_CA;
  Signing_CA2 -> TLS_Client_CA;
    
  Signing_CA3 -> VPN_Server_CA;
  Signing_CA3 -> VPN_Client_CA;
}
```


    
![png](/posts/img/2015/manage-a-pki-using-openssl/output_20_0.png)
    


Create the directories:


```python
%%bash↔

```

Initialize the database:


```bash
%%bash
cd /tmp/pki
touch ca/dev-ca/db/dev-ca.db
touch ca/dev-ca/db/dev-ca.db.attr
echo 01 > ca/dev-ca/db/dev-ca.crt.srl
echo 01 > ca/dev-ca/db/dev-ca.crl.srl
```

Configure the CA:


```python
%%writefile /tmp/pki/ca/conf/dev-ca.conf
# <!-- collapse=True -->

# dev.dornea.nu CA
# Adapated from https://pki-tutorial.readthedocs.org/en/latest/advanced/tls-ca.conf.html

[ default ]
ca                      = dev-ca                # CA name
dir                     = .                     # Top dir
base_url                = http://dev.dornea.nu/ca    # CA base URL
aia_url                 = $base_url/$ca.cer     # CA certificate URL
crl_url                 = $base_url/$ca.crl     # CRL distribution point
name_opt                = multiline,-esc_msb,utf8 # Display UTF-8 characters

# CA certificate request

[ req ]
default_bits            = 4096                  # RSA key size
encrypt_key             = yes                   # Protect private key
default_md              = sha2                  # MD to use
utf8                    = yes                   # Input is UTF-8
string_mask             = utf8only              # Emit UTF-8 strings
prompt                  = no                    # Don't prompt for DN
distinguished_name      = ca_dn                 # DN section
req_extensions          = ca_reqext             # Desired extensions

[ ca_dn ]
countryName             = "NU"
organizationName        = "dornea.nu"
organizationalUnitName  = "dornea.nu Root CA"
commonName              = "dev.dornea.nu CA"

[ ca_reqext ]
keyUsage                = critical,keyCertSign,cRLSign
basicConstraints        = critical,CA:true,pathlen:0
subjectKeyIdentifier    = hash

# CA operational settings

[ ca ]
default_ca              = dev_ca                # The default CA section

[ dev_ca ]
certificate             = $dir/ca/$ca/$ca.crt       # The CA cert
private_key             = $dir/ca/$ca/private/$ca.key # CA private key
new_certs_dir           = $dir/ca/$ca           # Certificate archive
serial                  = $dir/ca/$ca/db/$ca.crt.srl # Serial number file
crlnumber               = $dir/ca/$ca/db/$ca.crl.srl # CRL number file
database                = $dir/ca/$ca/db/$ca.db # Index file
unique_subject          = no                    # Require unique subject
default_days            = 365                   # How long to certify for
default_md              = sha256                # MD to use
policy                  = match_pol             # Default naming policy
email_in_dn             = no                    # Add email to cert DN
preserve                = no                    # Keep passed DN ordering
name_opt                = $name_opt             # Subject DN display options
cert_opt                = ca_default            # Certificate display options
copy_extensions         = copy                  # Copy extensions from CSR
x509_extensions         = server_ext            # Default cert extensions
default_crl_days        = 1                     # How long before next CRL
crl_extensions          = crl_ext               # CRL extensions

[ match_pol ]
countryName             = match                 # Must match 'NO'
stateOrProvinceName     = optional              # Included if present
localityName            = optional              # Included if present
organizationName        = match                 # Must match 'Green AS'
organizationalUnitName  = optional              # Included if present
commonName              = supplied              # Must be present

[ extern_pol ]
countryName             = supplied              # Must be present
stateOrProvinceName     = optional              # Included if present
localityName            = optional              # Included if present
organizationName        = supplied              # Must be present
organizationalUnitName  = optional              # Included if present
commonName              = supplied              # Must be present

[ any_pol ]
domainComponent         = optional
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = optional
emailAddress            = optional

# Extensions

[ server_ext ]
keyUsage                = critical,digitalSignature,keyEncipherment
basicConstraints        = CA:false
extendedKeyUsage        = serverAuth,clientAuth
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always
authorityInfoAccess     = @issuer_info
crlDistributionPoints   = @crl_info

[ client_ext ]
keyUsage                = critical,digitalSignature
basicConstraints        = CA:false
extendedKeyUsage        = clientAuth
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always
authorityInfoAccess     = @issuer_info
crlDistributionPoints   = @crl_info

[ crl_ext ]
authorityKeyIdentifier  = keyid:always
authorityInfoAccess     = @issuer_info

[ issuer_info ]
caIssuers;URI.0         = $aia_url

[ crl_info ]
URI.0                   = $crl_url

```

    Writing /tmp/pki/ca/conf/dev-ca.conf


Create **CA signing request** (CSR):
    
~~~.bash
\\( cd /tmp/pki
\\) openssl req -new \
            -config ca/conf/dev-ca.conf \
            -out ca/dev-ca/dev-ca.csr \
            -keyout ca/dev-ca/private/dev-ca.key
            
Generating a 4096 bit RSA private key
.............++
..........................................................................++
writing new private key to 'ca/dev-ca/private/dev-ca.key'
Enter PEM pass phrase:
Verifying - Enter PEM pass phrase:
-----

~~~

Now we use the **root CA** to create the **dev-ca** certificate:

~~~.bash
\\( cd /tmp/pki
\\) openssl ca -config ca/conf/root-ca.conf \
           -in ca/dev-ca/dev-ca.csr \       
           -out ca/dev-ca/dev-ca.crt \
           -extensions signing_ca_ext
           
Using configuration from ca/conf/root-ca.conf
Enter pass phrase for ./ca/root-ca/private/root-ca.key:
Check that the request matches the signature
Signature ok
Certificate Details:
        Serial Number: 2 (0x2)
        Validity
            Not Before: Sep 28 18:13:56 2015 GMT
            Not After : Sep 27 18:13:56 2025 GMT
        Subject:
            countryName               = NU
            organizationName          = dornea.nu
            organizationalUnitName    = dornea.nu Root CA
            commonName                = dev.dornea.nu CA
        X509v3 extensions:
            X509v3 Key Usage: critical
                Certificate Sign, CRL Sign
            X509v3 Basic Constraints: critical
                CA:TRUE, pathlen:0
            X509v3 Subject Key Identifier: 
                1A:42:33:7A:18:93:91:5F:B1:92:AA:37:39:76:31:92:3D:A6:2C:68
            X509v3 Authority Key Identifier: 
                keyid:B1:56:7C:FB:69:C7:77:CE:6C:7D:BA:CF:C7:7D:0C:6A:24:AF:8A:A1

            Authority Information Access: 
                CA Issuers - URI:http://pki.dornea.nu/root-ca.cer

            X509v3 CRL Distribution Points: 

                Full Name:
                  URI:http://pki.dornea.nu/root-ca.crl

Certificate is to be certified until Sep 27 18:13:56 2025 GMT (3652 days)
Sign the certificate? [y/n]:y


1 out of 1 certificate requests certified, commit? [y/n]y
Write out database with 1 new entries
Data Base Updated

~~~

### Create vpn.dornea.nu CA


```python
%%blockdiag
# <!-- collapse=True -->
blockdiag {
  // Define orientation
  orientation = portrait;

  // Define class (list of attributes)
  class emphasis [color = pink, style = dashed];
  class blackline [color = black, style = dotted];
  class blue [color = lightblue];
  class active [color = lightgreen];
  class inactive [color = lightgrey]; 

  Root_CA [label = "dornea.nu root CA"];
  Signing_CA2 [label = "dev.dornea.nu CA"];
  Signing_CA3 [class = active, label = "vpn.dornea.nu CA"];
  TLS_Server_CA [label = "TLS Server Cert", shape = flowchart.terminator, style = dotted];
  TLS_Client_CA [label = "TLS Client Cert", shape = flowchart.terminator, style = dotted];
  VPN_Server_CA [class = inactive, label = "VPN Server Cert", shape = flowchart.terminator, style = dotted];
  VPN_Client_CA [class = inactive, label = "VPN Client Cert", shape = flowchart.terminator, style = dotted];

  Root_CA -> Signing_CA2;
  Root_CA -> Signing_CA3;

  Signing_CA2 -> TLS_Server_CA;
  Signing_CA2 -> TLS_Client_CA;
    
  Signing_CA3 -> VPN_Server_CA;
  Signing_CA3 -> VPN_Client_CA;
}
```


    
![png](/posts/img/2015/manage-a-pki-using-openssl/output_30_0.png)
    


Create the directories:


```bash
%%bash
cd /tmp/pki
mkdir -p ca/vpn-ca/ ca/vpn-ca/private ca/vpn-ca/db ca/vpn-ca/certs
```

Initialize the database:


```bash
%%bash
cd /tmp/pki
touch ca/vpn-ca/db/vpn-ca.db
touch ca/vpn-ca/db/vpn-ca.db.attr
echo 01 > ca/vpn-ca/db/vpn-ca.crt.srl
echo 01 > ca/vpn-ca/db/vpn-ca.crl.srl
```

Configure CA:


```python
%%writefile /tmp/pki/ca/conf/vpn-ca.conf
# <!-- collapse=True -->

# vpn.dornea.nu CA
# Adapated from https://pki-tutorial.readthedocs.org/en/latest/advanced/tls-ca.conf.html

[ default ]
ca                      = vpn-ca                # CA name
dir                     = .                     # Top dir
base_url                = http://vpn.dornea.nu/ca    # CA base URL
aia_url                 = $base_url/$ca.cer     # CA certificate URL
crl_url                 = $base_url/$ca.crl     # CRL distribution point
name_opt                = multiline,-esc_msb,utf8 # Display UTF-8 characters

# CA certificate request

[ req ]
default_bits            = 4096                  # RSA key size
encrypt_key             = yes                   # Protect private key
default_md              = sha2                  # MD to use
utf8                    = yes                   # Input is UTF-8
string_mask             = utf8only              # Emit UTF-8 strings
prompt                  = no                    # Don't prompt for DN
distinguished_name      = ca_dn                 # DN section
req_extensions          = ca_reqext             # Desired extensions

[ ca_dn ]
countryName             = "NU"
organizationName        = "dornea.nu"
organizationalUnitName  = "dornea.nu Root CA"
commonName              = "vpn.dornea.nu CA"

[ ca_reqext ]
keyUsage                = critical,keyCertSign,cRLSign
basicConstraints        = critical,CA:true,pathlen:0
subjectKeyIdentifier    = hash

# CA operational settings

[ ca ]
default_ca              = vpn_ca                # The default CA section

[ vpn_ca ]
certificate             = $dir/ca/$ca/$ca.crt       # The CA cert
private_key             = $dir/ca/$ca/private/$ca.key # CA private key
new_certs_dir           = $dir/ca/$ca           # Certificate archive
serial                  = $dir/ca/$ca/db/$ca.crt.srl # Serial number file
crlnumber               = $dir/ca/$ca/db/$ca.crl.srl # CRL number file
database                = $dir/ca/$ca/db/$ca.db # Index file
unique_subject          = no                    # Require unique subject
default_days            = 365                   # How long to certify for
default_md              = sha1                  # MD to use
policy                  = match_pol             # Default naming policy
email_in_dn             = no                    # Add email to cert DN
preserve                = no                    # Keep passed DN ordering
name_opt                = $name_opt             # Subject DN display options
cert_opt                = ca_default            # Certificate display options
copy_extensions         = copy                  # Copy extensions from CSR
x509_extensions         = server_ext            # Default cert extensions
default_crl_days        = 1                     # How long before next CRL
crl_extensions          = crl_ext               # CRL extensions

[ match_pol ]
countryName             = match                 # Must match 'NO'
stateOrProvinceName     = optional              # Included if present
localityName            = optional              # Included if present
organizationName        = match                 # Must match 'Green AS'
organizationalUnitName  = optional              # Included if present
commonName              = supplied              # Must be present

[ extern_pol ]
countryName             = supplied              # Must be present
stateOrProvinceName     = optional              # Included if present
localityName            = optional              # Included if present
organizationName        = supplied              # Must be present
organizationalUnitName  = optional              # Included if present
commonName              = supplied              # Must be present

[ any_pol ]
domainComponent         = optional
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = optional
emailAddress            = optional

# Extensions

[ server_ext ]
keyUsage                = critical,digitalSignature,keyEncipherment
basicConstraints        = CA:false
extendedKeyUsage        = serverAuth,clientAuth
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always
authorityInfoAccess     = @issuer_info
crlDistributionPoints   = @crl_info

[ client_ext ]
keyUsage                = critical,digitalSignature
basicConstraints        = CA:false
extendedKeyUsage        = clientAuth
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always
authorityInfoAccess     = @issuer_info
crlDistributionPoints   = @crl_info

[ crl_ext ]
authorityKeyIdentifier  = keyid:always
authorityInfoAccess     = @issuer_info

[ issuer_info ]
caIssuers;URI.0         = $aia_url

[ crl_info ]
URI.0                   = $crl_url

```

    Overwriting /tmp/pki/ca/conf/vpn-ca.conf


Create **CA signing request** (CSR):

~~~.bash
\\( cd /tmp/pki
\\) openssl req -new \
            -config ca/conf/vpn-ca.conf \
            -out ca/vpn-ca/vpn-ca.csr \
            -keyout ca/vpn-ca/private/vpn-ca.key
            
Generating a 4096 bit RSA private key
...........................................++
.......++
writing new private key to 'ca/vpn-ca/private/vpn-ca.key'
Enter PEM pass phrase:
Verifying - Enter PEM pass phrase:
-----

~~~

Now we use the **root CA** to create the **vpn-ca** certificate:

~~~.bash
\\( cd /tmp/pki
\\) openssl ca -config ca/conf/root-ca.conf \
           -in ca/vpn-ca/vpn-ca.csr \       
           -out ca/vpn-ca/vpn-ca.crt \
           -extensions signing_ca_ext
           
Using configuration from ca/conf/root-ca.conf
Enter pass phrase for ./ca/root-ca/private/root-ca.key:
Check that the request matches the signature
Signature ok
Certificate Details:
        Serial Number: 3 (0x3)
        Validity
            Not Before: Sep 29 18:28:45 2015 GMT
            Not After : Sep 28 18:28:45 2025 GMT
        Subject:
            countryName               = NU
            organizationName          = dornea.nu
            organizationalUnitName    = dornea.nu Root CA
            commonName                = vpn.dornea.nu CA
        X509v3 extensions:
            X509v3 Key Usage: critical
                Certificate Sign, CRL Sign
            X509v3 Basic Constraints: critical
                CA:TRUE, pathlen:0
            X509v3 Subject Key Identifier: 
                52:53:49:45:12:D4:7B:A3:B7:8D:E0:14:00:81:4E:30:BC:A0:19:69
            X509v3 Authority Key Identifier: 
                keyid:F4:3B:44:1F:6D:02:26:06:C1:16:B9:1F:84:FC:41:48:5B:F6:0D:77

            Authority Information Access: 
                CA Issuers - URI:http://pki.dornea.nu/root-ca.cer

            X509v3 CRL Distribution Points: 

                Full Name:
                  URI:http://pki.dornea.nu/root-ca.crl

Certificate is to be certified until Sep 28 18:28:45 2025 GMT (3652 days)
Sign the certificate? [y/n]:y


1 out of 1 certificate requests certified, commit? [y/n]y
Write out database with 1 new entries
Data Base Updated
           
~~~

## Create dev-ca CA chain


```bash
%%bash
cd /tmp/pki
cat ca/dev-ca/dev-ca.crt ca/root-ca/root-ca.crt > ca/dev-ca/dev-ca-chain.pem
```

## Create vpn-ca CA chain


```bash
%%bash
cd /tmp/pki
cat ca/vpn-ca/vpn-ca.crt ca/root-ca/root-ca.crt > ca/vpn-ca/vpn-ca-chain.pem
```

# Issue dev-CA certificates

We'll now create the **TLS** *server* and *client* certificates.

## Create TLS server certificate


```python
%%blockdiag
# <!-- collapse=True -->
blockdiag {
  // Define orientation
  orientation = portrait;

  // Define class (list of attributes)
  class emphasis [color = pink, style = dashed];
  class blackline [color = black, style = dotted];
  class blue [color = lightblue];
  class active [color = lightgreen];
  class inactive [color = lightgrey]; 

  Root_CA [label = "dornea.nu root CA"];
  Signing_CA2 [label = "dev.dornea.nu CA"];
  Signing_CA3 [label = "vpn.dornea.nu CA"];
  TLS_Server_CA [class = active, label = "TLS Server Cert", shape = flowchart.terminator, style = dotted];
  TLS_Client_CA [label = "TLS Client Cert", shape = flowchart.terminator, style = dotted];
  VPN_Server_CA [class = inactive, label = "VPN Server Cert", shape = flowchart.terminator, style = dotted];
  VPN_Client_CA [class = inactive, label = "VPN Client Cert", shape = flowchart.terminator, style = dotted];
    
  dev_dornea_nu [class = active, label = "DNS: dev.dornea.nu\nDNS: dev2.dornea.nu\nIP: 10.10.10.1\nIP: 10.20.20.1"];

  Root_CA -> Signing_CA2;
  Root_CA -> Signing_CA3;

  Signing_CA2 -> TLS_Server_CA;
  Signing_CA2 -> TLS_Client_CA;
    
  Signing_CA3 -> VPN_Server_CA;
  Signing_CA3 -> VPN_Client_CA;
    
  TLS_Server_CA -> dev_dornea_nu;
}
```


    
![png](/posts/img/2015/manage-a-pki-using-openssl/output_44_0.png)
    


We will specify **multiple domains** with one certificate by using **SANs** (Subject Alternatve Name). Those are a *X.509* V3 extension to allow a SSL certificate to specify multiple names that the certificate should match. They can contain:

* mail addresses
* IP addresses
* DNS names
* etc.

Let's have a look at the config file:


```python
%%writefile /tmp/pki/ca/conf/vpn-server-cert.conf
# <!-- collapse=True -->

# # Code-signing certificate request for the VPN server
# Adapted from https://pki-tutorial.readthedocs.org/en/latest/advanced/server.conf.html

[ default ]
SAN                     = DNS:dev.dornea.nu    # Default value / [S]ubject[A]lt[N]ame

[ req ]
default_bits            = 4096                  # RSA key size
encrypt_key             = no                    # Protect private key
default_md              = sha2                  # MD to use
utf8                    = yes                   # Input is UTF-8
string_mask             = utf8only              # Emit UTF-8 strings
prompt                  = yes                   # Prompt for DN
distinguished_name      = server_dn             # DN template
req_extensions          = server_reqext         # Desired extensions

[ server_dn ]
countryName             = "1. Country Name (2 letters) (eg, US)       "
countryName_max         = 2
stateOrProvinceName     = "2. State or Province Name   (eg, region)   "
localityName            = "3. Locality Name            (eg, city)     "
organizationName        = "4. Organization Name        (eg, company)  "
organizationalUnitName  = "5. Organizational Unit Name (eg, section)  "
commonName              = "6. Common Name              (eg, FQDN)     "
commonName_max          = 64

[ server_reqext ]
keyUsage                = critical,digitalSignature,keyEncipherment
extendedKeyUsage        = serverAuth,clientAuth
subjectKeyIdentifier    = hash
subjectAltName          = @alt_names

[alt_names]
DNS.1 = dev.dornea.nu
DNS.2 = dev2.dornea.nu
IP.1 = 10.10.10.1
IP.2 = 10.20.20.1
```

    Overwriting /tmp/pki/ca/conf/dev-server-ca.conf


Create directories:


```bash
%%bash
cd /tmp/pki
mkdir -p ca/dev-server-ca/ ca/dev-server-ca/private ca/dev-server-ca/db ca/dev-server-ca/certs
```

Create a private key and CSR for the TLS server certificate:

~~~.bash
\\( cd /tmp/pki
\\) openssl req -new \
            -config ca/conf/dev-server-ca.conf \
            -out ca/dev-server-ca/certs/dev.dornea.nu.csr \
            -keyout ca/dev-server-ca/certs/dev.dornea.nu.key
            
Generating a 4096 bit RSA private key
......................................................................................................................................................++
...........................................++
writing new private key to 'ca/dev-server-ca/private/dev-server-ca.key'
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
1. Country Name (2 letters) (eg, US)        []:DE
2. State or Province Name   (eg, region)    []:Berlin
3. Locality Name            (eg, city)      []:Berlin
4. Organization Name        (eg, company)   []:dornea.nu
5. Organizational Unit Name (eg, section)   []:dev.dornea.nu
6. Common Name              (eg, FQDN)      []:dev.dornea.nu
~~~

Now use the **dev-ca** certificate to issue the TLS server certificate:

~~~.bash
\\( cd /tmp/pki
\\) openssl ca -config ca/conf/dev-ca.conf \
            -in ca/dev-server-ca/certs/dev.dornea.nu.csr \
            -out ca/dev-server-ca/certs/dev.dornea.nu.crt \
            -extensions server_ext
~~~

Now we create a **PKCS#12 bundle** including the private key, the certificate and the CA chain. 

> PKCS#12 defines an archive file format to store crypto stuff inside a *single* file. It is usually used to store a
> *private key* along with the *X.509 certificate*. The PKCS#12 file may be *encrypted* and *signed*.

~~~.bash
\\( cd /tmp/pki
\\) openssl pkcs12 -export \
                -name "dev.dornea.nu (Developer)" \
                -caname "dev.dornea.nu CA" \
                -caname "dornea.nu root CA" \
                -inkey certs/green.no.key \
                -in ca/dev-server-ca/certs/dev.dornea.nu.crt \
                -certfile ca/dev-server-ca/dev-ca-chain.pem \
                -out ca/dev-server-ca/certs/dev.dornea.nu.p12
Enter Export Password:
Verifying - Enter Export Password:
~~~

### Verify PKCS#12 bundle

You can now verify the bundle:

~~~.bash
$ openssl pkcs12 -in ca/dev-server-ca/certs/dev.dornea.nu.p12 -info | egrep -e "issuer" -e "subject"
Enter Import Password:
MAC Iteration 2048
MAC verified OK
PKCS7 Encrypted data: pbeWithSHA1And40BitRC2-CBC, Iteration 2048
Certificate bag
Certificate bag
Certificate bag
PKCS7 Data
Shrouded Keybag: pbeWithSHA1And3-KeyTripleDES-CBC, Iteration 2048
subject=/C=NU/ST=Germany/L=Berlin/O=dornea.nu/OU=dev dornea.nu/CN=dev.dornea.nu
issuer=/C=NU/O=dornea.nu/OU=dornea.nu Root CA/CN=dev.dornea.nu CA
subject=/C=NU/O=dornea.nu/OU=dornea.nu Root CA/CN=dev.dornea.nu CA
issuer=/C=NU/O=dornea.nu/OU=dornea.nu Root CA/CN=dornea.nu Root CA
Enter PEM pass phrase:
subject=/C=NU/O=dornea.nu/OU=dornea.nu Root CA/CN=dornea.nu Root CA
issuer=/C=NU/O=dornea.nu/OU=dornea.nu Root CA/CN=dornea.nu Root CA
~~~

## Create TLS client certificate


```python
%%blockdiag
# <!-- collapse=True -->
blockdiag {
  // Define orientation
  orientation = portrait;

  // Define class (list of attributes)
  class emphasis [color = pink, style = dashed];
  class blackline [color = black, style = dotted];
  class blue [color = lightblue];
  class active [color = lightgreen];
  class inactive [color = lightgrey]; 

  Root_CA [label = "dornea.nu root CA"];
  Signing_CA2 [label = "dev.dornea.nu CA"];
  Signing_CA3 [label = "vpn.dornea.nu CA"];
  TLS_Server_CA [label = "TLS Server Cert", shape = flowchart.terminator, style = dotted];
  TLS_Client_CA [class = active, label = "TLS Client Cert", shape = flowchart.terminator, style = dotted];
  VPN_Server_CA [class = inactive, label = "VPN Server Cert", shape = flowchart.terminator, style = dotted];
  VPN_Client_CA [class = inactive, label = "VPN Client Cert", shape = flowchart.terminator, style = dotted];
    
  dev_client_victor [class = active, label = "CN: Victor Dorneanu\n"];

  Root_CA -> Signing_CA2;
  Root_CA -> Signing_CA3;

  Signing_CA2 -> TLS_Server_CA;
  Signing_CA2 -> TLS_Client_CA;
    
  Signing_CA3 -> VPN_Server_CA;
  Signing_CA3 -> VPN_Client_CA;
    
  TLS_Client_CA -> dev_client_victor;
}
```


    
![png](/posts/img/2015/manage-a-pki-using-openssl/output_52_0.png)
    


Create directories:


```bash
%%bash
cd /tmp/pki
mkdir -p ca/dev-client-ca/ ca/dev-client-ca/ ca/dev-client-ca/db ca/dev-client-ca/certs
```

Create config:


```python
%%writefile /tmp/pki/ca/conf/dev-client-ca.conf↔

```

    Overwriting /tmp/pki/ca/conf/dev-client-ca.conf


Now I'll create a new CSR for the user **victor**:

~~~.bash
\\( openssl req -new \\
            -config ca/conf/dev-client-ca.conf \\
            -out ca/dev-client-ca/certs/victor.csr \\
            -keyout ca/dev-client-ca/certs/victor.key
Generating a 4096 bit RSA private key
.......................................................................................++
..........................................................................................................................................................................................++
writing new private key to 'ca/dev-client-ca/certs/victor.key'
Enter PEM pass phrase:
Verifying - Enter PEM pass phrase:
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
1. Country Name (2 letters) (eg, US)        []:NU
2. State or Province Name   (eg, region)    []:Germany
3. Locality Name            (eg, city)      []:Berlin
4. Organization Name        (eg, company)   []:dornea.nu
5. Organizational Unit Name (eg, section)   []:dev dornea.nu
6. Common Name              (eg, full name) []:Victor Dorneanu
7. Email Address            (eg, name@fqdn) []:blabla@dornea.nu
~~~

Now create the TLS client certificate:

~~~.bash
\\) openssl ca -config ca/conf/dev-ca.conf \
            -in ca/dev-client-ca/certs/victor.csr \
            -out ca/dev-client-ca/certs/victor.crt \
            -extensions client_ext
            
Using configuration from ca/conf/dev-ca.conf
Enter pass phrase for ./ca/dev-ca/private/dev-ca.key:
Check that the request matches the signature
Signature ok
Certificate Details:
        Serial Number: 3 (0x3)
        Validity
            Not Before: Sep 30 19:01:14 2015 GMT
            Not After : Sep 29 19:01:14 2016 GMT
        Subject:
            countryName               = NU
            stateOrProvinceName       = Germany
            localityName              = Berlin
            organizationName          = dornea.nu
            organizationalUnitName    = dev dornea.nu
            commonName                = Victor Dorneanu
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature
            X509v3 Basic Constraints: 
                CA:FALSE
            X509v3 Extended Key Usage: 
                TLS Web Client Authentication
            X509v3 Subject Key Identifier: 
                21:E4:47:97:E8:90:39:B5:8C:8A:5B:DD:24:78:23:A9:17:DB:97:9E
            X509v3 Authority Key Identifier: 
                keyid:C5:7E:17:39:6F:CE:D2:40:B8:7E:B8:5D:0E:41:04:75:BB:0D:2B:98

            Authority Information Access: 
                CA Issuers - URI:http://dev.dornea.nu/ca/dev-ca.cer

            X509v3 CRL Distribution Points: 

                Full Name:
                  URI:http://dev.dornea.nu/ca/dev-ca.crl

            X509v3 Subject Alternative Name: 
                email:blabla@dornea.nu
Certificate is to be certified until Sep 29 19:01:14 2016 GMT (365 days)
Sign the certificate? [y/n]:y


1 out of 1 certificate requests certified, commit? [y/n]y
Write out database with 1 new entries
Data Base Updated

~~~

### Create PKCS#12 bundle

~~~.bash
\\( openssl pkcs12 -export \\
                 -name "dev.dornea.nu (Developer)" \\
                 -caname "dev.dornea.nu CA" \\
                 -caname "dornea.nu Root CA" \\
                 -inkey ca/dev-client-ca/certs/victor.key \\ 
                 -in ca/dev-client-ca/certs/victor.crt \\ 
                 -certfile ca/dev-ca/dev-ca-chain.pem \\ 
                 -out ca/dev-client-ca/certs/victor.p12        
Enter pass phrase for ca/dev-client-ca/certs/victor.key:
Enter Export Password:
Verifying - Enter Export Password:
~~~

Now *verify* the bundle:

~~~.bash
\\) openssl pkcs12 -in ca/dev-client-ca/certs/victor.p12 -info | egrep -e "issuer" -e "subject"
Enter Import Password:
MAC Iteration 2048
MAC verified OK
PKCS7 Encrypted data: pbeWithSHA1And40BitRC2-CBC, Iteration 2048
Certificate bag
Certificate bag
Certificate bag
PKCS7 Data
Shrouded Keybag: pbeWithSHA1And3-KeyTripleDES-CBC, Iteration 2048
subject=/C=NU/ST=Germany/L=Berlin/O=dornea.nu/OU=dev dornea.nu/CN=Victor Dorneanu
issuer=/C=NU/O=dornea.nu/OU=dornea.nu Root CA/CN=dev.dornea.nu CA
subject=/C=NU/O=dornea.nu/OU=dornea.nu Root CA/CN=dev.dornea.nu CA
issuer=/C=NU/O=dornea.nu/OU=dornea.nu Root CA/CN=dornea.nu Root CA
Enter PEM pass phrase:
Verifying - Enter PEM pass phrase:
subject=/C=NU/O=dornea.nu/OU=dornea.nu Root CA/CN=dornea.nu Root CA
issuer=/C=NU/O=dornea.nu/OU=dornea.nu Root CA/CN=dornea.nu Root CA

~~~

# Issue vpn-CA certificates

We'll now create **VPN** *server* and *client* certificates.

## Create VPN server certificate



```python
%%blockdiag
# <!-- collapse=True -->
blockdiag {↔

  // Define class (list of attributes)
  class emphasis [color = pink, style = dashed];
  class blackline [color = black, style = dotted];
  class blue [color = lightblue];
  class active [color = lightgreen];
  class inactive [color = lightgrey]; 

  Root_CA [label = "dornea.nu root CA"];
  Signing_CA2 [label = "dev.dornea.nu CA"];
  Signing_CA3 [label = "vpn.dornea.nu CA"];
  TLS_Server_CA [label = "TLS Server Cert", shape = flowchart.terminator, style = dotted];
  TLS_Client_CA [label = "TLS Client Cert", shape = flowchart.terminator, style = dotted];
  VPN_Server_CA [class = active, label = "VPN Server Cert", shape = flowchart.terminator, style = dotted];
  VPN_Client_CA [label = "VPN Client Cert", shape = flowchart.terminator, style = dotted];
    

  Root_CA -> Signing_CA2;
  Root_CA -> Signing_CA3;

  Signing_CA2 -> TLS_Server_CA;
  Signing_CA2 -> TLS_Client_CA;
    
  Signing_CA3 -> VPN_Server_CA;
  Signing_CA3 -> VPN_Client_CA;
}
```


    
![png](/posts/img/2015/manage-a-pki-using-openssl/output_60_0.png)
    



```bash
%%bash
cd /tmp/pki
mkdir -p ca/vpn-ca/certs/vpn-server
```


```python
%%writefile /tmp/pki/ca/conf/vpn-server-cert.conf
# <!-- collapse=True -->

# dev.dornea.nu server certificate
# Adapted from https://pki-tutorial.readthedocs.org/en/latest/advanced/codesign.conf.html

[ req ]
default_bits            = 4096                    # RSA key size
encrypt_key             = yes                     # Protect private key
default_md              = sha2                    # MD to use
utf8                    = yes                     # Input is UTF-8
string_mask             = utf8only                # Emit UTF-8 strings
prompt                  = yes                     # Prompt for DN
distinguished_name      = vpn_server_dn           # DN template
req_extensions          = vpn_server_reqext       # Desired extensions

[ vpn_server_dn ]
countryName             = "1. Country Name (2 letters) (eg, US)       "
countryName_max         = 2
stateOrProvinceName     = "2. State or Province Name   (eg, region)   "
localityName            = "3. Locality Name            (eg, city)     "
organizationName        = "4. Organization Name        (eg, company)  "
organizationalUnitName  = "5. Organizational Unit Name (eg, section)  "
commonName              = "6. Common Name              (eg, full name)"
commonName_max          = 64

[ vpn_server_reqext ]
keyUsage                = critical,digitalSignature
extendedKeyUsage        = critical,codeSigning
subjectKeyIdentifier    = hash
```

    Overwriting /tmp/pki/ca/conf/vpn-server-cert.conf


### Create CSR

And now create the **CSR** (Code Signing Request):
    
```.bash
\\( openssl req -new \\
            -config ca/conf/vpn-server-cert.conf \\
            -out ca/vpn-ca/certs/vpn-server/raspberry\_pi.csr \\
            -keyout ca/vpn-ca/certs/vpn-server/raspberry\_pi.key
            
Generating a 4096 bit RSA private key
............................................................................................................................................................++
.....................................++
writing new private key to 'ca/vpn-ca/certs/vpn-server/raspberry\_pi.key'
Enter PEM pass phrase:
Verifying - Enter PEM pass phrase:
Verify failure
Enter PEM pass phrase:
Verifying - Enter PEM pass phrase:
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
1. Country Name (2 letters) (eg, US)        []:NU
2. State or Province Name   (eg, region)    []:/dev/null
3. Locality Name            (eg, city)      []:/dev/random
4. Organization Name        (eg, company)   []:dornea.nu
5. Organizational Unit Name (eg, section)   []:VPN
6. Common Name              (eg, full name) []:vpn.dornea.nu

```


### Sign certificate 

Now use the **VPN-CA** to issue the **CRT** (Code Signing Certificate):

```.bash
\\) openssl ca -config ca/conf/vpn-ca.conf \                                                               1 ↵
                -in ca/vpn-ca/certs/vpn-server/raspberry_pi.csr \
                -out ca/vpn-ca/certs/vpn-server/raspberry_pi.crt \
                -extensions server_ext
                
Using configuration from ca/conf/vpn-ca.conf
Enter pass phrase for ./ca/vpn-ca/private/vpn-ca.key:
Check that the request matches the signature
Signature ok
Certificate Details:
        Serial Number: 1 (0x1)
        Validity
            Not Before: Nov  9 19:39:48 2015 GMT
            Not After : Nov  8 19:39:48 2016 GMT
        Subject:
            countryName               = NU
            stateOrProvinceName       = /dev/null
            localityName              = /dev/random
            organizationName          = dornea.nu
            organizationalUnitName    = VPN
            commonName                = vpn.dornea.nu
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Basic Constraints: 
                CA:FALSE
            X509v3 Extended Key Usage: 
                TLS Web Server Authentication, TLS Web Client Authentication
            X509v3 Subject Key Identifier: 
                80:CA:5B:3C:C7:8A:E4:76:FF:4B:DC:5D:17:F9:99:07:27:69:76:60
            X509v3 Authority Key Identifier: 
                keyid:E2:DB:62:AB:F4:5D:56:17:65:B2:FA:66:55:C9:04:1D:1C:9B:10:A3

            Authority Information Access: 
                CA Issuers - URI:http://vpn.dornea.nu/ca/vpn-ca.cer

            X509v3 CRL Distribution Points: 

                Full Name:
                  URI:http://vpn.dornea.nu/ca/vpn-ca.crl

Certificate is to be certified until Nov  8 19:39:48 2016 GMT (365 days)
Sign the certificate? [y/n]:y


1 out of 1 certificate requests certified, commit? [y/n]y
Write out database with 1 new entries
Data Base Updated

```

### Create PKCS12 bundle

Now bundle the **root** CA, **VPN** ca and the VPN **server** cert into one file:


```.bash
$ openssl pkcs12 -export \                                                    
    -name "VPN Server (Raspberry Pi)" \
    -caname "vpn.dornea.nu CA" \
    -caname "dornea.nu Root CA" \
    -inkey ca/vpn-ca/certs/vpn-server/raspberry_pi.key \
    -in ca/vpn-ca/certs/vpn-server/raspberry_pi.crt \
    -certfile ca/vpn-ca/vpn-ca-chain.pem \ 
    -out ca/vpn-ca/certs/vpn-server/raspberry_pi.p12
    
Enter pass phrase for ca/vpn-ca/certs/vpn-server/raspberry_pi.key:
Enter Export Password:
Verifying - Enter Export Password:
```

## Create VPN client certificate


```python
%%blockdiag
# <!-- collapse=True -->
blockdiag {
  // Define orientation
  orientation = portrait;

  // Define class (list of attributes)
  class emphasis [color = pink, style = dashed];
  class blackline [color = black, style = dotted];
  class blue [color = lightblue];
  class active [color = lightgreen];
  class inactive [color = lightgrey]; 

  Root_CA [label = "dornea.nu root CA"];
  Signing_CA2 [label = "dev.dornea.nu CA"];
  Signing_CA3 [label = "vpn.dornea.nu CA"];
  TLS_Server_CA [label = "TLS Server Cert", shape = flowchart.terminator, style = dotted];
  TLS_Client_CA [label = "TLS Client Cert", shape = flowchart.terminator, style = dotted];
  VPN_Server_CA [label = "VPN Server Cert", shape = flowchart.terminator, style = dotted];
  VPN_Client_CA [class = active, label = "VPN Client Cert", shape = flowchart.terminator, style = dotted];
    

  Root_CA -> Signing_CA2;
  Root_CA -> Signing_CA3;

  Signing_CA2 -> TLS_Server_CA;
  Signing_CA2 -> TLS_Client_CA;
    
  Signing_CA3 -> VPN_Server_CA;
  Signing_CA3 -> VPN_Client_CA;
}
```


    
![png](/posts/img/2015/manage-a-pki-using-openssl/output_65_0.png)
    



```bash
%%bash
cd /tmp/pki
mkdir -p ca/vpn-ca/certs/vpn-client
```


```python
%%writefile /tmp/pki/ca/conf/vpn-client-cert.conf
# <!-- collapse=True -->

# VPN client certificate
# Adapted from https://pki-tutorial.readthedocs.org/en/latest/advanced/client.conf.html

[ req ]
default_bits            = 4096                  # RSA key size
encrypt_key             = yes                   # Protect private key
default_md              = sha2                  # MD to use
utf8                    = yes                   # Input is UTF-8
string_mask             = utf8only              # Emit UTF-8 strings
prompt                  = yes                   # Prompt for DN
distinguished_name      = client_dn             # DN template
req_extensions          = client_reqext         # Desired extensions

[ client_dn ]
countryName             = "1. Country Name (2 letters) (eg, US)       "
countryName_max         = 2
stateOrProvinceName     = "2. State or Province Name   (eg, region)   "
localityName            = "3. Locality Name            (eg, city)     "
organizationName        = "4. Organization Name        (eg, company)  "
organizationalUnitName  = "5. Organizational Unit Name (eg, section)  "
commonName              = "6. Common Name              (eg, full name)"
commonName_max          = 64
emailAddress            = "7. Email Address            (eg, name@fqdn)"
emailAddress_max        = 40

[ client_reqext ]
keyUsage                = critical,digitalSignature
extendedKeyUsage        = clientAuth
subjectKeyIdentifier    = hash
subjectAltName          = email:move
```

    Overwriting /tmp/pki/ca/conf/vpn-client-cert.conf


### Create CSR

Now create the **CSR** for the user **victor**:

```.bash
\\( openssl req -new \\                      
            -config ca/conf/vpn-client-cert.conf \\               
            -out ca/vpn-ca/certs/vpn-client/victor.csr \\      
            -keyout ca/vpn-ca/certs/vpn-client/victor.key    
            
Generating a 4096 bit RSA private key
...............................................................++
................................................................................++
writing new private key to 'ca/vpn-ca/certs/vpn-client/victor.key'
Enter PEM pass phrase:
Verifying - Enter PEM pass phrase:
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
1. Country Name (2 letters) (eg, US)        []:NU
2. State or Province Name   (eg, region)    []:/dev/null
3. Locality Name            (eg, city)      []:/dev/random
4. Organization Name        (eg, company)   []:dornea.nu
5. Organizational Unit Name (eg, section)   []:vpn.dornea.nu
6. Common Name              (eg, full name) []:Victor Dorneanu
7. Email Address            (eg, name@fqdn) []:bla@nsa.gov

```

### Sign the CSR

Sign the **CSR** using **VPN-CA**:


```.bash
\\) openssl ca -config ca/conf/vpn-ca.conf \
                -in ca/vpn-ca/certs/vpn-client/victor.csr \      
                -out ca/vpn-ca/certs/vpn-client/victor.crt \      
                -extensions client_ext              
                
Using configuration from ca/conf/vpn-ca.conf
Enter pass phrase for ./ca/vpn-ca/private/vpn-ca.key:
Check that the request matches the signature
Signature ok
Certificate Details:
        Serial Number: 2 (0x2)
        Validity
            Not Before: Nov  9 19:49:16 2015 GMT
            Not After : Nov  8 19:49:16 2016 GMT
        Subject:
            countryName               = NU
            stateOrProvinceName       = /dev/null
            localityName              = /dev/random
            organizationName          = dornea.nu
            organizationalUnitName    = vpn.dornea.nu
            commonName                = Victor Dorneanu
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature
            X509v3 Basic Constraints: 
                CA:FALSE
            X509v3 Extended Key Usage: 
                TLS Web Client Authentication
            X509v3 Subject Key Identifier: 
                12:3F:57:DF:1D:DB:73:BC:E0:A0:97:18:0D:B9:6C:C9:FF:53:8E:1B
            X509v3 Authority Key Identifier: 
                keyid:E2:DB:62:AB:F4:5D:56:17:65:B2:FA:66:55:C9:04:1D:1C:9B:10:A3

            Authority Information Access: 
                CA Issuers - URI:http://vpn.dornea.nu/ca/vpn-ca.cer

            X509v3 CRL Distribution Points: 

                Full Name:
                  URI:http://vpn.dornea.nu/ca/vpn-ca.crl

            X509v3 Subject Alternative Name: 
                email:bla@nsa.gov
Certificate is to be certified until Nov  8 19:49:16 2016 GMT (365 days)
Sign the certificate? [y/n]:y


1 out of 1 certificate requests certified, commit? [y/n]y
Write out database with 1 new entries
Data Base Updated

```

### Create PKCS#12 bundle

Bundle the **root CA**, **VPN CA ** and the VPN **client** cert into a single file:

```.bash
$ openssl pkcs12 -export \
    -name "VPN Client (Victor)" \      
    -caname "vpn.dornea.nu CA" \
    -caname "dornea.nu Root CA" \
    -inkey ca/vpn-ca/certs/vpn-client/victor.key \ 
    -in ca/vpn-ca/certs/vpn-client/victor.crt \      
    -certfile ca/vpn-ca/vpn-ca-chain.pem \
    -out ca/vpn-ca/certs/vpn-client/victor.p12      
    
Enter pass phrase for ca/vpn-ca/certs/vpn-client/victor.key:
Enter Export Password:
Verifying - Enter Export Password:

```

## References

* https://pki-tutorial.readthedocs.org/en/latest/advanced/index.html
* http://serverfault.com/questions/306345/certification-authority-root-certificate-expiry-and-renewal
* http://www.flatmtn.com/article/setting-openssl-create-certificates
* https://www.debian-administration.org/article/284/Creating_and_Using_a_self_signed__SSL_Certificates_in_debian
* http://gatwards.org/techblog/creating-and-signing-ssl-certs
