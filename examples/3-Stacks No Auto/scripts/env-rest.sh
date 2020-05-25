for i in {west,central,east}
do
  : > ../$i/cluster-keys.json
  : > ../$i/nomad-bootstrap.txt
done
reset-ssh
