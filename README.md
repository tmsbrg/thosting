# Thomas Hosting script

Thomas in the Clouds (With Diamonds)

Uses DigitalOcean and Porkbun APIs to create servers and give instantly give them a subdomain.

Also optionally uses Ansible to set them up with software (currently only supports xsshunter, playbook included!)

License: GPLv3

Requirements: ansible, httpie, doctl

First time setup:

 - first, edit editme.sh to set domain to a domain you control that's managed by Porkbun.
 - then, create a PAT for DigitalOcean and authenticate to DigitalOcean with `doctl auth init`
 - then, link an SSH key to your DigitalOcean account and find its ID with `doctl compute ssh-key list`, edit editme.sh and set ssh_key to this.
 - create an API key for the Porkbun API and save it in ~/porkbun-apikey.txt (first line API key, second line secret key)
 - For xsshunter playbook: Be sure to edit editme.sh to add your own email address there

Usage examples:

 - Create a new VM and link random.<domain> subdomain to it:
```
    thosting make random1
```

 - List current VMs:
```
    thosting list
```

 - Use xsshunter ansible playbook on the domain to deploy XSS hunter:
```
    thosting config random1 xsshunter
```

 - Create a VM at xss.<domain> and immediately set it up with the xsshunter ansible playbook (same as make and then config but in one command):
```
    thosting make xss xsshunter
```

 - Destroy created VM and the subdomain link
```
    thosting destroy random1
```

