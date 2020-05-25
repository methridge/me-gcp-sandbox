nomad acl bootstrap > nomad-bootstrap.txt

bootstrap_token=$(sed -n 2,2p nomad-bootstrap.txt | cut -d '=' -f 2 | sed 's/ //')

direnv reload