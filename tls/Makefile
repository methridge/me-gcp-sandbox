all: ca vault

ca:
	cfssl gencert -initca ca-csr.json | cfssljson -bare ca

vault:
	cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server vault-csr.json | cfssljson -bare vault
